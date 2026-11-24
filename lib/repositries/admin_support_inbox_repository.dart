import 'package:realtime_client/realtime_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/models/admin_support_ticket_model.dart';

class AdminSupportInboxException implements Exception {
  const AdminSupportInboxException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AdminSupportInboxRepository {
  AdminSupportInboxRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  RealtimeChannel? _channel;

  Future<List<AdminSupportTicket>> fetchTickets({
    String search = '',
    String status = 'all',
    String category = 'all',
    String priority = 'all',
    int limit = 100,
  }) async {
    try {
      final response = await _client.rpc(
        'admin_list_support_requests',
        params: {
          'p_search': search.trim().isEmpty ? null : search.trim(),
          'p_status': status == 'all' ? null : status,
          'p_category': category == 'all' ? null : category,
          'p_priority': priority == 'all' ? null : priority,
          'p_limit': limit,
          'p_offset': 0,
        },
      );
      if (response is! List) return const [];
      return response
          .whereType<Map>()
          .map((row) => AdminSupportTicket.fromMap(
                Map<String, dynamic>.from(row),
              ))
          .toList(growable: false);
    } catch (error) {
      throw AdminSupportInboxException(_friendlyMessage(error));
    }
  }

  Future<void> updateTicket({
    required String requestId,
    required String status,
    required String priority,
    required String adminNote,
  }) async {
    try {
      await _client.rpc(
        'admin_update_support_request',
        params: {
          'p_request_id': requestId,
          'p_status': status,
          'p_priority': priority,
          'p_admin_note': adminNote,
        },
      );
    } catch (error) {
      throw AdminSupportInboxException(_friendlyMessage(error));
    }
  }

  void subscribeToChanges(void Function() onChanged) {
    if (_channel != null) return;
    final userId = _client.auth.currentUser?.id ?? 'admin';
    _channel = _client
        .channel('admin-support-inbox-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'support_requests',
          callback: (_) => onChanged(),
        )
        .subscribe();
  }

  Future<void> dispose() async {
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      await _client.removeChannel(channel);
    }
  }

  String _friendlyMessage(Object error) {
    final text = error.toString();
    final lower = text.toLowerCase();
    if (lower.contains('admin_list_support_requests') ||
        lower.contains('admin_update_support_request') ||
        lower.contains('priority')) {
      return 'Admin Support Inbox setup is missing. Run migration 021 in Supabase SQL Editor after migration 020.';
    }
    if (lower.contains('only administrators') ||
        lower.contains('42501') ||
        lower.contains('permission denied')) {
      return 'This page is available only to an account with the Admin role.';
    }
    return 'Could not complete the support inbox action. Check your connection and confirm migration 021 is applied.';
  }
}
