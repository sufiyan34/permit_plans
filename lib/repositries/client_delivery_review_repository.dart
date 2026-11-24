import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/models/client_delivery_review_model.dart';

class ClientDeliveryReviewException implements Exception {
  const ClientDeliveryReviewException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Read/review access for Client-owned project deliveries.
/// The SQL RPCs perform role and contract ownership checks server-side.
class ClientDeliveryReviewRepository {
  ClientDeliveryReviewRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String deliveryBucket = 'project-deliveries';
  String? get currentUserId => _client.auth.currentUser?.id;

  Stream<List<Map<String, dynamic>>> watchDeliveryChanges() {
    if (currentUserId == null) {
      throw const ClientDeliveryReviewException(
        'Your session has expired. Please sign in again.',
      );
    }
    // RLS limits the stream to deliveries on contracts involving this user.
    return _client.from('project_deliveries').stream(primaryKey: ['id']);
  }

  Future<List<ClientDeliveryReviewModel>> fetchReviews() async {
    _requireSession();
    try {
      final response = await _client.rpc(
        'get_my_client_delivery_reviews',
        params: {'p_limit': 100, 'p_offset': 0},
      );
      if (response is! List) {
        throw const ClientDeliveryReviewException(
          'The delivery review service returned an unexpected response.',
        );
      }
      return response
          .whereType<Map>()
          .map((row) => ClientDeliveryReviewModel.fromJson(
                Map<String, dynamic>.from(row),
              ))
          .toList(growable: false);
    } on ClientDeliveryReviewException {
      rethrow;
    } on PostgrestException catch (error) {
      throw ClientDeliveryReviewException(_friendlyMessage(error));
    } catch (_) {
      throw const ClientDeliveryReviewException(
        'Unable to load project deliveries. Please try again.',
      );
    }
  }

  Future<void> reviewDelivery({
    required String deliveryId,
    required String action,
    String? reviewNote,
  }) async {
    _requireSession();
    try {
      await _client.rpc(
        'review_project_delivery',
        params: {
          'p_delivery_id': deliveryId,
          'p_action': action,
          'p_review_note': reviewNote?.trim(),
        },
      );
    } on PostgrestException catch (error) {
      throw ClientDeliveryReviewException(_friendlyMessage(error));
    } catch (_) {
      throw const ClientDeliveryReviewException(
        'We could not save your review. Please try again.',
      );
    }
  }

  Future<String> createFileLink(String storagePath) async {
    _requireSession();
    try {
      return await _client.storage
          .from(deliveryBucket)
          .createSignedUrl(storagePath, 5 * 60);
    } on StorageException catch (error) {
      throw ClientDeliveryReviewException(
        'This delivery file could not be opened. ${error.message}',
      );
    } catch (_) {
      throw const ClientDeliveryReviewException(
        'Unable to create a secure download link. Please try again.',
      );
    }
  }

  void _requireSession() {
    if (currentUserId == null) {
      throw const ClientDeliveryReviewException(
        'Your session has expired. Please sign in again.',
      );
    }
  }

  String _friendlyMessage(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (error.code == '42883' ||
        message.contains('get_my_client_delivery_reviews') ||
        message.contains('review_project_delivery')) {
      return 'Client delivery review is not installed yet. Run migration 015 in Supabase SQL Editor.';
    }
    if (error.code == '42501' || error.code == '28000') {
      return 'Only the Client who owns this project can review its delivery.';
    }
    if (message.contains('already reviewed') ||
        message.contains('no longer awaiting')) {
      return 'This delivery has already been reviewed. Refresh to see its latest status.';
    }
    if (message.contains('revision note')) {
      return 'Please explain the changes you need before requesting a revision.';
    }
    return 'We could not complete this review. ${error.message}';
  }
}
