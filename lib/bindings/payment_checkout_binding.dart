import 'package:get/get.dart';

import 'package:permit_plans/controllers/payment_checkout_controller.dart';
import 'package:permit_plans/repositries/contract_confirmation_repository.dart';

class PaymentCheckoutBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ContractConfirmationRepository>()) {
      Get.lazyPut<ContractConfirmationRepository>(
        ContractConfirmationRepository.new,
      );
    }

    Get.lazyPut<PaymentCheckoutController>(
      () => PaymentCheckoutController(
        repository: Get.find<ContractConfirmationRepository>(),
      ),
    );
  }
}
