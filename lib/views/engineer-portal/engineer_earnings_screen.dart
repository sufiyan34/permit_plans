import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/controllers/engineer_earnings_controller.dart';
import 'package:permit_plans/models/engineer_earnings_currency_summary.dart';
import 'package:permit_plans/models/engineer_project_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

/// Screen 26 — Engineer earnings overview.
///
/// Figures are derived from completed contract snapshots. This screen does not
/// represent provider settlement, an available wallet balance, or a payout.
class EngineerEarningsScreen extends StatelessWidget {
  const EngineerEarningsScreen({super.key});

  static const double _wideBreakpoint = 1040;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EngineerEarningsController>();

    return AppShell(
      title: 'Earnings',
      currentIndex: 6,
      destinations: const [
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
          selectedIcon: Icons.folder_rounded,
          label: 'Projects',
          route: AppRoutes.engineerProjects,
        ),
        ShellDestination(
          icon: Icons.rate_review_outlined,
          selectedIcon: Icons.rate_review_rounded,
          label: 'Revisions',
          route: AppRoutes.engineerRevisionRequests,
        ),
        ShellDestination(
          icon: Icons.chat_bubble_outline_rounded,
          selectedIcon: Icons.chat_bubble_rounded,
          label: 'Messages',
          route: AppRoutes.projectChats,
        ),
        ShellDestination(
          icon: Icons.account_balance_wallet_outlined,
          selectedIcon: Icons.account_balance_wallet_rounded,
          label: 'Earnings',
          route: AppRoutes.engineerEarnings,
        ),
      ],
      sidebarItems: const [
        SidebarItem(
          icon: Icons.rate_review_outlined,
          label: 'Revision requests',
          route: AppRoutes.engineerRevisionRequests,
        ),
        SidebarItem(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Earnings',
          route: AppRoutes.engineerEarnings,
        ),
        SidebarItem(
          icon: Icons.payments_outlined,
          label: 'Payout management',
          route: AppRoutes.engineerPayoutManagement,
        ),
        SidebarItem(icon: Icons.person_outline_rounded, label: 'My profile'),
        SidebarItem(icon: Icons.settings_outlined, label: 'Settings'),
        SidebarItem(icon: Icons.help_outline_rounded, label: 'Help & support'),
      ],
      actions: [
        IconButton(
          tooltip: 'Payout management',
          onPressed: () => Get.toNamed<void>(AppRoutes.engineerPayoutManagement),
          icon: const Icon(Icons.payments_outlined),
        ),
        IconButton(
          tooltip: 'Refresh earnings',
          onPressed: controller.refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      body: _EngineerEarningsBody(
        controller: controller,
        wideBreakpoint: _wideBreakpoint,
      ),
    );
  }
}

class _EngineerEarningsBody extends StatelessWidget {
  const _EngineerEarningsBody({
    required this.controller,
    required this.wideBreakpoint,
  });

  final EngineerEarningsController controller;
  final double wideBreakpoint;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allProjects = controller.projects;
      final isInitialLoading = controller.isLoading.value && allProjects.isEmpty;
      final error = controller.errorMessage.value;

