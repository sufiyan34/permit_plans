import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/models/engineer_directory_model.dart';
import 'package:permit_plans/models/task_assignment_model.dart';
import 'package:permit_plans/repositries/task_assignment_repository.dart';

class AssignTaskController extends GetxController {
  AssignTaskController({
    required this.repository,
    required this.engineer,
  });

  final TaskAssignmentRepository repository;
  final EngineerDirectoryProfile? engineer;

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final budgetMinController = TextEditingController();
  final budgetMaxController = TextEditingController();
  final skillController = TextEditingController();

  final selectedCategory = ''.obs;
  final selectedCurrency = 'USD'.obs;
  final deadlineAt = Rxn<DateTime>();
  final requiredSkills = <String>[].obs;
  final attachments = <PlatformFile>[].obs;
  // file_picker v12+ exposes file length asynchronously instead of `size`.
  // Cache validated lengths for synchronous display in attachment rows.
  final Map<String, int> _attachmentSizes = <String, int>{};
  final isSubmitting = false.obs;
  final errorMessage = ''.obs;

  static const categories = <String>[
    'Web Development',
    'Mobile App Development',
    'UI/UX Design',
    'Graphic Design',
    'Software & Automation',
    'Data & AI',
    'DevOps & Cloud',
    'Writing & Documentation',
    'Other',
  ];

  static const currencies = <String>[
    'USD', 'EUR', 'GBP', 'PKR', 'AED', 'CAD', 'AUD', 'SAR', 'INR', 'JPY',
  ];

  static const allowedExtensions = <String>[
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
    'png', 'jpg', 'jpeg', 'webp', 'zip', 'csv', 'txt',
  ];

