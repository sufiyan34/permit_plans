import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/models/task_assignment_model.dart';

class TaskAssignmentException implements Exception {
  const TaskAssignmentException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Creates a task and its direct engineer invitation through one secure RPC.
/// Reference files are uploaded to a private bucket first; if the RPC fails,
/// this repository removes the uploaded objects to avoid orphaned files.
class TaskAssignmentRepository {
  TaskAssignmentRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _bucket = 'task-attachments';
  static const int maxFileBytes = 10 * 1024 * 1024;
  static const int maxFiles = 5;

  Future<TaskAssignmentResult> sendInvitation(
    TaskAssignmentDraft draft,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const TaskAssignmentException(
        'Your session has expired. Please sign in again.',
      );
    }

    if (!draft.engineer.canReceiveAssignment) {
      throw const TaskAssignmentException(
        'This engineer is not accepting new assignments right now.',
      );
    }

    if (draft.attachments.length > maxFiles) {
      throw const TaskAssignmentException('You can attach up to 5 files.');
    }

    final uploadedPaths = <String>[];
    final attachmentRows = <Map<String, dynamic>>[];

    try {
      for (var index = 0; index < draft.attachments.length; index++) {
        final file = draft.attachments[index];
        // file_picker v12+ reads bytes through readAsBytes(); the old
        // PlatformFile.bytes property is no longer part of the public API.
        final int? reportedLength = await file.length();
        if (reportedLength == null || reportedLength <= 0) {
          throw TaskAssignmentException(
            'Could not determine the size of ${file.name}. Please select that file again.',
          );
        }
        if (reportedLength > maxFileBytes) {
          throw TaskAssignmentException(
            '${file.name} is larger than the 10 MB limit.',
          );
        }

        final Uint8List bytes = await file.readAsBytes();
        if (bytes.isEmpty) {
          throw TaskAssignmentException(
            'Could not read ${file.name}. Please select that file again.',
          );
        }
        if (bytes.length > maxFileBytes) {
          throw TaskAssignmentException(
            '${file.name} is larger than the 10 MB limit.',
          );
        }

        final safeName = _safeFileName(file.name);
        final storagePath =
            '${user.id}/${DateTime.now().microsecondsSinceEpoch}_${index}_$safeName';
        final mimeType = _mimeType(file.extension);

        await _client.storage.from(_bucket).uploadBinary(
              storagePath,
              bytes,
              fileOptions: FileOptions(
                contentType: mimeType,
                cacheControl: '3600',
                upsert: false,
              ),
            );
        uploadedPaths.add(storagePath);
        attachmentRows.add({
          'storage_path': storagePath,
          'file_name': file.name,
          'mime_type': mimeType,
          'size_bytes': bytes.length,
        });
      }

      final response = await _client.rpc(
        'create_task_invitation',
        params: {
          'p_engineer_id': draft.engineer.userId,
          'p_title': draft.title.trim(),
          'p_description': draft.description.trim(),
          'p_category': draft.category,
          'p_required_skills': draft.requiredSkills,
          'p_currency': draft.currency,
          'p_budget_min_minor': draft.budgetMinMinor,
          'p_budget_max_minor': draft.budgetMaxMinor,
          'p_deadline_at': draft.deadlineAt?.toUtc().toIso8601String(),
          'p_attachments': attachmentRows,
        },
      );

      final taskId = response?.toString().trim() ?? '';
      if (taskId.isEmpty) {
        throw const TaskAssignmentException(
          'The task was submitted but the server did not return its reference. Check My Tasks before trying again.',
        );
      }

      return TaskAssignmentResult(taskId: taskId);
    } on TaskAssignmentException {
      await _removeUploadedFiles(uploadedPaths);
      rethrow;
    } on PostgrestException catch (error) {
      await _removeUploadedFiles(uploadedPaths);
      // ignore: avoid_print
      print('[TaskAssignmentRepository] ${error.code}: ${error.message}');
      throw TaskAssignmentException(_friendlyPostgresError(error));
    } on StorageException catch (error) {
      await _removeUploadedFiles(uploadedPaths);
      // ignore: avoid_print
      print('[TaskAssignmentRepository.storage] ${error.message}');
      throw TaskAssignmentException(_friendlyStorageError(error));
    } catch (error) {
      await _removeUploadedFiles(uploadedPaths);
      // ignore: avoid_print
      print('[TaskAssignmentRepository.sendInvitation] $error');
      throw const TaskAssignmentException(
        'We could not send the task invitation. Please try again.',
      );
    }
  }

  Future<void> _removeUploadedFiles(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _client.storage.from(_bucket).remove(paths);
    } catch (error) {
      // ignore: avoid_print
      print('[TaskAssignmentRepository.cleanup] $error');
    }
  }

  String _safeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return cleaned.isEmpty ? 'attachment' : cleaned.substring(0, cleaned.length > 90 ? 90 : cleaned.length);
  }

  String _mimeType(String? extension) {
    switch ((extension ?? '').toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'zip':
        return 'application/zip';
      case 'csv':
        return 'text/csv';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  String _friendlyPostgresError(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (error.code == '42883' || message.contains('function') && message.contains('does not exist')) {
      return 'Task assignment database setup is missing. Run migration 005 in Supabase SQL Editor.';
    }
    if (error.code == '42501' || message.contains('only clients')) {
      return 'Only Client accounts can assign tasks. Please sign in with your Client account.';
    }
    if (message.contains('not accepting') || message.contains('unavailable')) {
      return 'This engineer is no longer accepting assignments. Please choose another engineer.';
    }
    if (message.contains('deadline')) {
      return 'Choose a deadline in the future.';
    }
    if (message.contains('budget') || message.contains('currency')) {
      return 'Please check the budget and currency details.';
    }
    if (message.contains('storage') || message.contains('attachment')) {
      return 'The reference files could not be attached. Please try again.';
    }
    return 'We could not create the task invitation. Please check the form and try again.';
  }

  String _friendlyStorageError(StorageException error) {
    final message = error.message.toLowerCase();
    if (message.contains('bucket') && message.contains('not found')) {
      return 'Task file storage is not configured. Run migration 005 in Supabase.';
    }
    if (message.contains('row-level security') || message.contains('permission')) {
      return 'Supabase blocked the file upload. Check migration 005 and your Client account role.';
    }
    if (message.contains('size') || message.contains('limit')) {
      return 'One of the selected files exceeds the 10 MB limit.';
    }
    return 'A reference file could not be uploaded. Please try again.';
  }
}
