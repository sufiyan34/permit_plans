import 'package:get/get.dart';

import 'package:permit_plans/controllers/engineer_directory_controller.dart';
import 'package:permit_plans/repositries/engineer_directory_repository.dart';

class EngineerDirectoryBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<EngineerDirectoryRepository>()) {
      Get.lazyPut<EngineerDirectoryRepository>(
        () => EngineerDirectoryRepository(),
        fenix: true,
      );
    }

    Get.lazyPut<EngineerDirectoryController>(
      () => EngineerDirectoryController(
        repository: Get.find<EngineerDirectoryRepository>(),
      ),
    );
  }
}
