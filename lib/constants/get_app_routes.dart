import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permit_plans/bindings/engineer_dashboard_binding.dart';

import 'package:permit_plans/views/engineer-portal/engineer_dashboard_screen.dart';
import 'package:permit_plans/auths/supabase_auth_pages.dart';
import 'package:permit_plans/auths/auth_screen_components.dart';
import 'package:permit_plans/bindings/client_dashboard_binding.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/bindings/profile_binding.dart';
import 'package:permit_plans/controllers/auth_controller.dart';
import 'package:permit_plans/middleware/auth_guard.dart';
import 'package:permit_plans/views/account_type_selection_screen.dart';
import 'package:permit_plans/views/coming_soon_screen.dart';
import 'package:permit_plans/views/customer-portal/client_dashboard_screen.dart';
import 'package:permit_plans/views/customer-portal/client_profile_setup_screen.dart';
import 'package:permit_plans/bindings/client_edit_profile_binding.dart';
import 'package:permit_plans/views/customer-portal/client_edit_profile_screen.dart';
import 'package:permit_plans/bindings/engineer_edit_profile_binding.dart';
import 'package:permit_plans/views/engineer-portal/engineer_edit_profile_screen.dart';
import 'package:permit_plans/views/engineer-portal/engineer_profile_setup_screen.dart';
import 'package:permit_plans/views/not_found_screen.dart';
import 'package:permit_plans/views/onboarding_screen.dart';
import 'package:permit_plans/views/splash_screen.dart';
import 'package:permit_plans/bindings/engineer_directory_binding.dart';

import 'package:permit_plans/views/customer-portal/browse_engineers_screen.dart';
import 'package:permit_plans/bindings/engineer_profile_details_binding.dart';

import 'package:permit_plans/views/customer-portal/engineer_profile_details_screen.dart';
import 'package:permit_plans/bindings/assign_task_binding.dart';

import 'package:permit_plans/views/customer-portal/assign_task_screen.dart';
import 'package:permit_plans/bindings/engineer_task_invitations_binding.dart';

import 'package:permit_plans/views/engineer-portal/engineer_task_invitations_screen.dart';
import 'package:permit_plans/bindings/submit_quote_binding.dart';

import 'package:permit_plans/views/engineer-portal/submit_quote_screen.dart';
import 'package:permit_plans/bindings/client_quote_review_binding.dart';

import 'package:permit_plans/views/customer-portal/client_quote_review_screen.dart';
import 'package:permit_plans/bindings/engineer_negotiation_binding.dart';

import 'package:permit_plans/views/engineer-portal/engineer_negotiation_screen.dart';
import 'package:permit_plans/bindings/contract_confirmation_binding.dart';
import 'package:permit_plans/views/customer-portal/contract_confirmation_screen.dart';
import 'package:permit_plans/bindings/payment_checkout_binding.dart';

import 'package:permit_plans/views/customer-portal/payment_checkout_screen.dart';
import 'package:permit_plans/bindings/payment_processing_binding.dart';
import 'package:permit_plans/views/customer-portal/payment_processing_screen.dart';
import 'package:permit_plans/bindings/engineer_projects_binding.dart';
import 'package:permit_plans/bindings/engineer_earnings_binding.dart';
import 'package:permit_plans/bindings/engineer_payout_management_binding.dart';
import 'package:permit_plans/bindings/submit_project_work_binding.dart';
import 'package:permit_plans/views/engineer-portal/engineer_projects_screen.dart';
import 'package:permit_plans/views/engineer-portal/engineer_earnings_screen.dart';
import 'package:permit_plans/views/engineer-portal/engineer_payout_management_screen.dart';
import 'package:permit_plans/views/engineer-portal/submit_project_work_screen.dart';
import 'package:permit_plans/bindings/engineer_revision_requests_binding.dart';
import 'package:permit_plans/views/engineer-portal/engineer_revision_requests_screen.dart';
import 'package:permit_plans/bindings/client_delivery_review_binding.dart';
import 'package:permit_plans/views/customer-portal/client_delivery_review_screen.dart';
import 'package:permit_plans/bindings/client_final_approval_binding.dart';
import 'package:permit_plans/views/customer-portal/client_final_approval_screen.dart';
import 'package:permit_plans/bindings/admin_dashboard_binding.dart';
import 'package:permit_plans/views/admin-portal/admin_dashboard_screen.dart';
import 'package:permit_plans/bindings/project_chat_binding.dart';
import 'package:permit_plans/views/project_chat_screen.dart';
import 'package:permit_plans/bindings/account_settings_binding.dart';
import 'package:permit_plans/views/account_settings_screen.dart';
import 'package:permit_plans/bindings/legal_policies_binding.dart';
import 'package:permit_plans/views/legal_policies_screen.dart';
import 'package:permit_plans/bindings/workbridge_notifications_binding.dart';
import 'package:permit_plans/views/workbridge_notifications_screen.dart';
import 'package:permit_plans/bindings/notification_preferences_binding.dart';
import 'package:permit_plans/views/notification_preferences_screen.dart';
import 'package:permit_plans/bindings/help_support_binding.dart';
import 'package:permit_plans/views/help_support_screen.dart';
import 'package:permit_plans/bindings/admin_support_inbox_binding.dart';
import 'package:permit_plans/views/admin-portal/admin_support_inbox_screen.dart';

