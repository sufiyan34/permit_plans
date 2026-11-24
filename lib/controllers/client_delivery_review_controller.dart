import 'dart:async';

import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:permit_plans/models/client_delivery_review_model.dart';
import 'package:permit_plans/models/project_delivery_model.dart';
import 'package:permit_plans/repositries/client_delivery_review_repository.dart';

class ClientDeliveryReviewController extends GetxController {
  ClientDeliveryReviewController({
    required ClientDeliveryReviewRepository repository,
  }) : _repository = repository;

  final ClientDeliveryReviewRepository _repository;

  final deliveries = <ClientDeliveryReviewModel>[].obs;
  final filteredDeliveries = <ClientDeliveryReviewModel>[].obs;
  final selectedDeliveryId = RxnString();
  final activeFilter = 'needs_review'.obs;
  final searchText = ''.obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final isReviewing = false.obs;
  final busyDeliveryId = ''.obs;
  final openingFileId = ''.obs;
  final errorMessage = ''.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  Timer? _realtimeDebounce;
  bool _ignoreInitialSnapshot = true;
  bool _pendingRealtimeRefresh = false;
  bool _isDisposed = false;

  ClientDeliveryReviewModel? get selectedDelivery {
    final id = selectedDeliveryId.value;
    if (id == null) return null;
    for (final item in deliveries) {
      if (item.deliveryId == id) return item;
    }
    return null;
  }

  int get needsReviewCount =>
      deliveries.where((item) => item.status == 'submitted').length;
  int get revisionRequestedCount =>
      deliveries.where((item) => item.status == 'revision_requested').length;
  int get approvedCount =>
      deliveries.where((item) => item.status == 'approved').length;

  @override
  void onInit() {
    super.onInit();
    _subscribeToChanges();
    unawaited(loadReviews());
  }

  @override
  void onClose() {
    _isDisposed = true;
    _realtimeDebounce?.cancel();
    final subscription = _subscription;
    if (subscription != null) unawaited(subscription.cancel());
    super.onClose();
  }

  void selectFilter(String filter) {
    if (activeFilter.value == filter) return;
    activeFilter.value = filter;
    _applyFilters();
  }

  void setSearch(String value) {
    searchText.value = value;
    _applyFilters();
  }

  void selectDelivery(ClientDeliveryReviewModel item) {
    selectedDeliveryId.value = item.deliveryId;
  }

  Future<void> refresh() => loadReviews(refresh: true);

