import 'package:get/get.dart';

import 'package:permit_plans/controllers/account_settings_controller.dart';
import 'package:permit_plans/repositries/account_settings_repository.dart';

class AccountSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AccountSettingsRepository>(
      () => AccountSettingsRepository(),
    );
    Get.lazyPut<AccountSettingsController>(
      () => AccountSettingsController(
        repository: Get.find<AccountSettingsRepository>(),
      ),
    );
  }
}
