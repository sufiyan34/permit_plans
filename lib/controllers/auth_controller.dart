import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/services/auth_service.dart';
import 'package:permit_plans/repositries/profile_repository.dart';

/// Called after a user's role has been loaded from the protected role table.
/// When no callback is supplied the controller navigates to the role's
/// dashboard itself (see [AppRoutes.homeForRole]).
typedef AuthenticatedCallback = void Function(String role);

class AuthController extends GetxController {
  AuthController({
    required AuthService authService,
    required ProfileRepository profileRepository,
    this.onAuthenticated,
  })  : _authService = authService,
        _profileRepository = profileRepository;

  final AuthService _authService;
  final ProfileRepository _profileRepository;
  final AuthenticatedCallback? onAuthenticated;

  final Rxn<User> currentUser = Rxn<User>();
  final RxnString currentRole = RxnString();
  final RxBool profileCompleted = false.obs;
  final RxnString pendingVerificationEmail = RxnString();
  final RxBool isLoading = false.obs;

  /// True while the user arrived through a password-recovery email link and
  /// has not chosen a new password yet.
  final RxBool inPasswordRecovery = false.obs;

  StreamSubscription<AuthState>? _authSubscription;

  bool get isSignedIn => currentUser.value != null;

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _authService.currentUser;

    // Keep controller state synchronized with token refresh, sign-out and
    // email-confirmation deep-link events. Always handle stream errors.
    _authSubscription = _authService.onAuthStateChange.listen(
      _handleAuthState,
      onError: (Object error, StackTrace stackTrace) {
        // Avoid throwing stream errors into Flutter's global error zone.
        // A later API call can retry the role lookup.
      },
    );

