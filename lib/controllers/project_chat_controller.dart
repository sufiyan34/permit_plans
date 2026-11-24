import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:permit_plans/controllers/auth_controller.dart';
import 'package:permit_plans/models/project_chat_conversation_model.dart';
import 'package:permit_plans/models/project_chat_message_model.dart';
import 'package:permit_plans/repositries/project_chat_repository.dart';

class ProjectChatController extends GetxController {
  ProjectChatController({required ProjectChatRepository repository})
      : _repository = repository;

  final ProjectChatRepository _repository;

  final conversations = <ProjectChatConversation>[].obs;
  final messages = <ProjectChatMessage>[].obs;
  final selectedConversation = Rxn<ProjectChatConversation>();
  final pendingAttachment = Rxn<PlatformFile>();
  final pendingAttachmentBytes = Rxn<int>();

  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final isThreadLoading = false.obs;
  final isSending = false.obs;
  final errorMessage = ''.obs;
  final threadErrorMessage = ''.obs;
  final sendErrorMessage = ''.obs;
  final searchQuery = ''.obs;
  final composerText = ''.obs;

  final TextEditingController composerController = TextEditingController();
  final ScrollController messageScrollController = ScrollController();

  StreamSubscription<List<Map<String, dynamic>>>? _messageSubscription;
  String? _initialContractId;
  String? _activeContractId;
  bool _markingRead = false;

  String? get currentUserId => _repository.currentUserId;

  String get currentRole {
    try {
      return Get.find<AuthController>().currentRole.value ?? '';
    } catch (_) {
      return '';
    }
  }

