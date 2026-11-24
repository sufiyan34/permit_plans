import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/controllers/engineer_projects_controller.dart';
import 'package:permit_plans/models/engineer_project_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

/// Screen 20 — the Engineer's read-only overview of confirmed contract work.
/// Project/payment state is displayed from Supabase; this screen never changes it.
class EngineerProjectsScreen extends StatelessWidget {
  const EngineerProjectsScreen({super.key});

  static const double _wideBreakpoint = 1080;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EngineerProjectsController>();

    return AppShell(
      title: 'Project workspace',
      currentIndex: 3,
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
        SidebarItem(icon: Icons.person_outline_rounded, label: 'My profile'),
        SidebarItem(icon: Icons.settings_outlined, label: 'Settings'),
        SidebarItem(icon: Icons.help_outline_rounded, label: 'Help & support'),
      ],
      actions: [
        IconButton(
          tooltip: 'Refresh projects',
          onPressed: controller.refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      body: _EngineerProjectsBody(
        controller: controller,
        wideBreakpoint: _wideBreakpoint,
      ),
    );
  }
}

class _EngineerProjectsBody extends StatelessWidget {
  const _EngineerProjectsBody({
    required this.controller,
    required this.wideBreakpoint,
  });

  final EngineerProjectsController controller;
  final double wideBreakpoint;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final projects = controller.filteredProjects;
      final allProjects = controller.projects;
      final isInitialLoading = controller.isLoading.value && allProjects.isEmpty;
      final error = controller.errorMessage.value;

      if (isInitialLoading) return const _ProjectsLoadingState();
      if (allProjects.isEmpty && error.isNotEmpty) {
        return _ProjectsErrorState(
          message: error,
          onRetry: () => controller.loadProjects(),
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= wideBreakpoint;
          final horizontalPadding = isWide ? 32.0 : 18.0;

          return RefreshIndicator(
            onRefresh: controller.refresh,
            color: AppColors.papaya,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                isWide ? 28 : 20,
                horizontalPadding,
                36,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PageHeading(
                        projectCount: allProjects.length,
                        isRefreshing: controller.isRefreshing.value,
                      ),
                      const SizedBox(height: 22),
                      _ProjectStats(controller: controller, isWide: isWide),
                      const SizedBox(height: 26),
                      _FilterBar(controller: controller),
                      const SizedBox(height: 16),
                      if (error.isNotEmpty)
                        _InlineWarning(message: error),
                      if (projects.isEmpty)
                        _NoFilteredProjects(
                          hasAnyProjects: allProjects.isNotEmpty,
                          selectedFilter: controller.selectedFilter.value,
                          onShowAll: () =>
                              controller.selectFilter('All projects'),
                        )
                      else if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _ProjectList(
                                projects: projects,
                                controller: controller,
                                compact: false,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 6,
                              child: _ProjectDetails(
                                project: controller.selectedProject!,
                                isWide: true,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _ProjectList(
                          projects: projects,
                          controller: controller,
                          compact: true,
                        ),
                        if (controller.selectedProject != null) ...[
                          const SizedBox(height: 20),
                          _ProjectDetails(
                            project: controller.selectedProject!,
                            isWide: false,
                          ),
                        ],
                      ],
                      const SizedBox(height: 22),
                      const _WorkspaceFootnote(),
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

class _PageHeading extends StatelessWidget {
  const _PageHeading({
    required this.projectCount,
    required this.isRefreshing,
  });

  final int projectCount;
  final bool isRefreshing;

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
              Text(
                'YOUR WORK',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.papayaDark,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Project workspace',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                projectCount == 0
                    ? 'Your confirmed contract projects will appear here.'
                    : '$projectCount contract${projectCount == 1 ? '' : 's'} in your workspace.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (isRefreshing)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.papaya,
              ),
            ),
          ),
      ],
    );
  }
}

class _ProjectStats extends StatelessWidget {
  const _ProjectStats({required this.controller, required this.isWide});

