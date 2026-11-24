import 'package:get/get.dart';

import 'package:permit_plans/controllers/auth_controller.dart';
import 'package:permit_plans/services/auth_service.dart';
import 'package:permit_plans/repositries/profile_repository.dart';

/// Register this once after Supabase.initialize() and before runApp().
class AuthBinding extends Bindings {
  AuthBinding({this.onAuthenticated});

  final AuthenticatedCallback? onAuthenticated;

  @override
  void dependencies() {
    if (!Get.isRegistered<AuthService>()) {
      Get.put<AuthService>(AuthService(), permanent: true);
    }
    if (!Get.isRegistered<ProfileRepository>()) {
      Get.put<ProfileRepository>(ProfileRepository(), permanent: true);
    }
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(
        AuthController(
          authService: Get.find<AuthService>(),
          profileRepository: Get.find<ProfileRepository>(),
          onAuthenticated: onAuthenticated,
        ),
        permanent: true,
      );
    }
  }
}
