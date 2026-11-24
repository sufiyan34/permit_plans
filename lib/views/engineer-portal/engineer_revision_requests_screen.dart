import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/controllers/engineer_revision_requests_controller.dart';
import 'package:permit_plans/models/engineer_revision_request_model.dart';
import 'package:permit_plans/models/project_delivery_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

/// Screen 24 — Engineer reviews Client feedback and prepares a revised delivery.
/// The actual resubmission is handled by the existing Screen 22 workflow.
class EngineerRevisionRequestsScreen
    extends GetView<EngineerRevisionRequestsController> {
  const EngineerRevisionRequestsScreen({super.key});

  static const double _wideBreakpoint = 1100;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Revision requests',
      currentIndex: 4,
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
          tooltip: 'Refresh revision requests',
          onPressed: controller.refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      body: _RevisionRequestsBody(
        controller: controller,
        wideBreakpoint: _wideBreakpoint,
      ),
    );
  }
}

class _RevisionRequestsBody extends StatelessWidget {
  const _RevisionRequestsBody({
    required this.controller,
    required this.wideBreakpoint,
  });

  final EngineerRevisionRequestsController controller;
  final double wideBreakpoint;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final requests = controller.filteredRequests;
      final selected = controller.selectedRequest;
      final isInitialLoading =
          controller.isLoading.value && controller.requests.isEmpty;
      final error = controller.errorMessage.value;

      if (isInitialLoading) return const _RevisionLoadingState();
      if (controller.requests.isEmpty && error.isNotEmpty) {
        return _RevisionErrorState(
          message: error,
          onRetry: controller.refresh,
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
                      _PageHeading(isRefreshing: controller.isRefreshing.value),
                      const SizedBox(height: 20),
                      _OverviewCards(
                        requestCount: controller.totalRequests,
                        fileCount: controller.totalFiles,
                      ),
                      const SizedBox(height: 18),
                      _SearchField(onChanged: controller.setSearch),
                      if (error.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _InlineNotice(message: error),
                      ],
                      const SizedBox(height: 18),
                      if (requests.isEmpty)
                        _EmptyRequestsState(
                          hasSearch: controller.searchText.value.isNotEmpty,
                          onProjects: () => Get.toNamed<void>(
                            AppRoutes.engineerProjects,
                          ),
                        )
                      else if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _RequestList(
                                requests: requests,
                                selected: selected,
                                onSelect: controller.selectRequest,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 7,
                              child: selected == null
                                  ? const _SelectRequestHint()
                                  : _RequestDetails(
                                      item: selected,
                                      controller: controller,
                                    ),
                            ),
                          ],
                        )
                      else ...[
                        _RequestList(
                          requests: requests,
                          selected: selected,
                          onSelect: controller.selectRequest,
                        ),
                        const SizedBox(height: 18),
                        if (selected == null)
                          const _SelectRequestHint()
                        else
                          _RequestDetails(
                            item: selected,
                            controller: controller,
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

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.isRefreshing});

  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.warningSoft,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.rate_review_outlined,
            color: AppColors.warningInk,
            size: 25,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PROJECT FEEDBACK',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.warningInk,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Revision requests',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Review the Client’s feedback, check the previous delivery and send an updated version.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (isRefreshing)
          const Padding(
            padding: EdgeInsets.only(left: 10, top: 8),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}

class _OverviewCards extends StatelessWidget {
  const _OverviewCards({required this.requestCount, required this.fileCount});