  final EngineerProjectsController controller;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData(
        label: 'Awaiting funding',
        value: controller.awaitingFundingCount,
        icon: Icons.hourglass_top_rounded,
        color: AppColors.warning,
        surface: AppColors.warningSoft,
      ),
      _MetricData(
        label: 'In progress',
        value: controller.activeCount,
        icon: Icons.work_outline_rounded,
        color: AppColors.info,
        surface: AppColors.infoSoft,
      ),
      _MetricData(
        label: 'In review',
        value: controller.reviewCount,
        icon: Icons.rate_review_outlined,
        color: AppColors.saffronDark,
        surface: AppColors.saffronSoft,
      ),
      _MetricData(
        label: 'Completed',
        value: controller.completedCount,
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.success,
        surface: AppColors.successSoft,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 104,
      ),
      itemBuilder: (context, index) => _MetricCard(data: metrics[index]),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.surface,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color surface;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});
  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: data.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value.toString(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  data.label,
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
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});
  final EngineerProjectsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your projects',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EngineerProjectsController.filters.map((filter) {
            final selected = controller.selectedFilter.value == filter;
            return ChoiceChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) => controller.selectFilter(filter),
              selectedColor: AppColors.brandSoft,
              backgroundColor: Theme.of(context).colorScheme.surface,
              side: BorderSide(
                color: selected ? AppColors.brandTint : AppColors.outlineVariant,
              ),
              labelStyle: TextStyle(
                color: selected ? AppColors.brand : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              showCheckmark: false,
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}

class _ProjectList extends StatelessWidget {
  const _ProjectList({
    required this.projects,
    required this.controller,
    required this.compact,
  });

