import 'dart:async';

import 'package:get/get.dart';

import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/controllers/auth_controller.dart';
import 'package:permit_plans/models/workbridge_notification_model.dart';
import 'package:permit_plans/repositries/workbridge_notifications_repository.dart';

class WorkbridgeNotificationsController extends GetxController {
  WorkbridgeNotificationsController({
    required WorkbridgeNotificationsRepository repository,
  }) : _repository = repository;

  final WorkbridgeNotificationsRepository _repository;
  final notifications = <WorkbridgeNotification>[].obs;
  final selectedFilter = 'all'.obs;
  final isLoading = true.obs;
  final isRefreshing = false.obs;
  final isMarkingAllRead = false.obs;
  final errorMessage = ''.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  bool _receivedFirstStreamValue = false;

  String get currentRole {
    try {
      return Get.find<AuthController>().currentRole.value ?? '';
    } catch (_) {
      return '';
    }
  }

  int get unreadCount => notifications.where((item) => !item.isRead).length;

  List<WorkbridgeNotification> get filteredNotifications {
    final filter = selectedFilter.value;
    final source = notifications.toList(growable: false);
    switch (filter) {
      case 'unread':
        return source.where((item) => !item.isRead).toList(growable: false);
      case 'quotes':
        return source.where((item) => item.category == 'quotes').toList(growable: false);
      case 'projects':
        return source.where((item) => item.category == 'projects').toList(growable: false);
      case 'messages':
        return source.where((item) => item.category == 'messages').toList(growable: false);
      default:
        return source;
    }
  }

  bool get canMarkAllRead => unreadCount > 0 && !isMarkingAllRead.value;

  @override
  void onInit() {
    super.onInit();
    _listen();
  }

  @override
  void onClose() {
    unawaited(_subscription?.cancel());
    super.onClose();
  }

  void _listen() {
    errorMessage.value = '';
    try {
      _subscription = _repository.watchNotifications().listen(
        (rows) {
          _receivedFirstStreamValue = true;
          notifications.assignAll(
            rows.map(WorkbridgeNotification.fromJson),
          );
          isLoading.value = false;
          isRefreshing.value = false;
        },
        onError: (Object error) {
          isLoading.value = false;
          isRefreshing.value = false;
          errorMessage.value = _friendlyError(error);
        },
      );
    } catch (error) {
      isLoading.value = false;
      errorMessage.value = _friendlyError(error);
    }
  }

  Future<void> refresh() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    try {
      final rows = await _repository.fetchNotifications();
      notifications.assignAll(rows);
      errorMessage.value = '';
    } catch (error) {
      errorMessage.value = _friendlyError(error);
    } finally {
      isRefreshing.value = false;
      if (!_receivedFirstStreamValue) isLoading.value = false;
    }
  }

  void setFilter(String filter) => selectedFilter.value = filter;

  Future<void> markNotificationRead(WorkbridgeNotification item) async {
    if (item.isRead) return;
    final index = notifications.indexWhere((row) => row.id == item.id);
    if (index >= 0) {
      notifications[index] = item.copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
    }
    try {
      await _repository.markRead(item.id);
    } catch (error) {
      errorMessage.value = _friendlyError(error);
      await refresh();
    }
  }

  Future<void> markAllRead() async {
    if (!canMarkAllRead) return;
    isMarkingAllRead.value = true;
    final previous = notifications.toList(growable: false);
    notifications.assignAll(
      previous.map((item) => item.copyWith(
            isRead: true,
            readAt: item.readAt ?? DateTime.now(),
          )),
    );
    try {
      await _repository.markAllRead();
      errorMessage.value = '';
    } catch (error) {
      notifications.assignAll(previous);
      errorMessage.value = _friendlyError(error);
    } finally {
      isMarkingAllRead.value = false;
    }
  }

  Future<void> openNotification(WorkbridgeNotification item) async {
    await markNotificationRead(item);
    final route = _routeFor(item);
    if (route == null || route == Get.currentRoute) return;

    final contractId = item.metadata['contract_id']?.toString();
    if (route == AppRoutes.projectChats && contractId != null && contractId.isNotEmpty) {
      Get.toNamed<void>(route, arguments: {'contractId': contractId});
    } else {
      Get.toNamed<void>(route);
    }
  }

  String? _routeFor(WorkbridgeNotification item) {
    switch (item.type) {
      case 'task_invitation_received':
        return AppRoutes.engineerInvitations;
      case 'task_invitation_rejected':
        return AppRoutes.clientHome;
      case 'quote_received':
      case 'engineer_counteroffer_received':
        return AppRoutes.clientQuotes;
      case 'client_counteroffer_received':
      case 'quote_accepted':
      case 'quote_rejected':
        return AppRoutes.engineerNegotiations;
      case 'contract_confirmed':
        return AppRoutes.engineerProjects;
      case 'project_message_received':
        return AppRoutes.projectChats;
      case 'delivery_submitted':
        return AppRoutes.clientDeliveryReviews;
      case 'revision_requested':
        return AppRoutes.engineerRevisionRequests;
      case 'delivery_approved':
        return AppRoutes.engineerProjects;
      default:
        return currentRole == 'client'
            ? AppRoutes.clientHome
            : AppRoutes.engineerHome;
    }
  }

  String _friendlyError(Object error) {
    if (error is WorkbridgeNotificationsRepositoryException) {
      return error.message;
    }
    return 'Unable to update notifications. Please try again.';
  }
}
