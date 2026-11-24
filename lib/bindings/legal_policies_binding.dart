import 'package:get/get.dart';
import 'package:permit_plans/controllers/legal_policies_controller.dart';

class LegalPoliciesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LegalPoliciesController>(LegalPoliciesController.new);
  }
}
