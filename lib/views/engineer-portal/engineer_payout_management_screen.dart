import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/controllers/engineer_payout_management_controller.dart';
import 'package:permit_plans/models/engineer_earnings_currency_summary.dart';
import 'package:permit_plans/models/engineer_project_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

/// Screen 27 — payout management placeholder until a marketplace payout
/// provider is formally approved and integrated.
///
/// This screen intentionally does not store payout destination credentials,
/// create withdrawal requests, or display contract earnings as withdrawable.
class EngineerPayoutManagementScreen extends StatelessWidget {
  const EngineerPayoutManagementScreen({super.key});

  static const double _wideBreakpoint = 1040;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EngineerPayoutManagementController>();

    return AppShell(
      title: 'Payout management',
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
          tooltip: 'Refresh payout overview',
          onPressed: controller.refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: 8),
      ],
      body: _PayoutManagementBody(
        controller: controller,
        wideBreakpoint: _wideBreakpoint,
      ),
    );
  }
}

class _PayoutManagementBody extends StatelessWidget {
  const _PayoutManagementBody({
    required this.controller,
    required this.wideBreakpoint,
  });

  final EngineerPayoutManagementController controller;
  final double wideBreakpoint;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final projects = controller.projects;
      final isInitialLoading = controller.isLoading.value && projects.isEmpty;
      final error = controller.errorMessage.value;

