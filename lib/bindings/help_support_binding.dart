import 'package:get/get.dart';

import 'package:permit_plans/controllers/help_support_controller.dart';
import 'package:permit_plans/repositries/help_support_repository.dart';

class HelpSupportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HelpSupportRepository>(() => HelpSupportRepository());
    Get.lazyPut<HelpSupportController>(
      () => HelpSupportController(
        repository: Get.find<HelpSupportRepository>(),
      ),
    );
  }
}
