import 'package:get/get.dart';

import 'package:permit_plans/controllers/engineer_payout_management_controller.dart';
import 'package:permit_plans/repositries/engineer_projects_repository.dart';

class EngineerPayoutManagementBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<EngineerProjectsRepository>()) {
      Get.lazyPut<EngineerProjectsRepository>(
        EngineerProjectsRepository.new,
        fenix: true,
      );
    }

    Get.lazyPut<EngineerPayoutManagementController>(
      () => EngineerPayoutManagementController(
        repository: Get.find<EngineerProjectsRepository>(),
      ),
    );
  }
}