  final int requestCount;
  final int fileCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final cards = [
          _OverviewCard(
            icon: Icons.mark_chat_unread_outlined,
            title: 'Open requests',
            value: requestCount.toString(),
            color: AppColors.warningInk,
            surface: AppColors.warningSoft,
          ),
          _OverviewCard(
            icon: Icons.attach_file_rounded,
            title: 'Files to review',
            value: fileCount.toString(),
            color: AppColors.brand,
            surface: AppColors.brandSoft,
          ),
        ];
        if (compact) {
          return Column(
            children: [
              cards[0],
              const SizedBox(height: 10),
              cards[1],
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.surface,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search by project, Client or feedback…',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({
    required this.requests,
    required this.selected,
    required this.onSelect,
  });

  final List<EngineerRevisionRequestModel> requests;
  final EngineerRevisionRequestModel? selected;
  final ValueChanged<EngineerRevisionRequestModel> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Needs your attention',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ...requests.map((item) {
              final isSelected =
                  item.project.contractId == selected?.project.contractId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _RequestListTile(
                  item: item,
                  selected: isSelected,
                  onTap: () => onSelect(item),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _RequestListTile extends StatelessWidget {
  const _RequestListTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final EngineerRevisionRequestModel item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final project = item.project;
    final feedback = item.requestedDelivery.reviewNote?.trim() ?? '';
    return Material(
      color: selected ? AppColors.brandSoft : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.brandTint : AppColors.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.taskTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                project.clientDisplayName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (feedback.isNotEmpty) ...[
                const SizedBox(height: 9),
                Text(
                  feedback,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.warningInk,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 9),
              Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(
                        (item.requestedDelivery.reviewedAt ??
                                item.requestedDelivery.createdAt)
                            .toLocal(),
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  Text(
                    '${item.attachmentCount} files',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
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

class _StatusPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        'Changes requested',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.warningInk,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _RequestDetails extends StatelessWidget {
  const _RequestDetails({required this.item, required this.controller});

  final EngineerRevisionRequestModel item;
  final EngineerRevisionRequestsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final project = item.project;
    final delivery = item.requestedDelivery;
    final feedback = delivery.reviewNote?.trim() ?? '';
    final reviewDate = DateFormat('dd MMM yyyy, hh:mm a').format(
      (delivery.reviewedAt ?? delivery.createdAt).toLocal(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Client feedback',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _StatusPill(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${project.clientDisplayName} requested changes on $reviewDate.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.saffron.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.format_quote_rounded,
                            color: AppColors.warningInk,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Requested changes',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppColors.warningInk,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        feedback.isEmpty
                            ? 'The Client did not include a written note. Contact them in project chat before resubmitting.'
                            : feedback,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Previous handover note',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  delivery.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                _ProjectFacts(item: item),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _DeliveryFilesCard(
          files: delivery.files,
          controller: controller,
        ),
        const SizedBox(height: 14),
        _HistoryCard(item: item),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: () => controller.submitRevisedWork(item),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Submit revised work'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => controller.openProjectChat(item),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Discuss in project chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brand,
                    side: const BorderSide(color: AppColors.brandTint),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Your next delivery will be saved as a new version. The previous submission and Client feedback remain in the project history.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectFacts extends StatelessWidget {
  const _ProjectFacts({required this.item});

  final EngineerRevisionRequestModel item;

  @override
  Widget build(BuildContext context) {
    final project = item.project;
    final facts = [
      ('Project', project.taskTitle),
      ('Contract', project.contractShortId),
      ('Agreed amount', project.formattedAmount),
      ('Deadline', project.deadlineLabel),
      ('Included revisions', project.includedRevisions.toString()),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: facts
            .map(
              (fact) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        fact.$1,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        fact.$2,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _DeliveryFilesCard extends StatelessWidget {
  const _DeliveryFilesCard({
    required this.files,
    required this.controller,
  });

  final List<ProjectDeliveryFile> files;
  final EngineerRevisionRequestsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Files from previous submission',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Open these files to compare them with the Client’s feedback.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            if (files.isEmpty)
              const _SmallEmptyMessage(
                text: 'No files were attached to this submission.',
              )
            else
              ...files.map(
                (file) => Obx(() {
                  final isOpening = controller.openingFileId.value == file.id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.insert_drive_file_outlined,
                        color: AppColors.brand,
                      ),
                    ),
                    title: Text(
                      file.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${file.formattedSize} • ${file.mimeType}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: 'Open secure file link',
                      onPressed: isOpening ? null : () => controller.openFile(file),
                      icon: isOpening
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_outlined),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});

  final EngineerRevisionRequestModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery history',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 13),
            ...item.history.map((delivery) => _HistoryRow(delivery: delivery)),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.delivery});

  final ProjectDeliveryModel delivery;

  @override
  Widget build(BuildContext context) {
    final current = delivery.status == 'revision_requested';
    final color = current ? AppColors.warningInk : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            current ? Icons.flag_circle_rounded : Icons.history_rounded,
            color: current ? AppColors.warning : AppColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submission #${delivery.submissionNumber} • ${delivery.statusLabel}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  delivery.formattedDate,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
                if ((delivery.reviewNote?.trim().isNotEmpty ?? false)) ...[
                  const SizedBox(height: 4),
                  Text(
                    delivery.reviewNote!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRequestsState extends StatelessWidget {
  const _EmptyRequestsState({required this.hasSearch, required this.onProjects});

  final bool hasSearch;
  final VoidCallback onProjects;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                const Icon(
                  Icons.task_alt_rounded,
                  size: 48,
                  color: AppColors.success,
                ),
                const SizedBox(height: 14),
                Text(
                  hasSearch ? 'No matching requests' : 'You’re all caught up',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  hasSearch
                      ? 'Try another project name, Client or feedback keyword.'
                      : 'There are no open revision requests on your projects right now. New Client feedback will appear here.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (!hasSearch) ...[
                  const SizedBox(height: 17),
                  OutlinedButton.icon(
                    onPressed: onProjects,
                    icon: const Icon(Icons.folder_open_rounded),
                    label: const Text('View my projects'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectRequestHint extends StatelessWidget {
  const _SelectRequestHint();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.rate_review_outlined,
                size: 40,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 10),
              Text(
                'Select a revision request',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Client feedback and previous delivery details will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevisionLoadingState extends StatelessWidget {
  const _RevisionLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(color: AppColors.papaya),
      ),
    );
  }
}

class _RevisionErrorState extends StatelessWidget {
  const _RevisionErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 40),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.warningInk, height: 1.4),
      ),
    );
  }
}

class _SmallEmptyMessage extends StatelessWidget {
  const _SmallEmptyMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
