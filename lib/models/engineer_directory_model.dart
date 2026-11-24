/// A privacy-filtered engineer profile returned by public.browse_engineers.
/// This model intentionally has no email, phone, or payout fields.
class EngineerDirectoryProfile {
  const EngineerDirectoryProfile({
    required this.userId,
    required this.fullName,
    required this.headline,
    required this.bio,
    required this.experienceLevel,
    required this.yearsExperience,
    required this.availability,
    required this.skills,
    required this.languages,
    required this.portfolioLinks,
    required this.totalCount,
    this.countryName,
    this.avatarUrl,
  });

  final String userId;
  final String fullName;
  final String headline;
  final String bio;
  final String experienceLevel;
  final int yearsExperience;
  final String availability;
  final List<String> skills;
  final List<String> languages;
  final List<String> portfolioLinks;
  final int totalCount;
  final String? countryName;
  final String? avatarUrl;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'E';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  String get experienceLabel {
    final years = yearsExperience;
    if (years <= 0) return 'New professional';
    if (years == 1) return '1 year experience';
    return '$years years experience';
  }

  String get levelLabel {
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
        return 'Currently unavailable';
      default:
        return 'Available for work';
    }
  }

  bool get canReceiveAssignment => availability != 'unavailable';

  factory EngineerDirectoryProfile.fromMap(Map<String, dynamic> map) {
    return EngineerDirectoryProfile(
      userId: map['user_id']?.toString() ?? '',
      fullName: (map['full_name'] as String?)?.trim().isNotEmpty == true
          ? (map['full_name'] as String).trim()
          : 'Marketplace engineer',
      headline: (map['headline'] as String?) ?? '',
      bio: (map['bio'] as String?) ?? '',
      experienceLevel: (map['experience_level'] as String?) ?? 'intermediate',
      yearsExperience: (map['years_experience'] as num?)?.toInt() ?? 0,
      availability: (map['availability'] as String?) ?? 'available',
      skills: _stringList(map['skills']),
      languages: _stringList(map['languages']),
      portfolioLinks: _stringList(map['portfolio_links']),
      totalCount: (map['total_count'] as num?)?.toInt() ?? 0,
      countryName: map['country_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}

class EngineerDirectoryPage {
  const EngineerDirectoryPage({
    required this.engineers,
    required this.totalCount,
  });

  final List<EngineerDirectoryProfile> engineers;
  final int totalCount;
}
