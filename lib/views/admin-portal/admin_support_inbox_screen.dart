import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/controllers/admin_support_inbox_controller.dart';
import 'package:permit_plans/models/admin_support_ticket_model.dart';
import 'package:permit_plans/models/help_support_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

class AdminSupportInboxScreen extends GetView<AdminSupportInboxController> {
  const AdminSupportInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Admin Support Inbox',
      currentIndex: 0,
      destinations: const [],
      sidebarItems: const [
        SidebarItem(
          icon: Icons.space_dashboard_outlined,
          label: 'Admin dashboard',
          route: AppRoutes.adminHome,
        ),
        SidebarItem(
          icon: Icons.inbox_outlined,
          label: 'Support inbox',
          route: AppRoutes.adminSupportInbox,
        ),
        SidebarItem(
          icon: Icons.help_outline_rounded,
          label: 'Help center',
          route: AppRoutes.helpSupport,
        ),
      ],
      actions: [
        Obx(
          () => IconButton(
            tooltip: 'Refresh support tickets',
            onPressed: controller.isRefreshing.value
                ? null
                : () => controller.loadTickets(silent: true),
            icon: controller.isRefreshing.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ),
      ],
      body: _InboxBody(controller: controller),
    );
  }
}

class _InboxBody extends StatelessWidget {
  const _InboxBody({required this.controller});
  final AdminSupportInboxController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        if (wide) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PageHeader(),
                const SizedBox(height: 18),
                _SummaryRow(controller: controller),
                const SizedBox(height: 18),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 390, child: _TicketListPane(controller: controller)),
                      const SizedBox(width: 16),
                      Expanded(child: _TicketDetailsPane(controller: controller)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PageHeader(),
              const SizedBox(height: 16),
              _SummaryRow(controller: controller),
              const SizedBox(height: 16),
              SizedBox(
                height: 590,
                child: _TicketListPane(controller: controller),
              ),
              const SizedBox(height: 16),
              _TicketDetailsPane(controller: controller),
            ],
          ),
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CUSTOMER CARE · ADMIN OPERATIONS',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.papayaDark,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.25,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Support inbox',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Review requests from Clients and Engineers, set priority, update status and send a visible support response.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.controller});
  final AdminSupportInboxController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cards = <(String, int, IconData, Color)>[
        ('Open', controller.openCount, Icons.mark_email_unread_outlined, AppColors.warning),
        ('In review', controller.inReviewCount, Icons.manage_search_rounded, AppColors.info),
        ('Urgent', controller.urgentCount, Icons.priority_high_rounded, AppColors.error),
        ('Resolved', controller.resolvedCount, Icons.task_alt_rounded, AppColors.success),
      ];
      return LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 4
              : constraints.maxWidth >= 560
                  ? 2
                  : 2;
          final gap = 10.0;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: cards
                .map((item) => SizedBox(
                      width: width,
                      child: _SummaryCard(
                        label: item.$1,
                        count: item.$2,
                        icon: item.$3,
                        accent: item.$4,
                      ),
                    ))
                .toList(),
          );
        },
      );
    });
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.accent,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text('$count', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketListPane extends StatelessWidget {
  const _TicketListPane({required this.controller});
  final AdminSupportInboxController controller;

  static const _statuses = <(String, String)>[
    ('All', 'all'),
    ('Open', 'open'),
    ('In review', 'in_review'),
    ('Waiting', 'waiting_for_user'),
    ('Resolved', 'resolved'),
    ('Closed', 'closed'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Tickets', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              Obx(() => Text('${controller.tickets.length} loaded', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary))),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.searchController,
            onChanged: controller.search,
            decoration: InputDecoration(
              hintText: 'Search subject, requester or email',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          Obx(() => Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _statuses.map((status) => _SmallFilterChip(
                      label: status.$1,
                      selected: controller.statusFilter.value == status.$2,
                      onTap: () => controller.setStatusFilter(status.$2),
                    )).toList(),
              )),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Obx(() => _CompactDropdown(
                      value: controller.categoryFilter.value,
                      hint: 'Category',
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('All categories')),
                        ...HelpTopic.all.map((topic) => DropdownMenuItem(value: topic.value, child: Text(topic.label, overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: controller.setCategoryFilter,
                    )),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(() => _CompactDropdown(
                      value: controller.priorityFilter.value,
                      hint: 'Priority',
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All priorities')),
                        DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(value: 'normal', child: Text('Normal')),
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                      ],
                      onChanged: controller.setPriorityFilter,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.tickets.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.errorMessage.value.isNotEmpty && controller.tickets.isEmpty) {
                return _InlineMessage(
                  icon: Icons.cloud_off_outlined,
                  title: 'Inbox unavailable',
                  message: controller.errorMessage.value,
                  action: () => controller.loadTickets(),
                );
              }
              if (controller.tickets.isEmpty) {
                return const _InlineMessage(
                  icon: Icons.inbox_outlined,
                  title: 'No matching tickets',
                  message: 'New requests from Clients and Engineers will appear here.',
                );
              }
              return ListView.separated(
                itemCount: controller.tickets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final ticket = controller.tickets[index];
                  return _TicketListTile(
                    ticket: ticket,
                    selected: controller.selectedTicket.value?.id == ticket.id,
                    onTap: () => controller.selectTicket(ticket),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TicketListTile extends StatelessWidget {
  const _TicketListTile({
    required this.ticket,
    required this.selected,
    required this.onTap,
  });

  final AdminSupportTicket ticket;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _priorityColor(ticket.priority);
    final date = ticket.createdAt == null
        ? 'Date unavailable'
        : DateFormat('dd MMM · hh:mm a').format(ticket.createdAt!.toLocal());
    return Material(
      color: selected ? AppColors.brandSoft.withValues(alpha: 0.75) : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.brand : theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(ticket.subject, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 6),
                  _Tag(label: ticket.priorityLabel, color: accent),
                ],
              ),
              const SizedBox(height: 6),
              Text('${ticket.requesterName} · ${ticket.accountRole.toUpperCase()}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text(ticket.categoryLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall)),
                  _Tag(label: ticket.statusLabel, color: _statusColor(ticket.status)),
                ],
              ),
              const SizedBox(height: 5),
              Text(date, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketDetailsPane extends StatelessWidget {
  const _TicketDetailsPane({required this.controller});
  final AdminSupportInboxController controller;

  static const _statusOptions = <(String, String)>[
    ('Open', 'open'),
    ('In review', 'in_review'),
    ('Waiting for user', 'waiting_for_user'),
    ('Resolved', 'resolved'),
    ('Closed', 'closed'),
  ];

  static const _priorityOptions = <(String, String)>[
    ('Low', 'low'),
    ('Normal', 'normal'),
    ('High', 'high'),
    ('Urgent', 'urgent'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final ticket = controller.selectedTicket.value;
      if (ticket == null) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: const _InlineMessage(
            icon: Icons.mark_email_unread_outlined,
            title: 'Select a support request',
            message: 'Choose a ticket from the inbox to review its details and send an update.',
          ),
        );
      }

      final created = ticket.createdAt == null
          ? 'Date unavailable'
          : DateFormat('dd MMM yyyy · hh:mm a').format(ticket.createdAt!.toLocal());
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('REQUEST DETAILS', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.papayaDark, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                        const SizedBox(height: 5),
                        Text(ticket.subject, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  _Tag(label: ticket.statusLabel, color: _statusColor(ticket.status)),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoPill(icon: Icons.person_outline_rounded, text: ticket.requesterName),
                  _InfoPill(icon: Icons.badge_outlined, text: ticket.accountRole.toUpperCase()),
                  if (ticket.requesterEmail.isNotEmpty)
                    _InfoPill(icon: Icons.email_outlined, text: ticket.requesterEmail),
                  _InfoPill(icon: Icons.calendar_today_outlined, text: created),
                ],
              ),
              const SizedBox(height: 14),
              _DetailBlock(label: 'Category', child: Text(ticket.categoryLabel)),
              if (ticket.relatedReference != null) ...[
                const SizedBox(height: 12),
                _DetailBlock(label: 'Related project / reference', child: SelectableText(ticket.relatedReference!)),
              ],
              const SizedBox(height: 12),
              _DetailBlock(
                label: 'Message from requester',
                child: SelectableText(ticket.message, style: theme.textTheme.bodyMedium?.copyWith(height: 1.55)),
              ),
              const SizedBox(height: 20),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 14),
              Text('Manage ticket', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text('Changes are saved to the support request and its status is visible to the requester.',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.4)),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 520;
                  final status = Obx(() => DropdownButtonFormField<String>(
                        value: controller.selectedStatus.value,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Ticket status'),
                        items: _statusOptions.map((item) => DropdownMenuItem(value: item.$2, child: Text(item.$1))).toList(),
                        onChanged: controller.setSelectedStatus,
                      ));
                  final priority = Obx(() => DropdownButtonFormField<String>(
                        value: controller.selectedPriority.value,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Priority'),
                        items: _priorityOptions.map((item) => DropdownMenuItem(value: item.$2, child: Text(item.$1))).toList(),
                        onChanged: controller.setSelectedPriority,
                      ));
                  if (stacked) {
                    return Column(children: [status, const SizedBox(height: 12), priority]);
                  }
                  return Row(children: [Expanded(child: status), const SizedBox(width: 12), Expanded(child: priority)]);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller.replyController,
                minLines: 3,
                maxLines: 6,
                maxLength: 3000,
                decoration: const InputDecoration(
                  labelText: 'Support response / update',
                  hintText: 'Write a clear update for the Client or Engineer…',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('This response is visible in the requester’s Help & Support history.',
                        style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                  ),
                ],
              ),
              Obx(() {
                if (controller.saveError.value.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(controller.saveError.value, style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
                );
              }),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Obx(() => FilledButton.icon(
                      onPressed: controller.isSaving.value ? null : controller.saveUpdate,
                      icon: controller.isSaving.value
                          ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined),
                      label: Text(controller.isSaving.value ? 'Saving…' : 'Save ticket update'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
                    )),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w800, letterSpacing: 0.75)),
          const SizedBox(height: 7),
          child,
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(30)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(text, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(30)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800)),
    );
  }
}

class _SmallFilterChip extends StatelessWidget {
  const _SmallFilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : theme.colorScheme.onSurface, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _CompactDropdown extends StatelessWidget {
  const _CompactDropdown({required this.value, required this.hint, required this.items, required this.onChanged});
  final String value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: hint, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      items: items,
      onChanged: (value) { if (value != null) onChanged(value); },
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.icon, required this.title, required this.message, this.action});
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.45)),
            if (action != null) ...[
              const SizedBox(height: 10),
              TextButton(onPressed: action, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

Color _statusColor(String status) => switch (status) {
      'resolved' => AppColors.success,
      'closed' => AppColors.textSecondary,
      'in_review' => AppColors.info,
      'waiting_for_user' => AppColors.warning,
      _ => AppColors.papayaDark,
    };

Color _priorityColor(String priority) => switch (priority) {
      'urgent' => AppColors.error,
      'high' => AppColors.warning,
      'low' => AppColors.textSecondary,
      _ => AppColors.info,
    };
