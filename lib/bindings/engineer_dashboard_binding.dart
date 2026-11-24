import 'package:get/get.dart';

import 'package:permit_plans/controllers/engineer_dashboard_controller.dart';
import 'package:permit_plans/repositries/engineer_dashboard_repository.dart';

class EngineerDashboardBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<EngineerDashboardRepository>()) {
      Get.lazyPut<EngineerDashboardRepository>(
        () => EngineerDashboardRepository(),
        fenix: true,
      );
    }

    Get.lazyPut<EngineerDashboardController>(
      () => EngineerDashboardController(
        repository: Get.find<EngineerDashboardRepository>(),
      ),
    );
  }
}
