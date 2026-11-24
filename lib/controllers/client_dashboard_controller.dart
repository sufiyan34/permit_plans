import 'package:get/get.dart';

import 'package:permit_plans/models/client_dashboard_model.dart';
import 'package:permit_plans/repositries/client_dashboard_repository.dart';

class ClientDashboardController extends GetxController {
  ClientDashboardController({required ClientDashboardRepository repository})
      : _repository = repository;

  final ClientDashboardRepository _repository;

  final Rxn<ClientDashboardProfile> profile = Rxn<ClientDashboardProfile>();
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
    } on ClientDashboardRepositoryException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Unable to load your workspace. Please try again.';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refresh() => loadProfile(refresh: true);
}
