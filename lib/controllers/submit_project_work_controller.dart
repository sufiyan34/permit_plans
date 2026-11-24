import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/models/engineer_project_model.dart';
import 'package:permit_plans/models/project_delivery_model.dart';
import 'package:permit_plans/repositries/project_delivery_repository.dart';

class PendingDeliveryFile {
  const PendingDeliveryFile({required this.file, required this.sizeBytes});

  final PlatformFile file;
  final int sizeBytes;

  String get formattedSize {
    if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (sizeBytes >= 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$sizeBytes B';
  }
}

class SubmitProjectWorkController extends GetxController {
  SubmitProjectWorkController({required ProjectDeliveryRepository repository})
      : _repository = repository;

  final ProjectDeliveryRepository _repository;

  final project = Rxn<EngineerProjectModel>();
  final deliveryHistory = <ProjectDeliveryModel>[].obs;
  final pendingFiles = <PendingDeliveryFile>[].obs;
  final isLoadingHistory = false.obs;
  final isPickingFile = false.obs;
  final isSubmitting = false.obs;
  final errorMessage = ''.obs;
  final formErrorMessage = ''.obs;
  final noteText = ''.obs;

  final TextEditingController noteController = TextEditingController();

  static const Set<String> supportedExtensions = {
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
    'png', 'jpg', 'jpeg', 'webp', 'zip', 'csv', 'txt', 'dwg', 'dxf',
  };

  EngineerProjectModel? get selectedProject => project.value;

  bool get canSubmit =>
      selectedProject != null &&
      _canSubmitStatus(selectedProject!.contractStatus) &&
      !isSubmitting.value &&
      noteText.value.trim().length >= 20 &&
      pendingFiles.length <= ProjectDeliveryRepository.maxFiles;

  String get submitButtonLabel {
    final status = selectedProject?.contractStatus;
    if (status == 'revision_requested') return 'Submit revised work';
    return 'Submit completed work';
  }

