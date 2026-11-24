import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/controllers/admin_dashboard_controller.dart';
import 'package:permit_plans/models/admin_dashboard_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

class AdminDashboardScreen extends GetView<AdminDashboardController> {
  const AdminDashboardScreen({super.key});

  static const _destinations = <ShellDestination>[
    ShellDestination(
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard_rounded,
      label: 'Overview',
    ),
    ShellDestination(
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      label: 'Users',
    ),
    ShellDestination(
      icon: Icons.work_outline_rounded,
      selectedIcon: Icons.work_rounded,
      label: 'Projects',
    ),
    ShellDestination(
      icon: Icons.payments_outlined,
      selectedIcon: Icons.payments_rounded,
      label: 'Payments',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = controller.selectedTab.value;
      return AppShell(
        title: 'WorkBridge Admin',
        currentIndex: index,
        destinations: _destinations,
        onDestinationSelected: controller.selectTab,
        sidebarItems: [
          SidebarItem(
            icon: Icons.space_dashboard_outlined,
            label: 'Overview',
            onTap: () => controller.selectTab(0),
          ),
          SidebarItem(
            icon: Icons.people_outline_rounded,
            label: 'Users',
            onTap: () => controller.selectTab(1),
          ),
          SidebarItem(
            icon: Icons.work_outline_rounded,
            label: 'Projects & contracts',
            onTap: () => controller.selectTab(2),
          ),
          SidebarItem(
            icon: Icons.payments_outlined,
            label: 'Payment monitoring',
            onTap: () => controller.selectTab(3),
          ),
          const SidebarItem(
            icon: Icons.inbox_outlined,
            label: 'Admin Support Inbox',
            route: AppRoutes.adminSupportInbox,
          ),
          const SidebarItem(
            icon: Icons.help_outline_rounded,
            label: 'Help Center',
            route: AppRoutes.helpSupport,
          ),
        ],
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: () => controller.refreshAll(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        body: switch (index) {
          1 => _UsersPage(controller: controller),
          2 => _ProjectsPage(controller: controller),
          3 => _PaymentsPage(controller: controller),
          _ => _OverviewPage(controller: controller),
        },
      );
    });
  }
}

class _OverviewPage extends StatelessWidget {
  const _OverviewPage({required this.controller});
  final AdminDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final snapshot = controller.snapshot.value;
      if (snapshot == null && controller.isLoading.value) {
        return const _PageFrame(child: _LoadingState());
      }
      if (snapshot == null) {
        return _PageFrame(
          child: _ErrorState(
            message: controller.errorMessage.value ?? 'Dashboard data is unavailable.',
            onRetry: controller.refreshAll,
          ),
        );
      }

      final metrics = snapshot.metrics;
      final cards = <_MetricData>[
        _MetricData('Total users', snapshot.metric('total_users'), Icons.people_alt_outlined, AppColors.brand),
        _MetricData('Engineers', snapshot.metric('engineers'), Icons.engineering_outlined, AppColors.papayaDark),
        _MetricData('Clients', snapshot.metric('clients'), Icons.business_outlined, AppColors.saffronDark),
        _MetricData('Tasks created', snapshot.metric('total_tasks'), Icons.assignment_outlined, AppColors.info),
        _MetricData('Quotes to review', snapshot.metric('quotes_pending_review'), Icons.request_quote_outlined, AppColors.warning),
        _MetricData('Awaiting payment', snapshot.metric('contracts_awaiting_payment'), Icons.hourglass_top_rounded, AppColors.warning),
        _MetricData('Deliveries to review', snapshot.metric('deliveries_submitted'), Icons.fact_check_outlined, AppColors.info),
        _MetricData('Completed projects', snapshot.metric('contracts_completed'), Icons.task_alt_rounded, AppColors.success),
      ];

