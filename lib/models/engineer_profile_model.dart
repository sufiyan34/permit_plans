class EngineerProfileModel {
  const EngineerProfileModel({
    required this.fullName,
    required this.countryName,
    required this.headline,
    required this.bio,
    required this.experienceLevel,
    required this.yearsExperience,
    required this.availability,
    required this.skills,
    this.languages = const [],
    this.portfolioLinks = const [],
    this.avatarUrl,
  });

  final String fullName;
  final String countryName;
  final String headline;
  final String bio;
  final String experienceLevel;
  final int yearsExperience;
  final String availability;
  final List<String> skills;
  final List<String> languages;
  final List<String> portfolioLinks;
  final String? avatarUrl;
}