  bool _canSubmitStatus(String status) =>
      const {'funded', 'in_progress', 'revision_requested'}.contains(status);

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is EngineerProjectModel) {
      project.value = args;
      loadHistory();
    } else {
      errorMessage.value =
          'Project details were not provided. Open this screen from your Project Workspace.';
    }
  }

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }

  void updateNote(String value) {
    noteText.value = value;
    formErrorMessage.value = '';
  }

  Future<void> loadHistory() async {
    final current = selectedProject;
    if (current == null || isLoadingHistory.value) return;
    isLoadingHistory.value = true;
    errorMessage.value = '';
    try {
      final items = await _repository.fetchHistory(current.contractId);
      deliveryHistory.assignAll(items);
    } on ProjectDeliveryRepositoryException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value =
          'Previous delivery history could not be loaded. You can still prepare your submission.';
    } finally {
      isLoadingHistory.value = false;
    }
  }

  Future<void> pickFile() async {
    if (isPickingFile.value || isSubmitting.value) return;
    if (pendingFiles.length >= ProjectDeliveryRepository.maxFiles) {
      formErrorMessage.value = 'You can attach up to 20 files.';
      return;
    }

    isPickingFile.value = true;
    formErrorMessage.value = '';
    try {
      final file = await FilePicker.pickFile(type: FileType.any);
      if (file == null) return;

      final extension = _extensionOf(file.name);
      if (!supportedExtensions.contains(extension)) {
        formErrorMessage.value =
            'Unsupported file type. Use PDF, Office files, images, ZIP, CSV, TXT, DWG or DXF.';
        return;
      }

      final size = file.lengthSync() ?? await file.length();
      if (size == null || size < 1 ||
          size > ProjectDeliveryRepository.maxFileBytes) {
        formErrorMessage.value = 'Each file must be smaller than 25 MB.';
        return;
      }

      final duplicate = pendingFiles.any((item) =>
          item.file.name == file.name && item.sizeBytes == size);
      if (duplicate) {
        formErrorMessage.value = 'That file is already attached.';
        return;
      }

      pendingFiles.add(PendingDeliveryFile(file: file, sizeBytes: size));
    } catch (_) {
      formErrorMessage.value = 'Unable to select that file. Please try again.';
    } finally {
      isPickingFile.value = false;
    }
  }

  void removeFile(PendingDeliveryFile file) {
    pendingFiles.remove(file);
    formErrorMessage.value = '';
  }

  Future<bool> submit() async {
    final current = selectedProject;
    if (current == null) return false;
    if (!_canSubmitStatus(current.contractStatus)) {
      formErrorMessage.value = _lockedMessage(current.contractStatus);
      return false;
    }

    final message = noteText.value.trim();
    if (message.length < 20) {
      formErrorMessage.value =
          'Please add a delivery note with at least 20 characters.';
      return false;
    }
    if (pendingFiles.length > ProjectDeliveryRepository.maxFiles) {
      formErrorMessage.value = 'You can attach up to 20 files.';
      return false;
    }

    isSubmitting.value = true;
    formErrorMessage.value = '';
    errorMessage.value = '';
    final uploadedPaths = <String>[];

    try {
      final filePayload = <Map<String, dynamic>>[];
      for (final pending in pendingFiles) {
        final bytes = Uint8List.fromList(await pending.file.readAsBytes());
        final mimeType = _mimeTypeFor(pending.file.name);
        final path = await _repository.uploadFile(
          contractId: current.contractId,
          originalName: pending.file.name,
          mimeType: mimeType,
          bytes: bytes,
        );
        uploadedPaths.add(path);
        filePayload.add({
          'storage_path': path,
          'file_name': pending.file.name,
          'mime_type': mimeType,
          'size_bytes': pending.sizeBytes,
        });
      }

      await _repository.submitDelivery(
        contractId: current.contractId,
        message: message,
        files: filePayload,
      );

      pendingFiles.clear();
      noteController.clear();
      noteText.value = '';
      await loadHistory();
      Get.snackbar(
        'Work submitted',
        'Your delivery has been sent to the Client for review.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE4F1E9),
        colorText: const Color(0xFF28765A),
        margin: const EdgeInsets.all(14),
      );
      return true;
    } on ProjectDeliveryRepositoryException catch (error) {
      if (uploadedPaths.isNotEmpty) {
        await _repository.removeUploadedFiles(uploadedPaths);
      }
      formErrorMessage.value = error.message;
      return false;
    } catch (_) {
      if (uploadedPaths.isNotEmpty) {
        await _repository.removeUploadedFiles(uploadedPaths);
      }
      formErrorMessage.value =
          'Your work was not submitted. Check your connection and try again.';
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  String _lockedMessage(String status) {
    switch (status) {
      case 'awaiting_payment':
        return 'You can submit work after payment is confirmed and the project becomes active.';
      case 'submitted':
        return 'Your latest delivery is already with the Client for review.';
      case 'completed':
        return 'This project has already been completed.';
      case 'disputed':
        return 'Delivery is unavailable while this project is disputed.';
      case 'cancelled':
        return 'This project has been cancelled.';
      default:
        return 'This project is not ready for delivery yet.';
    }
  }

  static String _extensionOf(String fileName) {
    final index = fileName.lastIndexOf('.');
    if (index < 0 || index == fileName.length - 1) return '';
    return fileName.substring(index + 1).toLowerCase();
  }

  static String _mimeTypeFor(String fileName) {
    switch (_extensionOf(fileName)) {
      case 'pdf': return 'application/pdf';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls': return 'application/vnd.ms-excel';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt': return 'application/vnd.ms-powerpoint';
      case 'pptx': return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'png': return 'image/png';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'webp': return 'image/webp';
      case 'zip': return 'application/zip';
      case 'csv': return 'text/csv';
      case 'txt': return 'text/plain';
      case 'dwg': return 'application/acad';
      case 'dxf': return 'application/dxf';
      default: return 'application/octet-stream';
    }
  }
}
