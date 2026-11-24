import 'package:get/get.dart';

import 'package:permit_plans/controllers/client_edit_profile_controller.dart';
import 'package:permit_plans/repositries/profile_repository.dart';

class ClientEditProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ProfileRepository>()) {
      Get.lazyPut<ProfileRepository>(() => ProfileRepository(), fenix: true);
    }
    Get.lazyPut<ClientEditProfileController>(
      () => ClientEditProfileController(repository: Get.find<ProfileRepository>()),
    );
  }
}
