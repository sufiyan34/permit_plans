import 'package:get/get.dart';

import 'package:permit_plans/controllers/engineer_edit_profile_controller.dart';
import 'package:permit_plans/repositries/profile_repository.dart';

class EngineerEditProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ProfileRepository>()) {
      Get.lazyPut<ProfileRepository>(() => ProfileRepository(), fenix: true);
    }
    Get.lazyPut<EngineerEditProfileController>(
      () => EngineerEditProfileController(
        repository: Get.find<ProfileRepository>(),
      ),
    );
  }
}