class GetAppRoutes {
  GetAppRoutes._();

  /// Shown for any URL that doesn't match a route (set as `unknownRoute`
  /// in main.dart).
  static final unknownRoute = GetPage<dynamic>(
    name: AppRoutes.notFound,
    page: _notFoundPage,
  );

  static final pages = <GetPage<dynamic>>[
    // -----------------------------------------------------------------------
    // GENERAL
    // -----------------------------------------------------------------------
    GetPage<dynamic>(
      name: AppRoutes.splash,
      page: () => const SplashScreen(onFinished: _startApp),
    ),
    unknownRoute,
    GetPage<dynamic>(
      name: AppRoutes.comingSoon,
      page: () {
        final feature = Get.parameters['feature'];
        return ComingSoonScreen(
          title: (feature == null || feature.isEmpty) ? 'This page' : feature,
        );
      },
    ),
    // Public legal and policy library (Screen 32).
    GetPage<dynamic>(
      name: AppRoutes.legalPolicies,
      page: () => const LegalPoliciesScreen(),
      binding: LegalPoliciesBinding(),
    ),
    // Engineer Profile Details
    GetPage<dynamic>(
      name: AppRoutes.clientEngineerProfileDetails,
      page: () => const EngineerProfileDetailsScreen(),
      binding: EngineerProfileDetailsBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'client'}),
      ],
    ),
    // -----------------------------------------------------------------------
    // GUEST FLOW: onboarding -> account type -> sign up / login
    // -----------------------------------------------------------------------
    GetPage<dynamic>(
      name: AppRoutes.onboarding,
      page: () => OnboardingScreen(
        onComplete: () => Get.toNamed<void>(AppRoutes.accountType),
      ),
      middlewares: [GuestGuard()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.accountType,
      page: () => const AccountTypeSelectionScreen(),
      middlewares: [GuestGuard()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.login,
      page: () => const SupabaseLoginPage(),
      middlewares: [GuestGuard()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.signUp,
      page: () {
        final role = _roleFromName(Get.parameters['role']);
        return SupabaseSignUpPage(
          initialRole: role ?? MarketplaceAccountRole.client,
          showRoleSelection: role == null,
        );
      },
      middlewares: [GuestGuard()],
    ),
    // Assign Task
    GetPage<dynamic>(
      name: AppRoutes.clientAssignTask,
      page: () => const AssignTaskScreen(),
      binding: AssignTaskBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'client'}),
      ],
    ),
    // Engineer Submit Quote
    GetPage<dynamic>(
      name: AppRoutes.engineerSubmitQuote,
      page: () => const SubmitQuoteScreen(),
      binding: SubmitQuoteBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'engineer'}),
      ],
    ),
    // Client Quote Review
    GetPage<dynamic>(
      name: AppRoutes.clientQuotes,
      page: () => const ClientQuoteReviewScreen(),
      binding: ClientQuoteReviewBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'client'}),
      ],
    ),
    // Engineer Negotiations
    GetPage<dynamic>(
      name: AppRoutes.engineerNegotiations,
      page: () => const EngineerNegotiationScreen(),
      binding: EngineerNegotiationBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'engineer'}),
      ],
    ),
    // Client Payment Checkout
    GetPage<dynamic>(
      name: AppRoutes.clientPaymentCheckout,
      page: () => const PaymentCheckoutScreen(),
      binding: PaymentCheckoutBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'client'}),
      ],
    ),
    // Client Payment Processing / Result (Screen 19, mock-only).
    GetPage<dynamic>(
      name: AppRoutes.clientPaymentProcessing,
      page: () => const PaymentProcessingScreen(),
      binding: PaymentProcessingBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'client'}),
      ],
    ),
    // -----------------------------------------------------------------------
    // PASSWORD RECOVERY (needs the temporary session from the email link)
    // -----------------------------------------------------------------------
    GetPage<dynamic>(
      name: AppRoutes.resetPassword,
      page: () => const SupabaseResetPasswordPage(),
      middlewares: [AuthGuard()],
    ),
    // Shared account settings and security (Screen 31).
    GetPage<dynamic>(
      name: AppRoutes.accountSettings,
      page: () => const AccountSettingsScreen(),
      binding: AccountSettingsBinding(),
      middlewares: [AuthGuard()],
    ),
    // Shared Client / Engineer in-app notifications (Screen 33).
    GetPage<dynamic>(
      name: AppRoutes.notifications,
      page: () => const WorkbridgeNotificationsScreen(),
      binding: WorkbridgeNotificationsBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'client', 'engineer'}),
      ],
    ),
    // Shared Client / Engineer notification preferences (Screen 34).
    GetPage<dynamic>(
      name: AppRoutes.notificationPreferences,
      page: () => const NotificationPreferencesScreen(),
      binding: NotificationPreferencesBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'client', 'engineer'}),
      ],
    ),
    // Shared authenticated Help & Support center (Screen 35).
    GetPage<dynamic>(
      name: AppRoutes.helpSupport,
      page: () => const HelpSupportScreen(),
      binding: HelpSupportBinding(),
      middlewares: [AuthGuard()],
    ),
    // Admin-only support request inbox (Screen 36).
    GetPage<dynamic>(
      name: AppRoutes.adminSupportInbox,
      page: () => const AdminSupportInboxScreen(),
      binding: AdminSupportInboxBinding(),
      middlewares: [AuthGuard(allowedRoles: const {'admin'})],
    ),
    // Engineer Task Invitations
    GetPage<dynamic>(
      name: AppRoutes.engineerInvitations,
      page: () => const EngineerTaskInvitationsScreen(),
      binding: EngineerTaskInvitationsBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'engineer'}),
      ],
    ),
    // Engineer Project Workspace (Screen 20).
    GetPage<dynamic>(
      name: AppRoutes.engineerProjects,
      page: () => const EngineerProjectsScreen(),
      binding: EngineerProjectsBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'engineer'}),
      ],
    ),
    // Engineer Earnings (Screen 26).
    GetPage<dynamic>(
      name: AppRoutes.engineerEarnings,
      page: () => const EngineerEarningsScreen(),
      binding: EngineerEarningsBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'engineer'}),
      ],
    ),
    // Engineer Payout Management (Screen 27; provider integration pending).
    GetPage<dynamic>(
      name: AppRoutes.engineerPayoutManagement,
      page: () => const EngineerPayoutManagementScreen(),
      binding: EngineerPayoutManagementBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'engineer'}),
      ],
    ),
    // Engineer Submit Completed Work (Screen 22).
    GetPage<dynamic>(
      name: AppRoutes.engineerSubmitWork,
      page: () => const SubmitProjectWorkScreen(),
      binding: SubmitProjectWorkBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'engineer'}),
      ],
    ),
    // Engineer Revision Requests (Screen 24).
    GetPage<dynamic>(
      name: AppRoutes.engineerRevisionRequests,
      page: () => const EngineerRevisionRequestsScreen(),
      binding: EngineerRevisionRequestsBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'engineer'}),
      ],
    ),
    // Client Delivery Review (Screen 23).
    GetPage<dynamic>(
      name: AppRoutes.clientDeliveryReviews,
      page: () => const ClientDeliveryReviewScreen(),
      binding: ClientDeliveryReviewBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'client'}),
      ],
    ),
    // Client Final Approval / approved final files (Screen 25).
    GetPage<dynamic>(
      name: AppRoutes.clientFinalApproval,
      page: () => const ClientFinalApprovalScreen(),
      binding: ClientFinalApprovalBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'client'}),
      ],
    ),
    // Shared Client / Engineer Project Chat (Screen 21).
    GetPage<dynamic>(
      name: AppRoutes.projectChats,
      page: () => const ProjectChatScreen(),
      binding: ProjectChatBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'client', 'engineer'}),
      ],
    ),
    // client Contract Confirmation
    GetPage<dynamic>(
      name: AppRoutes.clientContractConfirmation,
      page: () => const ContractConfirmationScreen(),
      binding: ContractConfirmationBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'client'}),
      ],
    ),
    // -----------------------------------------------------------------------
    // ROLE-SPECIFIC PROFILE ONBOARDING
    // -----------------------------------------------------------------------
    GetPage<dynamic>(
      name: AppRoutes.clientProfileSetup,
      page: () => const ClientProfileSetupScreen(),
      binding: ProfileBinding(),
      middlewares: [ProfileSetupGuard(allowedRole: 'client')],
    ),
    GetPage<dynamic>(
      name: AppRoutes.engineerProfileSetup,
      page: () => const EngineerProfileSetupScreen(),
      binding: ProfileBinding(),
      middlewares: [ProfileSetupGuard(allowedRole: 'engineer')],
    ),

    // Client profile editing (Screen 29).
    GetPage<dynamic>(
      name: AppRoutes.clientEditProfile,
      page: () => const ClientEditProfileScreen(),
      binding: ClientEditProfileBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'client'}),
      ],
    ),

    // Engineer profile editing (Screen 30).
    GetPage<dynamic>(
      name: AppRoutes.engineerEditProfile,
      page: () => const EngineerEditProfileScreen(),
      binding: EngineerEditProfileBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'engineer'}),
      ],
    ),

    // -----------------------------------------------------------------------
    // ROLE DASHBOARDS (placeholders until the real portals are built)
    // -----------------------------------------------------------------------
    GetPage<dynamic>(
      name: AppRoutes.clientHome,
      page: () => ClientDashboardScreen(),
      binding: ClientDashboardBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'client'}),
      ],
    ),
    GetPage<dynamic>(
      name: AppRoutes.clientBrowseEngineers,
      page: () => const BrowseEngineersScreen(),
      binding: EngineerDirectoryBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'client'}),
      ],
    ),
    GetPage<dynamic>(
      name: AppRoutes.engineerHome,
      page: () => EngineerDashboardScreen(),
      binding: EngineerDashboardBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'engineer'}),
      ],
    ),
    GetPage<dynamic>(
      name: AppRoutes.adminHome,
      page: () => const AdminDashboardScreen(),
      binding: AdminDashboardBinding(),
      middlewares: [
        AuthGuard(allowedRoles: const {'admin'}),
      ],
    ),
  ];

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Splash finished: restore the session (if any) and route accordingly.
  static Future<void> _startApp() async {
    final route = await Get.find<AuthController>().resolveStartRoute();
    Get.offAllNamed<void>(route);
  }

  static Widget _notFoundPage() {
    void goHome() => Get.offAllNamed<void>(AppRoutes.splash);

    void goBack() {
      if (Get.key.currentState?.canPop() ?? false) {
        Get.back<void>();
      } else {
        goHome();
      }
    }

    // The not-found page is often the only route in the stack, so the
    // default Navigator-based actions would do nothing.
    return NotFoundScreen(onGoHome: goHome, onGoBack: goBack);
  }

  static MarketplaceAccountRole? _roleFromName(String? name) {
    for (final role in MarketplaceAccountRole.values) {
      if (role.name == name) return role;
    }
    return null; // includes 'admin' and anything unexpected
  }
}
