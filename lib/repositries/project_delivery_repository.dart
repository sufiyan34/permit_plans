import 'dart:math' as math;
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/models/project_delivery_model.dart';

class ProjectDeliveryRepositoryException implements Exception {
  const ProjectDeliveryRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProjectDeliveryRepository {
  ProjectDeliveryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String deliveryBucket = 'project-deliveries';
  static const int maxFileBytes = 25 * 1024 * 1024;
  static const int maxFiles = 20;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<ProjectDeliveryModel>> fetchHistory(String contractId) async {
    _requireSession();
    try {
      final response = await _client.rpc(
        'get_my_project_deliveries',
        params: {'p_contract_id': contractId},
      );
      if (response is! List) {
        throw const ProjectDeliveryRepositoryException(
          'The delivery history service returned an unexpected response.',
        );
      }
      return response
          .whereType<Map>()
          .map((row) => ProjectDeliveryModel.fromJson(
                Map<String, dynamic>.from(row),
              ))
          .toList(growable: false);
    } catch (error) {
      throw ProjectDeliveryRepositoryException(_friendlyMessage(error));
    }
  }

  Future<String> uploadFile({
    required String contractId,
    required String originalName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const ProjectDeliveryRepositoryException(
        'Your session has expired. Please sign in again.',
      );
    }
    if (bytes.isEmpty || bytes.length > maxFileBytes) {
      throw const ProjectDeliveryRepositoryException(
        'Each delivery file must be between 1 byte and 25 MB.',
      );
    }

    final safeName = originalName
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    final random = math.Random.secure();
    final token = List<int>.generate(8, (_) => random.nextInt(256))
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    final path = '$contractId/$userId/${token}_$safeName';

    try {
      await _client.storage.from(deliveryBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: false),
          );
      return path;
    } catch (error) {
      throw ProjectDeliveryRepositoryException(_friendlyMessage(error));
    }
  }

  Future<String> submitDelivery({
    required String contractId,
    required String message,
    required List<Map<String, dynamic>> files,
  }) async {
    _requireSession();
    try {
      final response = await _client.rpc(
        'submit_project_delivery',
        params: {
          'p_contract_id': contractId,
          'p_message': message.trim(),
          'p_files': files,
        },
      );
      final id = response?.toString().trim() ?? '';
      if (id.isEmpty) {
        throw const ProjectDeliveryRepositoryException(
          'The delivery was submitted without a confirmation reference.',
        );
      }
      return id;
    } catch (error) {
      throw ProjectDeliveryRepositoryException(_friendlyMessage(error));
    }
  }

  Future<void> removeUploadedFiles(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _client.storage.from(deliveryBucket).remove(paths);
    } catch (_) {
      // Preserve the original submission error; orphan cleanup can be retried.
    }
  }

  void _requireSession() {
    if (currentUserId == null) {
      throw const ProjectDeliveryRepositoryException(
        'Your session has expired. Please sign in again.',
      );
    }
  }

  String _friendlyMessage(Object error) {
    if (error is PostgrestException) {
      final lower = error.message.toLowerCase();
      if (error.code == '42883' ||
          lower.contains('get_my_project_deliveries') ||
          lower.contains('submit_project_delivery')) {
        return 'Project delivery is not installed yet. Run migration 013 in the Supabase SQL Editor.';
      }
      if (error.code == '42501' || error.code == '28000') {
        return 'Only the assigned Engineer can submit work for this project.';
      }
      if (lower.contains('payment is confirmed') ||
          lower.contains('funded') ||
          lower.contains('revision')) {
        return 'This project is not ready for delivery yet. Payment must be confirmed and the project must be active.';
      }
      return 'Supabase could not save this delivery. ${error.message}';
    }
    if (error is StorageException) {
      return 'A delivery file could not be uploaded. ${error.message}';
    }
    final text = error.toString();
    if (text.toLowerCase().contains('project-deliveries')) {
      return 'The private delivery storage bucket is not ready. Run migration 013 in Supabase.';
    }
    return 'Something went wrong while submitting your work. Please try again.';
  }
}
