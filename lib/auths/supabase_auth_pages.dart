import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/auths/auth_screen_components.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/controllers/auth_controller.dart';
import 'package:permit_plans/views/login_screen.dart';
import 'package:permit_plans/views/reset_password_screen.dart';
import 'package:permit_plans/views/signup_screen.dart';

/// Route page for [AppRoutes.login]: connects the login UI to Supabase
/// through [AuthController]. Navigation after a successful sign-in is handled
/// by the controller (it routes to the user's role dashboard).
class SupabaseLoginPage extends StatelessWidget {
  const SupabaseLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return LoginScreen(
      onLogin: auth.signIn,
      onForgotPassword: (email) => unawaited(auth.sendPasswordReset(email)),
      // New users pick Client / Engineer first, then land on sign-up.
      onCreateAccount: () => Get.toNamed<void>(AppRoutes.accountType),
    );
  }
}

/// Route page for [AppRoutes.signUp]. The user chooses Client or Engineer in
/// the form, or arrives with `?role=` already chosen. Admin is never a public
/// option.
class SupabaseSignUpPage extends StatelessWidget {
  const SupabaseSignUpPage({
    this.initialRole = MarketplaceAccountRole.client,
    this.showRoleSelection = true,
    super.key,
  });

  final MarketplaceAccountRole initialRole;
  final bool showRoleSelection;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return SignUpScreen(
      initialRole: initialRole,
      showRoleSelection: showRoleSelection,
      onSignUp: (data) => auth.signUp(
        fullName: data.fullName,
        email: data.email,
        password: data.password,
        role: data.role.name,
      ),
      onSignIn: () => Get.offNamed<void>(AppRoutes.login),
    );
  }
}

/// Route page for [AppRoutes.resetPassword].
class SupabaseResetPasswordPage extends StatelessWidget {
  const SupabaseResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return ResetPasswordScreen(onSubmit: auth.updatePassword);
  }
}