      return _PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeading(
              eyebrow: 'PLATFORM CONTROL CENTER',
              title: 'Good to see you, Admin',
              subtitle: 'A read-only overview of WorkBridge activity and marketplace operations.',
              trailing: controller.isRefreshing.value
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
            ),
            const SizedBox(height: 20),
            const _PaymentProviderNotice(),
            const SizedBox(height: 22),
            _SectionHeading(
              title: 'Platform overview',
              subtitle: '${snapshot.metric('new_users_7d')} new accounts in the last 7 days',
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1120
                    ? 4
                    : constraints.maxWidth >= 650
                        ? 2
                        : 1;
                final gap = 12.0;
                final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: cards
                      .map((card) => SizedBox(
                            width: width,
                            child: _MetricCard(data: card),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            _SectionHeading(
              title: 'Work pipeline',
              subtitle: 'Current marketplace records by workflow status.',
            ),
            const SizedBox(height: 12),
            _PipelinePanel(metrics: metrics),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final recentUsers = _RecentUsersPanel(users: snapshot.recentUsers);
                final recentWork = _RecentWorkPanel(items: snapshot.recentWorkItems);
                if (!wide) {
                  return Column(
                    children: [
                      recentWork,
                      const SizedBox(height: 14),
                      recentUsers,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: recentWork),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: recentUsers),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const _ReadOnlyFooter(),
          ],
        ),
      );
    });
  }
}

class _UsersPage extends StatelessWidget {
  const _UsersPage({required this.controller});
  final AdminDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => _PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PageHeading(
                eyebrow: 'ACCOUNT DIRECTORY',
                title: 'Users',
                subtitle: 'Search and inspect Client, Engineer and Admin accounts.',
              ),
              const SizedBox(height: 18),
              const _ReadOnlyNotice(
                icon: Icons.admin_panel_settings_outlined,
                text: 'Account records are view-only. Suspension, deletion and role changes are not enabled in this dashboard.',
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: controller.searchUsers,
                decoration: _searchDecoration('Search name, email or country'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(label: 'All users', value: 'all', selected: controller.userRole.value == 'all', onTap: controller.filterUsersByRole),
                  _FilterChip(label: 'Clients', value: 'client', selected: controller.userRole.value == 'client', onTap: controller.filterUsersByRole),
                  _FilterChip(label: 'Engineers', value: 'engineer', selected: controller.userRole.value == 'engineer', onTap: controller.filterUsersByRole),
                  _FilterChip(label: 'Admins', value: 'admin', selected: controller.userRole.value == 'admin', onTap: controller.filterUsersByRole),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text('${controller.users.length} accounts loaded', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary)),
                  const Spacer(),
                  if (controller.isUsersLoading.value)
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
              const SizedBox(height: 8),
              if (controller.usersError.value != null)
                _InlineError(message: controller.usersError.value!, onRetry: controller.loadUsers)
              else if (controller.isUsersLoading.value && controller.users.isEmpty)
                const _LoadingState()
              else if (controller.users.isEmpty)
                const _EmptyState(icon: Icons.person_search_outlined, title: 'No matching accounts', detail: 'Try a different search term or role filter.')
              else
                ...controller.users.map((user) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _UserRow(user: user),
                    )),
              const SizedBox(height: 18),
              const _ReadOnlyFooter(),
            ],
          ),
        ));
  }
}

class _ProjectsPage extends StatelessWidget {
  const _ProjectsPage({required this.controller});
  final AdminDashboardController controller;

