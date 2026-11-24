import 'package:get/get.dart';

import 'package:permit_plans/controllers/client_delivery_review_controller.dart';
import 'package:permit_plans/repositries/client_delivery_review_repository.dart';

class ClientDeliveryReviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClientDeliveryReviewRepository>(
      ClientDeliveryReviewRepository.new,
    );
    Get.lazyPut<ClientDeliveryReviewController>(
      () => ClientDeliveryReviewController(
        repository: Get.find<ClientDeliveryReviewRepository>(),
      ),
    );
  }
}
