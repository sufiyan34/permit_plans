import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/models/contract_confirmation_model.dart';
import 'package:permit_plans/repositries/contract_confirmation_repository.dart';

class ContractConfirmationController extends GetxController {
  ContractConfirmationController({
    required ContractConfirmationRepository repository,
  }) : _repository = repository;

  final ContractConfirmationRepository _repository;

  final preview = Rxn<ContractConfirmationModel>();
  final isLoading = false.obs;
  final isConfirming = false.obs;
  final hasAcceptedTerms = false.obs;
  final errorMessage = ''.obs;
  final contractId = ''.obs;

  String quoteId = '';

  bool get isConfirmed =>
      preview.value?.isConfirmed == true || contractId.value.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    quoteId = _readQuoteId(Get.arguments);
    if (quoteId.isEmpty) {
      errorMessage.value = 'The accepted quote was not provided. Open this screen from your Quotes page.';
      return;
    }
    loadPreview();
  }

  String _readQuoteId(dynamic argument) {
    if (argument is String) return argument.trim();
    if (argument is Map) {
      final value = argument['quote_id'] ?? argument['quoteId'];
      return value?.toString().trim() ?? '';
    }
    return '';
  }

  Future<void> loadPreview() async {
    if (quoteId.isEmpty || isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      preview.value = await _repository.fetchPreview(quoteId);
      if (preview.value?.contractId != null) {
        contractId.value = preview.value!.contractId!;
      }
    } on ContractConfirmationException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Unable to load the contract. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> confirmContract() async {
    if (isConfirmed || isConfirming.value) return;
    if (!hasAcceptedTerms.value) {
      Get.snackbar(
        'Please confirm the terms',
        'Review the agreement and tick the confirmation box before continuing.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(14),
      );
      return;
    }

    isConfirming.value = true;
    errorMessage.value = '';
    try {
      final id = await _repository.confirmContract(quoteId);
      contractId.value = id;
      await loadPreview();
      Get.snackbar(
        'Contract confirmed',
        'Your agreement has been recorded. No card has been charged yet.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 4),
      );
    } on ContractConfirmationException catch (error) {
      errorMessage.value = error.message;
      Get.snackbar(
        'Unable to confirm contract',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(14),
      );
    } catch (_) {
      errorMessage.value = 'Unable to confirm the contract. Please try again.';
    } finally {
      isConfirming.value = false;
    }
  }
}
