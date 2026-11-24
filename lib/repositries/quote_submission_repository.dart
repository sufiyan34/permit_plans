import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/models/quote_submission_model.dart';

class QuoteSubmissionException implements Exception {
  const QuoteSubmissionException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Submits the Engineer's first quote through a server-validated RPC.
/// No card is charged and no payment is created at this stage.
class QuoteSubmissionRepository {
  QuoteSubmissionRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<QuoteSubmissionResult> submitQuote(
    QuoteSubmissionDraft draft,
  ) async {
    if (_client.auth.currentUser == null) {
      throw const QuoteSubmissionException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      final response = await _client.rpc(
        'submit_task_quote',
        params: {
          'p_invitation_id': draft.invitationId,
          'p_amount_minor': draft.amountMinor,
          'p_delivery_days': draft.deliveryDays,
          'p_scope_of_work': draft.scopeOfWork.trim(),
          'p_included_revisions': draft.includedRevisions,
          'p_notes': draft.notes?.trim().isEmpty == true
              ? null
              : draft.notes?.trim(),
        },
      );

      final quoteId = response?.toString().trim() ?? '';
      if (quoteId.isEmpty) {
        throw const QuoteSubmissionException(
          'The quote may have been submitted, but the server did not return its reference. Check your proposal list before trying again.',
        );
      }

      return QuoteSubmissionResult(quoteId: quoteId);
    } on QuoteSubmissionException {
      rethrow;
    } on PostgrestException catch (error) {
      // ignore: avoid_print
      print(
        '[QuoteSubmissionRepository.submitQuote] '
        '${error.code}: ${error.message}',
      );
      throw QuoteSubmissionException(_friendlyError(error));
    } catch (error) {
      // ignore: avoid_print
      print('[QuoteSubmissionRepository.submitQuote] $error');
      throw const QuoteSubmissionException(
        'We could not submit your quote. Please try again.',
      );
    }
  }

  String _friendlyError(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (error.code == '42883' || message.contains('submit_task_quote')) {
      return 'The quote feature is not installed yet. Please run migration 007 in Supabase SQL Editor.';
    }
    if (error.code == '42501' || error.code == '28000') {
      return 'Only the Engineer who received this invitation can submit its quote.';
    }
    if (error.code == '23505' ||
        message.contains('already has a quote') ||
        message.contains('already submitted')) {
      return 'A quote has already been submitted for this task. Refresh your invitations.';
    }
    if (message.contains('no longer pending') ||
        message.contains('not found') ||
        message.contains('not awaiting')) {
      return 'This invitation is no longer available. Refresh your invitations.';
    }
    if (message.contains('amount') || message.contains('price')) {
      return 'Please enter a valid quote amount greater than zero.';
    }
    if (message.contains('delivery')) {
      return 'Please enter a valid delivery estimate.';
    }
    return 'We could not submit your quote. ${error.message}';
  }
}
