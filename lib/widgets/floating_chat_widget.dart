import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permit_plans/services/workbridge_ai_service.dart';

class ChatMessageModel {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final List<String> attachmentNames;

  ChatMessageModel({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.attachmentNames = const [],
  });
}

class FloatingChatController extends GetxController {
  FloatingChatController({WorkbridgeAiService? aiService})
      : _aiService = aiService ?? WorkbridgeAiService();

  final WorkbridgeAiService _aiService;
  final RxBool isExpanded = false.obs;
  final RxBool isSending = false.obs;
  final RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    messages.add(
      ChatMessageModel(
        text: "Hi! I'm WorkBridge AI Assistant. I can help with WorkBridge tasks, quotes, projects, policies and using the platform. Ask me a question to get started.",
        isMe: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void toggleChat() {
    isExpanded.value = !isExpanded.value;
    if (isExpanded.value) scrollToBottom();
  }

  Future<void> sendMessage({
    String? text,
    List<String> attachmentNames = const [],
  }) async {
    final trimmedText = text?.trim() ?? '';
    final hasText = trimmedText.isNotEmpty;
    if ((!hasText && attachmentNames.isEmpty) || isSending.value) return;

    messages.add(
      ChatMessageModel(
        text: hasText
            ? trimmedText
            : 'Selected ${attachmentNames.length} attachment(s)',
        isMe: true,
        timestamp: DateTime.now(),
        attachmentNames: attachmentNames,
      ),
    );
    textController.clear();
    scrollToBottom();

    // Attachments are currently selected locally only. They are not uploaded
    // or sent to the model, so never imply that the AI has inspected them.
    if (!hasText) {
      messages.add(
        ChatMessageModel(
          text: 'I can see the attachment name, but file upload and document/image analysis are not connected yet. Please describe the file or paste the relevant text in your message.',
          isMe: false,
          timestamp: DateTime.now(),
        ),
      );
      scrollToBottom();
      return;
    }

    if (trimmedText.length > 3000) {
      messages.add(
        ChatMessageModel(
          text: 'Please keep each message under 3,000 characters.',
          isMe: false,
          timestamp: DateTime.now(),
        ),
      );
      scrollToBottom();
      return;
    }

    isSending.value = true;
    try {
      final history = messages
          .where((message) => message.attachmentNames.isEmpty)
          .toList()
          .reversed
          .take(12)
          .toList()
          .reversed
          .map(
            (message) => <String, String>{
              'role': message.isMe ? 'user' : 'assistant',
              'content': message.text,
            },
          )
          .toList();

      final reply = await _aiService.generateReply(messages: history);
      messages.add(
        ChatMessageModel(
          text: attachmentNames.isEmpty
              ? reply
              : '$reply\n\nNote: I answered your text only. The selected attachment(s) were not uploaded or analysed.',
          isMe: false,
          timestamp: DateTime.now(),
        ),
      );
    } on WorkbridgeAiException catch (error) {
      messages.add(
        ChatMessageModel(
          text: error.message,
          isMe: false,
          timestamp: DateTime.now(),
        ),
      );
    } catch (_) {
      messages.add(
        ChatMessageModel(
          text: 'Something went wrong while contacting WorkBridge AI. Please try again.',
          isMe: false,
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      isSending.value = false;
      scrollToBottom();
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// Pick images for local preview only. The files are not sent to the AI yet.
  Future<void> pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isEmpty) return;
      await sendMessage(
        attachmentNames: images.map((image) => image.name).toList(),
      );
    } catch (_) {
      messages.add(
        ChatMessageModel(
          text: 'Could not select the images. Please try again.',
          isMe: false,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Pick documents for local preview only. The files are not sent to the AI yet.
  Future<void> pickFiles() async {
    try {
      final List<PlatformFile> files = await FilePicker.pickFiles();
      if (files.isEmpty) return;
      await sendMessage(
        attachmentNames: files.map((file) => file.name).toList(),
      );
    } catch (_) {
      messages.add(
        ChatMessageModel(
          text: 'Could not select the documents. Please try again.',
          isMe: false,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}

class FloatingChatWidget extends StatelessWidget {
  const FloatingChatWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final FloatingChatController controller = Get.put(FloatingChatController());
    final screenSize = MediaQuery.sizeOf(context);
    final panelWidth = (screenSize.width - 32).clamp(280.0, 380.0).toDouble();
    final panelHeight = (screenSize.height - 170).clamp(320.0, 500.0).toDouble();

    return Obx(
      () => Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Expanded Floating Mini Window
          if (controller.isExpanded.value)
            Positioned(
              right: 12,
              bottom: 76,
              width: panelWidth,
              height: panelHeight,
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      // Chat Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        color: Theme.of(context).primaryColor,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: Colors.white24,
                                    child: Icon(
                                      Icons.auto_awesome_rounded,
                                      color: Colors.white,
                                      size: 17,
                                    ),
                                  ),
                                  SizedBox(width: 9),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "WorkBridge AI Assistant",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          "WorkBridge help · AI assistant",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: controller.toggleChat,
                            ),
                          ],
                        ),
                      ),

                      // Message List
                      Expanded(
                        child: Obx(
                          () => ListView.builder(
                            controller: controller.scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: controller.messages.length +
                                (controller.isSending.value ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= controller.messages.length) {
                                return const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                );
                              }
                              final msg = controller.messages[index];
                              return Align(
                                alignment: msg.isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  constraints: const BoxConstraints(
                                    maxWidth: 240,
                                  ),
                                  decoration: BoxDecoration(
                                    color: msg.isMe
                                        ? Theme.of(context).primaryColor
                                              .withValues(alpha: 0.12)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // One row per attachment
                                      for (final name
                                          in msg.attachmentNames) ...[
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.attach_file,
                                              size: 14,
                                              color: Colors.blueGrey,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                  color: Colors.blueGrey,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      Text(
                                        msg.text,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Input & Media Upload Bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.image_outlined,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: controller.pickImages,
                              tooltip: "Select image (not sent to AI yet)",
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.attach_file,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: controller.pickFiles,
                              tooltip: "Select file (not sent to AI yet)",
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: TextField(
                                controller: controller.textController,
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: "Ask about WorkBridge...",
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 8,
                                  ),
                                ),
                                onSubmitted: (val) =>
                                    controller.sendMessage(text: val),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.send_rounded,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              onPressed: controller.isSending.value
                                  ? null
                                  : () => controller.sendMessage(
                                        text: controller.textController.text,
                                      ),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Floating Action Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton(
              onPressed: controller.toggleChat,
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(
                controller.isExpanded.value
                    ? Icons.close
                    : Icons.chat_bubble_outline,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
