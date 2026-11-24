import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/models/engineer_negotiation_model.dart';

class EngineerNegotiationException implements Exception {
  const EngineerNegotiationException(this.message);
  final String message;
  @override
  String toString() => message;
}

class EngineerNegotiationRepository {
  EngineerNegotiationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<EngineerNegotiationItem>> fetchNegotiations({String? status}) async {
    if (_client.auth.currentUser == null) {
      throw const EngineerNegotiationException(
        'Your session has expired. Please sign in again.',
      );
    }
    try {
      final response = await _client.rpc(
        'get_engineer_negotiations',
        params: {
          'p_status': status,
          'p_limit': 100,
          'p_offset': 0,
        },
      );
      final rows = response as List<dynamic>? ?? const <dynamic>[];
      return rows
          .whereType<Map<String, dynamic>>()
          .map(EngineerNegotiationItem.fromJson)
          .toList(growable: false);
    } on PostgrestException catch (error) {
      // ignore: avoid_print
      print('[EngineerNegotiationRepository.fetchNegotiations] ${error.code}: ${error.message}');
      throw EngineerNegotiationException(_friendlyError(error));
    } catch (error) {
      // ignore: avoid_print
      print('[EngineerNegotiationRepository.fetchNegotiations] $error');
      throw const EngineerNegotiationException(
        'Unable to load negotiations. Please try again.',
      );
    }
  }

  Future<List<EngineerQuoteRevision>> fetchHistory(String quoteId) async {
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
          .map((row) => EngineerQuoteRevision.fromJson(row))
          .toList(growable: false);
    } on PostgrestException catch (error) {
      // ignore: avoid_print
      print('[EngineerNegotiationRepository.fetchHistory] ${error.code}: ${error.message}');
      throw EngineerNegotiationException(_friendlyError(error));
    } catch (error) {
      // ignore: avoid_print
      print('[EngineerNegotiationRepository.fetchHistory] $error');
      throw const EngineerNegotiationException(
        'Unable to load negotiation history. Please try again.',
      );
    }
  }

  Future<void> respond({
    required String quoteId,
    required String action,
    int? amountMinor,
    int? deliveryDays,
    String? scopeOfWork,
    int? includedRevisions,
    String? notes,
  }) async {
    if (_client.auth.currentUser == null) {
      throw const EngineerNegotiationException(
        'Your session has expired. Please sign in again.',
      );
    }
    try {
      await _client.rpc(
        'respond_to_engineer_counteroffer',
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
      print('[EngineerNegotiationRepository.respond] ${error.code}: ${error.message}');
      throw EngineerNegotiationException(_friendlyError(error));
    } catch (error) {
      // ignore: avoid_print
      print('[EngineerNegotiationRepository.respond] $error');
      throw const EngineerNegotiationException(
        'We could not update this negotiation. Please try again.',
      );
    }
  }

  String _friendlyError(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (error.code == '42883' ||
        message.contains('get_engineer_negotiations') ||
        message.contains('respond_to_engineer_counteroffer')) {
      return 'Engineer Negotiation is not installed yet. Run migration 009 in Supabase SQL Editor.';
    }
    if (error.code == '42501' || error.code == '28000') {
      return 'Only the Engineer assigned to this quote can respond to it.';
    }
    if (message.contains('not waiting') || message.contains('no longer') || message.contains('not available')) {
      return 'This counteroffer is no longer awaiting your response. Refresh the list.';
    }
    if (message.contains('amount')) return 'Enter a valid counteroffer amount.';
    if (message.contains('delivery')) return 'Enter a valid delivery estimate.';
    return 'We could not complete this action. ${error.message}';
  }
}
