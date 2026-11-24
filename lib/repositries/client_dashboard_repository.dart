import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/models/client_dashboard_model.dart';

class ClientDashboardRepositoryException implements Exception {
  const ClientDashboardRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads only profile data that already exists in migrations 001 and 002.
/// Tasks, proposals and payment totals are deliberately not queried until
/// their marketplace tables and RLS policies are implemented.
class ClientDashboardRepository {
  ClientDashboardRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<ClientDashboardProfile> fetchProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const ClientDashboardRepositoryException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      final profileRow = await _client
          .from('profiles')
          .select('full_name, email, country_name, avatar_url, profile_completed')
          .eq('id', user.id)
          .maybeSingle();

      if (profileRow == null) {
        throw const ClientDashboardRepositoryException(
          'Your profile could not be found. Please complete your profile setup.',
        );
      }

      final clientRow = await _client
          .from('client_profiles')
          .select('account_type, company_name')
          .eq('user_id', user.id)
          .maybeSingle();

      return ClientDashboardProfile.fromRows(
        profile: profileRow,
        clientProfile: clientRow,
        fallbackEmail: user.email ?? '',
      );
    } on ClientDashboardRepositoryException {
      rethrow;
    } on PostgrestException catch (error) {
      // Keep the detailed backend error in the debug console, but show a
      // safe and actionable message in the interface.
      // ignore: avoid_print
      print('[ClientDashboardRepository.fetchProfile] ${error.message}');
      throw const ClientDashboardRepositoryException(
        'We could not load your profile. Check your connection and try again.',
      );
    } catch (error) {
      // ignore: avoid_print
      print('[ClientDashboardRepository.fetchProfile] $error');
      throw const ClientDashboardRepositoryException(
        'Something went wrong while loading your workspace.',
      );
    }
  }
}