  Future<void> loadReviews({bool refresh = false}) async {
    if (isLoading.value || isRefreshing.value) {
      if (refresh) _pendingRealtimeRefresh = true;
      return;
    }
    if (refresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    errorMessage.value = '';
    try {
      final result = await _repository.fetchReviews();
      deliveries.assignAll(result);
      if (!result.any((item) => item.deliveryId == selectedDeliveryId.value)) {
        selectedDeliveryId.value = result.isEmpty ? null : result.first.deliveryId;
      }
      _applyFilters();
      if (selectedDeliveryId.value != null &&
          !filteredDeliveries.any(
            (item) => item.deliveryId == selectedDeliveryId.value,
          ) &&
          filteredDeliveries.isNotEmpty) {
        selectedDeliveryId.value = filteredDeliveries.first.deliveryId;
      }
    } on ClientDeliveryReviewException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Unable to load your deliveries. Please try again.';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      if (_pendingRealtimeRefresh && !_isDisposed) {
        _pendingRealtimeRefresh = false;
        _scheduleRealtimeRefresh();
      }
    }
  }

  Future<bool> approveDelivery(String deliveryId, {String? note}) async {
    return _review(
      deliveryId: deliveryId,
      action: 'approve',
      note: note,
    );
  }

  Future<bool> requestRevision(String deliveryId, String note) async {
    final trimmed = note.trim();
    if (trimmed.length < 10 || trimmed.length > 3000) {
      Get.snackbar(
        'Add revision instructions',
        'Explain the changes in at least 10 characters (maximum 3,000).',
      );
      return false;
    }
    return _review(
      deliveryId: deliveryId,
      action: 'request_revision',
      note: trimmed,
    );
  }

  Future<bool> _review({
    required String deliveryId,
    required String action,
    String? note,
  }) async {
    if (isReviewing.value) return false;
    isReviewing.value = true;
    busyDeliveryId.value = deliveryId;
    try {
      await _repository.reviewDelivery(
        deliveryId: deliveryId,
        action: action,
        reviewNote: note,
      );
      await loadReviews();
      final title = action == 'approve' ? 'Delivery approved' : 'Revision requested';
      final message = action == 'approve'
          ? 'The project work has been marked complete. Payment release is a separate step.'
          : 'Your instructions have been sent to the Engineer.';
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } on ClientDeliveryReviewException catch (error) {
      Get.snackbar('Could not save review', error.message);
      return false;
    } finally {
      isReviewing.value = false;
      busyDeliveryId.value = '';
    }
  }

  Future<void> openFile(ProjectDeliveryFile file) async {
    if (openingFileId.value.isNotEmpty) return;
    openingFileId.value = file.id;
    try {
      final link = await _repository.createFileLink(file.storagePath);
      final opened = await launchUrl(
        Uri.parse(link),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        Get.snackbar('Unable to open file', 'Please try again on this device.');
      }
    } on ClientDeliveryReviewException catch (error) {
      Get.snackbar('File unavailable', error.message);
    } catch (_) {
      Get.snackbar('File unavailable', 'A secure file link could not be opened.');
    } finally {
      openingFileId.value = '';
    }
  }

  void _subscribeToChanges() {
    if (_repository.currentUserId == null) return;
    try {
      _subscription = _repository.watchDeliveryChanges().listen(
        (rows) {
          if (_ignoreInitialSnapshot) {
            _ignoreInitialSnapshot = false;
            if (_snapshotDiffers(rows)) _scheduleRealtimeRefresh();
            return;
          }
          _scheduleRealtimeRefresh();
        },
        onError: (Object error, StackTrace stackTrace) {
          // Screen remains usable via pull-to-refresh if Realtime is offline.
        },
      );
    } catch (_) {
      // A failed subscription must not prevent the initial RPC fetch.
    }
  }

  bool _snapshotDiffers(List<Map<String, dynamic>> rows) {
    final loaded = <String, String>{
      for (final item in deliveries) item.deliveryId: item.status,
    };
    if (rows.length != loaded.length) return true;
    for (final row in rows) {
      final id = row['id']?.toString();
      final status = row['status']?.toString();
      if (id == null || loaded[id] != status) return true;
    }
    return false;
  }

  void _scheduleRealtimeRefresh() {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!_isDisposed) unawaited(loadReviews(refresh: true));
    });
  }

  void _applyFilters() {
    Iterable<ClientDeliveryReviewModel> result = deliveries;
    switch (activeFilter.value) {
      case 'needs_review':
        result = result.where((item) => item.status == 'submitted');
        break;
      case 'revision_requested':
        result = result.where((item) => item.status == 'revision_requested');
        break;
      case 'approved':
        result = result.where((item) => item.status == 'approved');
        break;
      case 'all':
      default:
        break;
    }
    final query = searchText.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((item) =>
          item.taskTitle.toLowerCase().contains(query) ||
          item.engineerName.toLowerCase().contains(query) ||
          item.message.toLowerCase().contains(query) ||
          item.taskCategory.toLowerCase().contains(query));
    }
    final visible = result.toList(growable: false);
    filteredDeliveries.assignAll(visible);
    if (!visible.any((item) => item.deliveryId == selectedDeliveryId.value)) {
      selectedDeliveryId.value = visible.isEmpty ? null : visible.first.deliveryId;
    }
  }
}