  static const _filters = <(String, String)>[
    ('All', 'all'),
    ('Invitations', 'invitation_pending'),
    ('Negotiating', 'negotiating'),
    ('Awaiting payment', 'awaiting_payment'),
    ('Active', 'in_progress'),
    ('Submitted', 'submitted'),
    ('Revision', 'revision_requested'),
    ('Completed', 'completed'),
    ('Disputed', 'disputed'),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() => _PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PageHeading(
                eyebrow: 'MARKETPLACE OPERATIONS',
                title: 'Projects & contracts',
                subtitle: 'Monitor assigned tasks, quote progress and contract workflow states.',
              ),
              const SizedBox(height: 18),
              TextField(
                onChanged: controller.searchWorkItems,
                decoration: _searchDecoration('Search task, category, Client or Engineer'),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters
                      .map((filter) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: filter.$1,
                              value: filter.$2,
                              selected: controller.workStatus.value == filter.$2,
                              onTap: controller.filterWorkItemsByStatus,
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),
              if (controller.workItemsError.value != null)
                _InlineError(message: controller.workItemsError.value!, onRetry: controller.loadWorkItems)
              else if (controller.isWorkItemsLoading.value && controller.workItems.isEmpty)
                const _LoadingState()
              else if (controller.workItems.isEmpty)
                const _EmptyState(icon: Icons.work_off_outlined, title: 'No matching projects', detail: 'No marketplace tasks match this search and status.')
              else ...controller.workItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _WorkItemRow(item: item, showContractAmount: true),
                  )),
              const SizedBox(height: 16),
              const _ReadOnlyFooter(),
            ],
          ),
        ));
  }
}

class _PaymentsPage extends StatelessWidget {
  const _PaymentsPage({required this.controller});
  final AdminDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final snapshot = controller.snapshot.value;
      final contractItems = controller.workItems.where((item) => item.hasContract).toList();
      return _PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PageHeading(
              eyebrow: 'FINANCIAL OPERATIONS',
              title: 'Payment monitoring',
              subtitle: 'Read-only contract payment-stage visibility. This is not a transaction ledger.',
            ),
            const SizedBox(height: 18),
            const _PaymentProviderNotice(),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  _MetricData('Awaiting payment', snapshot?.metric('contracts_awaiting_payment') ?? 0, Icons.hourglass_top_rounded, AppColors.warning),
                  _MetricData('Marked funded / started', snapshot?.metric('contracts_active') ?? 0, Icons.play_circle_outline_rounded, AppColors.info),
                  _MetricData('Completed contracts', snapshot?.metric('contracts_completed') ?? 0, Icons.task_alt_rounded, AppColors.success),
                ];
                final columns = constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 600 ? 2 : 1;
                final gap = 12.0;
                final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: cards.map((data) => SizedBox(width: width, child: _MetricCard(data: data))).toList(),
                );
              },
            ),
            const SizedBox(height: 22),
            const _SectionHeading(
              title: 'Contract value monitor',
              subtitle: 'Amounts below are agreed contract values, not proof of funds received or payouts sent.',
            ),
            const SizedBox(height: 12),
            if (controller.workItemsError.value != null)
              _InlineError(message: controller.workItemsError.value!, onRetry: controller.loadWorkItems)
            else if (controller.isWorkItemsLoading.value && contractItems.isEmpty)
              const _LoadingState()
            else if (contractItems.isEmpty)
              const _EmptyState(icon: Icons.receipt_long_outlined, title: 'No contracts to monitor yet', detail: 'Confirmed contracts will appear here with their current workflow status.')
            else ...contractItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _WorkItemRow(item: item, showContractAmount: true),
                )),
            const SizedBox(height: 14),
            const _ReadOnlyFooter(),
          ],
        ),
      );
    });
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.eyebrow, required this.title, required this.subtitle, this.trailing});
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.papayaDark, fontWeight: FontWeight.w800, letterSpacing: 1.35)),
              const SizedBox(height: 7),
              Text(title, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 5),
              Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.45)),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _MetricData {
  const _MetricData(this.title, this.value, this.icon, this.color);
  final String title;
  final int value;
  final IconData icon;
  final Color color;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});
  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: data.color.withValues(alpha: 0.11), borderRadius: BorderRadius.circular(13)),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(NumberFormat.compact().format(data.value), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelinePanel extends StatelessWidget {
  const _PipelinePanel({required this.metrics});
  final Map<String, int> metrics;

  @override
  Widget build(BuildContext context) {
    final items = <_PipelineData>[
      _PipelineData('Invitations pending', metrics['pending_invitations'] ?? 0, AppColors.warning),
      _PipelineData('Quotes negotiating', metrics['quotes_negotiating'] ?? 0, AppColors.saffronDark),
      _PipelineData('Active contracts', metrics['contracts_active'] ?? 0, AppColors.info),
      _PipelineData('Deliveries submitted', metrics['deliveries_submitted'] ?? 0, AppColors.papayaDark),
      _PipelineData('Revisions requested', metrics['contracts_revision_requested'] ?? 0, AppColors.warning),
      _PipelineData('Completed', metrics['contracts_completed'] ?? 0, AppColors.success),
      _PipelineData('Needs attention', metrics['contracts_attention'] ?? 0, AppColors.error),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: AppRadii.card, border: Border.all(color: AppColors.outlineVariant)),
      child: Wrap(
        spacing: 22,
        runSpacing: 16,
        children: items.map((item) => SizedBox(
          width: 175,
          child: Row(
            children: [
              Container(width: 9, height: 9, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
              const SizedBox(width: 9),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.title, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text('${item.value}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              ])),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

class _PipelineData {
  const _PipelineData(this.title, this.value, this.color);
  final String title;
  final int value;
  final Color color;
}

class _PaymentProviderNotice extends StatelessWidget {
  const _PaymentProviderNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.saffron.withValues(alpha: 0.65)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warningInk),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Payment provider is not connected. This area shows contract workflow states and agreed values only; it does not show captured payments, escrow balances, refunds or payouts.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warningInk, height: 1.45, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: AppColors.infoSoft, borderRadius: AppRadii.input),
      child: Row(children: [Icon(icon, color: AppColors.info), const SizedBox(width: 10), Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink, height: 1.4)))]),
    );
  }
}

class _ReadOnlyFooter extends StatelessWidget {
  const _ReadOnlyFooter();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.shield_outlined, size: 17, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Admin reporting is read-only. Changes to roles, user access, contracts and money movement require separately authorized backend workflows.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, height: 1.45),
          ),
        ),
      ],
    );
  }
}

