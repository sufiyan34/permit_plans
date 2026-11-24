import 'package:supabase_flutter/supabase_flutter.dart';

/// Calls the authenticated Supabase Edge Function for WorkBridge AI.
/// The OpenAI API key is deliberately never stored in the Flutter application.
class WorkbridgeAiService {
  WorkbridgeAiService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<String> generateReply({
    required List<Map<String, String>> messages,
  }) async {
    if (_client.auth.currentSession == null) {
      throw const WorkbridgeAiException(
        'Please sign in again to use WorkBridge AI.',
      );
    }

    try {
      final response = await _client.functions.invoke(
        'workbridge-ai',
        body: <String, dynamic>{'messages': messages},
      );

      final dynamic payload = response.data;
      if (response.status < 200 || response.status >= 300) {
        final message = payload is Map
            ? payload['error']?.toString()
            : null;
        throw WorkbridgeAiException(
          message?.isNotEmpty == true
              ? message!
              : 'WorkBridge AI could not process this message. Please try again.',
        );
      }

      if (payload is Map && payload['reply'] is String) {
        final reply = (payload['reply'] as String).trim();
        if (reply.isNotEmpty) return reply;
      }

      throw const WorkbridgeAiException(
        'The AI service returned an empty response. Please try again.',
      );
    } on WorkbridgeAiException {
      rethrow;
    } catch (_) {
      throw const WorkbridgeAiException(
        'Could not connect to WorkBridge AI. Check that the Edge Function is deployed and its server secret is configured.',
      );
    }
  }
}

class WorkbridgeAiException implements Exception {
  const WorkbridgeAiException(this.message);

  final String message;

  @override
  String toString() => message;
}
