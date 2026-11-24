import 'package:get/get.dart';

import 'package:permit_plans/controllers/workbridge_notifications_controller.dart';
import 'package:permit_plans/repositries/workbridge_notifications_repository.dart';

class WorkbridgeNotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WorkbridgeNotificationsRepository>(
      () => WorkbridgeNotificationsRepository(),
    );
    Get.lazyPut<WorkbridgeNotificationsController>(
      () => WorkbridgeNotificationsController(
        repository: Get.find<WorkbridgeNotificationsRepository>(),
      ),
    );
  }
}
