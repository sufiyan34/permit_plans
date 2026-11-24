class ClientProfileModel {
  const ClientProfileModel({
    required this.fullName,
    required this.countryName,
    required this.accountType,
    this.phoneNumber,
    this.companyName,
    this.companyWebsite,
    this.about,
    this.avatarUrl,
  });

  final String fullName;
  final String countryName;
  final String accountType;
  final String? phoneNumber;
  final String? companyName;
  final String? companyWebsite;
  final String? about;
  final String? avatarUrl;
}
