import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/models/project_chat_conversation_model.dart';

import 'dart:typed_data';

class ProjectChatRepositoryException implements Exception {
  const ProjectChatRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Supabase data access for conversations, messages and private attachments.
class ProjectChatRepository {
  ProjectChatRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String attachmentBucket = 'project-chat-attachments';
  static const int maxAttachmentBytes = 10 * 1024 * 1024;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<ProjectChatConversation>> fetchConversations({
    int limit = 100,
    int offset = 0,
  }) async {
    _requireSession();
    try {
      final response = await _client.rpc(
        'get_my_project_chats',
        params: {'p_limit': limit, 'p_offset': offset},
      );
      final rows = response as List<dynamic>? ?? const <dynamic>[];
      return rows
          .whereType<Map>()
          .map(
            (row) => ProjectChatConversation.fromJson(
              Map<String, dynamic>.from(row),
            ),
          )
          .toList(growable: false);
    } catch (error) {
      throw ProjectChatRepositoryException(_friendlyMessage(error));
    }
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String contractId) {
    _requireSession();
    return _client
        .from('project_messages')
        .stream(primaryKey: ['id'])
        .eq('contract_id', contractId)
        .order('created_at', ascending: false)
        .limit(200);
  }

  Future<void> markMessagesRead(String contractId) async {
    _requireSession();
    try {
      await _client.rpc(
        'mark_project_messages_read',
        params: {'p_contract_id': contractId},
      );
    } catch (error) {
      throw ProjectChatRepositoryException(_friendlyMessage(error));
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    required String contractId,
    required String body,
    String? attachmentPath,
    String? attachmentName,
    String? attachmentMimeType,
    int? attachmentSizeBytes,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const ProjectChatRepositoryException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      final row = await _client
          .from('project_messages')
          .insert({
            'contract_id': contractId,
            'sender_id': userId,
            'body': body.trim(),
            'attachment_path': attachmentPath,
            'attachment_name': attachmentName,
            'attachment_mime_type': attachmentMimeType,
            'attachment_size_bytes': attachmentSizeBytes,
          })
          .select()
          .single();
      return Map<String, dynamic>.from(row);
    } catch (error) {
      throw ProjectChatRepositoryException(_friendlyMessage(error));
    }
  }

  Future<String> uploadAttachment({
    required String contractId,
    required String originalName,
    required String mimeType,
    required List<int> bytes,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const ProjectChatRepositoryException(
        'Your session has expired. Please sign in again.',
      );
    }
    if (bytes.isEmpty || bytes.length > maxAttachmentBytes) {
      throw const ProjectChatRepositoryException(
        'Attachments must be between 1 byte and 10 MB.',
      );
    }

    final safeName = originalName.trim().replaceAll(
      RegExp(r'[^A-Za-z0-9._-]+'),
      '_',
    );
    final random = math.Random.secure();
    final token = List<int>.generate(
      8,
      (_) => random.nextInt(256),
    ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    final path = '$contractId/$userId/${token}_$safeName';

    try {
      await _client.storage
          .from(attachmentBucket)
          .uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(contentType: mimeType, upsert: false),
          );

      return path;
    } catch (error) {
      throw ProjectChatRepositoryException(_friendlyMessage(error));
    }
  }

  Future<void> removeAttachment(String path) async {
    try {
      await _client.storage.from(attachmentBucket).remove([path]);
    } catch (_) {
      // A failed message insert should not hide the original send error.
      // The object can be cleaned up later by an admin retention task.
    }
  }

  Future<String> createAttachmentUrl(String path) async {
    try {
      return await _client.storage
          .from(attachmentBucket)
          .createSignedUrl(path, 5 * 60);
    } catch (error) {
      throw ProjectChatRepositoryException(_friendlyMessage(error));
    }
  }

  void _requireSession() {
    if (currentUserId == null) {
      throw const ProjectChatRepositoryException(
        'Your session has expired. Please sign in again.',
      );
    }
  }

  String _friendlyMessage(Object error) {
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      if (error.code == '42883' ||
          message.contains('get_my_project_chats') ||
          message.contains('mark_project_messages_read')) {
        return 'Project Chat is not installed yet. Run migration 012 in Supabase SQL Editor.';
      }
      if (error.code == '42501' || error.code == '28000') {
        return 'Only the Client and Engineer on this contract can access its chat.';
      }
      return 'Supabase could not complete this chat action. ${error.message}';
    }
    if (error is StorageException) {
      return 'The private attachment could not be accessed. ${error.message}';
    }
    final text = error.toString();
    if (text.toLowerCase().contains('project_messages')) {
      return 'Project Chat is not installed yet. Run migration 012 in Supabase SQL Editor.';
    }
    return 'Something went wrong with Project Chat. Please try again.';
  }
}
