import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/controllers/project_chat_controller.dart';
import 'package:permit_plans/models/project_chat_conversation_model.dart';
import 'package:permit_plans/models/project_chat_message_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

/// Screen 21 — private Client / Engineer conversations attached to contracts.
/// Realtime data, message access and attachment access are protected by RLS.
class ProjectChatScreen extends GetView<ProjectChatController> {
  const ProjectChatScreen({super.key});

  static const double _splitBreakpoint = 1040;

  @override
  Widget build(BuildContext context) {
    final isClient = controller.currentRole == 'client';
    final destinations = isClient
        ? const [
            ShellDestination(
              icon: Icons.grid_view_outlined,
              selectedIcon: Icons.grid_view_rounded,
              label: 'Overview',
              route: AppRoutes.clientHome,
            ),
            ShellDestination(
              icon: Icons.request_quote_outlined,
              label: 'Quotes',
              route: AppRoutes.clientQuotes,
            ),
            ShellDestination(
              icon: Icons.fact_check_outlined,
              selectedIcon: Icons.fact_check_rounded,
              label: 'Deliveries',
              route: AppRoutes.clientDeliveryReviews,
            ),
            ShellDestination(
              icon: Icons.search_rounded,
              label: 'Find engineers',
              route: AppRoutes.clientBrowseEngineers,
            ),
            ShellDestination(
              icon: Icons.chat_bubble_outline_rounded,
              selectedIcon: Icons.chat_bubble_rounded,
              label: 'Messages',
              route: AppRoutes.projectChats,
            ),
          ]
        : const [
            ShellDestination(
              icon: Icons.grid_view_outlined,
              selectedIcon: Icons.grid_view_rounded,
              label: 'Overview',
              route: AppRoutes.engineerHome,
            ),
            ShellDestination(
              icon: Icons.search_rounded,
              label: 'Invitations',
              route: AppRoutes.engineerInvitations,
            ),
            ShellDestination(
              icon: Icons.assignment_outlined,
              label: 'Negotiations',
              route: AppRoutes.engineerNegotiations,
            ),
            ShellDestination(
              icon: Icons.folder_open_outlined,
              label: 'Projects',
              route: AppRoutes.engineerProjects,
            ),
            ShellDestination(
              icon: Icons.chat_bubble_outline_rounded,
              selectedIcon: Icons.chat_bubble_rounded,
              label: 'Messages',
              route: AppRoutes.projectChats,
            ),
          ];

    return AppShell(
      title: 'Project messages',
      currentIndex: 4,
      destinations: destinations,
      sidebarItems: isClient
          ? const [
              SidebarItem(
                icon: Icons.fact_check_outlined,
                label: 'Delivery reviews',
                route: AppRoutes.clientDeliveryReviews,
              ),
              SidebarItem(icon: Icons.folder_open_outlined, label: 'My projects'),
              SidebarItem(icon: Icons.receipt_long_outlined, label: 'Payments'),
              SidebarItem(icon: Icons.person_outline_rounded, label: 'My profile'),
              SidebarItem(icon: Icons.help_outline_rounded, label: 'Help & support'),
            ]
          : const [
              SidebarItem(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Earnings',
                route: AppRoutes.engineerEarnings,
              ),
              SidebarItem(icon: Icons.person_outline_rounded, label: 'My profile'),
              SidebarItem(icon: Icons.settings_outlined, label: 'Settings'),
              SidebarItem(icon: Icons.help_outline_rounded, label: 'Help & support'),
            ],
      actions: [
        IconButton(
          tooltip: 'Refresh conversations',
          onPressed: controller.refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      body: _ProjectChatBody(
        controller: controller,
        splitBreakpoint: _splitBreakpoint,
      ),
    );
  }
}

class _ProjectChatBody extends StatelessWidget {
  const _ProjectChatBody({
    required this.controller,
    required this.splitBreakpoint,
  });

  final ProjectChatController controller;
  final double splitBreakpoint;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedConversation.value;
      final conversations = controller.filteredConversations;
      final isInitialLoading = controller.isLoading.value &&
          controller.conversations.isEmpty;

      if (isInitialLoading) return const _ChatLoadingState();

      return LayoutBuilder(
        builder: (context, constraints) {
          final isSplit = constraints.maxWidth >= splitBreakpoint;
          final horizontal = constraints.maxWidth >= 1200 ? 28.0 : 16.0;

          if (!isSplit && selected != null) {
            return Padding(
              padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 16),
              child: _ChatThreadPanel(
                controller: controller,
                conversation: selected,
                showBack: true,
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 18, horizontal, 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1500),
                child: isSplit
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 350,
                            child: _ChatInboxPanel(
                              controller: controller,
                              conversations: conversations,
                              isRefreshing: controller.isRefreshing.value,
                              errorMessage: controller.errorMessage.value,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: selected == null
                                ? const _SelectConversationState()
                                : _ChatThreadPanel(
                                    controller: controller,
                                    conversation: selected,
                                    showBack: false,
                                  ),
                          ),
                        ],
                      )
                    : _ChatInboxPanel(
                        controller: controller,
                        conversations: conversations,
                        isRefreshing: controller.isRefreshing.value,
                        errorMessage: controller.errorMessage.value,
                      ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _ChatInboxPanel extends StatelessWidget {
  const _ChatInboxPanel({
    required this.controller,
    required this.conversations,
    required this.isRefreshing,
    required this.errorMessage,
  });

  final ProjectChatController controller;
  final List<ProjectChatConversation> conversations;
  final bool isRefreshing;
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 19, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MESSAGES',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.papayaDark,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Project inbox',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isRefreshing)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.papaya,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: TextField(
              onChanged: controller.updateSearch,
              decoration: InputDecoration(
                hintText: 'Search projects or people',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: AppColors.inputFill,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: errorMessage.isNotEmpty && conversations.isEmpty
                ? _InlineChatError(
                    message: errorMessage,
                    onRetry: () => controller.loadConversations(),
                  )
                : conversations.isEmpty
                    ? const _NoConversationsState(compact: true)
                    : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    itemCount: conversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      return _ConversationTile(
                        conversation: conversation,
                        selected: controller.selectedConversation.value?.contractId ==
                            conversation.contractId,
                        onTap: () => controller.selectConversation(conversation),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 13),
            child: Text(
              'Private chats are available to the Client and Engineer on each confirmed contract.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.selected,
    required this.onTap,
  });

  final ProjectChatConversation conversation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? AppColors.brandSoft : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PartnerAvatar(conversation: conversation, radius: 22),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.partnerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          conversation.lastActivityLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      conversation.taskTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.previewLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (conversation.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.papaya,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              conversation.unreadCount > 99
                                  ? '99+'
                                  : conversation.unreadCount.toString(),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatThreadPanel extends StatelessWidget {
  const _ChatThreadPanel({
    required this.controller,
    required this.conversation,
    required this.showBack,
  });

  final ProjectChatController controller;
  final ProjectChatConversation conversation;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 13),
            child: Row(
              children: [
                if (showBack) ...[
                  IconButton(
                    tooltip: 'Back to messages',
                    onPressed: controller.clearSelectedConversation,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 2),
                ],
                _PartnerAvatar(conversation: conversation, radius: 21),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.partnerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${conversation.partnerRole == 'client' ? 'Client' : 'Engineer'}  ·  ${conversation.taskTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _ContractStatusPill(label: conversation.statusLabel),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _MessageList(controller: controller)),
          const Divider(height: 1),
          _MessageComposer(controller: controller),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.controller});
  final ProjectChatController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isThreadLoading.value && controller.messages.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.papaya),
        );
      }
      if (controller.threadErrorMessage.value.isNotEmpty &&
          controller.messages.isEmpty) {
        return _InlineChatError(
          message: controller.threadErrorMessage.value,
          onRetry: () {
            final conversation = controller.selectedConversation.value;
            if (conversation != null) {
              controller.selectConversation(conversation);
            }
          },
        );
      }
      if (controller.messages.isEmpty) {
        return const _NoMessagesState();
      }

      final messages = controller.messages.toList(growable: false);
      return ListView.builder(
        controller: controller.messageScrollController,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final previous = index > 0 ? messages[index - 1] : null;
          final showDate = previous == null ||
              !_sameDay(previous.createdAt, message.createdAt);
          final isMine = message.senderId == controller.currentUserId;
          return Column(
            children: [
              if (showDate) _DateSeparator(date: message.createdAt),
              _MessageBubble(
                message: message,
                isMine: isMine,
                onOpenAttachment: () => controller.openAttachment(message),
              ),
            ],
          );
        },
      );
    });
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final label = _sameDay(date, today)
        ? 'Today'
        : _sameDay(date, yesterday)
            ? 'Yesterday'
            : DateFormat('EEEE, d MMMM yyyy').format(date.toLocal());
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.onOpenAttachment,
  });

  final ProjectChatMessage message;
  final bool isMine;
  final VoidCallback onOpenAttachment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isMine ? AppColors.brandSoft : AppColors.surfaceAlt;
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(17),
              topRight: const Radius.circular(17),
              bottomLeft: Radius.circular(isMine ? 17 : 5),
              bottomRight: Radius.circular(isMine ? 5 : 17),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.body.trim().isNotEmpty)
                Text(
                  message.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                    height: 1.45,
                  ),
                ),
              if (message.hasAttachment) ...[
                if (message.body.trim().isNotEmpty)
                  const SizedBox(height: 9),
                _AttachmentMessageTile(
                  message: message,
                  onTap: onOpenAttachment,
                ),
              ],
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('h:mm a').format(message.createdAt.toLocal()),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 5),
                    Icon(
                      message.readAt == null
                          ? Icons.check_rounded
                          : Icons.done_all_rounded,
                      size: 14,
                      color: message.readAt == null
                          ? AppColors.textTertiary
                          : AppColors.info,
                    ),
                    Text(
                      message.readAt == null ? 'Sent' : 'Read',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentMessageTile extends StatelessWidget {
  const _AttachmentMessageTile({
    required this.message,
    required this.onTap,
  });

  final ProjectChatMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = message.attachmentName ?? 'Project attachment';
    final extension = name.contains('.') ? name.split('.').last.toUpperCase() : 'FILE';
    return Material(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 37,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.papayaSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.insert_drive_file_outlined,
                  color: AppColors.papayaDark,
                ),
              ),
              const SizedBox(width: 9),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 230),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$extension  ·  ${message.formattedAttachmentSize}  ·  Open file',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.brand),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({required this.controller});
  final ProjectChatController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              final file = controller.pendingAttachment.value;
              if (file == null) return const SizedBox.shrink();
              final size = controller.pendingAttachmentBytes.value ?? 0;
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.saffronSoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file_rounded, size: 18, color: AppColors.saffronDark),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '${file.name}  ·  ${(size / 1024).toStringAsFixed(0)} KB',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove attachment',
                      visualDensity: VisualDensity.compact,
                      onPressed: controller.removePendingAttachment,
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              );
            }),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton.filledTonal(
                  tooltip: 'Attach a file',
                  onPressed: controller.isSending.value
                      ? null
                      : controller.pickAttachment,
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.brand,
                    backgroundColor: AppColors.brandSoft,
                    fixedSize: const Size(45, 45),
                  ),
                  icon: const Icon(Icons.attach_file_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller.composerController,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: controller.updateComposer,
                    onSubmitted: (_) => controller.sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Write a message about this project...',
                      filled: true,
                      fillColor: AppColors.inputFill,
                      contentPadding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(() {
                  final sending = controller.isSending.value;
                  return IconButton.filled(
                    tooltip: 'Send message',
                    onPressed: controller.canSend ? controller.sendMessage : null,
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppColors.brand,
                      disabledBackgroundColor: AppColors.disabled,
                      fixedSize: const Size(47, 47),
                    ),
                    icon: sending
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 19),
                  );
                }),
              ],
            ),
            Obx(() {
              final error = controller.sendErrorMessage.value;
              if (error.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8, left: 3),
                  child: Text(
                    error,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(top: 7, left: 3),
                child: Text(
                  'Private project chat  ·  Attachments up to 10 MB',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _PartnerAvatar extends StatelessWidget {
  const _PartnerAvatar({required this.conversation, required this.radius});

  final ProjectChatConversation conversation;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = conversation.partnerAvatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.brandSoft,
      foregroundImage: (url != null && url.isNotEmpty) ? NetworkImage(url) : null,
      child: Text(
        conversation.initials,
        style: TextStyle(
          color: AppColors.brand,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.58,
        ),
      ),
    );
  }
}

class _ContractStatusPill extends StatelessWidget {
  const _ContractStatusPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.saffronSoft,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.saffronDark,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NoConversationsState extends StatelessWidget {
  const _NoConversationsState({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 22 : 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: AppColors.brandSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 27,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No project conversations yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'A private chat opens after a Client confirms a contract with an Engineer. Your project conversations will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMessagesState extends StatelessWidget {
  const _NoMessagesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.forum_outlined,
              size: 38,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'Start the project conversation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Keep project questions, updates and files in one private place.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectConversationState extends StatelessWidget {
  const _SelectConversationState();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: const _NoMessagesState(),
    );
  }
}

class _ChatLoadingState extends StatelessWidget {
  const _ChatLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.papaya),
    );
  }
}

class _InlineChatError extends StatelessWidget {
  const _InlineChatError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, color: AppColors.error, size: 30),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
