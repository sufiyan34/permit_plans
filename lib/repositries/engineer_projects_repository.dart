import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/models/engineer_project_model.dart';

class EngineerProjectsRepositoryException implements Exception {
  const EngineerProjectsRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Read-only access to contracts belonging to the signed-in Engineer.
class EngineerProjectsRepository {
  EngineerProjectsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<EngineerProjectModel>> fetchProjects({
    int limit = 50,
    int offset = 0,
  }) async {
    if (_client.auth.currentUser == null) {
      throw const EngineerProjectsRepositoryException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      final response = await _client.rpc(
        'get_my_engineer_projects',
        params: {'p_limit': limit, 'p_offset': offset},
      );

      if (response is! List) {
        throw const EngineerProjectsRepositoryException(
          'The projects service returned an unexpected response.',
        );
      }

      return response
          .whereType<Map>()
          .map(
            (row) => EngineerProjectModel.fromJson(
              Map<String, dynamic>.from(row),
            ),
          )
          .toList(growable: false);
    } on EngineerProjectsRepositoryException {
      rethrow;
    } on PostgrestException catch (error) {
      // ignore: avoid_print
      print(
        '[EngineerProjectsRepository.fetchProjects] '
        '${error.code}: ${error.message}',
      );
      if (error.code == '42883' ||
          error.message.toLowerCase().contains('get_my_engineer_projects')) {
        throw const EngineerProjectsRepositoryException(
          'The Engineer projects service is not installed. Apply migration 011 in the Supabase SQL Editor.',
        );
      }
      if (error.code == '42501' || error.code == '28000') {
        throw const EngineerProjectsRepositoryException(
          'Only a signed-in Engineer can view this project workspace.',
        );
      }
      throw const EngineerProjectsRepositoryException(
        'We could not load your projects. Check your connection and try again.',
      );
    } catch (error) {
      // ignore: avoid_print
      print('[EngineerProjectsRepository.fetchProjects] $error');
      throw const EngineerProjectsRepositoryException(
        'Something went wrong while loading your projects.',
      );
    }
  }
}
