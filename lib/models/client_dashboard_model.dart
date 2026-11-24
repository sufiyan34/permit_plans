/// Minimal profile data displayed by the Client Dashboard.
/// Project counts are intentionally not included until the task/contract
/// tables are implemented; the dashboard must not display invented totals.
class ClientDashboardProfile {
  const ClientDashboardProfile({
    required this.fullName,
    required this.email,
    this.countryName,
    this.avatarUrl,
    this.accountType = 'individual',
    this.companyName,
  });

  final String fullName;
  final String email;
  final String? countryName;
  final String? avatarUrl;
  final String accountType;
  final String? companyName;

  String get firstName {
    final normalized = fullName.trim();
    if (normalized.isEmpty) return 'there';
    return normalized.split(RegExp(r'\s+')).first;
  }

  String get displayName => fullName.trim().isEmpty ? email : fullName.trim();

  String get accountLabel => accountType == 'company' ? 'Company account' : 'Individual account';

  factory ClientDashboardProfile.fromRows({
    required Map<String, dynamic> profile,
    Map<String, dynamic>? clientProfile,
    required String fallbackEmail,
  }) {
    return ClientDashboardProfile(
      fullName: (profile['full_name'] as String?)?.trim().isNotEmpty == true
          ? (profile['full_name'] as String).trim()
          : fallbackEmail.split('@').first,
      email: (profile['email'] as String?) ?? fallbackEmail,
      countryName: profile['country_name'] as String?,
      avatarUrl: profile['avatar_url'] as String?,
      accountType: (clientProfile?['account_type'] as String?) ?? 'individual',
      companyName: clientProfile?['company_name'] as String?,
    );
  }
}
