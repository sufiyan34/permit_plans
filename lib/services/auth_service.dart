import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, kIsWeb, debugPrintStack;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/constants/app_routes.dart';

/// A friendly exception that can safely be displayed in the authentication UI.
class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthenticatedAccount {
  const AuthenticatedAccount({required this.user, required this.role});

  final User user;
  final String role;
}

/// Supabase email/password authentication and account-role lookup.
///
/// Roles are read from public.user_roles, never from editable user metadata.
class AuthService {
  AuthService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Where Supabase email links (confirm sign-up) should send the user back
  /// to. On web this is the origin the app is running on, so localhost links
  /// stay on localhost. The URL must be listed under Authentication ->
  /// URL Configuration -> Redirect URLs in the Supabase dashboard; otherwise
  /// Supabase falls back to the project's Site URL.
  static String? get _webOrigin => kIsWeb ? Uri.base.origin : null;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<AuthenticatedAccount> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthServiceException(
          'We could not sign you in. Please try again.',
        );
      }

      // A valid password is not enough to enter the marketplace: the role
      // row must also exist. Fail closed and clear the session if it cannot be
      // loaded, rather than leaving an authenticated user with unknown access.
      final String role;
      try {
        role = await getRoleForUser(user.id);
      } catch (_) {
        await _client.auth.signOut();
        rethrow;
      }
      return AuthenticatedAccount(user: user, role: role);
    } catch (error) {
      if (error is AuthServiceException) rethrow;
      throw AuthServiceException(_friendlyMessage(error, signingUp: false));
    }
  }

  /// Creates the Supabase Auth user. A database trigger creates the profile
  /// and immutable initial role in public.profiles and public.user_roles.
  Future<AuthResponse> signUp({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    if (role != 'client' && role != 'engineer') {
      throw const AuthServiceException(
        'Please choose either a Client or Engineer account.',
      );
    }

    try {
      return await _client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: _webOrigin,
        data: <String, dynamic>{
          'full_name': fullName.trim(),
          // The SQL trigger allowlists this value and writes it to a protected
          // table. Authorization never relies on user-editable metadata.
          'account_role': role,
        },
      );
    } catch (error) {
      if (error is AuthServiceException) rethrow;
      throw AuthServiceException(_friendlyMessage(error, signingUp: true));
    }
  }

  Future<String> getRoleForUser(String userId) async {
    try {
      final row = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();

      final role = row?['role'] as String?;
      if (role == null || !{'client', 'engineer', 'admin'}.contains(role)) {
        throw const AuthServiceException(
          'Your account role is missing. Please contact support.',
        );
      }
      return role;
    } catch (error, stackTrace) {
      if (error is AuthServiceException) rethrow;

      // Keep the user-facing message helpful without exposing database details.
      // The full PostgREST error is printed only in debug builds so the actual
      // cause (missing table, GRANT, RLS policy, or schema-cache issue) is visible.
      if (kDebugMode) {
        debugPrint('[AuthService.getRoleForUser] Role lookup failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      throw const AuthServiceException(
        'Your sign-in succeeded, but your account role could not be read. '
        'Please check that migration 001 is applied and that your user has '
        'a Client or Engineer role in public.user_roles.',
      );
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      final origin = _webOrigin;
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        // Lands on the reset-password page, which asks for the new password.
        redirectTo: origin == null ? null : '$origin${AppRoutes.resetPassword}',
      );
    } catch (error) {
      throw AuthServiceException(_friendlyMessage(error, signingUp: false));
    }
  }

  /// Sets a new password for the current (recovery or normal) session.
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (error) {
      throw AuthServiceException(_friendlyMessage(error, signingUp: false));
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      throw const AuthServiceException(
        'Unable to sign out right now. Please try again.',
      );
    }
  }

  String _friendlyMessage(Object error, {required bool signingUp}) {
    final message = error.toString().toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('invalid_credentials')) {
      return 'The email or password is incorrect.';
    }
    if (message.contains('email not confirmed') ||
        message.contains('email_not_confirmed')) {
      return 'Please verify your email address before signing in.';
    }
    if (message.contains('user already registered') ||
        message.contains('already been registered')) {
      return 'An account with this email already exists. Please sign in.';
    }
    if (message.contains('same_password') ||
        message.contains('different from the old password')) {
      return 'Choose a password that is different from your current one.';
    }
    if (message.contains('session missing') ||
        message.contains('session_not_found') ||
        message.contains('otp_expired') ||
        message.contains('token has expired')) {
      return 'This link has expired. Please request a new one.';
    }
    if (message.contains('password should be') ||
        message.contains('weak_password')) {
      return 'Please choose a stronger password.';
    }
    if (message.contains('rate limit') ||
        message.contains('too many requests')) {
      return 'Too many attempts. Please wait a little and try again.';
    }
    if (message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network is unreachable')) {
      return 'A network error occurred. Check your internet connection.';
    }

    return signingUp
        ? 'We could not create your account. Please check your details and try again.'
        : 'We could not complete sign-in. Please check your details and try again.';
  }
}
