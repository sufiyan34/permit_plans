import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/models/help_support_model.dart';

class HelpSupportException implements Exception {
  const HelpSupportException(this.message);
  final String message;

  @override
  String toString() => message;
}

class HelpSupportRepository {
  HelpSupportRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const HelpSupportException(
        'Your session has expired. Please sign in again.',
      );
    }
    return id;
  }

  Stream<List<Map<String, dynamic>>> watchMyRequests() {
    final userId = _userId;
    return _client
        .from('support_requests')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(30);
  }

  Future<List<HelpSupportRequest>> fetchMyRequests() async {
    try {
      final rows = await _client
          .from('support_requests')
          .select(
            'id, category, subject, message, status, created_at, related_reference, admin_note',
          )
          .eq('user_id', _userId)
          .order('created_at', ascending: false)
          .limit(30);
      return rows
          .map((row) => HelpSupportRequest.fromMap(
                Map<String, dynamic>.from(row),
              ))
          .toList(growable: false);
    } catch (error) {
      throw HelpSupportException(_friendlyMessage(error));
    }
  }

  Future<String> submitRequest({
    required String category,
    required String subject,
    required String message,
    String? relatedReference,
  }) async {
    try {
      final result = await _client.rpc(
        'submit_support_request',
        params: {
          'p_category': category,
          'p_subject': subject.trim(),
          'p_message': message.trim(),
          'p_related_reference': _blankToNull(relatedReference),
        },
      );
      return result.toString();
    } catch (error) {
      throw HelpSupportException(_friendlyMessage(error));
    }
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  String _friendlyMessage(Object error) {
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      if (error.code == '42P01' ||
          message.contains('support_requests') &&
              (message.contains('does not exist') ||
                  message.contains('schema cache'))) {
        return 'Help & Support is not installed yet. Run migration 020 in Supabase SQL Editor.';
      }
      if (error.code == '42501' || error.code == '28000') {
        return 'You are not allowed to submit this request. Please sign in again.';
      }
      if (message.contains('too many support requests')) {
        return 'You have submitted several requests recently. Please try again later.';
      }
      return 'Supabase could not complete your support request. ${error.message}';
    }
    return 'Something went wrong. Please check your connection and try again.';
  }
}