class _RecentUsersPanel extends StatelessWidget {
  const _RecentUsersPanel({required this.users});
  final List<AdminUserRecord> users;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Recently joined',
      subtitle: 'Latest registered accounts',
      child: users.isEmpty
          ? const Text('No user records yet.')
          : Column(children: users.map((user) => _CompactUserRow(user: user)).toList()),
    );
  }
}

class _RecentWorkPanel extends StatelessWidget {
  const _RecentWorkPanel({required this.items});
  final List<AdminWorkItemRecord> items;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Recent marketplace activity',
      subtitle: 'Latest assigned tasks and contract progress',
      child: items.isEmpty
          ? const Text('No marketplace activity yet.')
          : Column(children: items.take(8).map((item) => _CompactWorkRow(item: item)).toList()),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: AppRadii.card, border: Border.all(color: AppColors.outlineVariant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _CompactUserRow extends StatelessWidget {
  const _CompactUserRow({required this.user});
  final AdminUserRecord user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        _InitialAvatar(label: user.fullName),
        const SizedBox(width: 9),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
          Text(user.role.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, letterSpacing: 0.5)),
        ])),
        Text(_shortDate(user.createdAt), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textTertiary)),
      ]),
    );
  }
}

class _CompactWorkRow extends StatelessWidget {
  const _CompactWorkRow({required this.item});
  final AdminWorkItemRecord item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.work_outline_rounded, color: AppColors.brand, size: 19)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.taskTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
          Text('${item.clientName} · ${item.engineerName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
        ])),
        const SizedBox(width: 8),
        _StatusPill(status: item.effectiveStatus),
      ]),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user});
  final AdminUserRecord user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: AppRadii.card, border: Border.all(color: AppColors.outlineVariant)),
      child: Row(
        children: [
          _InitialAvatar(label: user.fullName, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(user.email.isEmpty ? 'No email available' : user.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text([if (user.countryName != null) user.countryName!, 'Joined ${_shortDate(user.createdAt)}'].join(' · '), style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _RolePill(role: user.role),
              const SizedBox(height: 6),
              Text(user.profileCompleted ? 'Profile complete' : 'Profile incomplete', style: theme.textTheme.labelSmall?.copyWith(color: user.profileCompleted ? AppColors.success : AppColors.warning)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkItemRow extends StatelessWidget {
  const _WorkItemRow({required this.item, required this.showContractAmount});
  final AdminWorkItemRecord item;
  final bool showContractAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: AppRadii.card, border: Border.all(color: AppColors.outlineVariant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.taskTitle, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(item.category, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            ])),
            const SizedBox(width: 8),
            _StatusPill(status: item.effectiveStatus),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _MetaItem(icon: Icons.person_outline_rounded, label: 'Client', value: item.clientName),
              _MetaItem(icon: Icons.engineering_outlined, label: 'Engineer', value: item.engineerName),
              _MetaItem(icon: Icons.update_rounded, label: 'Updated', value: _shortDate(item.updatedAt)),
              if (item.quoteStatus != null) _MetaItem(icon: Icons.request_quote_outlined, label: 'Quote', value: _humanize(item.quoteStatus!)),
              if (showContractAmount && item.hasContract) _MetaItem(icon: Icons.receipt_long_outlined, label: 'Agreed contract value', value: item.formattedAgreedAmount),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: AppColors.textTertiary),
      const SizedBox(width: 5),
      Text('$label: ', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textTertiary)),
      Text(value, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
    ]);
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.label, this.size = 36});
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: AppColors.brandSoft, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initial, style: TextStyle(color: AppColors.brand, fontSize: size * 0.42, fontWeight: FontWeight.w800)),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      'engineer' => AppColors.papayaDark,
      'admin' => AppColors.brand,
      _ => AppColors.info,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30)),
      child: Text(role.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'completed' || 'approved' => AppColors.success,
      'funded' || 'in_progress' => AppColors.info,
      'awaiting_payment' || 'pending' || 'invitation_pending' => AppColors.warning,
      'submitted' || 'quote_received' || 'pending_client_review' => AppColors.papayaDark,
      'revision_requested' || 'disputed' || 'refund_pending' => AppColors.error,
      'cancelled' || 'rejected' || 'refunded' => AppColors.textSecondary,
      _ => AppColors.brand,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30)),
      child: Text(_humanize(status), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.value, required this.selected, required this.onTap});
  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(value),
      selectedColor: AppColors.brandSoft,
      labelStyle: TextStyle(color: selected ? AppColors.brand : AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 12),
      side: BorderSide(color: selected ? AppColors.brandTint : AppColors.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      showCheckmark: false,
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(padding: EdgeInsets.all(44), child: Center(child: CircularProgressIndicator()));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.detail});
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: AppRadii.card, border: Border.all(color: AppColors.outlineVariant)),
      child: Column(children: [
        Icon(icon, size: 34, color: AppColors.textTertiary),
        const SizedBox(height: 10),
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(detail, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(24), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.cloud_off_outlined, size: 42, color: AppColors.error),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
    ])));
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: AppColors.errorSoft, borderRadius: AppRadii.input),
      child: Row(children: [Expanded(child: Text(message, style: const TextStyle(color: AppColors.error))), TextButton(onPressed: onRetry, child: const Text('Retry'))]),
    );
  }
}

InputDecoration _searchDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: const Icon(Icons.search_rounded),
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(borderRadius: AppRadii.input, borderSide: const BorderSide(color: AppColors.outlineVariant)),
    enabledBorder: OutlineInputBorder(borderRadius: AppRadii.input, borderSide: const BorderSide(color: AppColors.outlineVariant)),
    focusedBorder: OutlineInputBorder(borderRadius: AppRadii.input, borderSide: const BorderSide(color: AppColors.brand, width: 1.4)),
  );
}

String _humanize(String value) => value.replaceAll('_', ' ').split(' ').map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}').join(' ');

String _shortDate(DateTime? value) => value == null ? '—' : DateFormat('dd MMM yyyy').format(value.toLocal());
