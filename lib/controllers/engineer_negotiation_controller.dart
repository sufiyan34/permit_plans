import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/models/engineer_negotiation_model.dart';
import 'package:permit_plans/repositries/engineer_negotiation_repository.dart';

class EngineerNegotiationController extends GetxController {
  EngineerNegotiationController({required EngineerNegotiationRepository repository})
      : _repository = repository;

  final EngineerNegotiationRepository _repository;

  final negotiations = <EngineerNegotiationItem>[].obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final isResponding = false.obs;
  final busyQuoteId = ''.obs;
  final errorMessage = ''.obs;
  final searchText = ''.obs;
  final activeFilter = 'needs_response'.obs;
  final historyByQuote = <String, List<EngineerQuoteRevision>>{}.obs;
  final historyLoadingQuoteId = ''.obs;
  final historyError = ''.obs;

  String? get currentUserId => _repository.currentUserId;

  int get needsResponseCount =>
      negotiations.where((item) => item.status == 'client_countered').length;
  int get waitingForClientCount => negotiations
      .where((item) => item.status == 'engineer_countered' || item.status == 'pending_client_review')
      .length;
  int get acceptedCount => negotiations.where((item) => item.status == 'accepted').length;
  int get rejectedCount => negotiations.where((item) => item.status == 'rejected').length;

  List<EngineerNegotiationItem> get filteredNegotiations {
    Iterable<EngineerNegotiationItem> result = negotiations;
    switch (activeFilter.value) {
      case 'needs_response':
        result = result.where((item) => item.status == 'client_countered');
        break;
      case 'waiting':
        result = result.where((item) =>
            item.status == 'engineer_countered' || item.status == 'pending_client_review');
        break;
      case 'closed':
        result = result.where((item) =>
            item.status == 'accepted' || item.status == 'rejected');
        break;
      case 'all':
      default:
        break;
    }

    final query = searchText.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((item) =>
          item.taskTitle.toLowerCase().contains(query) ||
          item.clientName.toLowerCase().contains(query) ||
          item.taskCategory.toLowerCase().contains(query));
    }
    return result.toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    loadNegotiations();
  }

  void setFilter(String value) => activeFilter.value = value;
  void setSearch(String value) => searchText.value = value;

  Future<void> loadNegotiations({bool refresh = false}) async {
    if (isLoading.value || isRefreshing.value) return;
    if (refresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    errorMessage.value = '';
    try {
      negotiations.assignAll(await _repository.fetchNegotiations());
    } on EngineerNegotiationException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Unable to load negotiations. Please try again.';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refresh() => loadNegotiations(refresh: true);

  Future<List<EngineerQuoteRevision>> loadHistory(String quoteId) async {
    historyError.value = '';
    historyLoadingQuoteId.value = quoteId;
    try {
      final result = await _repository.fetchHistory(quoteId);
      historyByQuote[quoteId] = result;
      return result;
    } on EngineerNegotiationException catch (error) {
      historyError.value = error.message;
      return const <EngineerQuoteRevision>[];
    } finally {
      historyLoadingQuoteId.value = '';
    }
  }

  Future<bool> acceptCounteroffer(EngineerNegotiationItem item) =>
      _respond(item, 'accept');

  Future<bool> rejectCounteroffer(EngineerNegotiationItem item) =>
      _respond(item, 'reject');

  Future<bool> sendCounteroffer({
    required EngineerNegotiationItem item,
    required String amountText,
    required String deliveryDaysText,
    required String scopeOfWork,
    required String revisionsText,
    String? notes,
  }) async {
    final amountMinor = parseAmountToMinor(amountText, item.currency);
    final deliveryDays = int.tryParse(deliveryDaysText.trim());
    final revisions = int.tryParse(revisionsText.trim());
    final scope = scopeOfWork.trim();

    if (amountMinor == null || amountMinor <= 0) {
      Get.snackbar('Check the amount', 'Enter a valid counteroffer amount.');
      return false;
    }
    if (deliveryDays == null || deliveryDays < 1 || deliveryDays > 3650) {
      Get.snackbar('Check delivery time', 'Enter between 1 and 3650 days.');
      return false;
    }
    if (scope.length < 30 || scope.length > 6000) {
      Get.snackbar('Check the scope', 'Describe the work in 30 to 6000 characters.');
      return false;
    }
    if (revisions == null || revisions < 0 || revisions > 10) {
      Get.snackbar('Check revisions', 'Enter a number from 0 to 10.');
      return false;
    }
    if ((notes?.trim().length ?? 0) > 2000) {
      Get.snackbar('Check your note', 'Keep the note under 2000 characters.');
      return false;
    }

    return _respond(
      item,
      'counteroffer',
      amountMinor: amountMinor,
      deliveryDays: deliveryDays,
      scopeOfWork: scope,
      includedRevisions: revisions,
      notes: notes?.trim(),
    );
  }

  Future<bool> _respond(
    EngineerNegotiationItem item,
    String action, {
    int? amountMinor,
    int? deliveryDays,
    String? scopeOfWork,
    int? includedRevisions,
    String? notes,
  }) async {
    if (isResponding.value || !item.needsEngineerResponse) return false;
    isResponding.value = true;
    busyQuoteId.value = item.quoteId;
    try {
      await _repository.respond(
        quoteId: item.quoteId,
        action: action,
        amountMinor: amountMinor,
        deliveryDays: deliveryDays,
        scopeOfWork: scopeOfWork,
        includedRevisions: includedRevisions,
        notes: notes,
      );
      await loadNegotiations();
      final title = switch (action) {
        'accept' => 'Counteroffer accepted',
        'reject' => 'Counteroffer rejected',
        _ => 'Your counteroffer was sent',
      };
      final message = switch (action) {
        'accept' => 'You and the Client have agreed. The next step is payment setup; no card has been charged yet.',
        'reject' => 'This negotiation has been closed. No payment was taken.',
        _ => 'Your revised terms were sent to the Client for review.',
      };
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 4),
      );
      return true;
    } on EngineerNegotiationException catch (error) {
      Get.snackbar(
        'Unable to update negotiation',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(14),
      );
      return false;
    } finally {
      isResponding.value = false;
      busyQuoteId.value = '';
    }
  }

  static int? parseAmountToMinor(String raw, String currency) {
    final value = raw.trim().replaceAll(',', '');
    if (value.isEmpty || !RegExp(r'^\d+(\.\d*)?$').hasMatch(value)) return null;
    final decimals = _fractionDigits(currency);
    final parts = value.split('.');
    final whole = BigInt.tryParse(parts.first);
    if (whole == null) return null;
    final fractionText = parts.length > 1 ? parts[1] : '';
    if (fractionText.length > decimals) return null;
    final fraction = BigInt.tryParse(fractionText.padRight(decimals, '0')) ?? BigInt.zero;
    final result = whole * BigInt.from(10).pow(decimals) + fraction;
    if (result <= BigInt.zero || result > BigInt.from(9000000000000000)) return null;
    return result.toInt();
  }

  static int _fractionDigits(String currency) {
    final code = currency.toUpperCase();
    if (const {
      'BIF', 'CLP', 'DJF', 'GNF', 'ISK', 'JPY', 'KMF', 'KRW', 'PYG',
      'RWF', 'UGX', 'VND', 'VUV', 'XAF', 'XOF', 'XPF'
    }.contains(code)) return 0;
    if (const {'BHD', 'IQD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND'}
        .contains(code)) return 3;
    return 2;
  }
}
