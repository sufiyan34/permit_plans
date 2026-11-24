import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/models/notification_preferences_model.dart';

class NotificationPreferencesRepositoryException implements Exception {
  const NotificationPreferencesRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Stores channel and event preferences for the signed-in account.
/// Email and push values are saved for future integrations; this repository
/// does not send email or push notifications.
class NotificationPreferencesRepository {
  NotificationPreferencesRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const _table = 'notification_preferences';

  String? get _userId => _client.auth.currentUser?.id;

  Future<NotificationPreferences> loadOrCreate() async {
    final userId = _requireUser();
    try {
      final row = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (row != null) {
        return NotificationPreferences.fromMap(
          Map<String, dynamic>.from(row),
        );
      }

      final created = await _client
          .from(_table)
          .upsert(
            {'user_id': userId},
            onConflict: 'user_id',
            defaultToNull: false,
          )
          .select()
          .single();
      return NotificationPreferences.fromMap(
        Map<String, dynamic>.from(created),
      );
    } catch (error) {
      throw NotificationPreferencesRepositoryException(
        _friendlyMessage(error),
      );
    }
  }

  Future<NotificationPreferences> save(
    NotificationPreferences preferences,
  ) async {
    final userId = _requireUser();
    if (preferences.userId != userId) {
      throw const NotificationPreferencesRepositoryException(
        'You can only update your own notification preferences.',
      );
    }

    try {
      final row = await _client
          .from(_table)
          .upsert(
            preferences.toUpsertMap(),
            onConflict: 'user_id',
            defaultToNull: false,
          )
          .select()
          .single();
      return NotificationPreferences.fromMap(
        Map<String, dynamic>.from(row),
      );
    } catch (error) {
      throw NotificationPreferencesRepositoryException(
        _friendlyMessage(error),
      );
    }
  }

  String _requireUser() {
    final userId = _userId;
    if (userId == null) {
      throw const NotificationPreferencesRepositoryException(
        'Your session has expired. Please sign in again.',
      );
    }
    return userId;
  }

  String _friendlyMessage(Object error) {
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      if (error.code == '42501' || error.code == '28000') {
        return 'You are not allowed to update these settings. Please sign in again.';
      }
      if (error.code == '42P01' ||
          error.code == 'PGRST205' ||
          message.contains('notification_preferences') &&
              (message.contains('does not exist') ||
                  message.contains('schema cache'))) {
        return 'Notification preferences are not installed yet. Run migration 019 in Supabase SQL Editor.';
      }
      return 'Supabase could not save notification preferences. ${error.message}';
    }
    return 'Something went wrong while saving notification preferences. Please try again.';
  }
}
