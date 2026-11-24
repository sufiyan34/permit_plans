import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/controllers/client_delivery_review_controller.dart';
import 'package:permit_plans/models/client_delivery_review_model.dart';
import 'package:permit_plans/models/project_delivery_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

/// Screen 23 — Client reviews the Engineer's submitted project delivery.
/// Approval records work acceptance only; payouts remain a separate workflow.
class ClientDeliveryReviewScreen
    extends GetView<ClientDeliveryReviewController> {
  const ClientDeliveryReviewScreen({super.key});

  static const double _wideBreakpoint = 1060;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Delivery review',
      currentIndex: 2,
      destinations: const [
        ShellDestination(
          icon: Icons.grid_view_outlined,
          selectedIcon: Icons.grid_view_rounded,
          label: 'Overview',
          route: AppRoutes.clientHome,
        ),
        ShellDestination(
          icon: Icons.request_quote_outlined,
          selectedIcon: Icons.request_quote_rounded,
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
          selectedIcon: Icons.search_rounded,
          label: 'Find engineers',
          route: AppRoutes.clientBrowseEngineers,
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
          icon: Icons.fact_check_outlined,
          label: 'Delivery reviews',
          route: AppRoutes.clientDeliveryReviews,
        ),
        SidebarItem(
          icon: Icons.verified_outlined,
          label: 'Final approved files',
          route: AppRoutes.clientFinalApproval,
        ),
        SidebarItem(
          icon: Icons.folder_open_outlined,
          label: 'Quotes',
          route: AppRoutes.clientQuotes,
        ),
        SidebarItem(icon: Icons.receipt_long_outlined, label: 'Payments'),
        SidebarItem(icon: Icons.person_outline_rounded, label: 'My profile'),
        SidebarItem(icon: Icons.help_outline_rounded, label: 'Help & support'),
      ],
      actions: [
        IconButton(
          tooltip: 'Final approved files',
          onPressed: () => Get.toNamed<void>(AppRoutes.clientFinalApproval),
          icon: const Icon(Icons.verified_outlined),
        ),
        IconButton(
          tooltip: 'Refresh deliveries',
          onPressed: controller.refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      body: _ClientDeliveryReviewBody(
        controller: controller,
        wideBreakpoint: _wideBreakpoint,
      ),
    );
  }
}

class _ClientDeliveryReviewBody extends StatelessWidget {
  const _ClientDeliveryReviewBody({
    required this.controller,
    required this.wideBreakpoint,
  });

  final ClientDeliveryReviewController controller;
  final double wideBreakpoint;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.deliveries.isEmpty) {
        return const _LoadingState();
      }
      if (controller.errorMessage.value.isNotEmpty &&
          controller.deliveries.isEmpty) {
        return _ErrorState(
          message: controller.errorMessage.value,
          onRetry: controller.refresh,
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= wideBreakpoint;
          final padding = isWide ? 30.0 : 17.0;
          final selected = controller.selectedDelivery;

          return RefreshIndicator(
            color: AppColors.papaya,
            onRefresh: controller.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(padding, 24, padding, 42),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PageHeading(isWide: isWide),
                      const SizedBox(height: 22),
                      _ReviewStats(controller: controller),
                      const SizedBox(height: 20),
                      _ReviewToolbar(controller: controller),
                      if (controller.errorMessage.value.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _InlineError(message: controller.errorMessage.value),
                      ],
                      const SizedBox(height: 17),
                      if (isWide)
                        SizedBox(
                          height: 700,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: constraints.maxWidth >= 1300 ? 390 : 340,
                                child: _DeliveryListPanel(controller: controller),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: _DeliveryDetailPanel(
                                  controller: controller,
                                  delivery: selected,
                                  scrollable: true,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        _DeliveryListPanel(controller: controller),
                        const SizedBox(height: 16),
                        _DeliveryDetailPanel(
                          controller: controller,
                          delivery: selected,
                          scrollable: false,
                        ),
                      ],
                      const SizedBox(height: 16),
                      const _PaymentBoundaryNotice(),
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
  const _PageHeading({required this.isWide});

  final bool isWide;

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
            color: AppColors.papayaSoft,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.fact_check_outlined,
            color: AppColors.papayaDark,
            size: 25,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CLIENT WORKSPACE · DELIVERIES',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.papayaDark,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Review submitted work',
                style: (isWide
                        ? theme.textTheme.headlineMedium
                        : theme.textTheme.headlineSmall)
                    ?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.55,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Check the Engineer’s handover, open the files, then approve the work or request a revision.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewStats extends StatelessWidget {
  const _ReviewStats({required this.controller});

  final ClientDeliveryReviewController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;
        final children = [
          _StatCard(
            label: 'Needs review',
            value: controller.needsReviewCount,
            icon: Icons.mark_email_unread_outlined,
            color: AppColors.papayaDark,
            background: AppColors.papayaSoft,
            selected: controller.activeFilter.value == 'needs_review',
            onTap: () => controller.selectFilter('needs_review'),
          ),
          _StatCard(
            label: 'Revision requested',
            value: controller.revisionRequestedCount,
            icon: Icons.replay_rounded,
            color: AppColors.saffronDark,
            background: AppColors.saffronSoft,
            selected: controller.activeFilter.value == 'revision_requested',
            onTap: () => controller.selectFilter('revision_requested'),
          ),
          _StatCard(
            label: 'Approved',
            value: controller.approvedCount,
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
            background: AppColors.successSoft,
            selected: controller.activeFilter.value == 'approved',
            onTap: () => controller.selectFilter('approved'),
          ),
        ];
        if (compact) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                children[i],
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color background;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? AppColors.brandSoft : AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.brandTint : AppColors.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewToolbar extends StatelessWidget {
  const _ReviewToolbar({required this.controller});

  final ClientDeliveryReviewController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const filters = <(String, String)>[
      ('needs_review', 'Needs review'),
      ('revision_requested', 'Revision requested'),
      ('approved', 'Approved'),
      ('all', 'All deliveries'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: controller.setSearch,
          decoration: InputDecoration(
            hintText: 'Search by project, Engineer or delivery note...',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
          ),
        ),
        const SizedBox(height: 11),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final filter in filters)
              Obx(() {
                final selected = controller.activeFilter.value == filter.$1;
                return ChoiceChip(
                  label: Text(filter.$2),
                  selected: selected,
                  onSelected: (_) => controller.selectFilter(filter.$1),
                  selectedColor: AppColors.brandSoft,
                  backgroundColor: AppColors.surfaceAlt,
                  side: BorderSide(
                    color: selected ? AppColors.brandTint : AppColors.outlineVariant,
                  ),
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: selected ? AppColors.brandDark : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                );
              }),
          ],
        ),
      ],
    );
  }
}

