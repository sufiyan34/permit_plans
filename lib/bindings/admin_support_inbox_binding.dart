import 'package:get/get.dart';

import 'package:permit_plans/controllers/admin_support_inbox_controller.dart';
import 'package:permit_plans/repositries/admin_support_inbox_repository.dart';

class AdminSupportInboxBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminSupportInboxRepository>(AdminSupportInboxRepository.new);
    Get.lazyPut<AdminSupportInboxController>(
      () => AdminSupportInboxController(
        repository: Get.find<AdminSupportInboxRepository>(),
      ),
    );
  }
}
