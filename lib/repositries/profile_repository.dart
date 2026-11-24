import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/models/client_profile_model.dart';
import 'package:permit_plans/models/engineer_profile_model.dart';

class ProfileRepositoryException implements Exception {
  const ProfileRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Persists role-specific onboarding data in Supabase.
///
/// The database migration owns authorization and profile-completion checks.
/// This repository never trusts a role supplied by the UI.
class ProfileRepository {
  ProfileRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const ProfileRepositoryException(
        'Your session has expired. Please sign in again.',
      );
    }
    return user.id;
  }

  Future<bool> isProfileComplete(String userId) async {
    try {
      final row = await _client
          .from('profiles')
          .select('profile_completed')
          .eq('id', userId)
          .maybeSingle();
      return row?['profile_completed'] == true;
    } catch (error) {
      throw ProfileRepositoryException(_friendlyError(error));
    }
  }

  /// Loads the signed-in client's editable profile fields.
  ///
  /// Reads the shared identity row and the role-specific client row separately
  /// so the query remains compatible with the existing migration schema.
  Future<ClientProfileModel> fetchClientProfile() async {
    final userId = _userId;
    try {
      final profileRow = await _client
          .from('profiles')
          .select('full_name, country_name, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      if (profileRow == null) {
        throw const ProfileRepositoryException(
          'Your profile could not be found. Please sign in again.',
        );
      }

      final clientRow = await _client
          .from('client_profiles')
          .select('account_type, phone_number, company_name, company_website, about')
          .eq('user_id', userId)
          .maybeSingle();

      if (clientRow == null) {
        throw const ProfileRepositoryException(
          'Your client profile details could not be found. Please contact support.',
        );
      }

      return ClientProfileModel(
        fullName: profileRow['full_name'] as String? ?? '',
        countryName: profileRow['country_name'] as String? ?? '',
        avatarUrl: profileRow['avatar_url'] as String?,
        accountType: clientRow['account_type'] as String? ?? 'individual',
        phoneNumber: clientRow['phone_number'] as String?,
        companyName: clientRow['company_name'] as String?,
        companyWebsite: clientRow['company_website'] as String?,
        about: clientRow['about'] as String?,
      );
    } catch (error) {
      if (error is ProfileRepositoryException) rethrow;
      throw ProfileRepositoryException(_friendlyError(error));
    }
  }

  /// Loads the signed-in engineer's editable shared and professional fields.
  Future<EngineerProfileModel> fetchEngineerProfile() async {
    final userId = _userId;
    try {
      final profileRow = await _client
          .from('profiles')
          .select('full_name, country_name, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      if (profileRow == null) {
        throw const ProfileRepositoryException(
          'Your profile could not be found. Please sign in again.',
        );
      }

      final engineerRow = await _client
          .from('engineer_profiles')
          .select(
            'headline, bio, experience_level, years_experience, availability, skills, languages, portfolio_links',
          )
          .eq('user_id', userId)
          .maybeSingle();

      if (engineerRow == null) {
        throw const ProfileRepositoryException(
          'Your professional profile could not be found. Please contact support.',
        );
      }

      List<String> stringList(Object? value) => value is List
          ? value.whereType<String>().toList(growable: false)
          : const <String>[];

      return EngineerProfileModel(
        fullName: profileRow['full_name'] as String? ?? '',
        countryName: profileRow['country_name'] as String? ?? '',
        avatarUrl: profileRow['avatar_url'] as String?,
        headline: engineerRow['headline'] as String? ?? '',
        bio: engineerRow['bio'] as String? ?? '',
        experienceLevel:
            engineerRow['experience_level'] as String? ?? 'intermediate',
        yearsExperience:
            (engineerRow['years_experience'] as num?)?.toInt() ?? 0,
        availability: engineerRow['availability'] as String? ?? 'available',
        skills: stringList(engineerRow['skills']),
        languages: stringList(engineerRow['languages']),
        portfolioLinks: stringList(engineerRow['portfolio_links']),
      );
    } catch (error) {
      if (error is ProfileRepositoryException) rethrow;
      throw ProfileRepositoryException(_friendlyError(error));
    }
  }

  Future<void> saveClientProfile(
    ClientProfileModel profile, {
    XFile? avatar,
  }) async {
    final userId = _userId;
    try {
      final avatarUrl = avatar == null ? profile.avatarUrl : await _uploadAvatar(avatar);

      await _client.from('profiles').update({
        'full_name': profile.fullName.trim(),
        'country_name': profile.countryName.trim(),
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      }).eq('id', userId);

      await _client.from('client_profiles').upsert(
        {
          'user_id': userId,
          'account_type': profile.accountType,
          'phone_number': _nullable(profile.phoneNumber),
          'company_name': _nullable(profile.companyName),
          'company_website': _nullable(profile.companyWebsite),
          'about': _nullable(profile.about),
        },
        onConflict: 'user_id',
      );

      await _client.rpc('mark_marketplace_profile_complete');
    } catch (error) {
      if (error is ProfileRepositoryException) rethrow;
      throw ProfileRepositoryException(_friendlyError(error));
    }
  }

  Future<void> saveEngineerProfile(
    EngineerProfileModel profile, {
    XFile? avatar,
  }) async {
    final userId = _userId;
    try {
      final avatarUrl = avatar == null ? profile.avatarUrl : await _uploadAvatar(avatar);

      await _client.from('profiles').update({
        'full_name': profile.fullName.trim(),
        'country_name': profile.countryName.trim(),
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      }).eq('id', userId);

      await _client.from('engineer_profiles').upsert(
        {
          'user_id': userId,
          'headline': profile.headline.trim(),
          'bio': profile.bio.trim(),
          'experience_level': profile.experienceLevel,
          'years_experience': profile.yearsExperience,
          'availability': profile.availability,
          'skills': profile.skills.map((value) => value.trim()).where((value) => value.isNotEmpty).toList(),
          'languages': profile.languages.map((value) => value.trim()).where((value) => value.isNotEmpty).toList(),
          'portfolio_links': profile.portfolioLinks.map((value) => value.trim()).where((value) => value.isNotEmpty).toList(),
        },
        onConflict: 'user_id',
      );

      await _client.rpc('mark_marketplace_profile_complete');
    } catch (error) {
      if (error is ProfileRepositoryException) rethrow;
      throw ProfileRepositoryException(_friendlyError(error));
    }
  }

  Future<String> _uploadAvatar(XFile file) async {
    final userId = _userId;
    final rawExtension = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : 'jpg';
    const allowed = {'jpg', 'jpeg', 'png', 'webp'};
    if (!allowed.contains(rawExtension)) {
      throw const ProfileRepositoryException(
        'Choose a JPG, PNG or WebP profile image.',
      );
    }

    final bytes = await file.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      throw const ProfileRepositoryException(
        'Profile images must be 5 MB or smaller.',
      );
    }

    final path = '$userId/avatar.$rawExtension';
    final contentType = switch (rawExtension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    await _client.storage.from('profile-avatars').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: contentType,
        cacheControl: '3600',
        upsert: true,
      ),
    );
    return _client.storage.from('profile-avatars').getPublicUrl(path);
  }

  String? _nullable(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String _friendlyError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('bucket') && message.contains('not found')) {
      return 'Profile image storage is not configured. Run migration 002 and try again.';
    }
    if (message.contains('permission denied') || message.contains('row-level security')) {
      return 'Supabase denied this profile update. Check that migration 002 has been applied and your account role is correct.';
    }
    if (message.contains('column') && message.contains('does not exist')) {
      return 'The profile database migration is missing. Run migration 002 in Supabase SQL Editor.';
    }
    if (message.contains('socketexception') || message.contains('failed host lookup')) {
      return 'A network error occurred. Check your internet connection.';
    }
    return 'We could not save your profile. Please check your connection and try again.';
  }
}