class _DeliveryListPanel extends StatelessWidget {
  const _DeliveryListPanel({required this.controller});

  final ClientDeliveryReviewController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.filteredDeliveries;
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: items.isEmpty
            ? const _ListEmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 9),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = item.deliveryId == controller.selectedDeliveryId.value;
                  return _DeliveryListTile(
                    item: item,
                    selected: selected,
                    onTap: () => controller.selectDelivery(item),
                  );
                },
              ),
      );
    });
  }
}

class _DeliveryListTile extends StatelessWidget {
  const _DeliveryListTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ClientDeliveryReviewModel item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? AppColors.brandSoft : AppColors.surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
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
                      item.taskTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusPill(status: item.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: AppColors.brandSoft,
                    backgroundImage: item.engineerAvatarUrl == null
                        ? null
                        : NetworkImage(item.engineerAvatarUrl!),
                    child: item.engineerAvatarUrl == null
                        ? Text(
                            item.engineerInitials,
                            style: const TextStyle(
                              color: AppColors.brandDark,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.engineerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    'v${item.submissionNumber}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 13, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.formattedDate,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  Icon(Icons.attach_file_rounded, size: 13, color: AppColors.textTertiary),
                  const SizedBox(width: 3),
                  Text(
                    '${item.files.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
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

class _DeliveryDetailPanel extends StatelessWidget {
  const _DeliveryDetailPanel({
    required this.controller,
    required this.delivery,
    required this.scrollable,
  });

  final ClientDeliveryReviewController controller;
  final ClientDeliveryReviewModel? delivery;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final item = delivery;
    if (item == null) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: const _NoSelectionState(),
      );
    }

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: scrollable
          ? SingleChildScrollView(child: _detailContent(context, item))
          : _detailContent(context, item),
    );
  }

  Widget _detailContent(BuildContext context, ClientDeliveryReviewModel item) {
    final theme = Theme.of(context);
    return Column(
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
                        'SUBMISSION · VERSION ${item.submissionNumber}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.papayaDark,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.taskTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusPill(status: item.status),
              ],
            ),
            const SizedBox(height: 17),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _MetaItem(icon: Icons.person_outline_rounded, label: item.engineerName),
                _MetaItem(icon: Icons.calendar_today_outlined, label: item.formattedDate),
                _MetaItem(icon: Icons.payments_outlined, label: item.formattedAmount),
                _MetaItem(icon: Icons.event_outlined, label: 'Due ${item.deadlineLabel}'),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: AppColors.outlineVariant),
            const SizedBox(height: 14),
            Text(
              'Engineer handover note',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(15),
              ),
              child: SelectableText(
                item.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Submitted files',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                _CountPill(count: item.files.length),
              ],
            ),
            const SizedBox(height: 10),
            if (item.files.isEmpty)
              const _NoFilesNotice()
            else
              Column(
                children: [
                  for (final file in item.files) ...[
                    _DeliveryFileTile(
                      file: file,
                      controller: controller,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            if (item.reviewNote != null && item.reviewNote!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ReviewNoteBox(
                note: item.reviewNote!,
                reviewedAt: item.reviewedAt,
              ),
            ],
            const SizedBox(height: 20),
            if (item.canReview)
              Obx(() {
                final busy = controller.isReviewing.value &&
                    controller.busyDeliveryId.value == item.deliveryId;
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final vertical = constraints.maxWidth < 470;
                    final approve = FilledButton.icon(
                      onPressed: busy
                          ? null
                          : () => _confirmApproval(context, item),
                      icon: busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Approve work'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(160, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    );
                    final revise = OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => _requestRevision(context, item),
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Request revision'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brand,
                        minimumSize: const Size(170, 48),
                        side: const BorderSide(color: AppColors.brandTint),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    );
                    if (vertical) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [approve, const SizedBox(height: 9), revise],
                      );
                    }
                    return Wrap(spacing: 10, runSpacing: 10, children: [approve, revise]);
                  },
                );
              })
            else
              _ReadOnlyStatusNotice(status: item.status),
          ],
    );
  }

  Future<void> _confirmApproval(
    BuildContext context,
    ClientDeliveryReviewModel item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve this delivery?'),
        content: const Text(
          'This marks the project work as completed. It does not charge, release or transfer any money.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep reviewing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Approve work'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.approveDelivery(item.deliveryId);
    }
  }

  Future<void> _requestRevision(
    BuildContext context,
    ClientDeliveryReviewModel item,
  ) async {
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request a revision'),
        content: SizedBox(
          width: 460,
          child: TextField(
            controller: noteController,
            autofocus: true,
            minLines: 4,
            maxLines: 7,
            maxLength: 3000,
            decoration: const InputDecoration(
              labelText: 'What needs to change?',
              hintText: 'Describe the specific updates required...',
              alignLabelWithHint: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (noteController.text.trim().length < 10) return;
              Navigator.of(dialogContext).pop(noteController.text.trim());
            },
            child: const Text('Send revision request'),
          ),
        ],
      ),
    );
    noteController.dispose();
    if (note != null) {
      await controller.requestRevision(item.deliveryId, note);
    }
  }
}

