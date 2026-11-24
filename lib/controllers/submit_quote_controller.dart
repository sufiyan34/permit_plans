import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/controllers/engineer_task_invitations_controller.dart';
import 'package:permit_plans/models/engineer_task_invitation_model.dart';
import 'package:permit_plans/models/quote_submission_model.dart';
import 'package:permit_plans/repositries/quote_submission_repository.dart';

class SubmitQuoteController extends GetxController {
  SubmitQuoteController({
    required QuoteSubmissionRepository repository,
    required this.invitation,
  }) : _repository = repository;

  final QuoteSubmissionRepository _repository;
  final EngineerTaskInvitation invitation;

  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final deliveryDaysController = TextEditingController(text: '7');
  final scopeController = TextEditingController();
  final revisionsController = TextEditingController(text: '2');
  final notesController = TextEditingController();

  final isSubmitting = false.obs;
  final errorMessage = ''.obs;
  final amountMinor = RxnInt();

  static const int platformCommissionBasisPoints = 500; // 5%

  int get currencyDecimals => _fractionDigits(invitation.currency);

  String? validateAmount(String? value) {
    final parsed = parseAmountToMinor(value ?? '', invitation.currency);
    if (parsed == null || parsed <= 0) {
      return currencyDecimals == 0
          ? 'Enter a valid amount using whole numbers.'
          : 'Enter a valid amount. Use up to $currencyDecimals decimal places.';
    }
    return null;
  }

  String? validateDeliveryDays(String? value) {
    final days = int.tryParse((value ?? '').trim());
    if (days == null || days < 1 || days > 3650) {
      return 'Enter a delivery estimate between 1 and 3650 days.';
    }
    return null;
  }

  String? validateScope(String? value) {
    final text = (value ?? '').trim();
    if (text.length < 30) return 'Please describe the work (at least 30 characters).';
    if (text.length > 6000) return 'Keep the scope under 6000 characters.';
    return null;
  }

  String? validateRevisions(String? value) {
    final revisions = int.tryParse((value ?? '').trim());
    if (revisions == null || revisions < 0 || revisions > 10) {
      return 'Enter a number from 0 to 10.';
    }
    return null;
  }

  void onAmountChanged(String value) {
    amountMinor.value = parseAmountToMinor(value, invitation.currency);
  }

  int? get estimatedEngineerNetMinor {
    final amount = amountMinor.value;
    if (amount == null || amount <= 0) return null;
    final commission = (amount * platformCommissionBasisPoints) ~/ 10000;
    return amount - commission;
  }

  static int? parseAmountToMinor(String raw, String currency) {
    final value = raw.trim().replaceAll(',', '');
    if (value.isEmpty || !RegExp(r'^\d+(\.\d*)?$').hasMatch(value)) {
      return null;
    }
    final decimals = _fractionDigits(currency);
    final parts = value.split('.');
    final whole = BigInt.tryParse(parts.first);
    if (whole == null) return null;
    final fractionText = parts.length > 1 ? parts[1] : '';
    if (fractionText.length > decimals) return null;
    final paddedFraction = fractionText.padRight(decimals, '0');
    final fraction = paddedFraction.isEmpty
        ? BigInt.zero
        : BigInt.tryParse(paddedFraction) ?? BigInt.zero;
    final multiplier = BigInt.from(10).pow(decimals);
    final result = whole * multiplier + fraction;
    if (result <= BigInt.zero || result > BigInt.from(9000000000000000)) {
      return null;
    }
    return result.toInt();
  }

  static int _fractionDigits(String currency) {
    final code = currency.toUpperCase();
    if (const {'BIF', 'CLP', 'DJF', 'GNF', 'ISK', 'JPY', 'KMF', 'KRW', 'PYG', 'RWF', 'UGX', 'VND', 'VUV', 'XAF', 'XOF', 'XPF'}.contains(code)) {
      return 0;
    }
    if (const {'BHD', 'IQD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND'}.contains(code)) {
      return 3;
    }
    return 2;
  }

  Future<void> submitQuote() async {
    if (isSubmitting.value) return;
    errorMessage.value = '';

    if (invitation.invitationStatus != 'pending' ||
        invitation.taskStatus != 'invitation_pending') {
      errorMessage.value = 'This invitation is no longer awaiting a quote.';
      return;
    }

    if (!(formKey.currentState?.validate() ?? false)) return;

    final amount = parseAmountToMinor(amountController.text, invitation.currency);
    final deliveryDays = int.tryParse(deliveryDaysController.text.trim());
    final revisions = int.tryParse(revisionsController.text.trim());
    if (amount == null || deliveryDays == null || revisions == null) return;

    isSubmitting.value = true;
    try {
      await _repository.submitQuote(
        QuoteSubmissionDraft(
          invitationId: invitation.invitationId,
          amountMinor: amount,
          currency: invitation.currency,
          deliveryDays: deliveryDays,
          scopeOfWork: scopeController.text.trim(),
          includedRevisions: revisions,
          notes: notesController.text.trim(),
        ),
      );

      if (Get.isRegistered<EngineerTaskInvitationsController>()) {
        await Get.find<EngineerTaskInvitationsController>().refresh();
      }

      Get.back<void>();
      Get.snackbar(
        'Quote submitted',
        'Your quote has been sent to ${invitation.clientName}. No payment has been taken.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 4),
      );
    } on QuoteSubmissionException catch (error) {
      errorMessage.value = error.message;
    } finally {
      isSubmitting.value = false;
    }
  }

  void goBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    } else {
      Get.offNamed<void>(AppRoutes.engineerInvitations);
    }
  }

  @override
  void onClose() {
    amountController.dispose();
    deliveryDaysController.dispose();
    scopeController.dispose();
    revisionsController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
