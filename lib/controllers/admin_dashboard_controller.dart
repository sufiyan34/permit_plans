import 'dart:async';

import 'package:get/get.dart';

import 'package:permit_plans/models/admin_dashboard_model.dart';
import 'package:permit_plans/repositries/admin_dashboard_repository.dart';

class AdminDashboardController extends GetxController {
  AdminDashboardController({required AdminDashboardRepository repository})
      : _repository = repository;

  final AdminDashboardRepository _repository;

  final Rxn<AdminDashboardSnapshot> snapshot = Rxn<AdminDashboardSnapshot>();
  final RxList<AdminUserRecord> users = <AdminUserRecord>[].obs;
  final RxList<AdminWorkItemRecord> workItems = <AdminWorkItemRecord>[].obs;

  final RxInt selectedTab = 0.obs;
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isUsersLoading = false.obs;
  final RxBool isWorkItemsLoading = false.obs;
  final RxnString errorMessage = RxnString();
  final RxnString usersError = RxnString();
  final RxnString workItemsError = RxnString();
  final RxString userSearch = ''.obs;
  final RxString userRole = 'all'.obs;
  final RxString workSearch = ''.obs;
  final RxString workStatus = 'all'.obs;

  Timer? _userSearchTimer;
  Timer? _workSearchTimer;

  @override
  void onInit() {
    super.onInit();
    refreshAll(initial: true);
  }

  Future<void> refreshAll({bool initial = false}) async {
    if (initial || snapshot.value == null) {
      isLoading.value = true;
    } else {
      isRefreshing.value = true;
    }
    errorMessage.value = null;

    try {
      final results = await Future.wait<dynamic>([
        _repository.fetchSnapshot(),
        _repository.fetchUsers(
          search: userSearch.value,
          role: userRole.value,
          limit: 50,
        ),
        _repository.fetchWorkItems(
          search: workSearch.value,
          status: workStatus.value,
          limit: 100,
        ),
      ]);
      snapshot.value = results[0] as AdminDashboardSnapshot;
      users.assignAll(results[1] as List<AdminUserRecord>);
      workItems.assignAll(results[2] as List<AdminWorkItemRecord>);
      usersError.value = null;
      workItemsError.value = null;
    } catch (error) {
      final message = _friendlyError(error);
      errorMessage.value = message;
      usersError.value = message;
      workItemsError.value = message;
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  void selectTab(int index) {
    if (index < 0 || index > 3 || selectedTab.value == index) return;
    selectedTab.value = index;
    if (index == 1 && users.isEmpty) unawaited(loadUsers());
    if (index == 2 && workItems.isEmpty) unawaited(loadWorkItems());
    if (index == 3) {
      workStatus.value = 'all';
      workSearch.value = '';
      unawaited(loadWorkItems());
    }
  }

  void searchUsers(String value) {
    userSearch.value = value;
    _userSearchTimer?.cancel();
    _userSearchTimer = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(loadUsers()),
    );
  }

  void filterUsersByRole(String value) {
    userRole.value = value;
    unawaited(loadUsers());
  }

  Future<void> loadUsers() async {
    isUsersLoading.value = true;
    usersError.value = null;
    try {
      final result = await _repository.fetchUsers(
        search: userSearch.value,
        role: userRole.value,
        limit: 50,
      );
      users.assignAll(result);
    } catch (error) {
      usersError.value = _friendlyError(error);
    } finally {
      isUsersLoading.value = false;
    }
  }

  void searchWorkItems(String value) {
    workSearch.value = value;
    _workSearchTimer?.cancel();
    _workSearchTimer = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(loadWorkItems()),
    );
  }

  void filterWorkItemsByStatus(String value) {
    workStatus.value = value;
    unawaited(loadWorkItems());
  }

  Future<void> loadWorkItems() async {
    isWorkItemsLoading.value = true;
    workItemsError.value = null;
    try {
      final result = await _repository.fetchWorkItems(
        search: workSearch.value,
        status: workStatus.value,
        limit: 100,
      );
      workItems.assignAll(result);
    } catch (error) {
      workItemsError.value = _friendlyError(error);
    } finally {
      isWorkItemsLoading.value = false;
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('admin_get_dashboard_snapshot') ||
        text.contains('admin_list_users') ||
        text.contains('admin_list_work_items')) {
      return 'Admin dashboard setup is missing. Apply Supabase migration 016, then sign in with an account whose user_roles role is admin.';
    }
    if (text.toLowerCase().contains('only administrators')) {
      return 'This account does not have the Admin role. Ask the trusted project owner to assign it in Supabase.';
    }
    return 'Could not load Admin data. Check your connection and confirm migration 016 is applied.';
  }

  @override
  void onClose() {
    _userSearchTimer?.cancel();
    _workSearchTimer?.cancel();
    super.onClose();
  }
}