      if (isInitialLoading) return const _PayoutLoadingState();
      if (projects.isEmpty && error.isNotEmpty) {
        return _PayoutErrorState(
          message: error,
          onRetry: controller.loadOverview,
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
                42,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PayoutHeader(
                        isWide: isWide,
                        lastUpdatedAt: controller.lastUpdatedAt.value,
                        isRefreshing: controller.isRefreshing.value,
                        onRefresh: controller.refresh,
                      ),
                      const SizedBox(height: 22),
                      const _ProviderPendingBanner(),
                      const SizedBox(height: 22),
                      _OverviewMetrics(
                        completedProjects: controller.completedProjectCount,
                        activeProjects: controller.activeProjectCount,
                        awaitingFunding: controller.awaitingFundingCount,
                        isWide: isWide,
                      ),
                      const SizedBox(height: 28),
                      _SectionHeading(
                        title: 'Estimated net by currency',
                        subtitle:
                            'Based on completed contract snapshots. Each currency is shown separately; these amounts are not confirmed withdrawable funds.',
                      ),
                      const SizedBox(height: 14),
                      if (controller.currencySummaries.isEmpty)
                        const _NoCompletedEarningsCard()
                      else
                        _CurrencySummaryWrap(
                          summaries: controller.currencySummaries.values
                              .toList(growable: false),
                          isWide: isWide,
                        ),
                      const SizedBox(height: 26),
                      _PayoutActionsRow(isWide: isWide),
                      const SizedBox(height: 26),
                      _SectionHeading(
                        title: 'Payout destination',
                        subtitle:
                            'A payout destination will be connected through an approved provider when marketplace onboarding is complete.',
                      ),
                      const SizedBox(height: 14),
                      const _PayoutDestinationCard(),
                      const SizedBox(height: 26),
                      _SectionHeading(
                        title: 'Payout history',
                        subtitle:
                            'Provider-confirmed transfers and their references will appear here after payout integration.',
                      ),
                      const SizedBox(height: 14),
                      const _PayoutHistoryEmptyCard(),
                      const SizedBox(height: 26),
                      _SectionHeading(
                        title: 'Completed projects included in estimates',
                        subtitle:
                            'Only projects with a completed contract status are included in the estimates above.',
                        trailing: Text(
                          '${controller.completedProjectCount} projects',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (controller.completedProjects.isEmpty)
                        const _NoCompletedEarningsCard(compact: true)
                      else
                        ...controller.completedProjects.map(
                          (project) => Padding(
                            padding: const EdgeInsets.only(bottom: 11),
                            child: _CompletedProjectPayoutRow(project: project),
                          ),
                        ),
                      const SizedBox(height: 8),
                      const _PayoutSafetyNote(),
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

class _PayoutHeader extends StatelessWidget {
  const _PayoutHeader({
    required this.isWide,
    required this.lastUpdatedAt,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final bool isWide;
  final DateTime? lastUpdatedAt;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intro = Column(
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
        const SizedBox(height: 6),
        Text(
          'Payout management',
          style: (isWide ? theme.textTheme.headlineMedium : theme.textTheme.headlineSmall)
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Review your estimated earnings and payout setup status.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    final updated = lastUpdatedAt == null
        ? 'Not refreshed yet'
        : 'Updated ${DateFormat('dd MMM, hh:mm a').format(lastUpdatedAt!.toLocal())}';

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          intro,
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  updated,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: isRefreshing ? null : onRefresh,
                icon: isRefreshing
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: intro),
        const SizedBox(width: 18),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              updated,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 5),
            OutlinedButton.icon(
              onPressed: isRefreshing ? null : onRefresh,
              icon: isRefreshing
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Refresh overview'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProviderPendingBanner extends StatelessWidget {
  const _ProviderPendingBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.pending_actions_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payout provider setup is pending',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.warningInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'WorkBridge has not connected an approved marketplace payout provider yet. Withdrawals and provider-confirmed payout balances are therefore unavailable.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.warningInk,
                    height: 1.45,
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

class _OverviewMetrics extends StatelessWidget {
  const _OverviewMetrics({
    required this.completedProjects,
    required this.activeProjects,
    required this.awaitingFunding,
    required this.isWide,
  });

  final int completedProjects;
  final int activeProjects;
  final int awaitingFunding;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = isWide ? 3 : (constraints.maxWidth >= 620 ? 3 : 1);
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: width,
              child: _MetricCard(
                icon: Icons.task_alt_rounded,
                label: 'Completed projects',
                value: completedProjects.toString(),
                color: AppColors.success,
                footnote: 'Included in estimates',
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                icon: Icons.work_outline_rounded,
                label: 'Active projects',
                value: activeProjects.toString(),
                color: AppColors.info,
                footnote: 'Not included in completed earnings',
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                icon: Icons.hourglass_bottom_rounded,
                label: 'Awaiting funding',
                value: awaitingFunding.toString(),
                color: AppColors.warning,
                footnote: 'Not available for payout',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.footnote,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            footnote,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              height: 1.35,
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

class _CurrencySummaryWrap extends StatelessWidget {
  const _CurrencySummaryWrap({
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
        const gap = 13.0;
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
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(9),
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
                '${summary.projectCount} completed',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            summary.formattedEngineerNet,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.brand,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'Estimated engineer net',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 15),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _AmountLine(label: 'Gross contract value', value: summary.formattedGross),
          const SizedBox(height: 7),
          _AmountLine(
            label: 'Recorded platform commission',
            value: '−${summary.formattedPlatformFee}',
          ),
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warningSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Settlement and withdrawal are not available yet.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.warningInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountLine extends StatelessWidget {
  const _AmountLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PayoutActionsRow extends StatelessWidget {
  const _PayoutActionsRow({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final providerCard = _ActionCard(
      icon: Icons.account_balance_outlined,
      title: 'Payout provider',
      description:
          'Connect a provider-managed payout account after WorkBridge completes provider approval.',
      actionLabel: 'Provider setup pending',
      onAction: null,
    );
    final withdrawalCard = _ActionCard(
      icon: Icons.send_to_mobile_outlined,
      title: 'Request a withdrawal',
      description:
          'Withdrawal requests will become available after real provider settlement and an auditable payable balance are connected.',
      actionLabel: 'Withdrawals unavailable',
      onAction: null,
    );

    if (!isWide) {
      return Column(
        children: [
          providerCard,
          const SizedBox(height: 12),
          withdrawalCard,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: providerCard),
        const SizedBox(width: 14),
        Expanded(child: withdrawalCard),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.brand, size: 23),
          const SizedBox(height: 13),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onAction,
              icon: const Icon(Icons.lock_outline_rounded, size: 17),
              label: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutDestinationCard extends StatelessWidget {
  const _PayoutDestinationCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 560;
          final detail = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No payout destination connected',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'When a supported provider is approved, you will complete payout onboarding in that provider’s secure flow.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final badge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.warningSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Not configured',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.warningInk,
                fontWeight: FontWeight.w800,
              ),
            ),
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [detail, const SizedBox(height: 14), badge],
            );
          }
          return Row(
            children: [Expanded(child: detail), const SizedBox(width: 16), badge],
          );
        },
      ),
    );
  }
}

class _PayoutHistoryEmptyCard extends StatelessWidget {
  const _PayoutHistoryEmptyCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppColors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.textSecondary,
              size: 26,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'No payout transfers yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 470),
            child: Text(
              'This history will show provider-confirmed payout references, amounts, currencies and statuses once payouts are integrated.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedProjectPayoutRow extends StatelessWidget {
  const _CompletedProjectPayoutRow({required this.project});

  final EngineerProjectModel project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projectIdentity = Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.successSoft,
            borderRadius: BorderRadius.circular(12),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${project.clientDisplayName} · #${project.contractShortId}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final amount = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          project.formattedEngineerNet,
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppColors.brand,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Estimated net · ${project.currency}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 520;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    projectIdentity,
                    const SizedBox(height: 13),
                    Align(alignment: Alignment.centerRight, child: amount),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: projectIdentity),
                    const SizedBox(width: 18),
                    amount,
                  ],
                ),
        );
      },
    );
  }
}

class _NoCompletedEarningsCard extends StatelessWidget {
  const _NoCompletedEarningsCard({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No completed project earnings to display yet. Approved and completed contracts will appear here.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutSafetyNote extends StatelessWidget {
  const _PayoutSafetyNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'These figures are derived from completed contract snapshots, not from a provider settlement ledger. No bank account, card number, CVV or payout credential is collected or stored by this screen.',
              style: theme.textTheme.bodySmall?.copyWith(
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

class _PayoutLoadingState extends StatelessWidget {
  const _PayoutLoadingState();

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

class _PayoutErrorState extends StatelessWidget {
  const _PayoutErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 42,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 12),
              Text(
                'Payout overview could not load',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 15),
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
