import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/controllers/auth_controller.dart';
import 'package:permit_plans/controllers/help_support_controller.dart';
import 'package:permit_plans/models/help_support_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

class HelpSupportScreen extends GetView<HelpSupportController> {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final role = auth.currentRole.value ?? 'client';
    final sidebarItems = <SidebarItem>[
      SidebarItem(
        icon: Icons.dashboard_outlined,
        label: 'Dashboard',
        route: AppRoutes.homeForRole(role),
      ),
      if (role == 'client')
        const SidebarItem(
          icon: Icons.person_outline_rounded,
          label: 'My profile',
          route: AppRoutes.clientEditProfile,
        ),
      if (role == 'engineer')
        const SidebarItem(
          icon: Icons.person_outline_rounded,
          label: 'My profile',
          route: AppRoutes.engineerEditProfile,
        ),
      if (role == 'client' || role == 'engineer')
        const SidebarItem(
          icon: Icons.notifications_none_rounded,
          label: 'Notifications',
          route: AppRoutes.notifications,
        ),
      if (role == 'client' || role == 'engineer')
        const SidebarItem(
          icon: Icons.notifications_active_outlined,
          label: 'Notification preferences',
          route: AppRoutes.notificationPreferences,
        ),
      const SidebarItem(
        icon: Icons.settings_outlined,
        label: 'Account settings',
        route: AppRoutes.accountSettings,
      ),
      const SidebarItem(
        icon: Icons.policy_outlined,
        label: 'Legal & policies',
        route: AppRoutes.legalPolicies,
      ),
      const SidebarItem(
        icon: Icons.help_outline_rounded,
        label: 'Help & support',
        route: AppRoutes.helpSupport,
      ),
    ];

    return AppShell(
      title: 'Help & Support',
      currentIndex: 0,
      destinations: const [],
      sidebarItems: sidebarItems,
      actions: [
        IconButton(
          tooltip: 'Refresh support requests',
          onPressed: controller.refreshRequests,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      body: _HelpSupportBody(controller: controller),
    );
  }
}

class _HelpSupportBody extends StatelessWidget {
  const _HelpSupportBody({required this.controller});

  final HelpSupportController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 980;

