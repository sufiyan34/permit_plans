import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/models/engineer_dashboard_model.dart';

class EngineerDashboardRepositoryException implements Exception {
  const EngineerDashboardRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Loads only profile data that exists in migrations 001 and 002.
/// Marketplace activity and earnings are not queried until their tables exist.
class EngineerDashboardRepository {
  EngineerDashboardRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<EngineerDashboardProfile> fetchProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const EngineerDashboardRepositoryException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      final profileRow = await _client
          .from('profiles')
          .select(
            'full_name, email, country_name, avatar_url, profile_completed',
          )
          .eq('id', user.id)
          .maybeSingle();

      if (profileRow == null) {
        throw const EngineerDashboardRepositoryException(
          'Your account profile was not found. Please sign in again.',
        );
      }

      final engineerRow = await _client
          .from('engineer_profiles')
          .select(
            'headline, bio, experience_level, years_experience, '
            'availability, skills, languages, portfolio_links',
          )
          .eq('user_id', user.id)
          .maybeSingle();

      if (engineerRow == null) {
        throw const EngineerDashboardRepositoryException(
          'Your engineer profile is incomplete. Please complete your profile setup.',
        );
      }

      return EngineerDashboardProfile.fromRows(
        profile: profileRow,
        engineerProfile: engineerRow,
        fallbackEmail: user.email ?? '',
      );
    } on EngineerDashboardRepositoryException {
      rethrow;
    } on PostgrestException catch (error) {
      // ignore: avoid_print
      print('[EngineerDashboardRepository.fetchProfile] ${error.message}');
      if (error.code == '42P01' || error.message.contains('does not exist')) {
        throw const EngineerDashboardRepositoryException(
          'The engineer profile database is not ready. Please apply migration 002.',
        );
      }
      if (error.code == '42501' ||
          error.message.toLowerCase().contains('row-level security')) {
        throw const EngineerDashboardRepositoryException(
          'Supabase blocked access to your engineer profile. Please check the profile RLS policies.',
        );
      }
      throw const EngineerDashboardRepositoryException(
        'We could not load your engineer profile. Check your connection and try again.',
      );
    } catch (error) {
      // ignore: avoid_print
      print('[EngineerDashboardRepository.fetchProfile] $error');
      throw const EngineerDashboardRepositoryException(
        'Something went wrong while loading your engineer workspace.',
      );
    }
  }
}
