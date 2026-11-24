import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/controllers/auth_controller.dart';
import 'package:permit_plans/controllers/notification_preferences_controller.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationPreferencesController>();
    final role = Get.find<AuthController>().currentRole.value ?? 'client';
    final profileRoute = role == 'client'
        ? AppRoutes.clientEditProfile
        : AppRoutes.engineerEditProfile;

    return AppShell(
      title: 'Notification preferences',
      currentIndex: 0,
      destinations: const [],
      sidebarItems: [
        SidebarItem(
          icon: Icons.dashboard_outlined,
          label: 'Dashboard',
          route: AppRoutes.homeForRole(role),
        ),
        const SidebarItem(
          icon: Icons.notifications_outlined,
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
          route: profileRoute,
        ),
        const SidebarItem(
          icon: Icons.settings_outlined,
          label: 'Account settings',
          route: AppRoutes.accountSettings,
        ),
      ],
      body: _NotificationPreferencesBody(controller: controller),
    );
  }
}

class _NotificationPreferencesBody extends StatelessWidget {
  const _NotificationPreferencesBody({required this.controller});

  final NotificationPreferencesController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final preferences = controller.preferences.value;
      if (preferences == null) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _StatusPanel(
                icon: Icons.notifications_off_outlined,
                title: 'Preferences could not be loaded',
                message: controller.errorMessage.value.isEmpty
                    ? 'Please check your connection and try again.'
                    : controller.errorMessage.value,
                actionLabel: 'Try again',
                onAction: controller.load,
              ),
            ),
          ),
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return ListView(
            padding: EdgeInsets.fromLTRB(wide ? 34 : 18, 24, wide ? 34 : 18, 42),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose what reaches you',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.45,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Control the WorkBridge updates you receive. Your choices are saved to your account.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _IntroBanner(),
                      const SizedBox(height: 18),
                      if (controller.errorMessage.value.isNotEmpty) ...[
                        _InlineMessage(
                          message: controller.errorMessage.value,
                          isError: true,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (controller.successMessage.value.isNotEmpty) ...[
                        _InlineMessage(
                          message: controller.successMessage.value,
                          isError: false,
                        ),
                        const SizedBox(height: 14),
                      ],
                      _PreferenceSection(
                        title: 'In-app notifications',
                        description:
                            'Choose whether WorkBridge adds new activity to your Notifications inbox.',
                        child: Column(
                          children: [
                            _PreferenceTile(
                              icon: Icons.notifications_active_outlined,
                              title: 'In-app notifications',
                              subtitle:
                                  'Show updates inside your WorkBridge account.',
                              value: preferences.inAppEnabled,
                              onChanged: controller.setInAppEnabled,
                            ),
                            const Divider(height: 1),
                            _PreferenceTile(
                              icon: Icons.assignment_outlined,
                              title: 'Task invitations',
                              subtitle:
                                  'New invitations and declined invitation updates.',
                              value: preferences.taskUpdates,
                              onChanged: controller.setTaskUpdates,
                            ),
                            _PreferenceTile(
                              icon: Icons.request_quote_outlined,
                              title: 'Quotes and negotiations',
                              subtitle:
                                  'New quotes, counteroffers and quote decisions.',
                              value: preferences.quoteUpdates,
                              onChanged: controller.setQuoteUpdates,
                            ),
                            _PreferenceTile(
                              icon: Icons.chat_bubble_outline_rounded,
                              title: 'Project messages',
                              subtitle:
                                  'A notification when the other project participant sends a message.',
                              value: preferences.messageUpdates,
                              onChanged: controller.setMessageUpdates,
                            ),
                            _PreferenceTile(
                              icon: Icons.fact_check_outlined,
                              title: 'Deliveries and revisions',
                              subtitle:
                                  'New delivery submissions, revision requests and approvals.',
                              value: preferences.deliveryUpdates,
                              onChanged: controller.setDeliveryUpdates,
                            ),
                            _PreferenceTile(
                              icon: Icons.handshake_outlined,
                              title: 'Project and contract updates',
                              subtitle:
                                  'Contract confirmations and important project changes.',
                              value: preferences.projectUpdates,
                              onChanged: controller.setProjectUpdates,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _PreferenceSection(
                        title: 'Delivery channels',
                        description:
                            'Save your preferred channels now. Email and push delivery will only start after those services are configured.',
                        child: Column(
                          children: [
                            _PreferenceTile(
                              icon: Icons.email_outlined,
                              title: 'Email notifications',
                              subtitle:
                                  'Preference saved for future email notification support.',
                              value: preferences.emailEnabled,
                              onChanged: controller.setEmailEnabled,
                              trailingLabel: 'Not active yet',
                            ),
                            const Divider(height: 1),
                            _PreferenceTile(
                              icon: Icons.phone_iphone_outlined,
                              title: 'Push notifications',
                              subtitle:
                                  'Preference saved for future Firebase/APNs push support.',
                              value: preferences.pushEnabled,
                              onChanged: controller.setPushEnabled,
                              trailingLabel: 'Not active yet',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ChannelStatusNote(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: controller.hasChanges &&
                                      !controller.isSaving.value
                                  ? controller.discardChanges
                                  : null,
                              child: const Text('Discard changes'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: controller.canSave
                                  ? controller.save
                                  : null,
                              icon: controller.isSaving.value
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined, size: 18),
                              label: Text(controller.isSaving.value
                                  ? 'Saving…'
                                  : 'Save preferences'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.brand,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          controller.hasChanges
                              ? 'You have unsaved changes.'
                              : 'Your preferences are up to date.',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }
}

class _IntroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(19),
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
            child: const Icon(Icons.tune_rounded,
                color: AppColors.saffron, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your updates, your choice',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose the activity that matters to your work.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceSection extends StatelessWidget {
  const _PreferenceSection({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(19, 18, 19, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: 5),
                Text(description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
              ],
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.trailingLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.brand, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (trailingLabel != null) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warningSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          trailingLabel!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.warningInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ChannelStatusNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.saffron.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.warningInk, size: 21),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Email and push preferences are stored in your account, but those delivery services are not active yet. In-app notifications are the only active delivery channel, and they will appear only while the in-app master switch is enabled.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.warningInk,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.success;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              color: color, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 13),
          Text(title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 17),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
