import 'package:get/get.dart';

import 'package:permit_plans/models/engineer_dashboard_model.dart';
import 'package:permit_plans/repositries/engineer_dashboard_repository.dart';

class EngineerDashboardController extends GetxController {
  EngineerDashboardController({required EngineerDashboardRepository repository})
      : _repository = repository;

  final EngineerDashboardRepository _repository;

  final Rxn<EngineerDashboardProfile> profile =
      Rxn<EngineerDashboardProfile>();
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile({bool refresh = false}) async {
    if (isLoading.value || isRefreshing.value) return;

    if (refresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
      profile.value = await _repository.fetchProfile();
    } on EngineerDashboardRepositoryException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value =
          'Unable to load your engineer workspace. Please try again.';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refresh() => loadProfile(refresh: true);
}
