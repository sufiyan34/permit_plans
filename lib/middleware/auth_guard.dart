import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/controllers/auth_controller.dart';

/// Protects routes that need a signed-in user.
///
/// - Not signed in            -> login
/// - Signed in, role unknown  -> splash (it restores the session + role, then
///   routes correctly; this covers a browser refresh on a dashboard URL)
/// - Wrong role for the page  -> that user's own dashboard
///
/// Pass [allowedRoles] for role dashboards. Leave it null for pages that only
/// need *a* session (for example the password-reset page).
class AuthGuard extends GetMiddleware {
  AuthGuard({this.allowedRoles});

  final Set<String>? allowedRoles;

  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();

    if (!auth.isSignedIn) {
      return const RouteSettings(name: AppRoutes.login);
    }

    final allowed = allowedRoles;
    if (allowed == null) return null;

    final role = auth.currentRole.value;
    if (role == null) {
      return const RouteSettings(name: AppRoutes.splash);
    }
    if (!allowed.contains(role)) {
      return RouteSettings(
        name: auth.profileCompleted.value
            ? AppRoutes.homeForRole(role)
            : AppRoutes.profileSetupForRole(role),
      );
    }
    if (!auth.profileCompleted.value && role != 'admin') {
      return RouteSettings(name: AppRoutes.profileSetupForRole(role));
    }
    return null;
  }
}

/// Allows only the matching signed-in role to complete its profile.
/// Users with a completed profile are sent to their dashboard instead.
class ProfileSetupGuard extends GetMiddleware {
  ProfileSetupGuard({required this.allowedRole});

  final String allowedRole;

  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    if (!auth.isSignedIn) {
      return const RouteSettings(name: AppRoutes.login);
    }

    final role = auth.currentRole.value;
    if (role == null) {
      return const RouteSettings(name: AppRoutes.splash);
    }
    if (role != allowedRole) {
      return RouteSettings(
        name: auth.profileCompleted.value
            ? AppRoutes.homeForRole(role)
            : AppRoutes.profileSetupForRole(role),
      );
    }
    if (auth.profileCompleted.value) {
      return RouteSettings(name: AppRoutes.homeForRole(role));
    }
    return null;
  }
}

/// Keeps signed-in users away from onboarding / login / sign-up.
class GuestGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    final role = auth.currentRole.value;

    // Only redirect once the role is known; otherwise let the page render so
    // we can never create a redirect loop with the splash screen.
    if (auth.isSignedIn && role != null) {
      return RouteSettings(
        name: auth.profileCompleted.value || role == 'admin'
            ? AppRoutes.homeForRole(role)
            : AppRoutes.profileSetupForRole(role),
      );
    }
    return null;
  }
}
