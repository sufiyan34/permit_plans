import 'package:get/get.dart';

import 'package:permit_plans/controllers/client_profile_controller.dart';
import 'package:permit_plans/controllers/engineer_profile_controller.dart';
import 'package:permit_plans/repositries/profile_repository.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ProfileRepository>()) {
      Get.lazyPut<ProfileRepository>(() => ProfileRepository(), fenix: true);
    }
    Get.lazyPut<ClientProfileController>(
      () => ClientProfileController(repository: Get.find<ProfileRepository>()),
    );
    Get.lazyPut<EngineerProfileController>(
      () => EngineerProfileController(repository: Get.find<ProfileRepository>()),
    );
  }
}
