import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/models/engineer_task_invitation_model.dart';

class EngineerTaskInvitationRepositoryException implements Exception {
  const EngineerTaskInvitationRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads invitations through a SECURITY DEFINER RPC that returns only the
/// task details and limited client identity needed by the invited Engineer.
/// Rejection is also performed through a server-side RPC, not a direct update.
class EngineerTaskInvitationRepository {
  EngineerTaskInvitationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<EngineerTaskInvitation>> fetchPendingInvitations() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const EngineerTaskInvitationRepositoryException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      final response = await _client.rpc(
        'get_my_task_invitations',
        params: {'p_limit': 50, 'p_offset': 0},
      );

      if (response is! List) {
        throw const EngineerTaskInvitationRepositoryException(
          'The invitation service returned an unexpected response.',
        );
      }

      return response
          .whereType<Map>()
          .map((row) => EngineerTaskInvitation.fromMap(
                Map<String, dynamic>.from(row),
              ))
          .where((item) => item.invitationId.isNotEmpty && item.taskId.isNotEmpty)
          .toList(growable: false);
    } on EngineerTaskInvitationRepositoryException {
      rethrow;
    } on PostgrestException catch (error) {
      // ignore: avoid_print
      print(
        '[EngineerTaskInvitationRepository.fetchPendingInvitations] '
        '${error.code}: ${error.message}',
      );
      if (error.code == '42883' || error.message.contains('get_my_task_invitations')) {
        throw const EngineerTaskInvitationRepositoryException(
          'The task invitation database update is missing. Please apply migration 006.',
        );
      }
      if (error.code == '42501' || error.code == '28000') {
        throw const EngineerTaskInvitationRepositoryException(
          'Your account is not allowed to view these invitations. Sign in with an Engineer account.',
        );
      }
      throw const EngineerTaskInvitationRepositoryException(
        'We could not load task invitations. Please check your connection and try again.',
      );
    } catch (error) {
      // ignore: avoid_print
      print('[EngineerTaskInvitationRepository.fetchPendingInvitations] $error');
      throw const EngineerTaskInvitationRepositoryException(
        'Something went wrong while loading your invitations.',
      );
    }
  }

  Future<void> rejectInvitation(String invitationId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const EngineerTaskInvitationRepositoryException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      final result = await _client.rpc(
        'reject_task_invitation',
        params: {'p_invitation_id': invitationId},
      );
      if (result != true) {
        throw const EngineerTaskInvitationRepositoryException(
          'The invitation could not be rejected. Refresh and try again.',
        );
      }
    } on EngineerTaskInvitationRepositoryException {
      rethrow;
    } on PostgrestException catch (error) {
      // ignore: avoid_print
      print(
        '[EngineerTaskInvitationRepository.rejectInvitation] '
        '${error.code}: ${error.message}',
      );
      if (error.code == '42883' || error.message.contains('reject_task_invitation')) {
        throw const EngineerTaskInvitationRepositoryException(
          'The invitation action is not installed yet. Please apply migration 006.',
        );
      }
      if (error.code == '42501' || error.code == '28000') {
        throw const EngineerTaskInvitationRepositoryException(
          'Only the invited Engineer can reject this invitation.',
        );
      }
      throw EngineerTaskInvitationRepositoryException(
        _friendlyRejectError(error.message),
      );
    } catch (error) {
      // ignore: avoid_print
      print('[EngineerTaskInvitationRepository.rejectInvitation] $error');
      throw const EngineerTaskInvitationRepositoryException(
        'We could not reject this invitation. Please try again.',
      );
    }
  }

  String _friendlyRejectError(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('no longer pending') ||
        normalized.contains('not found')) {
      return 'This invitation is no longer available. Refresh your inbox.';
    }
    if (normalized.contains('only engineers')) {
      return 'Only an Engineer account can reject an invitation.';
    }
    return 'We could not reject this invitation. Please try again.';
  }
}
