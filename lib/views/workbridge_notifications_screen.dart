import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/controllers/auth_controller.dart';
import 'package:permit_plans/controllers/workbridge_notifications_controller.dart';
import 'package:permit_plans/models/workbridge_notification_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

class WorkbridgeNotificationsScreen extends StatelessWidget {
  const WorkbridgeNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WorkbridgeNotificationsController>();
    final role = Get.find<AuthController>().currentRole.value ?? 'client';

    return AppShell(
      title: 'Notifications',
      currentIndex: 0,
      destinations: const [],
      sidebarItems: [
        SidebarItem(
          icon: Icons.dashboard_outlined,
          label: 'Dashboard',
          route: AppRoutes.homeForRole(role),
        ),
        SidebarItem(
          icon: Icons.notifications_active_outlined,
          label: 'Notifications',
          route: AppRoutes.notifications,
        ),
        const SidebarItem(
          icon: Icons.tune_rounded,
          label: 'Notification preferences',
          route: AppRoutes.notificationPreferences,
        ),
        SidebarItem(
          icon: Icons.person_outline_rounded,
          label: 'My profile',
          route: role == 'client'
              ? AppRoutes.clientEditProfile
              : AppRoutes.engineerEditProfile,
        ),
        const SidebarItem(
          icon: Icons.settings_outlined,
          label: 'Settings',
          route: AppRoutes.accountSettings,
        ),
      ],
      actions: [
        IconButton(
          tooltip: 'Notification preferences',
          onPressed: () => Get.toNamed<void>(AppRoutes.notificationPreferences),
          icon: const Icon(Icons.tune_rounded),
        ),
        Obx(
          () => IconButton(
            tooltip: 'Mark all as read',
            onPressed: controller.canMarkAllRead
                ? controller.markAllRead
                : null,
            icon: const Icon(Icons.done_all_rounded),
          ),
        ),
      ],
      body: _NotificationsBody(controller: controller),
    );
  }
}

class _NotificationsBody extends StatelessWidget {
  const _NotificationsBody({required this.controller});
  final WorkbridgeNotificationsController controller;

  static const _filters = <(String, String)>[
    ('all', 'All'),
    ('unread', 'Unread'),
    ('quotes', 'Quotes'),
    ('projects', 'Projects'),
    ('messages', 'Messages'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: controller.refresh,
      color: AppColors.papaya,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stay up to date',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Important updates about your tasks, quotes and projects.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(
                    () => _NotificationSummary(
                      total: controller.notifications.length,
                      unread: controller.unreadCount,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Obx(
                    () => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final filter in _filters)
                          ChoiceChip(
                            label: Text(filter.$2),
                            selected:
                                controller.selectedFilter.value == filter.$1,
                            onSelected: (_) => controller.setFilter(filter.$1),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Obx(() {
                    final error = controller.errorMessage.value;
                    if (error.isEmpty) return const SizedBox.shrink();
                    return _InlineError(
                      message: error,
                      onRetry: controller.refresh,
                    );
                  }),
                  Obx(() {
                    if (controller.isLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 72),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final items = controller.filteredNotifications;
                    if (items.isEmpty) {
                      return _EmptyNotifications(
                        unreadOnly: controller.selectedFilter.value == 'unread',
                        hasAny: controller.notifications.isNotEmpty,
                      );
                    }
                    return Column(
                      children: [
                        for (final item in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _NotificationTile(
                              item: item,
                              onTap: () => controller.openNotification(item),
                              onMarkRead: item.isRead
                                  ? null
                                  : () => controller.markNotificationRead(item),
                            ),
                          ),
                      ],
                    );
                  }),
                  const SizedBox(height: 8),
                  Text(
                    'Showing your 100 most recent in-app notifications. Pull down to refresh.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSummary extends StatelessWidget {
  const _NotificationSummary({required this.total, required this.unread});
  final int total;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brandDark],
        ),
        borderRadius: AppRadii.card,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.saffron,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unread unread updates',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$total notifications in your inbox',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.76),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.bolt_rounded, color: AppColors.saffron, size: 24),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onTap,
    this.onMarkRead,
  });

  final WorkbridgeNotification item;
  final VoidCallback onTap;
  final VoidCallback? onMarkRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final icon = _iconFor(item.type);
    final tint = _colorFor(context, item.type);

    return Material(
      color: item.isRead ? colors.surface : tint.withValues(alpha: 0.055),
      borderRadius: AppRadii.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: AppRadii.card,
            border: Border.all(
              color: item.isRead
                  ? colors.outlineVariant
                  : tint.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: tint, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 7),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.papaya,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _relativeTime(item.createdAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          _categoryLabel(item.category),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: tint,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (onMarkRead != null) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Mark as read',
                            visualDensity: VisualDensity.compact,
                            onPressed: onMarkRead,
                            icon: const Icon(
                              Icons.mark_email_read_outlined,
                              size: 18,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(String type) {
    if (type == 'project_message_received')
      return Icons.chat_bubble_outline_rounded;
    if (type.contains('quote') || type.contains('counteroffer')) {
      return Icons.request_quote_outlined;
    }
    if (type == 'task_invitation_received' ||
        type == 'task_invitation_rejected') {
      return Icons.assignment_outlined;
    }
    if (type == 'delivery_submitted' ||
        type == 'delivery_approved' ||
        type == 'revision_requested') {
      return Icons.folder_copy_outlined;
    }
    return Icons.notifications_outlined;
  }

  static Color _colorFor(BuildContext context, String type) {
    if (type == 'project_message_received') return AppColors.info;
    if (type.contains('quote') || type.contains('counteroffer'))
      return AppColors.saffronDark;
    if (type == 'revision_requested' || type == 'task_invitation_rejected') {
      return AppColors.warning;
    }
    if (type == 'delivery_approved') return AppColors.success;
    return Theme.of(context).colorScheme.primary;
  }

  static String _categoryLabel(String category) {
    switch (category) {
      case 'quotes':
        return 'QUOTE';
      case 'messages':
        return 'MESSAGE';
      default:
        return 'PROJECT';
    }
  }

  static String _relativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d, y · h:mm a').format(date.toLocal());
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({required this.unreadOnly, required this.hasAny});
  final bool unreadOnly;
  final bool hasAny;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = unreadOnly
        ? 'You are all caught up'
        : hasAny
        ? 'No notifications in this category'
        : 'No notifications yet';
    final description = unreadOnly
        ? 'New updates will appear here when something needs your attention.'
        : 'We will let you know when an invitation, quote, message or project update arrives.';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 42,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colors.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer, fontSize: 13),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
