import 'package:get/get.dart';

import 'package:permit_plans/controllers/engineer_projects_controller.dart';
import 'package:permit_plans/repositries/engineer_projects_repository.dart';

class EngineerProjectsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<EngineerProjectsRepository>()) {
      Get.lazyPut<EngineerProjectsRepository>(
        EngineerProjectsRepository.new,
      );
    }

    Get.lazyPut<EngineerProjectsController>(
      () => EngineerProjectsController(
        repository: Get.find<EngineerProjectsRepository>(),
      ),
    );
  }
}
