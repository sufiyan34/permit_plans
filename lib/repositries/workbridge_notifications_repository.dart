import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/models/workbridge_notification_model.dart';

class WorkbridgeNotificationsRepositoryException implements Exception {
  const WorkbridgeNotificationsRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Reads notifications belonging to the active user. Database triggers create
/// rows; this client repository intentionally has no notification insert API.
class WorkbridgeNotificationsRepository {
  WorkbridgeNotificationsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const int maxNotifications = 100;

  String? get currentUserId => _client.auth.currentUser?.id;

  Stream<List<Map<String, dynamic>>> watchNotifications() {
    _requireSession();
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', currentUserId!)
        .order('created_at', ascending: false)
        .limit(maxNotifications);
  }

  Future<List<WorkbridgeNotification>> fetchNotifications() async {
    _requireSession();
    try {
      final rows = await _client
          .from('notifications')
          .select()
          .eq('recipient_id', currentUserId!)
          .order('created_at', ascending: false)
          .limit(maxNotifications);
      return rows
          .map((row) => WorkbridgeNotification.fromJson(
                Map<String, dynamic>.from(row),
              ))
          .toList(growable: false);
    } catch (error) {
      throw WorkbridgeNotificationsRepositoryException(
        _friendlyMessage(error),
      );
    }
  }

  Future<void> markRead(String notificationId) async {
    _requireSession();
    try {
      await _client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('recipient_id', currentUserId!);
    } catch (error) {
      throw WorkbridgeNotificationsRepositoryException(
        _friendlyMessage(error),
      );
    }
  }

  Future<void> markAllRead() async {
    _requireSession();
    try {
      await _client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('recipient_id', currentUserId!)
          .eq('is_read', false);
    } catch (error) {
      throw WorkbridgeNotificationsRepositoryException(
        _friendlyMessage(error),
      );
    }
  }

  void _requireSession() {
    if (currentUserId == null) {
      throw const WorkbridgeNotificationsRepositoryException(
        'Your session has expired. Please sign in again.',
      );
    }
  }

  String _friendlyMessage(Object error) {
    if (error is PostgrestException) {
      final lower = error.message.toLowerCase();
      if (error.code == '42P01' ||
          lower.contains('notifications') &&
              (lower.contains('does not exist') || lower.contains('schema cache'))) {
        return 'Notifications are not installed yet. Run migration 018 in Supabase SQL Editor.';
      }
      if (error.code == '42501' || error.code == '28000') {
        return 'You are not allowed to access these notifications. Please sign in again.';
      }
      return 'Supabase could not load notifications. ${error.message}';
    }
    final text = error.toString().toLowerCase();
    if (text.contains('notifications')) {
      return 'Notifications are not installed yet. Run migration 018 in Supabase SQL Editor.';
    }
    return 'Something went wrong while loading notifications. Please try again.';
  }
}
