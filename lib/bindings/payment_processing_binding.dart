import 'package:get/get.dart';

import 'package:permit_plans/controllers/payment_processing_controller.dart';
import 'package:permit_plans/repositries/contract_confirmation_repository.dart';

class PaymentProcessingBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ContractConfirmationRepository>()) {
      Get.lazyPut<ContractConfirmationRepository>(
        ContractConfirmationRepository.new,
      );
    }

    Get.lazyPut<PaymentProcessingController>(
      () => PaymentProcessingController(
        repository: Get.find<ContractConfirmationRepository>(),
      ),
    );
  }
}
