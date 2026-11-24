import 'package:get/get.dart';

import 'package:permit_plans/controllers/notification_preferences_controller.dart';
import 'package:permit_plans/repositries/notification_preferences_repository.dart';

class NotificationPreferencesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationPreferencesRepository>(
      () => NotificationPreferencesRepository(),
    );
    Get.lazyPut<NotificationPreferencesController>(
      () => NotificationPreferencesController(
        repository: Get.find<NotificationPreferencesRepository>(),
      ),
    );
  }
}
