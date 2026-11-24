/// Route names for the WorkBridge marketplace.
///
/// Every screen the app can navigate to by name lives here. Register the
/// matching [GetPage] in `get_app_routes.dart`.
class AppRoutes {
  AppRoutes._();

  // ---------------------------------------------------------------------------
  // Public / guest
  // ---------------------------------------------------------------------------
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const accountType = '/account-type';
  static const login = '/login';

  /// Optional query: `/sign-up?role=client` or `/sign-up?role=engineer`.
  /// With a valid role the role picker is hidden; without it the picker shows.
  static const signUp = '/sign-up';
  static const notFound = '/not-found';

  /// Public legal and policy library (Screen 32).
  static const legalPolicies = '/legal-policies';

  static String legalPoliciesFor(String policy) =>
      Uri(path: legalPolicies, queryParameters: {'policy': policy}).toString();

  /// Placeholder for pages that are not built yet.
  /// Optional query: `/coming-soon?feature=Payments`.
  static const comingSoon = '/coming-soon';

  /// Route to the placeholder page, labelled with [feature].
  /// `Get.toNamed(AppRoutes.comingSoonFor('Payments'))`
  static String comingSoonFor(String feature) =>
      Uri(path: comingSoon, queryParameters: {'feature': feature}).toString();
  // ---------------------------------------------------------------------------
  // Signed-in (any role)
  // ---------------------------------------------------------------------------

  /// Target of the password-recovery email link.
  static const resetPassword = '/reset-password';
  // Shared authenticated account settings (Screen 31).
  static const accountSettings = '/account/settings';
  // Shared Client / Engineer notification inbox (Screen 33).
  static const notifications = '/notifications';
  // Shared Client / Engineer notification preferences (Screen 34).
  static const notificationPreferences = '/notification-preferences';
  // Shared authenticated Help & Support center (Screen 35).
  static const helpSupport = '/help-support';
  // Admin-only support request inbox (Screen 36).
  static const adminSupportInbox = '/admin/support-inbox';
  static const clientProfileSetup = '/client-profile-setup';
  static const clientEditProfile = '/client/profile/edit';
  static const engineerProfileSetup = '/engineer-profile-setup';
  static const engineerEditProfile = '/engineer/profile/edit';

  // ---------------------------------------------------------------------------
  // Role dashboards
  // ---------------------------------------------------------------------------
  static const clientHome = '/client';
  static const engineerHome = '/engineer';
  static const adminHome = '/admin';
  // Browse Engineers
  static const clientBrowseEngineers = '/client/engineers';
  static const clientEngineerProfileDetails = '/client/engineer-profile';
  // Client task assignment
  static const clientAssignTask = '/client/assign-task';
  // Engineer Task Invitations
  static const engineerInvitations = '/engineer/invitations';
  // Engineer Project Workspace (Screen 20).
  static const engineerProjects = '/engineer/projects';
  // Engineer Earnings (Screen 26).
  static const engineerEarnings = '/engineer/earnings';
  // Engineer Payout Management (Screen 27).
  static const engineerPayoutManagement = '/engineer/payouts';
  // Engineer Submit Completed Work (Screen 22).
  static const engineerSubmitWork = '/engineer/submit-work';
  // Engineer Revision Requests (Screen 24).
  static const engineerRevisionRequests = '/engineer/revision-requests';
  // Client Delivery Review (Screen 23).
  static const clientDeliveryReviews = '/client/delivery-reviews';
  // Client Final Approval / final approved files (Screen 25).
  static const clientFinalApproval = '/client/final-approval';
  // Shared Client / Engineer Project Chat (Screen 21).
  static const projectChats = '/project/chats';
  // Submit Quote
  static const engineerSubmitQuote = '/engineer/submit-quote';
  // client Quote
  static const clientQuotes = '/client/quotes';
  // engineer Negotiations
  static const engineerNegotiations = '/engineer/negotiations';
  // client Contract Confirmation
  static const clientContractConfirmation = '/client/contract-confirmation';
  // client Payment Checkout
  static const clientPaymentCheckout = '/client/payment-checkout';
  // Client payment processing / result (mock until a provider is approved).
  static const clientPaymentProcessing = '/client/payment-processing';

  /// Routes anyone may visit without being signed in. Used to decide whether
  /// a sign-out should bounce the user to the login screen.
  static const publicRoutes = <String>{
    splash,
    onboarding,
    accountType,
    login,
    signUp,
    notFound,
    legalPolicies,
    comingSoon,
  };

  /// Profile onboarding route for the role stored in `public.user_roles`.
  static String profileSetupForRole(String role) {
    switch (role) {
      case 'client':
        return clientProfileSetup;
      case 'engineer':
        return engineerProfileSetup;
      case 'admin':
        return adminHome;
      default:
        return login;
    }
  }

  /// Dashboard route for a role stored in `public.user_roles`.
  static String homeForRole(String role) {
    switch (role) {
      case 'admin':
        return adminHome;
      case 'engineer':
        return engineerHome;
      case 'client':
        return clientHome;
      default:
        return login;
    }
  }
}
