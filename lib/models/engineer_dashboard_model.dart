/// Profile information displayed on the Engineer Dashboard.
///
/// Project, proposal and payout totals are intentionally omitted until those
/// marketplace tables and their RLS policies are implemented.
class EngineerDashboardProfile {
  const EngineerDashboardProfile({
    required this.fullName,
    required this.email,
    required this.headline,
    required this.bio,
    required this.experienceLevel,
    required this.yearsExperience,
    required this.availability,
    required this.skills,
    required this.languages,
    required this.portfolioLinks,
    required this.profileCompleted,
    this.countryName,
    this.avatarUrl,
  });

  final String fullName;
  final String email;
  final String headline;
  final String bio;
  final String experienceLevel;
  final int yearsExperience;
  final String availability;
  final List<String> skills;
  final List<String> languages;
  final List<String> portfolioLinks;
  final bool profileCompleted;
  final String? countryName;
  final String? avatarUrl;

  String get firstName {
    final value = fullName.trim();
    if (value.isEmpty) return 'there';
    return value.split(RegExp(r'\s+')).first;
  }

  String get displayName => fullName.trim().isEmpty ? email : fullName.trim();

  String get experienceLabel {
    switch (experienceLevel) {
      case 'beginner':
        return 'Beginner';
      case 'expert':
        return 'Expert';
      default:
        return 'Intermediate';
    }
  }

  String get availabilityLabel {
    switch (availability) {
      case 'limited':
        return 'Limited availability';
      case 'unavailable':
        return 'Not available';
      default:
        return 'Available for work';
    }
  }

  factory EngineerDashboardProfile.fromRows({
    required Map<String, dynamic> profile,
    required Map<String, dynamic> engineerProfile,
    required String fallbackEmail,
  }) {
    final rawName = profile['full_name'] as String?;
    final rawEmail = profile['email'] as String?;

    return EngineerDashboardProfile(
      fullName: rawName?.trim().isNotEmpty == true
          ? rawName!.trim()
          : fallbackEmail.split('@').first,
      email: rawEmail?.trim().isNotEmpty == true
          ? rawEmail!.trim()
          : fallbackEmail,
      headline: (engineerProfile['headline'] as String?)?.trim() ?? '',
      bio: (engineerProfile['bio'] as String?)?.trim() ?? '',
      experienceLevel:
          (engineerProfile['experience_level'] as String?) ?? 'intermediate',
      yearsExperience:
          (engineerProfile['years_experience'] as num?)?.toInt() ?? 0,
      availability:
          (engineerProfile['availability'] as String?) ?? 'available',
      skills: _stringList(engineerProfile['skills']),
      languages: _stringList(engineerProfile['languages']),
      portfolioLinks: _stringList(engineerProfile['portfolio_links']),
      profileCompleted: profile['profile_completed'] == true,
      countryName: profile['country_name'] as String?,
      avatarUrl: profile['avatar_url'] as String?,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().map((item) => item.trim())
        .where((item) => item.isNotEmpty).toList(growable: false);
  }
}
