import 'package:get/get.dart';

import 'package:permit_plans/controllers/engineer_earnings_controller.dart';
import 'package:permit_plans/repositries/engineer_projects_repository.dart';

class EngineerEarningsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<EngineerProjectsRepository>()) {
      Get.lazyPut<EngineerProjectsRepository>(
        EngineerProjectsRepository.new,
        fenix: true,
      );
    }

    Get.lazyPut<EngineerEarningsController>(
      () => EngineerEarningsController(
        repository: Get.find<EngineerProjectsRepository>(),
      ),
    );
  }
}
