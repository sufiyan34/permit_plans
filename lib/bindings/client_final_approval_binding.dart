import 'package:get/get.dart';

import 'package:permit_plans/controllers/client_final_approval_controller.dart';
import 'package:permit_plans/repositries/client_delivery_review_repository.dart';

class ClientFinalApprovalBinding extends Bindings {
  @override
  void dependencies() {
    // Reuse the delivery repository when navigating from Screen 23.
    if (!Get.isRegistered<ClientDeliveryReviewRepository>()) {
      Get.lazyPut<ClientDeliveryReviewRepository>(
        ClientDeliveryReviewRepository.new,
      );
    }

    Get.lazyPut<ClientFinalApprovalController>(
      () => ClientFinalApprovalController(
        repository: Get.find<ClientDeliveryReviewRepository>(),
      ),
    );
  }
}
