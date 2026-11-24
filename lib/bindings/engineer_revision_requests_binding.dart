import 'package:get/get.dart';

import 'package:permit_plans/controllers/engineer_revision_requests_controller.dart';
import 'package:permit_plans/repositries/engineer_revision_requests_repository.dart';

class EngineerRevisionRequestsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EngineerRevisionRequestsRepository>(
      () => EngineerRevisionRequestsRepository(),
    );
    Get.lazyPut<EngineerRevisionRequestsController>(
      () => EngineerRevisionRequestsController(
        repository: Get.find<EngineerRevisionRequestsRepository>(),
      ),
    );
  }
}
