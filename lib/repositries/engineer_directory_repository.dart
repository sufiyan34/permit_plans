import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/models/engineer_directory_model.dart';

class EngineerDirectoryRepositoryException implements Exception {
  const EngineerDirectoryRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads public-safe engineer directory data through the browse_engineers RPC.
/// It deliberately does not query profiles/engineer_profiles directly because
/// those tables remain private under the existing RLS policies.
class EngineerDirectoryRepository {
  EngineerDirectoryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<EngineerDirectoryPage> browse({
    String? search,
    String? countryName,
    String? skill,
    String? experienceLevel,
    String? availability,
    String sortBy = 'recent',
    int limit = 20,
    int offset = 0,
  }) async {
    if (_client.auth.currentUser == null) {
      throw const EngineerDirectoryRepositoryException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      final response = await _client.rpc(
        'browse_engineers',
        params: {
          'p_search': _clean(search),
          'p_country_name': _clean(countryName),
          'p_skill': _clean(skill),
          'p_experience_level': _clean(experienceLevel),
          'p_availability': _clean(availability),
          'p_sort': sortBy,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (response is! List) {
        throw const EngineerDirectoryRepositoryException(
          'The engineer directory returned an unexpected response.',
        );
      }

      final engineers = response
          .whereType<Map>()
          .map((row) => EngineerDirectoryProfile.fromMap(
                Map<String, dynamic>.from(row),
              ))
          .toList(growable: false);

      final totalCount = engineers.isEmpty ? 0 : engineers.first.totalCount;
      return EngineerDirectoryPage(
        engineers: engineers,
        totalCount: totalCount,
      );
    } on EngineerDirectoryRepositoryException {
      rethrow;
    } on PostgrestException catch (error) {
      // ignore: avoid_print
      print('[EngineerDirectoryRepository.browse] ${error.code}: ${error.message}');

      if (error.code == '42883' ||
          error.message.toLowerCase().contains('function') &&
              error.message.toLowerCase().contains('does not exist')) {
        throw const EngineerDirectoryRepositoryException(
          'The engineer directory database function is missing. Run migration 004 in Supabase.',
        );
      }
      if (error.code == '42501' ||
          error.message.toLowerCase().contains('permission')) {
        throw const EngineerDirectoryRepositoryException(
          'Your account is not allowed to browse the engineer directory. Please sign in with a Client account.',
        );
      }
      throw const EngineerDirectoryRepositoryException(
        'We could not load engineers. Please check your connection and try again.',
      );
    } catch (error) {
      // ignore: avoid_print
      print('[EngineerDirectoryRepository.browse] $error');
      throw const EngineerDirectoryRepositoryException(
        'Something went wrong while loading engineers.',
      );
    }
  }

  String? _clean(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty || normalized == 'all'
        ? null
        : normalized;
  }
}
