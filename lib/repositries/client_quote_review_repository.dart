import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/models/client_quote_review_model.dart';

class ClientQuoteReviewException implements Exception {
  const ClientQuoteReviewException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ClientQuoteReviewRepository {
  ClientQuoteReviewRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Emits this Client's quote rows whenever a quote is inserted or updated.
  /// The controller reloads the RPC afterward so joined Engineer/task details
  /// stay in sync with the lightweight realtime row events.
  Stream<List<Map<String, dynamic>>> watchClientQuoteChanges() {
    final userId = currentUserId;
    if (userId == null) {
      throw const ClientQuoteReviewException(
        'Your session has expired. Please sign in again.',
      );
    }

    return _client
        .from('quotes')
        .stream(primaryKey: ['id'])
        .eq('client_id', userId);
  }

  Future<List<ClientQuoteReviewItem>> fetchClientQuotes() async {
    if (_client.auth.currentUser == null) {
      throw const ClientQuoteReviewException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      final response = await _client.rpc(
        'get_client_quotes',
        params: {
          'p_status': null,
          'p_limit': 100,
          'p_offset': 0,
        },
      );

      final rows = response as List<dynamic>? ?? const <dynamic>[];
      return rows
          .whereType<Map<String, dynamic>>()
          .map(ClientQuoteReviewItem.fromJson)
          .toList(growable: false);
    } on PostgrestException catch (error) {
      // ignore: avoid_print
      print(
        '[ClientQuoteReviewRepository.fetchClientQuotes] '
        '${error.code}: ${error.message}',
      );
      throw ClientQuoteReviewException(_friendlyError(error));
    } catch (error) {
      // ignore: avoid_print
      print('[ClientQuoteReviewRepository.fetchClientQuotes] $error');
      throw const ClientQuoteReviewException(
        'Unable to load quotes. Please try again.',
      );
    }
  }

  Future<void> respondToQuote({
    required String quoteId,
    required String action,
    int? amountMinor,
    int? deliveryDays,
    String? scopeOfWork,
    int? includedRevisions,
    String? notes,
  }) async {
    if (_client.auth.currentUser == null) {
      throw const ClientQuoteReviewException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      await _client.rpc(
        'respond_to_client_quote',
        params: {
          'p_quote_id': quoteId,
          'p_action': action,
          'p_amount_minor': amountMinor,
          'p_delivery_days': deliveryDays,
          'p_scope_of_work': scopeOfWork,
          'p_included_revisions': includedRevisions,
          'p_notes': notes,
        },
      );
    } on PostgrestException catch (error) {
      // ignore: avoid_print
      print(
        '[ClientQuoteReviewRepository.respondToQuote] '
        '${error.code}: ${error.message}',
      );
      throw ClientQuoteReviewException(_friendlyError(error));
    } catch (error) {
      // ignore: avoid_print
      print('[ClientQuoteReviewRepository.respondToQuote] $error');
      throw const ClientQuoteReviewException(
        'We could not update this quote. Please try again.',
      );
    }
  }

  Future<List<QuoteRevisionItem>> fetchQuoteHistory(String quoteId) async {
    try {
      final response = await _client
          .from('quote_revisions')
          .select(
            'revision_number, proposed_by, action, amount_minor, currency, '
            'delivery_days, scope_of_work, included_revisions, notes, created_at',
          )
          .eq('quote_id', quoteId)
          .order('revision_number');

      return response
          .map((row) => QuoteRevisionItem.fromJson(row))
          .toList(growable: false);
    } on PostgrestException catch (error) {
      // ignore: avoid_print
      print(
        '[ClientQuoteReviewRepository.fetchQuoteHistory] '
        '${error.code}: ${error.message}',
      );
      throw ClientQuoteReviewException(_friendlyError(error));
    } catch (error) {
      // ignore: avoid_print
      print('[ClientQuoteReviewRepository.fetchQuoteHistory] $error');
      throw const ClientQuoteReviewException(
        'Unable to load negotiation history. Please try again.',
      );
    }
  }

  String _friendlyError(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (error.code == '42883' ||
        message.contains('get_client_quotes') ||
        message.contains('respond_to_client_quote')) {
      return 'Client quote review is not installed yet. Run migration 008 in Supabase SQL Editor.';
    }
    if (error.code == '42501' || error.code == '28000') {
      return 'Only the Client who owns this task can manage its quote.';
    }
    if (message.contains('not waiting') || message.contains('no longer')) {
      return 'This quote has already been updated. Refresh the list to see its latest status.';
    }
    if (message.contains('not found')) {
      return 'This quote is not available in your account.';
    }
    return 'We could not complete this action. ${error.message}';
  }
}