  final List<EngineerProjectModel> projects;
  final EngineerProjectsController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final project in projects)
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Obx(
              () => _ProjectCard(
                project: project,
                selected: controller.selectedProjectId.value == project.contractId,
                compact: compact,
                onTap: () => controller.selectProject(project),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final EngineerProjectModel project;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.all(compact ? 15 : 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.papaya : AppColors.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      project.taskTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(status: project.contractStatus),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      project.clientDisplayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    project.formattedAmount,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  _SmallMeta(
                    icon: Icons.category_outlined,
                    label: project.taskCategory,
                  ),
                  const SizedBox(width: 14),
                  _SmallMeta(
                    icon: Icons.calendar_today_outlined,
                    label: project.deadlineAt == null
                        ? 'No deadline'
                        : project.deadlineLabel,
                  ),
                  const Spacer(),
                  Icon(
                    selected ? Icons.chevron_right_rounded : Icons.open_in_new_rounded,
                    size: 18,
                    color: selected ? AppColors.papaya : AppColors.textTertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallMeta extends StatelessWidget {
  const _SmallMeta({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectDetails extends StatelessWidget {
  const _ProjectDetails({required this.project, required this.isWide});

  final EngineerProjectModel project;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusInfo = _statusInfo(project.contractStatus);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isWide ? 22 : 18),
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
                      Text(
                        'PROJECT DETAILS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.papayaDark,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        project.taskTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusPill(status: project.contractStatus),
              ],
            ),
            const SizedBox(height: 17),
            _StatusNotice(
              icon: statusInfo.icon,
              title: statusInfo.title,
              message: statusInfo.message,
              color: statusInfo.color,
              surface: statusInfo.surface,
            ),
            const SizedBox(height: 20),
            _ClientStrip(project: project),
            const SizedBox(height: 19),
            _MoneySummary(project: project),
            const SizedBox(height: 20),
            _SectionLabel(title: 'Project overview'),
            const SizedBox(height: 8),
            Text(
              project.taskDescription.isEmpty
                  ? 'No additional project description was provided.'
                  : project.taskDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel(title: 'Agreed scope of work'),
            const SizedBox(height: 8),
            Text(
              project.scopeOfWork,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
            if (project.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 18),
              _SectionLabel(title: 'Additional agreement notes'),
              const SizedBox(height: 8),
              Text(
                project.notes!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 20),
            _SectionLabel(title: 'Project terms'),
            const SizedBox(height: 11),
            _TermRow(
              icon: Icons.category_outlined,
              label: 'Category',
              value: project.taskCategory,
            ),
            _TermRow(
              icon: Icons.event_available_outlined,
              label: 'Client deadline',
              value: project.deadlineLabel,
            ),
            _TermRow(
              icon: Icons.timelapse_rounded,
              label: 'Delivery period',
              value: project.deliveryDays > 0
                  ? '${project.deliveryDays} days after work starts'
                  : 'Not specified',
            ),
            _TermRow(
              icon: Icons.replay_rounded,
              label: 'Included revisions',
              value: project.includedRevisions.toString(),
            ),
            _TermRow(
              icon: Icons.verified_outlined,
              label: 'Terms confirmed',
              value: project.confirmedLabel,
            ),
            if (project.requiredSkills.isNotEmpty) ...[
              const SizedBox(height: 17),
              _SectionLabel(title: 'Requested skills'),
              const SizedBox(height: 9),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: project.requiredSkills
                    .map(
                      (skill) => Chip(
                        label: Text(skill),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.surfaceAlt,
                        side: BorderSide.none,
                        labelStyle: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Contract reference  •  ${project.contractShortId}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Get.toNamed<void>(
                  AppRoutes.projectChats,
                  arguments: project.contractId,
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Open project chat'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: project.contractStatus == 'revision_requested'
                    ? () => Get.toNamed<void>(
                          AppRoutes.engineerRevisionRequests,
                          arguments: project.contractId,
                        )
                    : const {'funded', 'in_progress'}.contains(
                        project.contractStatus,
                      )
                        ? () async {
                            final submitted = await Get.toNamed<bool>(
                              AppRoutes.engineerSubmitWork,
                              arguments: project,
                            );
                            if (submitted == true &&
                                Get.isRegistered<EngineerProjectsController>()) {
                              await Get.find<EngineerProjectsController>().refresh();
                            }
                          }
                        : null,
                icon: Icon(
                  project.contractStatus == 'revision_requested'
                      ? Icons.rate_review_outlined
                      : Icons.outbox_rounded,
                ),
                label: Text(
                  project.contractStatus == 'revision_requested'
                      ? 'Review Client feedback'
                      : project.contractStatus == 'submitted'
                          ? 'Delivery awaiting review'
                          : project.contractStatus == 'completed'
                              ? 'Project completed'
                              : project.contractStatus == 'awaiting_payment'
                                  ? 'Submit after payment confirmation'
                                  : 'Submit completed work',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.papayaDark,
                  disabledForegroundColor: AppColors.textTertiary,
                  side: BorderSide(
                    color: const {
                      'funded',
                      'in_progress',
                      'revision_requested',
                    }.contains(project.contractStatus)
                        ? AppColors.papaya
                        : AppColors.outlineVariant,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    required this.surface,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
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

class _ClientStrip extends StatelessWidget {
  const _ClientStrip({required this.project});
  final EngineerProjectModel project;

  @override
  Widget build(BuildContext context) {
    final name = project.clientDisplayName;
    final initial = name.trim().isEmpty ? 'C' : name.trim()[0].toUpperCase();

    return Row(
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: AppColors.brandSoft,
          backgroundImage: project.clientAvatarUrl == null
              ? null
              : NetworkImage(project.clientAvatarUrl!),
          child: project.clientAvatarUrl == null
              ? Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Client',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (project.clientCountryName?.isNotEmpty == true)
                Text(
                  project.clientCountryName!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoneySummary extends StatelessWidget {
  const _MoneySummary({required this.project});
  final EngineerProjectModel project;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.brandSoft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.brandTint.withValues(alpha: 0.65)),
      ),
      child: Column(
        children: [
          _MoneyRow(
            label: 'Agreed project amount',
            value: project.formattedAmount,
          ),
          const SizedBox(height: 9),
          _MoneyRow(
            label: 'Marketplace commission (${project.commissionPercent}%)',
            value: '− ${project.formattedPlatformFee}',
            subdued: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.brandTint),
          ),
          _MoneyRow(
            label: 'Your agreed share',
            value: project.formattedEngineerNet,
            emphasize: true,
          ),
          const SizedBox(height: 7),
          Text(
            'Payout is subject to completed delivery, Client approval and the approved provider flow.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.subdued = false,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool subdued;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: subdued ? AppColors.textTertiary : AppColors.textSecondary,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          textAlign: TextAlign.end,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: emphasize ? AppColors.brand : AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TermRow extends StatelessWidget {
  const _TermRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.textTertiary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final info = _statusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: info.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        _statusLabel(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: info.color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
      ),
    );
  }
}

class _StatusInfo {
  const _StatusInfo({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.surface,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final Color surface;
}

_StatusInfo _statusInfo(String status) {
  switch (status) {
    case 'awaiting_payment':
      return const _StatusInfo(
        title: 'Waiting for Client funding',
        message:
            'The contract is confirmed, but payment has not been verified yet. Do not begin paid work until the marketplace confirms funding.',
        icon: Icons.hourglass_top_rounded,
        color: AppColors.warningInk,
        surface: AppColors.warningSoft,
      );
    case 'funded':
      return const _StatusInfo(
        title: 'Funding confirmed',
        message:
            'The payment provider has confirmed funding. Review the agreed scope and delivery terms before work begins.',
        icon: Icons.verified_rounded,
        color: AppColors.success,
        surface: AppColors.successSoft,
      );
    case 'in_progress':
      return const _StatusInfo(
        title: 'Project in progress',
        message:
            'This project is marked as in progress. Keep your work aligned with the confirmed scope and delivery terms.',
        icon: Icons.engineering_rounded,
        color: AppColors.info,
        surface: AppColors.infoSoft,
      );
    case 'submitted':
      return const _StatusInfo(
        title: 'Waiting for Client review',
        message:
            'Your completed work has been submitted and is waiting for the Client to review it.',
        icon: Icons.rate_review_outlined,
        color: AppColors.saffronDark,
        surface: AppColors.saffronSoft,
      );
    case 'revision_requested':
      return const _StatusInfo(
        title: 'Revision requested',
        message:
            'The Client has requested changes. Open Revision Requests to review the feedback and submit an updated delivery.',
        icon: Icons.edit_note_rounded,
        color: AppColors.warningInk,
        surface: AppColors.warningSoft,
      );
    case 'completed':
      return const _StatusInfo(
        title: 'Project completed',
        message:
            'The project is marked completed. Check the payout area when that workflow becomes available.',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
        surface: AppColors.successSoft,
      );
    default:
      return const _StatusInfo(
        title: 'Project requires attention',
        message:
            'This contract is in a paused, disputed or closed state. Review its status with marketplace support before taking further action.',
        icon: Icons.info_outline_rounded,
        color: AppColors.textSecondary,
        surface: AppColors.surfaceAlt,
      );
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'awaiting_payment':
      return 'Awaiting funding';
    case 'funded':
      return 'Funded';
    case 'in_progress':
      return 'In progress';
    case 'submitted':
      return 'In review';
    case 'revision_requested':
      return 'Revision needed';
    case 'completed':
      return 'Completed';
    case 'disputed':
      return 'Disputed';
    case 'cancelled':
      return 'Cancelled';
    case 'refund_pending':
      return 'Refund pending';
    case 'refunded':
      return 'Refunded';
    default:
      return 'Unknown';
  }
}

class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warningInk),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warningInk,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoFilteredProjects extends StatelessWidget {
  const _NoFilteredProjects({
    required this.hasAnyProjects,
    required this.selectedFilter,
    required this.onShowAll,
  });

  final bool hasAnyProjects;
  final String selectedFilter;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final title = hasAnyProjects
        ? 'No $selectedFilter projects'
        : 'No contract projects yet';
    final message = hasAnyProjects
        ? 'There are no projects in this category. Choose another filter to see your work.'
        : 'When a Client confirms an agreed quote, its contract will appear here. Projects awaiting funding will be shown separately from funded work.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 38),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: AppColors.brandSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              color: AppColors.brand,
              size: 29,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
          ),
          if (hasAnyProjects) ...[
            const SizedBox(height: 17),
            OutlinedButton(
              onPressed: onShowAll,
              child: const Text('Show all projects'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProjectsLoadingState extends StatelessWidget {
  const _ProjectsLoadingState();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(color: AppColors.papaya),
        ),
      );
}

class _ProjectsErrorState extends StatelessWidget {
  const _ProjectsErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: AppColors.error,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                'Projects could not load',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
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

class _WorkspaceFootnote extends StatelessWidget {
  const _WorkspaceFootnote();

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 16,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Project information is read-only in this screen. Payment and project status must be confirmed by trusted backend workflows, not by a button in the Flutter app.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                    height: 1.45,
                  ),
            ),
          ),
        ],
      );
}
