import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/models/client_quote_review_model.dart';
import 'package:permit_plans/repositries/client_quote_review_repository.dart';

class ClientQuoteReviewController extends GetxController {
  ClientQuoteReviewController({required ClientQuoteReviewRepository repository})
      : _repository = repository;

  final ClientQuoteReviewRepository _repository;

  final quotes = <ClientQuoteReviewItem>[].obs;
  final filteredQuotes = <ClientQuoteReviewItem>[].obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final isResponding = false.obs;
  final errorMessage = ''.obs;
  final historyError = ''.obs;
  final history = <QuoteRevisionItem>[].obs;
  final searchText = ''.obs;
  final activeFilter = 'needs_action'.obs;
  final busyQuoteId = ''.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _quotesSubscription;
  Timer? _realtimeDebounce;
  bool _ignoreInitialRealtimeSnapshot = true;
  bool _pendingRealtimeRefresh = false;
  bool _isDisposed = false;

  String? get currentUserId => _repository.currentUserId;

  void _applyFilters() {
    Iterable<ClientQuoteReviewItem> result = quotes;
    switch (activeFilter.value) {
      case 'needs_action':
        result = result.where((q) => q.canRespond);
        break;
      case 'negotiating':
        result = result.where((q) => q.status == 'client_countered');
        break;
      case 'accepted':
        result = result.where((q) => q.status == 'accepted');
        break;
      case 'rejected':
        result = result.where((q) => q.status == 'rejected');
        break;
      case 'all':
      default:
        break;
    }

    final query = searchText.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((q) =>
          q.taskTitle.toLowerCase().contains(query) ||
          q.engineerName.toLowerCase().contains(query) ||
          q.engineerHeadline.toLowerCase().contains(query) ||
          q.taskCategory.toLowerCase().contains(query));
    }
    filteredQuotes.assignAll(result.toList(growable: false));
  }

  int get needsActionCount => quotes.where((q) => q.canRespond).length;
  int get negotiatingCount =>
      quotes.where((q) => q.status == 'client_countered').length;
  int get acceptedCount => quotes.where((q) => q.status == 'accepted').length;

  @override
  void onInit() {
    super.onInit();
    // Start listening before the first RPC fetch so no quote changes can be
    // missed between the initial load and the Realtime subscription.
    _subscribeToQuoteChanges();
    unawaited(loadQuotes());
  }

  void setFilter(String value) {
    if (activeFilter.value == value) return;
    activeFilter.value = value;
    _applyFilters();
  }

  void setSearch(String value) {
    searchText.value = value;
    _applyFilters();
  }

  void _subscribeToQuoteChanges() {
    if (currentUserId == null) return;
    try {
      _quotesSubscription = _repository.watchClientQuoteChanges().listen(
        (rows) {
          // stream() emits one initial snapshot; the first RPC load already
          // fetched its joined display data, so only later changes need reload.
          if (_ignoreInitialRealtimeSnapshot) {
            _ignoreInitialRealtimeSnapshot = false;
            if (_realtimeSnapshotDiffersFromLoadedQuotes(rows)) {
              _scheduleRealtimeRefresh();
            }
            return;
          }
          _scheduleRealtimeRefresh();
        },
        onError: (Object error, StackTrace stackTrace) {
          // Keep the page usable if Realtime is unavailable. Manual refresh
          // remains available and the migration enables the quotes table.
        },
      );
    } catch (_) {
      // Do not block quote review if the Realtime channel cannot be created.
    }
  }

  bool _realtimeSnapshotDiffersFromLoadedQuotes(
    List<Map<String, dynamic>> rows,
  ) {
    final loadedStatuses = <String, String>{
      for (final quote in quotes) quote.quoteId: quote.status,
    };
    if (rows.length != loadedStatuses.length) return true;

    for (final row in rows) {
      final id = row['id']?.toString();
      final status = row['status']?.toString();
      if (id == null || loadedStatuses[id] != status) return true;
    }
    return false;
  }

  void _scheduleRealtimeRefresh() {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!_isDisposed) unawaited(loadQuotes(refresh: true));
    });
  }

  @override
  void onClose() {
    _isDisposed = true;
    _realtimeDebounce?.cancel();
    final subscription = _quotesSubscription;
    if (subscription != null) unawaited(subscription.cancel());
    super.onClose();
  }

  Future<void> loadQuotes({bool refresh = false}) async {
    if (isLoading.value || isRefreshing.value) {
      if (refresh) _pendingRealtimeRefresh = true;
      return;
    }
    if (refresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    errorMessage.value = '';
    try {
      final result = await _repository.fetchClientQuotes();
      quotes.assignAll(result);
      _applyFilters();
    } on ClientQuoteReviewException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Unable to load your quotes. Please try again.';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      if (_pendingRealtimeRefresh && !_isDisposed) {
        _pendingRealtimeRefresh = false;
        _scheduleRealtimeRefresh();
      }
    }
  }

  Future<void> refresh() => loadQuotes(refresh: true);

  Future<bool> acceptQuote(ClientQuoteReviewItem quote) async {
    return _respond(quote, 'accept');
  }

  Future<bool> rejectQuote(ClientQuoteReviewItem quote) async {
    return _respond(quote, 'reject');
  }

  Future<bool> sendCounteroffer({
    required ClientQuoteReviewItem quote,
    required String amountText,
    required String deliveryDaysText,
    required String scopeOfWork,
    required String revisionsText,
    String? notes,
  }) async {
    final amountMinor = parseAmountToMinor(amountText, quote.currency);
    final deliveryDays = int.tryParse(deliveryDaysText.trim());
    final revisions = int.tryParse(revisionsText.trim());
    final scope = scopeOfWork.trim();

    if (amountMinor == null || amountMinor <= 0) {
      Get.snackbar('Check the amount', 'Enter a valid counteroffer amount.');
      return false;
    }
    if (deliveryDays == null || deliveryDays < 1 || deliveryDays > 3650) {
      Get.snackbar('Check the delivery time', 'Enter between 1 and 3650 days.');
      return false;
    }
    if (scope.length < 30 || scope.length > 6000) {
      Get.snackbar(
        'Check the scope',
        'Describe the agreed work in 30 to 6000 characters.',
      );
      return false;
    }
    if (revisions == null || revisions < 0 || revisions > 10) {
      Get.snackbar('Check revisions', 'Enter a number between 0 and 10.');
      return false;
    }
    if ((notes?.trim().length ?? 0) > 2000) {
      Get.snackbar('Check your note', 'Keep the note under 2000 characters.');
      return false;
    }

    return _respond(
      quote,
      'counteroffer',
      amountMinor: amountMinor,
      deliveryDays: deliveryDays,
      scopeOfWork: scope,
      includedRevisions: revisions,
      notes: notes?.trim(),
    );
  }

  Future<bool> _respond(
    ClientQuoteReviewItem quote,
    String action, {
    int? amountMinor,
    int? deliveryDays,
    String? scopeOfWork,
    int? includedRevisions,
    String? notes,
  }) async {
    if (isResponding.value) return false;
    isResponding.value = true;
    busyQuoteId.value = quote.quoteId;
    try {
      await _repository.respondToQuote(
        quoteId: quote.quoteId,
        action: action,
        amountMinor: amountMinor,
        deliveryDays: deliveryDays,
        scopeOfWork: scopeOfWork,
        includedRevisions: includedRevisions,
        notes: notes,
      );
      await loadQuotes();

      final message = switch (action) {
        'accept' => 'Quote accepted. The next step is to secure the payment; no card has been charged yet.',
        'reject' => 'The quote has been rejected.',
        _ => 'Your counteroffer has been sent. The Engineer can now review it.',
      };
      Get.snackbar(
        action == 'accept'
            ? 'Quote accepted'
            : action == 'reject'
                ? 'Quote rejected'
                : 'Counteroffer sent',
        message,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 4),
      );
      return true;
    } on ClientQuoteReviewException catch (error) {
      Get.snackbar('Unable to update quote', error.message,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(14));
      return false;
    } finally {
      isResponding.value = false;
      busyQuoteId.value = '';
    }
  }

  Future<List<QuoteRevisionItem>> loadHistory(String quoteId) async {
    historyError.value = '';
    history.clear();
    try {
      final items = await _repository.fetchQuoteHistory(quoteId);
      history.assignAll(items);
      return items;
    } on ClientQuoteReviewException catch (error) {
      historyError.value = error.message;
      return const <QuoteRevisionItem>[];
    }
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
    final fraction = BigInt.tryParse(fractionText.padRight(decimals, '0')) ??
        BigInt.zero;
    final result = whole * BigInt.from(10).pow(decimals) + fraction;
    if (result <= BigInt.zero || result > BigInt.from(9000000000000000)) {
      return null;
    }
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
