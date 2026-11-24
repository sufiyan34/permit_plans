import 'dart:async';

import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/models/engineer_revision_request_model.dart';
import 'package:permit_plans/models/project_delivery_model.dart';
import 'package:permit_plans/repositries/engineer_revision_requests_repository.dart';

class EngineerRevisionRequestsController extends GetxController {
  EngineerRevisionRequestsController({
    required EngineerRevisionRequestsRepository repository,
  }) : _repository = repository;

  final EngineerRevisionRequestsRepository _repository;

  final requests = <EngineerRevisionRequestModel>[].obs;
  final selectedContractId = RxnString();
  final searchText = ''.obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = ''.obs;
  final openingFileId = ''.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  Timer? _refreshDebounce;
  bool _pendingRefresh = false;
  bool _isDisposed = false;

  List<EngineerRevisionRequestModel> get filteredRequests {
    final query = searchText.value.trim().toLowerCase();
    if (query.isEmpty) return requests.toList(growable: false);
    return requests.where((item) {
      return item.project.taskTitle.toLowerCase().contains(query) ||
          item.project.clientDisplayName.toLowerCase().contains(query) ||
          (item.requestedDelivery.reviewNote ?? '').toLowerCase().contains(query) ||
          item.project.contractShortId.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  EngineerRevisionRequestModel? get selectedRequest {
    final id = selectedContractId.value;
    if (id == null) return null;
    for (final item in filteredRequests) {
      if (item.project.contractId == id) return item;
    }
    return null;
  }

  int get totalRequests => requests.length;
  int get totalFiles => requests.fold<int>(
        0,
        (sum, item) => sum + item.requestedDelivery.files.length,
      );

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is String && args.trim().isNotEmpty) {
      selectedContractId.value = args.trim();
    }
    _subscribeToChanges();
    unawaited(loadRequests());
  }

  @override
  void onClose() {
    _isDisposed = true;
    _refreshDebounce?.cancel();
    final subscription = _subscription;
    if (subscription != null) unawaited(subscription.cancel());
    super.onClose();
  }

  Future<void> refresh() => loadRequests(refresh: true);

  void setSearch(String value) {
    searchText.value = value;
    _ensureSelectionVisible();
  }

  void selectRequest(EngineerRevisionRequestModel item) {
    selectedContractId.value = item.project.contractId;
  }

  Future<void> loadRequests({bool refresh = false}) async {
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
      final result = await _repository.fetchRevisionRequests();
      requests.assignAll(result);
      if (!result.any(
        (item) => item.project.contractId == selectedContractId.value,
      )) {
        selectedContractId.value = result.isEmpty
            ? null
            : result.first.project.contractId;
      }
      _ensureSelectionVisible();
    } on EngineerRevisionRequestsException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value =
          'Unable to load Client revision feedback. Please try again.';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      if (_pendingRefresh && !_isDisposed) {
        _pendingRefresh = false;
        _scheduleRefresh();
      }
    }
  }

  Future<bool> submitRevisedWork(EngineerRevisionRequestModel item) async {
    final submitted = await Get.toNamed<bool>(
      AppRoutes.engineerSubmitWork,
      arguments: item.project,
    );
    if (submitted == true) {
      await refresh();
      Get.snackbar(
        'Revised work submitted',
        'Your updated delivery has been sent to the Client for review.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    }
    return false;
  }

  void openProjectChat(EngineerRevisionRequestModel item) {
    Get.toNamed<void>(
      AppRoutes.projectChats,
      arguments: item.project.contractId,
    );
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
    } on EngineerRevisionRequestsException catch (error) {
      Get.snackbar('File unavailable', error.message);
    } catch (_) {
      Get.snackbar(
        'File unavailable',
        'A secure download link could not be opened.',
      );
    } finally {
      openingFileId.value = '';
    }
  }

  void _ensureSelectionVisible() {
    final visible = filteredRequests;
    if (visible.isEmpty) {
      selectedContractId.value = null;
      return;
    }
    if (!visible.any(
      (item) => item.project.contractId == selectedContractId.value,
    )) {
      selectedContractId.value = visible.first.project.contractId;
    }
  }

  void _subscribeToChanges() {
    if (_repository.currentUserId == null) return;
    try {
      _subscription = _repository.watchDeliveryChanges().listen(
        (_) => _scheduleRefresh(),
        onError: (Object error, StackTrace stackTrace) {
          // The page remains usable through pull-to-refresh if Realtime is offline.
        },
      );
    } catch (_) {
      // Initial RPC loading must remain available if the stream cannot start.
    }
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!_isDisposed) unawaited(loadRequests(refresh: true));
    });
  }
}
