import 'package:get/get.dart';

import 'package:permit_plans/models/contract_confirmation_model.dart';
import 'package:permit_plans/repositries/contract_confirmation_repository.dart';

/// Screen 19 controller.
///
/// The success/failure actions below are deliberately local demonstrations.
/// They do not create a provider session, mutate Supabase, mark a contract as
/// funded, or release any money.
enum PaymentDemoStatus { ready, processing, success, failed, alreadyFunded }

class PaymentProcessingController extends GetxController {
  PaymentProcessingController({required ContractConfirmationRepository repository})
      : _repository = repository;

  final ContractConfirmationRepository _repository;

  final contract = Rxn<ContractConfirmationModel>();
  final status = PaymentDemoStatus.ready.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  String quoteId = '';
  String expectedContractId = '';

  @override
  void onInit() {
    super.onInit();
    _readArguments(Get.arguments);
    if (quoteId.isEmpty) {
      errorMessage.value =
          'The contract was not provided. Open this page from the confirmed contract checkout.';
      return;
    }
    loadContract();
  }

  void _readArguments(dynamic arguments) {
    if (arguments is ContractConfirmationModel) {
      quoteId = arguments.quoteId;
      expectedContractId = arguments.contractId ?? '';
      return;
    }

    if (arguments is Map) {
      quoteId = (arguments['quote_id'] ?? arguments['quoteId'] ?? '')
          .toString()
          .trim();
      expectedContractId =
          (arguments['contract_id'] ?? arguments['contractId'] ?? '')
              .toString()
              .trim();
    }
  }

  Future<void> loadContract() async {
    if (quoteId.isEmpty || isLoading.value ||
        status.value == PaymentDemoStatus.processing) {
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _repository.fetchPreview(quoteId);
      if (!result.isConfirmed) {
        throw const ContractConfirmationException(
          'This agreement has not been confirmed yet. Return to Contract Confirmation first.',
        );
      }
      if (expectedContractId.isNotEmpty &&
          result.contractId != expectedContractId) {
        throw const ContractConfirmationException(
          'The contract reference does not match this payment preview. Reopen it from your confirmed contract.',
        );
      }
      if (result.contractStatus == 'funded') {
        status.value = PaymentDemoStatus.alreadyFunded;
      } else if (result.contractStatus == 'awaiting_payment') {
        status.value = PaymentDemoStatus.ready;
      } else {
        throw const ContractConfirmationException(
          'This contract is not currently awaiting payment. Refresh its status or return to the contract page.',
        );
      }
      contract.value = result;
    } on ContractConfirmationException catch (error) {
      errorMessage.value = error.message;
    } catch (error) {
      // ignore: avoid_print
      print('[PaymentProcessingController.loadContract] $error');
      errorMessage.value =
          'Unable to load the confirmed contract. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> simulateSuccess() => _runDemo(PaymentDemoStatus.success);

  Future<void> simulateFailure() => _runDemo(PaymentDemoStatus.failed);

  Future<void> _runDemo(PaymentDemoStatus outcome) async {
    if (status.value == PaymentDemoStatus.processing ||
        status.value == PaymentDemoStatus.alreadyFunded ||
        contract.value == null) {
      return;
    }

    status.value = PaymentDemoStatus.processing;
    await Future<void>.delayed(const Duration(milliseconds: 1600));

    if (isClosed) return;

    // This only selects a demo result. It intentionally does not write to DB.
    status.value = outcome;
  }

  void resetDemo() {
    if (status.value == PaymentDemoStatus.processing ||
        status.value == PaymentDemoStatus.alreadyFunded) {
      return;
    }
    status.value = PaymentDemoStatus.ready;
  }
}