  bool get canSubmit => engineer?.canReceiveAssignment ?? false;

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    budgetMinController.dispose();
    budgetMaxController.dispose();
    skillController.dispose();
    super.onClose();
  }

  void addSkill() {
    final value = skillController.text.trim();
    if (value.isEmpty) return;
    if (requiredSkills.length >= 12) {
      _showMessage('Skill limit reached', 'You can add up to 12 required skills.');
      return;
    }
    if (requiredSkills.any((skill) => skill.toLowerCase() == value.toLowerCase())) {
      skillController.clear();
      return;
    }
    requiredSkills.add(value);
    skillController.clear();
  }

  void removeSkill(String skill) => requiredSkills.remove(skill);

  Future<void> pickAttachments() async {
    if (attachments.length >= TaskAssignmentRepository.maxFiles) {
      _showMessage('Attachment limit', 'You can attach up to 5 files.');
      return;
    }

    try {
      // file_picker v12+ uses static FilePicker.pickFiles() and returns
      // List<PlatformFile> directly. Multiple selection is the default.
      // `allowMultiple`, `withData`, and `FilePicker.platform` were removed.
      final selectedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );
      if (selectedFiles.isEmpty) return;

      final remaining = TaskAssignmentRepository.maxFiles - attachments.length;
      final candidates = selectedFiles.take(remaining).toList(growable: false);
      final valid = <PlatformFile>[];
      final invalidNames = <String>[];

      for (final file in candidates) {
        final int? size = await file.length();
        if (size == null || size <= 0 || size > TaskAssignmentRepository.maxFileBytes) {
          invalidNames.add(file.name);
          continue;
        }

        final alreadyAdded = attachments.any((existing) {
          final existingSize = _attachmentSizes[_attachmentKey(existing)];
          return existing.name == file.name && existingSize == size;
        });
        if (!alreadyAdded) {
          valid.add(file);
          _attachmentSizes[_attachmentKey(file)] = size;
        }
      }

      attachments.addAll(valid);
      if (selectedFiles.length > remaining) {
        _showMessage('Attachment limit', 'Only the first $remaining selected file(s) were considered.');
      }
      if (invalidNames.isNotEmpty) {
        _showMessage(
          'Some files were skipped',
          '${invalidNames.join(', ')} — files must be readable, non-empty and no larger than 10 MB each.',
        );
      }
    } catch (error) {
      // ignore: avoid_print
      print('[AssignTaskController.pickAttachments] $error');
      _showMessage('File selection failed', 'Please try selecting the files again.');
    }
  }

  String _attachmentKey(PlatformFile file) => '${file.name}|${file.uri}';

  int attachmentSize(PlatformFile file) =>
      _attachmentSizes[_attachmentKey(file)] ?? 0;

  void removeAttachment(PlatformFile file) {
    _attachmentSizes.remove(_attachmentKey(file));
    attachments.remove(file);
  }

  Future<void> selectDeadline(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final initial = deadlineAt.value ?? today.add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
      helpText: 'Select expected delivery date',
      builder: (context, child) => Theme(
        data: Theme.of(context),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null) deadlineAt.value = picked;
  }

  void clearDeadline() => deadlineAt.value = null;

  String? validateTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter a task title.';
    if (text.length < 8) return 'Use at least 8 characters.';
    if (text.length > 120) return 'Keep the title under 120 characters.';
    return null;
  }

  String? validateDescription(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Describe the work you need.';
    if (text.length < 30) return 'Please add at least 30 characters of detail.';
    if (text.length > 10000) return 'Description is too long.';
    return null;
  }

  String? validateBudgetMin(String? value) => _validateBudget(value, 'Minimum budget');
  String? validateBudgetMax(String? value) => _validateBudget(value, 'Maximum budget');

  String? _validateBudget(String? value, String label) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    try {
      _parseMinorUnits(text, selectedCurrency.value);
      return null;
    } on FormatException catch (error) {
      return error.message;
    }
  }

  int? _parseMinorUnits(String raw, String currency) {
    final normalized = raw.replaceAll(',', '').trim();
    if (normalized.isEmpty) return null;
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(normalized)) {
      throw const FormatException('Enter a valid positive amount.');
    }

    final fractionDigits = _currencyFractionDigits(currency);
    final parts = normalized.split('.');
    final fraction = parts.length == 1 ? '' : parts[1];
    if (fraction.length > fractionDigits) {
      throw FormatException('Use no more than $fractionDigits decimal places for $currency.');
    }

    final multiplier = BigInt.from(10).pow(fractionDigits);
    final major = BigInt.tryParse(parts[0]);
    if (major == null) throw const FormatException('Enter a valid amount.');
    final fractionValue = fraction.isEmpty
        ? BigInt.zero
        : BigInt.parse(fraction.padRight(fractionDigits, '0'));
    final total = major * multiplier + fractionValue;
    if (total <= BigInt.zero || total > BigInt.from(9007199254740991)) {
      throw const FormatException('Enter an amount greater than zero within the supported limit.');
    }
    return total.toInt();
  }

  int _currencyFractionDigits(String currency) {
    if (const {'JPY', 'KRW'}.contains(currency)) return 0;
    if (const {'BHD', 'KWD', 'OMR', 'JOD'}.contains(currency)) return 3;
    return 2;
  }

  Future<void> submit() async {
    errorMessage.value = '';
    if (engineer == null) {
      errorMessage.value = 'No engineer was selected. Return to the directory and choose an engineer.';
      return;
    }
    if (!canSubmit) {
      errorMessage.value = 'This engineer is not currently accepting assignments.';
      return;
    }
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (selectedCategory.value.isEmpty) {
      errorMessage.value = 'Please select a project category.';
      _showMessage('Category required', errorMessage.value);
      return;
    }

    int? minMinor;
    int? maxMinor;
    try {
      minMinor = _parseMinorUnits(budgetMinController.text, selectedCurrency.value);
      maxMinor = _parseMinorUnits(budgetMaxController.text, selectedCurrency.value);
    } on FormatException catch (error) {
      errorMessage.value = error.message;
      _showMessage('Check your budget', error.message);
      return;
    }

    if (minMinor != null && maxMinor != null && minMinor > maxMinor) {
      errorMessage.value = 'Minimum budget cannot be greater than maximum budget.';
      _showMessage('Check your budget range', errorMessage.value);
      return;
    }

    isSubmitting.value = true;
    try {
      final result = await repository.sendInvitation(
        TaskAssignmentDraft(
          engineer: engineer!,
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          category: selectedCategory.value,
          requiredSkills: requiredSkills.toList(growable: false),
          currency: selectedCurrency.value,
          budgetMinMinor: minMinor,
          budgetMaxMinor: maxMinor,
          deadlineAt: deadlineAt.value,
          attachments: attachments.toList(growable: false),
        ),
      );

      isSubmitting.value = false;
      Get.back<void>();
      Get.snackbar(
        'Invitation sent',
        'Your task was sent to ${engineer!.fullName}. No payment has been taken yet.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.successSoft,
        colorText: AppColors.success,
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 4),
      );
      // Keep the task reference available in the debug log for support.
      // ignore: avoid_print
      print('[AssignTaskController] Created task invitation ${result.taskId}');
    } on TaskAssignmentException catch (error) {
      errorMessage.value = error.message;
      _showMessage('Could not send invitation', error.message);
    } catch (error) {
      // ignore: avoid_print
      print('[AssignTaskController.submit] $error');
      errorMessage.value = 'Something went wrong. Please try again.';
      _showMessage('Could not send invitation', errorMessage.value);
    } finally {
      isSubmitting.value = false;
    }
  }

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surfaceAlt,
      colorText: AppColors.textPrimary,
      margin: const EdgeInsets.all(14),
      duration: const Duration(seconds: 3),
    );
  }
}