  List<ProjectChatConversation> get filteredConversations {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return conversations.toList(growable: false);
    return conversations.where((item) {
      return item.taskTitle.toLowerCase().contains(query) ||
          item.partnerName.toLowerCase().contains(query) ||
          item.previewLabel.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  bool get canSend =>
      !isSending.value &&
      (composerText.value.trim().isNotEmpty || pendingAttachment.value != null) &&
      selectedConversation.value != null;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is String) {
      _initialContractId = args;
    } else if (args is Map) {
      _initialContractId = args['contractId']?.toString();
    }
    unawaited(loadConversations());
  }

  @override
  void onClose() {
    unawaited(_messageSubscription?.cancel());
    composerController.dispose();
    messageScrollController.dispose();
    super.onClose();
  }

  Future<void> loadConversations({bool refresh = false}) async {
    if (isLoading.value || isRefreshing.value) return;
    if (refresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
      final result = await _repository.fetchConversations();
      conversations.assignAll(result);

      final activeId = selectedConversation.value?.contractId;
      if (activeId != null) {
        final updated = _findConversation(result, activeId);
        if (updated != null) selectedConversation.value = updated;
      }

      final requestedId = _initialContractId;
      if (requestedId != null && selectedConversation.value == null) {
        final requested = _findConversation(result, requestedId);
        if (requested != null) {
          await selectConversation(requested);
        } else {
          errorMessage.value =
              'This project chat is not available to your account.';
        }
        _initialContractId = null;
      }
    } on ProjectChatRepositoryException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value =
          'Unable to load project conversations. Please try again.';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refresh() => loadConversations(refresh: true);


  ProjectChatConversation? _findConversation(
    List<ProjectChatConversation> items,
    String contractId,
  ) {
    for (final item in items) {
      if (item.contractId == contractId) return item;
    }
    return null;
  }

  Future<void> selectConversation(ProjectChatConversation conversation) async {
    if (_activeContractId == conversation.contractId &&
        _messageSubscription != null &&
        threadErrorMessage.value.isEmpty) {
      selectedConversation.value = conversation;
      return;
    }

    await _messageSubscription?.cancel();
    _messageSubscription = null;
    _activeContractId = conversation.contractId;
    selectedConversation.value = conversation;
    messages.clear();
    isThreadLoading.value = true;
    threadErrorMessage.value = '';
    sendErrorMessage.value = '';

    _messageSubscription = _repository.watchMessages(conversation.contractId).listen(
      (rows) {
        final parsed = rows
            .map(ProjectChatMessage.fromJson)
            .toList(growable: false);
        messages.assignAll(parsed.reversed.toList(growable: false));
        isThreadLoading.value = false;

        if (parsed.any((message) =>
            message.senderId != currentUserId && message.readAt == null)) {
          unawaited(_markMessagesRead(conversation.contractId));
        }
        _scrollToLatestMessage();
      },
      onError: (Object error) {
        isThreadLoading.value = false;
        threadErrorMessage.value =
            'Live messages could not be loaded. Check migration 012 and Supabase Realtime.';
      },
    );
  }

  Future<void> _markMessagesRead(String contractId) async {
    if (_markingRead) return;
    _markingRead = true;
    try {
      await _repository.markMessagesRead(contractId);
      final index = conversations.indexWhere(
        (item) => item.contractId == contractId,
      );
      if (index >= 0) {
        conversations[index] = conversations[index].copyWith(unreadCount: 0);
      }
      final selected = selectedConversation.value;
      if (selected?.contractId == contractId) {
        selectedConversation.value = selected!.copyWith(unreadCount: 0);
      }
    } catch (_) {
      // Message delivery is still available when marking read has a transient
      // network error; the unread badge will refresh on the next inbox load.
    } finally {
      _markingRead = false;
    }
  }

  void clearSelectedConversation() {
    unawaited(_messageSubscription?.cancel());
    _messageSubscription = null;
    _activeContractId = null;
    selectedConversation.value = null;
    messages.clear();
    threadErrorMessage.value = '';
    composerText.value = '';
    composerController.clear();
    pendingAttachment.value = null;
    pendingAttachmentBytes.value = null;
  }

  void updateComposer(String value) {
    composerText.value = value;
    sendErrorMessage.value = '';
  }

  void updateSearch(String value) => searchQuery.value = value;

  Future<void> pickAttachment() async {
    if (isSending.value) return;
    sendErrorMessage.value = '';
    try {
      final file = await FilePicker.pickFile(type: FileType.any);
      if (file == null) return;

      final extension = _extensionOf(file.name);
      if (!_allowedExtensions.contains(extension)) {
        sendErrorMessage.value =
            'This file type is not supported. Choose a PDF, Office document, image, ZIP, TXT or CSV file.';
        return;
      }

      final size = file.lengthSync() ?? await file.length();
      if (size == null || size < 1 ||
          size > ProjectChatRepository.maxAttachmentBytes) {
        sendErrorMessage.value = 'Choose a file smaller than 10 MB.';
        return;
      }

      pendingAttachment.value = file;
      pendingAttachmentBytes.value = size;
    } catch (_) {
      sendErrorMessage.value = 'Unable to select that file. Please try again.';
    }
  }

  void removePendingAttachment() {
    pendingAttachment.value = null;
    pendingAttachmentBytes.value = null;
  }

  Future<void> sendMessage() async {
    if (!canSend) return;
    final conversation = selectedConversation.value;
    if (conversation == null) return;

    final body = composerText.value.trim();
    final file = pendingAttachment.value;
    isSending.value = true;
    sendErrorMessage.value = '';
    String? uploadedPath;

    try {
      String? attachmentName;
      String? attachmentMime;
      int? attachmentSize;

      if (file != null) {
        final bytes = await file.readAsBytes();
        attachmentName = file.name;
        attachmentMime = _mimeTypeFor(file.name);
        attachmentSize = pendingAttachmentBytes.value ?? bytes.length;
        uploadedPath = await _repository.uploadAttachment(
          contractId: conversation.contractId,
          originalName: file.name,
          mimeType: attachmentMime,
          bytes: bytes,
        );
      }

      await _repository.sendMessage(
        contractId: conversation.contractId,
        body: body,
        attachmentPath: uploadedPath,
        attachmentName: attachmentName,
        attachmentMimeType: attachmentMime,
        attachmentSizeBytes: attachmentSize,
      );

      composerController.clear();
      composerText.value = '';
      removePendingAttachment();
      await loadConversations(refresh: true);
    } on ProjectChatRepositoryException catch (error) {
      if (uploadedPath != null) {
        await _repository.removeAttachment(uploadedPath);
      }
      sendErrorMessage.value = error.message;
    } catch (_) {
      if (uploadedPath != null) {
        await _repository.removeAttachment(uploadedPath);
      }
      sendErrorMessage.value = 'Message was not sent. Please try again.';
    } finally {
      isSending.value = false;
    }
  }

  Future<void> openAttachment(ProjectChatMessage message) async {
    final path = message.attachmentPath;
    if (path == null) return;
    try {
      final url = await _repository.createAttachmentUrl(path);
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        sendErrorMessage.value = 'No app could open this attachment.';
      }
    } on ProjectChatRepositoryException catch (error) {
      sendErrorMessage.value = error.message;
    } catch (_) {
      sendErrorMessage.value = 'Unable to open this attachment.';
    }
  }

  void _scrollToLatestMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!messageScrollController.hasClients) return;
      messageScrollController.animateTo(
        messageScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  static const Set<String> _allowedExtensions = {
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
    'png', 'jpg', 'jpeg', 'webp', 'zip', 'txt', 'csv',
  };

  String _extensionOf(String fileName) {
    final index = fileName.lastIndexOf('.');
    if (index < 0 || index == fileName.length - 1) return '';
    return fileName.substring(index + 1).toLowerCase();
  }

  String _mimeTypeFor(String fileName) {
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
      default: return 'application/octet-stream';
    }
  }
}
