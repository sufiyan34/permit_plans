import 'dart:async';

import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/models/client_delivery_review_model.dart';
import 'package:permit_plans/models/project_delivery_model.dart';
import 'package:permit_plans/repositries/client_delivery_review_repository.dart';

/// Screen 25 — a Client library for work that was already approved on Screen 23.
/// This screen is read-only: it does not approve work or release payments.
class ClientFinalApprovalController extends GetxController {
  ClientFinalApprovalController({
    required ClientDeliveryReviewRepository repository,
  }) : _repository = repository;

  final ClientDeliveryReviewRepository _repository;

  final approvedDeliveries = <ClientDeliveryReviewModel>[].obs;
  final filteredDeliveries = <ClientDeliveryReviewModel>[].obs;
  final selectedDeliveryId = RxnString();
  final searchText = ''.obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final openingFileId = ''.obs;
  final errorMessage = ''.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  Timer? _refreshDebounce;
  bool _pendingRefresh = false;
  bool _disposed = false;

  ClientDeliveryReviewModel? get selectedDelivery {
    final id = selectedDeliveryId.value;
    if (id == null) return null;
    for (final delivery in approvedDeliveries) {
      if (delivery.deliveryId == id) return delivery;
    }
    return null;
  }

  int get completedProjectCount => approvedDeliveries
      .map((delivery) => delivery.contractId)
      .toSet()
      .length;

  int get finalFileCount => approvedDeliveries.fold<int>(
        0,
        (total, delivery) => total + delivery.files.length,
      );

  @override
  void onInit() {
    super.onInit();
    _subscribeToDeliveryChanges();
    unawaited(loadFinalDeliveries());
  }

  @override
  void onClose() {
    _disposed = true;
    _refreshDebounce?.cancel();
    final subscription = _subscription;
    if (subscription != null) unawaited(subscription.cancel());
    super.onClose();
  }

  Future<void> refresh() => loadFinalDeliveries(refresh: true);

  Future<void> loadFinalDeliveries({bool refresh = false}) async {
    if (isLoading.value || isRefreshing.value) {
      if (refresh) _pendingRefresh = true;
      return;
    }

    if (refresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
      final allDeliveries = await _repository.fetchReviews();
      final approved = allDeliveries
          .where((delivery) => delivery.status == 'approved')
          .toList(growable: true)
        ..sort((a, b) {
          final aDate = a.reviewedAt ?? a.createdAt;
          final bDate = b.reviewedAt ?? b.createdAt;
          return bDate.compareTo(aDate);
        });

      approvedDeliveries.assignAll(approved);
      if (!approved.any(
        (delivery) => delivery.deliveryId == selectedDeliveryId.value,
      )) {
        selectedDeliveryId.value =
            approved.isEmpty ? null : approved.first.deliveryId;
      }
      _applySearch();
    } on ClientDeliveryReviewException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Unable to load your approved project files. Please try again.';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      if (_pendingRefresh && !_disposed) {
        _pendingRefresh = false;
        _scheduleRefresh();
      }
    }
  }

  void setSearch(String value) {
    searchText.value = value;
    _applySearch();
  }

  void selectDelivery(ClientDeliveryReviewModel delivery) {
    selectedDeliveryId.value = delivery.deliveryId;
  }

  Future<void> openFile(ProjectDeliveryFile file) async {
    if (openingFileId.value.isNotEmpty) return;
    openingFileId.value = file.id;
    try {
      final signedUrl = await _repository.createFileLink(file.storagePath);
      final opened = await launchUrl(
        Uri.parse(signedUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        Get.snackbar(
          'Unable to open file',
          'Please try again on this device.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on ClientDeliveryReviewException catch (error) {
      Get.snackbar('File unavailable', error.message);
    } catch (_) {
      Get.snackbar(
        'File unavailable',
        'A secure file link could not be opened. Please try again.',
      );
    } finally {
      openingFileId.value = '';
    }
  }

  void openProjectChat(ClientDeliveryReviewModel delivery) {
    Get.toNamed<void>(
      AppRoutes.projectChats,
      arguments: {'contractId': delivery.contractId},
    );
  }

  void _subscribeToDeliveryChanges() {
    if (_repository.currentUserId == null) return;
    try {
      _subscription = _repository.watchDeliveryChanges().listen(
        (_) => _scheduleRefresh(),
        onError: (Object error, StackTrace stackTrace) {
          // The page remains usable with pull-to-refresh if Realtime is offline.
        },
      );
    } catch (_) {
      // Initial RPC fetch still works if Realtime cannot be started.
    }
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!_disposed) unawaited(loadFinalDeliveries(refresh: true));
    });
  }

  void _applySearch() {
    final query = searchText.value.trim().toLowerCase();
    final visible = approvedDeliveries.where((delivery) {
      if (query.isEmpty) return true;
      return delivery.taskTitle.toLowerCase().contains(query) ||
          delivery.engineerName.toLowerCase().contains(query) ||
          delivery.message.toLowerCase().contains(query) ||
          delivery.taskCategory.toLowerCase().contains(query);
    }).toList(growable: false);

    filteredDeliveries.assignAll(visible);
    if (!visible.any(
      (delivery) => delivery.deliveryId == selectedDeliveryId.value,
    )) {
      selectedDeliveryId.value = visible.isEmpty ? null : visible.first.deliveryId;
    }
  }
}