class _DeliveryFileTile extends StatelessWidget {
  const _DeliveryFileTile({required this.file, required this.controller});

  final ProjectDeliveryFile file;
  final ClientDeliveryReviewController controller;

  IconData get _icon {
    final name = file.fileName.toString().toLowerCase();
    if (name.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
    if (name.endsWith('.zip')) return Icons.folder_zip_outlined;
    if (name.endsWith('.png') || name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.webp')) {
      return Icons.image_outlined;
    }
    if (name.endsWith('.dwg') || name.endsWith('.dxf')) return Icons.architecture_outlined;
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(_icon, color: AppColors.brand, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  file.formattedSize.toString(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            final busy = controller.openingFileId.value == file.id.toString();
            return TextButton.icon(
              onPressed: busy ? null : () => controller.openFile(file),
              icon: busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(busy ? 'Opening' : 'Open / download'),
            );
          }),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textTertiary),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, foreground, background) = switch (status) {
      'submitted' => ('Needs review', AppColors.papayaDark, AppColors.papayaSoft),
      'revision_requested' => ('Revision requested', AppColors.saffronDark, AppColors.saffronSoft),
      'approved' => ('Approved', AppColors.success, AppColors.successSoft),
      'superseded' => ('Previous version', AppColors.textSecondary, AppColors.surfaceAlt),
      _ => (status.replaceAll('_', ' '), AppColors.textSecondary, AppColors.surfaceAlt),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReviewNoteBox extends StatelessWidget {
  const _ReviewNoteBox({required this.note, required this.reviewedAt});

  final String note;
  final DateTime? reviewedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Client review note',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.warningInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(note, style: const TextStyle(color: AppColors.warningInk, height: 1.4)),
          if (reviewedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Reviewed ${reviewedAt!.toLocal()}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.warningInk.withValues(alpha: .75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadOnlyStatusNotice extends StatelessWidget {
  const _ReadOnlyStatusNotice({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final message = switch (status) {
      'revision_requested' => 'A revision has been requested. The Engineer can submit a new version from their Project Workspace.',
      'approved' => 'You approved this delivery. The work is complete; payment release is handled separately.',
      'superseded' => 'This is an earlier version retained in the project delivery history.',
      _ => 'This delivery is available as read-only history.',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

class _NoFilesNotice extends StatelessWidget {
  const _NoFilesNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Text(
        'The Engineer included a handover note without file attachments.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

class _PaymentBoundaryNotice extends StatelessWidget {
  const _PaymentBoundaryNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: AppColors.info),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Approving confirms that the delivered work is accepted. It does not charge a card or release funds. Payment release will be connected only after a payment provider and payout process are approved.',
              style: TextStyle(color: AppColors.info, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListEmptyState extends StatelessWidget {
  const _ListEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 38, color: AppColors.textTertiary),
          const SizedBox(height: 10),
          Text(
            'No deliveries in this view',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'New submissions from your Engineers will appear here automatically.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSelectionState extends StatelessWidget {
  const _NoSelectionState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.task_alt_rounded, size: 44, color: AppColors.textTertiary),
        const SizedBox(height: 12),
        Text(
          'Select a delivery to review',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'You can open the Engineer’s files and decide whether the work is ready to approve.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.papaya),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
              const Icon(Icons.error_outline_rounded, size: 42, color: AppColors.error),
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
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.error)),
    );
  }
}