    return RefreshIndicator(
      onRefresh: controller.refreshRequests,
      child: ListView(
        padding: EdgeInsets.fromLTRB(wide ? 34 : 18, 24, wide ? 34 : 18, 48),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HelpHero(),
                  const SizedBox(height: 22),
                  TextField(
                    controller: controller.searchController,
                    onChanged: controller.setSearch,
                    decoration: InputDecoration(
                      hintText: 'Search help articles and common questions',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: Obx(() => controller.searchQuery.value.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                controller.searchController.clear();
                                controller.setSearch('');
                              },
                              icon: const Icon(Icons.close_rounded),
                            )),
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 11,
                          child: _FaqSection(controller: controller),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          flex: 9,
                          child: _SupportRequestForm(controller: controller),
                        ),
                      ],
                    )
                  else ...[
                    _FaqSection(controller: controller),
                    const SizedBox(height: 20),
                    _SupportRequestForm(controller: controller),
                  ],
                  const SizedBox(height: 24),
                  _MyRequestsSection(controller: controller),
                  const SizedBox(height: 18),
                  Text(
                    'Never send passwords, card numbers, CVV codes or other secrets in a support request.',
                    style: theme.textTheme.bodySmall?.copyWith(
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

class _HelpHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
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
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: AppColors.saffron,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Find an answer or send a request to the WorkBridge support team.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.4,
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

class _FaqSection extends StatelessWidget {
  const _FaqSection({required this.controller});
  final HelpSupportController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      title: 'Frequently asked questions',
      subtitle: 'Quick answers about using WorkBridge.',
      icon: Icons.quiz_outlined,
      child: Obx(() {
        final faqs = controller.filteredFaqs;
        if (faqs.isEmpty) {
          return const _EmptyInline(
            icon: Icons.search_off_rounded,
            title: 'No matching articles',
            message: 'Try another word or send us a support request.',
          );
        }
        return Column(
          children: [
            for (var index = 0; index < faqs.length; index++) ...[
              if (index > 0)
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
              ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 2),
                childrenPadding: const EdgeInsets.fromLTRB(2, 0, 2, 16),
                title: Text(
                  faqs[index].question,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    faqs[index].category,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.papayaDark,
                    ),
                  ),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      faqs[index].answer,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _SupportRequestForm extends StatelessWidget {
  const _SupportRequestForm({required this.controller});
  final HelpSupportController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      title: 'Contact support',
      subtitle: 'Tell us what happened. Your request will be saved to your account.',
      icon: Icons.mark_email_unread_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What do you need help with?', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Obx(() => DropdownButtonFormField<String>(
                value: controller.selectedCategory.value,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.topic_outlined),
                ),
                items: [
                  for (final topic in HelpTopic.all)
                    DropdownMenuItem<String>(
                      value: topic.value,
                      child: Text(topic.label, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: controller.setCategory,
              )),
          const SizedBox(height: 16),
          Text('Subject', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: controller.subjectController,
            maxLength: 140,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Briefly describe the issue',
              prefixIcon: Icon(Icons.subject_rounded),
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
          Text('Details', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: controller.messageController,
            minLines: 5,
            maxLines: 8,
            maxLength: 5000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Explain what happened and what you need help with...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Text('Project or contract reference (optional)',
              style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: controller.referenceController,
            maxLength: 100,
            decoration: const InputDecoration(
              hintText: 'Paste a project or contract ID if relevant',
              prefixIcon: Icon(Icons.tag_rounded),
              counterText: '',
            ),
          ),
          Obx(() {
            if (controller.requestError.value.isEmpty) {
              return const SizedBox(height: 10);
            }
            return Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text(
                controller.requestError.value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
          Obx(() => SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: controller.isSubmitting.value
                      ? null
                      : controller.submitRequest,
                  icon: controller.isSubmitting.value
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(controller.isSubmitting.value
                      ? 'Submitting...'
                      : 'Submit support request'),
                ),
              )),
          const SizedBox(height: 8),
          Text(
            'Subject: 5–140 characters · Details: 20–5,000 characters',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MyRequestsSection extends StatelessWidget {
  const _MyRequestsSection({required this.controller});
  final HelpSupportController controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'My support requests',
      subtitle: 'Track the requests you have already submitted.',
      icon: Icons.history_rounded,
      trailing: IconButton(
        tooltip: 'Refresh requests',
        onPressed: controller.refreshRequests,
        icon: const Icon(Icons.refresh_rounded),
      ),
      child: Obx(() {
        if (controller.isLoading.value && controller.requests.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (controller.errorMessage.value.isNotEmpty &&
            controller.requests.isEmpty) {
          return _EmptyInline(
            icon: Icons.cloud_off_outlined,
            title: 'Support history unavailable',
            message: controller.errorMessage.value,
            actionLabel: 'Try again',
            onAction: controller.refreshRequests,
          );
        }
        if (controller.requests.isEmpty) {
          return const _EmptyInline(
            icon: Icons.inbox_outlined,
            title: 'No support requests yet',
            message: 'Requests you submit will appear here with their current status.',
          );
        }
        return Column(
          children: [
            for (var i = 0; i < controller.requests.length; i++) ...[
              if (i > 0)
                Divider(height: 22, color: Theme.of(context).colorScheme.outlineVariant),
              _SupportRequestTile(item: controller.requests[i]),
            ],
          ],
        );
      }),
    );
  }
}

class _SupportRequestTile extends StatelessWidget {
  const _SupportRequestTile({required this.item});
  final HelpSupportRequest item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = HelpTopic.byValue(item.category).label;
    final (Color color, Color background) = switch (item.status) {
      'resolved' => (AppColors.success, AppColors.successSoft),
      'closed' => (theme.colorScheme.onSurfaceVariant, theme.colorScheme.surfaceContainerHighest),
      'in_review' => (AppColors.info, AppColors.infoSoft),
      'waiting_for_user' => (AppColors.warningInk, AppColors.warningSoft),
      _ => (AppColors.papayaDark, AppColors.papayaSoft),
    };
    final date = item.createdAt == null
        ? 'Date unavailable'
        : DateFormat('dd MMM yyyy · hh:mm a').format(item.createdAt!.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.subject,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  item.readableStatus,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text('$category · $date',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 8),
          Text(item.message, maxLines: 3, overflow: TextOverflow.ellipsis),
          if (item.relatedReference != null) ...[
            const SizedBox(height: 5),
            Text('Reference: ${item.relatedReference}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ],
          if (item.adminNote != null && item.adminNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Support update: ${item.adminNote}'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        )),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  const _EmptyInline({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 34, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(message, textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              )),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
