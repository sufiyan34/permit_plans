import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/models/contract_confirmation_model.dart';
import 'package:permit_plans/repositries/contract_confirmation_repository.dart';

/// Loads the already-confirmed contract for the Client checkout review.
///
/// This controller does not collect card data or create a payment session.
/// Its CTA opens Screen 19, which offers local-only success/failure demos until
/// a marketplace payment provider is selected, approved and integrated.
class PaymentCheckoutController extends GetxController {
  PaymentCheckoutController({
    required ContractConfirmationRepository repository,
  }) : _repository = repository;

  final ContractConfirmationRepository _repository;

  final contract = Rxn<ContractConfirmationModel>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  String quoteId = '';
  String expectedContractId = '';

  bool get hasConfirmedContract => contract.value?.isConfirmed == true;

  bool get isAwaitingPayment =>
      contract.value?.contractStatus == 'awaiting_payment';

  bool get isAlreadyFunded => contract.value?.contractStatus == 'funded';

  @override
  void onInit() {
    super.onInit();
    _readArguments(Get.arguments);
    if (quoteId.isEmpty) {
      errorMessage.value = 'The contract was not provided. Open checkout from the confirmed contract screen.';
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
    if (quoteId.isEmpty || isLoading.value) return;
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
          'The contract reference does not match this checkout. Please reopen checkout from your contract.',
        );
      }
      if (result.contractStatus != 'awaiting_payment' &&
          result.contractStatus != 'funded') {
        throw const ContractConfirmationException(
          'This contract is not currently ready for payment. Please refresh its status.',
        );
      }
      contract.value = result;
    } on ContractConfirmationException catch (error) {
      errorMessage.value = error.message;
    } catch (error) {
      // ignore: avoid_print
      print('[PaymentCheckoutController.loadContract] $error');
      errorMessage.value =
          'Unable to load the confirmed contract. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Opens Screen 19. The next screen only runs a local demo; it does not
  /// collect payment details or update the contract's funding state.
  void openPaymentPreview() {
    final currentContract = contract.value;
    if (currentContract == null) return;

    if (isAlreadyFunded) {
      Get.snackbar(
        'Project already funded',
        'This contract has already been funded. You do not need to pay again.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(14),
      );
      return;
    }

    Get.toNamed<void>(
      AppRoutes.clientPaymentProcessing,
      arguments: {
        'quote_id': currentContract.quoteId,
        'contract_id': currentContract.contractId,
      },
    );
  }
}
