import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/models/account_settings_model.dart';

class AccountSettingsException implements Exception {
  const AccountSettingsException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AccountSettingsRepository {
  AccountSettingsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AccountSettingsException(
        'Your session has expired. Please sign in again.',
      );
    }
    return user;
  }

  Future<AccountSettingsSnapshot> loadSnapshot() async {
    final user = _requireUser();
    try {
      final roleRow = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', user.id)
          .maybeSingle();

      final deletionRows = await _client
          .from('account_deletion_requests')
          .select('id, status, reason, requested_at')
          .eq('user_id', user.id)
          .order('requested_at', ascending: false)
          .limit(1);

      AccountDeletionRequest? deletionRequest;
      if (deletionRows is List && deletionRows.isNotEmpty) {
        final row = Map<String, dynamic>.from(deletionRows.first as Map);
        deletionRequest = AccountDeletionRequest.fromMap(row);
      }

      return AccountSettingsSnapshot(
        userId: user.id,
        email: user.email ?? '',
        role: roleRow?['role'] as String? ?? 'account',
        createdAt: DateTime.tryParse(user.createdAt),
        deletionRequest: deletionRequest,
      );
    } catch (error) {
      if (error is AccountSettingsException) rethrow;
      throw AccountSettingsException(_friendlyError(error));
    }
  }

  /// Re-authenticates with the current password before changing credentials.
  /// This avoids allowing a person with only an unlocked device to change the
  /// account password without knowing the existing password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _requireUser();
    final email = user.email;
    if (email == null || email.trim().isEmpty) {
      throw const AccountSettingsException(
        'This account has no email/password sign-in. Use password recovery or contact support.',
      );
    }

    try {
      final verification = await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
      if (verification.user?.id != user.id) {
        throw const AccountSettingsException(
          'We could not verify your current password.',
        );
      }

      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (error) {
      if (error is AccountSettingsException) rethrow;
      final message = error.toString().toLowerCase();
      if (message.contains('invalid login credentials') ||
          message.contains('invalid_credentials')) {
        throw const AccountSettingsException(
          'Your current password is incorrect.',
        );
      }
      if (message.contains('same_password') ||
          message.contains('different from the old password')) {
        throw const AccountSettingsException(
          'Choose a new password that is different from your current password.',
        );
      }
      if (message.contains('weak_password') ||
          message.contains('password should be')) {
        throw const AccountSettingsException(
          'Your new password does not meet the password requirements.',
        );
      }
      throw AccountSettingsException(_friendlyError(error));
    }
  }

  Future<void> submitDeletionRequest({String? reason}) async {
    _requireUser();
    try {
      await _client.rpc(
        'request_account_deletion',
        params: <String, dynamic>{
          'p_reason': reason?.trim().isEmpty == true ? null : reason?.trim(),
        },
      );
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('account_deletion_requests') ||
          message.contains('request_account_deletion')) {
        throw const AccountSettingsException(
          'Account deletion requests are not configured yet. Run migration 017 in Supabase SQL Editor.',
        );
      }
      if (message.contains('active deletion request')) {
        throw const AccountSettingsException(
          'You already have an active account deletion request.',
        );
      }
      throw AccountSettingsException(_friendlyError(error));
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network is unreachable')) {
      return 'A network error occurred. Check your internet connection.';
    }
    if (message.contains('account_deletion_requests') ||
        message.contains('request_account_deletion') ||
        message.contains('does not exist')) {
      return 'Account deletion requests are not configured yet. Run migration 017 in Supabase SQL Editor.';
    }
    if (message.contains('permission denied') ||
        message.contains('row-level security')) {
      return 'Supabase denied this action. Check that migrations 001 and 017 are applied.';
    }
    if (message.contains('user_roles') || message.contains('role')) {
      return 'We could not load your account role. Check that migration 001 is applied.';
    }
    return 'We could not complete this account action. Please try again.';
  }
}