      if (isInitialLoading) return const _EarningsLoadingState();
      if (allProjects.isEmpty && error.isNotEmpty) {
        return _EarningsErrorState(
          message: error,
          onRetry: () => controller.loadEarnings(),
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= wideBreakpoint;
          final horizontalPadding = isWide ? 34.0 : 18.0;

          return RefreshIndicator(
            onRefresh: controller.refresh,
            color: AppColors.papaya,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                isWide ? 28 : 20,
                horizontalPadding,
                40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _EarningsHeader(
                        isWide: isWide,
                        updatedAt: controller.lastUpdatedAt.value,
                        onRefresh: controller.refresh,
                        isRefreshing: controller.isRefreshing.value,
                      ),
                      const SizedBox(height: 22),
                      const _SettlementNotice(),
                      const SizedBox(height: 22),
                      _TopMetrics(
                        completedCount: controller.completedProjectCount,
                        activeCount: controller.activeProjectCount,
                        awaitingFundingCount: controller.awaitingFundingCount,
                        isWide: isWide,
                      ),
                      const SizedBox(height: 28),
                      _SectionHeading(
                        title: 'Estimated earnings by currency',
                        subtitle:
                            'Only approved, completed contracts are included. Currencies are kept separate.',
                      ),
                      const SizedBox(height: 14),
                      if (controller.currencySummaries.isEmpty)
                        const _NoEarningsState()
                      else
                        _CurrencySummaryGrid(
                          summaries: controller.currencySummaries.values
                              .toList(growable: false),
                          isWide: isWide,
                        ),
                      const SizedBox(height: 30),
                      _SectionHeading(
                        title: 'Completed project earnings',
                        subtitle:
                            'Gross contract amount less the commission recorded in each confirmed contract.',
                        trailing: Text(
                          '${controller.completedProjectCount} projects',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SearchField(controller: controller),
                      const SizedBox(height: 14),
                      if (controller.filteredCompletedProjects.isEmpty)
                        _NoMatchingEarnings(
                          hasCompletedProjects:
                              controller.completedProjectCount > 0,
                        )
                      else
                        ...controller.filteredCompletedProjects.map(
                          (project) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CompletedProjectCard(
                              project: project,
                              onViewProjects: () => Get.toNamed<void>(
                                AppRoutes.engineerProjects,
                              ),
                            ),
                          ),
                        ),
                      if (controller.projects.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        _ActivityNote(
                          activeCount: controller.activeProjectCount,
                          awaitingFundingCount:
                              controller.awaitingFundingCount,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _EarningsHeader extends StatelessWidget {
  const _EarningsHeader({
    required this.isWide,
    required this.updatedAt,
    required this.onRefresh,
    required this.isRefreshing,
  });

  final bool isWide;
  final DateTime? updatedAt;
  final VoidCallback onRefresh;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ENGINEER FINANCES',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.papayaDark,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Your earnings',
          style: (isWide ? theme.textTheme.headlineMedium : theme.textTheme.headlineSmall)
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          'Track the value of your completed WorkBridge projects.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    if (!isWide) return title;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: title),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (updatedAt != null)
              Text(
                'Updated ${DateFormat('dd MMM, h:mm a').format(updatedAt!.toLocal())}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: isRefreshing ? null : onRefresh,
              icon: isRefreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettlementNotice extends StatelessWidget {
  const _SettlementNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.saffronSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.saffron.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.saffron.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.saffronDark,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated earnings — payouts are not connected yet',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.warningInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'These figures come from completed contract snapshots. They are not a paid or withdrawable balance. WorkBridge will show settled payouts here after an approved payment provider and its payout flow are connected.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.warningInk,
                    height: 1.5,
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

class _TopMetrics extends StatelessWidget {
  const _TopMetrics({
    required this.completedCount,
    required this.activeCount,
    required this.awaitingFundingCount,
    required this.isWide,
  });

  final int completedCount;
  final int activeCount;
  final int awaitingFundingCount;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricData(
        label: 'Completed projects',
        value: completedCount.toString(),
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.success,
        tint: AppColors.successSoft,
      ),
      _MetricData(
        label: 'Active projects',
        value: activeCount.toString(),
        icon: Icons.work_outline_rounded,
        color: AppColors.brand,
        tint: AppColors.brandSoft,
      ),
      _MetricData(
        label: 'Awaiting funding',
        value: awaitingFundingCount.toString(),
        icon: Icons.hourglass_empty_rounded,
        color: AppColors.warning,
        tint: AppColors.warningSoft,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 12.0;
        final columns = isWide ? 3 : (constraints.maxWidth >= 600 ? 3 : 1);
        final width = (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _MetricCard(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.tint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color tint;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.item});

  final _MetricData item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  item.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          trailing!,
        ],
      ],
    );
  }
}

class _CurrencySummaryGrid extends StatelessWidget {
  const _CurrencySummaryGrid({
    required this.summaries,
    required this.isWide,
  });

  final List<EngineerEarningsCurrencySummary> summaries;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = isWide ? 2 : (constraints.maxWidth >= 650 ? 2 : 1);
        const gap = 14.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final summary in summaries)
              SizedBox(
                width: width,
                child: _CurrencySummaryCard(summary: summary),
              ),
          ],
        );
      },
    );
  }
}

class _CurrencySummaryCard extends StatelessWidget {
  const _CurrencySummaryCard({required this.summary});

  final EngineerEarningsCurrencySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  summary.currency,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${summary.projectCount} ${summary.projectCount == 1 ? 'project' : 'projects'}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            summary.formattedEngineerNet,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Estimated Engineer net',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 13),
          _AmountRow(label: 'Gross contract value', value: summary.formattedGross),
          const SizedBox(height: 9),
          _AmountRow(
            label: 'WorkBridge commission',
            value: '−${summary.formattedPlatformFee}',
            valueColor: AppColors.papayaDark,
          ),
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Estimated net total',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  summary.formattedEngineerNet,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w900,
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

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: style?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Text(
          value,
          style: style?.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final EngineerEarningsController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller.searchController,
      onChanged: controller.updateSearch,
      decoration: InputDecoration(
        hintText: 'Search completed projects or Clients...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: Obx(
          () => controller.searchQuery.value.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    controller.searchController.clear();
                    controller.updateSearch('');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
    );
  }
}

class _CompletedProjectCard extends StatelessWidget {
  const _CompletedProjectCard({
    required this.project,
    required this.onViewProjects,
  });

  final EngineerProjectModel project;
  final VoidCallback onViewProjects;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.sizeOf(context).width < 620;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.taskTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${project.clientDisplayName} · ${project.taskCategory}',
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
              _StatusPill(label: 'Completed'),
            ],
          ),
          const SizedBox(height: 17),
          if (isNarrow)
            Column(
              children: [
                _ProjectAmountCell(
                  label: 'Gross amount',
                  value: project.formattedAmount,
                ),
                const SizedBox(height: 12),
                _ProjectAmountCell(
                  label: 'Commission (${project.commissionPercent}%)',
                  value: '−${project.formattedPlatformFee}',
                  color: AppColors.papayaDark,
                ),
                const SizedBox(height: 12),
                _ProjectAmountCell(
                  label: 'Estimated net',
                  value: project.formattedEngineerNet,
                  color: AppColors.success,
                  emphasize: true,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _ProjectAmountCell(
                    label: 'Gross amount',
                    value: project.formattedAmount,
                  ),
                ),
                Expanded(
                  child: _ProjectAmountCell(
                    label: 'Commission (${project.commissionPercent}%)',
                    value: '−${project.formattedPlatformFee}',
                    color: AppColors.papayaDark,
                  ),
                ),
                Expanded(
                  child: _ProjectAmountCell(
                    label: 'Estimated net',
                    value: project.formattedEngineerNet,
                    color: AppColors.success,
                    emphasize: true,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Contract #${project.contractShortId}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onViewProjects,
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Project workspace'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectAmountCell extends StatelessWidget {
  const _ProjectAmountCell({
    required this.label,
    required this.value,
    this.color,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color ?? AppColors.textPrimary,
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _NoEarningsState extends StatelessWidget {
  const _NoEarningsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppColors.brandSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.brand,
              size: 27,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'No completed earnings yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            'When a Client approves your submitted work, that completed contract will appear here with its commission and estimated net amount.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _NoMatchingEarnings extends StatelessWidget {
  const _NoMatchingEarnings({required this.hasCompletedProjects});

  final bool hasCompletedProjects;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          hasCompletedProjects
              ? 'No completed projects match your search.'
              : 'Completed project earnings will appear here.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ),
    );
  }
}

class _ActivityNote extends StatelessWidget {
  const _ActivityNote({
    required this.activeCount,
    required this.awaitingFundingCount,
  });

  final int activeCount;
  final int awaitingFundingCount;

  @override
  Widget build(BuildContext context) {
    if (activeCount == 0 && awaitingFundingCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insights_outlined, color: AppColors.info),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'You also have $activeCount active ${activeCount == 1 ? 'project' : 'projects'} and $awaitingFundingCount awaiting funding. These contracts are not included in completed earnings yet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.info,
                    height: 1.45,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsLoadingState extends StatelessWidget {
  const _EarningsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(color: AppColors.papaya),
      ),
    );
  }
}

class _EarningsErrorState extends StatelessWidget {
  const _EarningsErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.error,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                'Earnings could not load',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
