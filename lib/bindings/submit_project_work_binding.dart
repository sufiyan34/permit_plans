import 'package:get/get.dart';

import 'package:permit_plans/controllers/submit_project_work_controller.dart';
import 'package:permit_plans/repositries/project_delivery_repository.dart';

class SubmitProjectWorkBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProjectDeliveryRepository>(() => ProjectDeliveryRepository());
    Get.lazyPut<SubmitProjectWorkController>(
      () => SubmitProjectWorkController(
        repository: Get.find<ProjectDeliveryRepository>(),
      ),
    );
  }
}
