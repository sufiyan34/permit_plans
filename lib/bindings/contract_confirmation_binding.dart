import 'package:get/get.dart';

import 'package:permit_plans/controllers/contract_confirmation_controller.dart';
import 'package:permit_plans/repositries/contract_confirmation_repository.dart';

class ContractConfirmationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ContractConfirmationRepository>(
      ContractConfirmationRepository.new,
    );
    Get.lazyPut<ContractConfirmationController>(
      () => ContractConfirmationController(
        repository: Get.find<ContractConfirmationRepository>(),
      ),
    );
  }
}
