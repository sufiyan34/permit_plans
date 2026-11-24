import 'package:get/get.dart';

import 'package:permit_plans/controllers/engineer_profile_details_controller.dart';
import 'package:permit_plans/models/engineer_directory_model.dart';

class EngineerProfileDetailsBinding extends Bindings {
  @override
  void dependencies() {
    final argument = Get.arguments;
    EngineerDirectoryProfile? profile;

    if (argument is EngineerDirectoryProfile) {
      profile = argument;
    } else if (argument is Map) {
      profile = EngineerDirectoryProfile.fromMap(
        Map<String, dynamic>.from(argument),
      );
    }

    Get.lazyPut<EngineerProfileDetailsController>(
      () => EngineerProfileDetailsController(profile: profile),
    );
  }
}
