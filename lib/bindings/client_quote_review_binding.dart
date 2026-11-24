import 'package:get/get.dart';

import 'package:permit_plans/controllers/client_quote_review_controller.dart';
import 'package:permit_plans/repositries/client_quote_review_repository.dart';

class ClientQuoteReviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClientQuoteReviewRepository>(
      () => ClientQuoteReviewRepository(),
    );
    Get.lazyPut<ClientQuoteReviewController>(
      () => ClientQuoteReviewController(
        repository: Get.find<ClientQuoteReviewRepository>(),
      ),
    );
  }
}
