import 'package:get/get.dart';

import 'package:permit_plans/controllers/engineer_negotiation_controller.dart';
import 'package:permit_plans/repositries/engineer_negotiation_repository.dart';

class EngineerNegotiationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EngineerNegotiationRepository>(
      () => EngineerNegotiationRepository(),
    );
    Get.lazyPut<EngineerNegotiationController>(
      () => EngineerNegotiationController(
        repository: Get.find<EngineerNegotiationRepository>(),
      ),
    );
  }
}