    final user = currentUser.value;
    if (user != null) {
      unawaited(_refreshRole(user.id));
    }
  }

  // ---------------------------------------------------------------------------
  // Start-up routing
  // ---------------------------------------------------------------------------

  /// Decides where the app should go once the splash screen is done:
  /// recovery page, role-specific profile setup, dashboard or onboarding.
  Future<String> resolveStartRoute() async {
    if (inPasswordRecovery.value) return AppRoutes.resetPassword;

    final user = _authService.currentUser;
    if (user == null) return AppRoutes.onboarding;

    currentUser.value = user;
    try {
      final role = await _authService.getRoleForUser(user.id);
      if (role == 'admin') {
        currentRole.value = role;
        profileCompleted.value = true;
        return AppRoutes.adminHome;
      }
      final completed = await _profileRepository.isProfileComplete(user.id);
      currentRole.value = role;
      profileCompleted.value = completed;
      return completed
          ? AppRoutes.homeForRole(role)
          : AppRoutes.profileSetupForRole(role);
    } catch (error) {
      final message = error is AuthServiceException
          ? error.message
          : error is ProfileRepositoryException
              ? error.message
              : 'Could not load your account. Check that the profile migration has been applied.';
      Get.snackbar(
        'Could not restore your session',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return AppRoutes.login;
    }
  }

  // ---------------------------------------------------------------------------
  // Auth actions
  // ---------------------------------------------------------------------------

  Future<void> signIn(String email, String password) async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final account = await _authService.signIn(
        email: email,
        password: password,
      );
      currentUser.value = account.user;
      pendingVerificationEmail.value = null;
      await _notifyAuthenticated(account.role, userId: account.user.id);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final response = await _authService.signUp(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthServiceException(
          'We could not create your account. Please try again.',
        );
      }

      if (response.session == null) {
        // Supabase email confirmation is enabled. The profile and role have
        // already been created by the auth.users database trigger.
        currentUser.value = null;
        currentRole.value = null;
        pendingVerificationEmail.value = email.trim();

        // Navigate first, then show the message: a snackbar shown before
        // offAll navigation can be removed along with the old routes.
        Get.offAllNamed<void>(AppRoutes.login);
        Get.snackbar(
          'Check your email',
          'We sent a verification link to ${email.trim()}. Verify your email, '
              'then return to sign in.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 6),
        );
        return;
      }

      currentUser.value = user;
      final roleFromDatabase = await _authService.getRoleForUser(user.id);
      pendingVerificationEmail.value = null;
      await _notifyAuthenticated(roleFromDatabase, userId: user.id);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordReset(email);
      Get.snackbar(
        'Password reset email sent',
        'Check ${email.trim()} for the password reset instructions.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on AuthServiceException catch (error) {
      Get.snackbar(
        'Unable to send reset email',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Saves the new password chosen on the reset page, then continues into the
  /// app like a normal sign-in. Throws [AuthServiceException] for the UI.
  Future<void> updatePassword(String newPassword) async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await _authService.updatePassword(newPassword);
      inPasswordRecovery.value = false;

      final user = _authService.currentUser;
      if (user == null) {
        throw const AuthServiceException(
          'Your password was updated. Please sign in again.',
        );
      }
      currentUser.value = user;
      final role = await _authService.getRoleForUser(user.id);

      await _notifyAuthenticated(role, userId: user.id);
      Get.snackbar(
        'Password updated',
        'Your new password is ready to use.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Signs out and returns to the login screen. Throws
  /// [AuthServiceException] if Supabase cannot sign out.
  Future<void> signOut() async {
    await _authService.signOut();
    _clearSession();
    _redirectToLoginIfProtected();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _notifyAuthenticated(String role, {required String userId}) async {
    final String destination;
    if (role == 'admin') {
      profileCompleted.value = true;
      destination = AppRoutes.adminHome;
    } else {
      final completed = await _profileRepository.isProfileComplete(userId);
      profileCompleted.value = completed;
      destination = completed
          ? AppRoutes.homeForRole(role)
          : AppRoutes.profileSetupForRole(role);
    }

    currentRole.value = role;

    final callback = onAuthenticated;
    if (callback != null) {
      callback(role);
      return;
    }
    Get.offAllNamed<void>(destination);
  }

  /// Called only after the role-specific profile has been saved and the
  /// database completion RPC has succeeded.
  void profileSetupCompleted() {
    profileCompleted.value = true;
    final role = currentRole.value;
    if (role == null) return;
    Get.offAllNamed<void>(AppRoutes.homeForRole(role));
  }

  void _clearSession() {
    currentUser.value = null;
    currentRole.value = null;
    profileCompleted.value = false;
    pendingVerificationEmail.value = null;
    inPasswordRecovery.value = false;
  }

  /// After a sign-out (button, expired session, or another browser tab) send
  /// the user to login unless they are already on a public page.
  void _redirectToLoginIfProtected() {
    if (Get.key.currentState == null) return; // app not built yet
    final path = Uri.parse(Get.currentRoute).path;
    if (AppRoutes.publicRoutes.contains(path)) return;
    Get.offAllNamed<void>(AppRoutes.login);
  }

  Future<void> _refreshRole(String userId) async {
    try {
      final role = await _authService.getRoleForUser(userId);
      final completed = role == 'admin'
          ? true
          : await _profileRepository.isProfileComplete(userId);
      profileCompleted.value = completed;
      currentRole.value = role;
    } catch (_) {
      // Leave the role empty. The next protected action must not assume a role.
    }
  }

  void _handleAuthState(AuthState state) {
    if (state.event == AuthChangeEvent.signedOut) {
      _clearSession();
      _redirectToLoginIfProtected();
      return;
    }

    final session = state.session;
    if (session == null) return;

    final user = session.user;
    currentUser.value = user;

    // The user followed a "reset password" email link (mobile deep link, or a
    // web link that was processed after start-up).
    if (state.event == AuthChangeEvent.passwordRecovery) {
      inPasswordRecovery.value = true;
      Get.offAllNamed<void>(AppRoutes.resetPassword);
      return;
    }

    // When the user follows the Supabase confirmation link back into the app,
    // complete the pending signup and route by the role in public.user_roles.
    final pendingEmail = pendingVerificationEmail.value?.toLowerCase();
    if (state.event == AuthChangeEvent.signedIn &&
        pendingEmail != null &&
        pendingEmail == user.email?.toLowerCase()) {
      unawaited(_completePendingVerification(user));
    } else {
      unawaited(_refreshRole(user.id));
    }
  }

  Future<void> _completePendingVerification(User user) async {
    try {
      final role = await _authService.getRoleForUser(user.id);
      pendingVerificationEmail.value = null;
      await _notifyAuthenticated(role, userId: user.id);
    } catch (error) {
      final message = error is AuthServiceException
          ? error.message
          : error is ProfileRepositoryException
              ? error.message
              : 'Please try signing in again.';
      Get.snackbar(
        'Account setup incomplete',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }
}
