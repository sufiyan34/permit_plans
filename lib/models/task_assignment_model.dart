import 'package:file_picker/file_picker.dart';

import 'package:permit_plans/models/engineer_directory_model.dart';

/// Form data for sending a direct task invitation to one selected engineer.
/// The optional budget is an indication only; the engineer will submit the
/// actual quote after receiving the invitation.
class TaskAssignmentDraft {
  const TaskAssignmentDraft({
    required this.engineer,
    required this.title,
    required this.description,
    required this.category,
    required this.requiredSkills,
    required this.currency,
    required this.attachments,
    this.budgetMinMinor,
    this.budgetMaxMinor,
    this.deadlineAt,
  });

  final EngineerDirectoryProfile engineer;
  final String title;
  final String description;
  final String category;
  final List<String> requiredSkills;
  final String currency;
  final int? budgetMinMinor;
  final int? budgetMaxMinor;
  final DateTime? deadlineAt;
  final List<PlatformFile> attachments;
}

class TaskAssignmentResult {
  const TaskAssignmentResult({required this.taskId});

  final String taskId;
}
