import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/models/engineer_project_model.dart';
import 'package:permit_plans/models/engineer_revision_request_model.dart';
import 'package:permit_plans/models/project_delivery_model.dart';

class EngineerRevisionRequestsException implements Exception {
  const EngineerRevisionRequestsException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads Client revision feedback for projects owned by the signed-in Engineer.
/// It does not change delivery, contract, payment or payout state.
class EngineerRevisionRequestsRepository {
  EngineerRevisionRequestsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String deliveryBucket = 'project-deliveries';

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<EngineerRevisionRequestModel>> fetchRevisionRequests() async {
    _requireSession();
    try {
      final response = await _client.rpc(
        'get_my_engineer_projects',
        params: {'p_limit': 100, 'p_offset': 0},
      );
      if (response is! List) {
        throw const EngineerRevisionRequestsException(
          'The Engineer projects service returned an unexpected response.',
        );
      }

      final projects = response
          .whereType<Map>()
          .map((row) => EngineerProjectModel.fromJson(
                Map<String, dynamic>.from(row),
              ))
          .where((project) => project.contractStatus == 'revision_requested')
          .toList(growable: false);

      if (projects.isEmpty) return const [];

      final results = await Future.wait(
        projects.map((project) async {
          final history = await _fetchHistory(project.contractId);
          ProjectDeliveryModel? request;
          for (final delivery in history) {
            if (delivery.status == 'revision_requested') {
              request = delivery;
              break;
            }
          }
          if (request == null) return null;
          return EngineerRevisionRequestModel(
            project: project,
            requestedDelivery: request,
            history: history,
          );
        }),
      );

      final items = results.whereType<EngineerRevisionRequestModel>().toList();
      items.sort((a, b) {
        final aDate = a.requestedDelivery.reviewedAt ??
            a.requestedDelivery.createdAt;
        final bDate = b.requestedDelivery.reviewedAt ??
            b.requestedDelivery.createdAt;
        return bDate.compareTo(aDate);
      });
      return items;
    } on EngineerRevisionRequestsException {
      rethrow;
    } on PostgrestException catch (error) {
      throw EngineerRevisionRequestsException(_friendlyPostgrestMessage(error));
    } catch (error) {
      throw EngineerRevisionRequestsException(_friendlyMessage(error));
    }
  }

  Future<List<ProjectDeliveryModel>> _fetchHistory(String contractId) async {
    final response = await _client.rpc(
      'get_my_project_deliveries',
      params: {'p_contract_id': contractId},
    );
    if (response is! List) {
      throw const EngineerRevisionRequestsException(
        'A project delivery history returned an unexpected response.',
      );
    }
    return response
        .whereType<Map>()
        .map((row) => ProjectDeliveryModel.fromJson(
              Map<String, dynamic>.from(row),
            ))
        .toList(growable: false);
  }

  Stream<List<Map<String, dynamic>>> watchDeliveryChanges() {
    final userId = currentUserId;
    if (userId == null) return const Stream.empty();
    return _client
        .from('project_deliveries')
        .stream(primaryKey: ['id'])
        .eq('engineer_id', userId);
  }

  Future<String> createFileLink(String storagePath) async {
    _requireSession();
    try {
      return await _client.storage
          .from(deliveryBucket)
          .createSignedUrl(storagePath, 600);
    } on StorageException catch (error) {
      throw EngineerRevisionRequestsException(
        'The private delivery file could not be opened. ${error.message}',
      );
    } catch (_) {
      throw const EngineerRevisionRequestsException(
        'A secure file link could not be created. Please try again.',
      );
    }
  }

  void _requireSession() {
    if (currentUserId == null) {
      throw const EngineerRevisionRequestsException(
        'Your session has expired. Please sign in again.',
      );
    }
  }

  String _friendlyPostgrestMessage(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (error.code == '42883' ||
        message.contains('get_my_engineer_projects') ||
        message.contains('get_my_project_deliveries')) {
      return 'Revision history is not installed. Apply migrations 011 and 013 in the Supabase SQL Editor, then confirm migration 015 is applied for Realtime updates.';
    }
    if (error.code == '42501' || error.code == '28000') {
      return 'Only the assigned Engineer can view revision requests for their projects.';
    }
    return 'We could not load revision requests. ${error.message}';
  }

  String _friendlyMessage(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('project-deliveries')) {
      return 'The private delivery storage bucket is not ready. Check migration 013.';
    }
    return 'Something went wrong while loading revision requests. Please try again.';
  }
}
