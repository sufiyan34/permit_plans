import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

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
  RxBool isExpanded = false.obs;
  RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    // Add an initial greeting message from the system/bot
    messages.add(
      ChatMessageModel(
        text: "Hello! How can I help you with your permit plans today?",
        isMe: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void toggleChat() {
    isExpanded.value = !isExpanded.value;
  }

  void sendMessage({String? text, List<String> attachmentNames = const []}) {
    final bool hasText = text != null && text.trim().isNotEmpty;
    if (!hasText && attachmentNames.isEmpty) return;

    messages.add(
      ChatMessageModel(
        text: hasText
            ? text.trim()
            : "Sent ${attachmentNames.length} attachment(s)",
        isMe: true,
        timestamp: DateTime.now(),
        attachmentNames: attachmentNames,
      ),
    );

    textController.clear();
    scrollToBottom();

    // Simulated automated response (Ready for AI integration later)
    Future.delayed(const Duration(milliseconds: 900), () {
      messages.add(
        ChatMessageModel(
          text: "Thanks for reaching out! Our system received your input. AI processing will be connected here soon.",
          isMe: false,
          timestamp: DateTime.now(),
        ),
      );
      scrollToBottom();
    });
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Pick multiple images from the gallery.
  Future<void> pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isEmpty) return; // user cancelled

    sendMessage(
      text: images.length == 1
          ? "Uploaded image"
          : "Uploaded ${images.length} images",
      attachmentNames: images.map((i) => i.name).toList(),
    );
  }

  /// Pick multiple documents.
  /// file_picker v12+: pickFiles() returns List<PlatformFile> (empty if cancelled).
  Future<void> pickFiles() async {
    final List<PlatformFile> files = await FilePicker.pickFiles();
    if (files.isEmpty) return; // user cancelled

    sendMessage(
      text: files.length == 1
          ? "Uploaded document"
          : "Uploaded ${files.length} documents",
      attachmentNames: files.map((f) => f.name).toList(),
    );
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

    return Obx(
      () => Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Expanded Floating Mini Window
          if (controller.isExpanded.value)
            Positioned(
              right: 16,
              bottom: 80,
              width: 350,
              height: 480,
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
                            const Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.white24,
                                  child: Icon(
                                    Icons.support_agent,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Permit Plans Assistant",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
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
                            itemCount: controller.messages.length,
                            itemBuilder: (context, index) {
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
                                              .withOpacity(0.12)
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
                              tooltip: "Upload Images",
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
                              tooltip: "Upload Files",
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: TextField(
                                controller: controller.textController,
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: "Type a message...",
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
                              onPressed: () => controller.sendMessage(
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
