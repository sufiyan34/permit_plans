import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/controllers/submit_project_work_controller.dart';
import 'package:permit_plans/models/engineer_project_model.dart';
import 'package:permit_plans/models/project_delivery_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

/// Screen 22 — Engineer submits the agreed project deliverables to the Client.
/// Payment approval and release remain separate trusted backend workflows.
class SubmitProjectWorkScreen extends StatelessWidget {
  const SubmitProjectWorkScreen({super.key});

  static const double _wideBreakpoint = 1000;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubmitProjectWorkController>();

    return AppShell(
      title: 'Submit completed work',
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
          icon: Icons.chat_bubble_outline_rounded,
          selectedIcon: Icons.chat_bubble_rounded,
          label: 'Messages',
          route: AppRoutes.projectChats,
        ),
      ],
      sidebarItems: [
        SidebarItem(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Earnings',
          route: AppRoutes.engineerEarnings,
        ),
        SidebarItem(icon: Icons.person_outline_rounded, label: 'My profile'),
        SidebarItem(icon: Icons.settings_outlined, label: 'Settings'),
        SidebarItem(icon: Icons.help_outline_rounded, label: 'Help & support'),
      ],
      body: _SubmitProjectWorkBody(
        controller: controller,
        wideBreakpoint: _wideBreakpoint,
      ),
    );
  }
}

class _SubmitProjectWorkBody extends StatelessWidget {
  const _SubmitProjectWorkBody({
    required this.controller,
    required this.wideBreakpoint,
  });

  final SubmitProjectWorkController controller;
  final double wideBreakpoint;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final project = controller.selectedProject;
      if (project == null) {
        return _EmptyProjectState(message: controller.errorMessage.value);
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= wideBreakpoint;
          final horizontalPadding = isWide ? 32.0 : 18.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              isWide ? 28 : 20,
              horizontalPadding,
              36,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1320),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PageHeading(project: project),
                    const SizedBox(height: 22),
                    if (controller.errorMessage.value.isNotEmpty)
                      _InlineNotice(
                        icon: Icons.info_outline_rounded,
                        message: controller.errorMessage.value,
                        color: AppColors.warning,
                        surface: AppColors.warningSoft,
                      ),
                    if (controller.errorMessage.value.isNotEmpty)
                      const SizedBox(height: 14),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: _DeliveryForm(controller: controller),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                _ProjectSummary(project: project),
                                const SizedBox(height: 16),
                                _DeliveryHistory(controller: controller),
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _ProjectSummary(project: project),
                      const SizedBox(height: 16),
                      _DeliveryForm(controller: controller),
                      const SizedBox(height: 16),
                      _DeliveryHistory(controller: controller),
                    ],
                  ],
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
  const _PageHeading({required this.project});

  final EngineerProjectModel project;

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
            Icons.outbox_rounded,
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
                'DELIVERY WORKSPACE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.papayaDark,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Submit completed work',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Send your files and a clear handover note to ${project.clientDisplayName}.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProjectSummary extends StatelessWidget {
  const _ProjectSummary({required this.project});

  final EngineerProjectModel project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.folder_copy_outlined,
                  color: AppColors.papayaDark,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Project summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                _StatusPill(status: project.contractStatus),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              project.taskTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            _SummaryRow(
              icon: Icons.person_outline_rounded,
              label: 'Client',
              value: project.clientDisplayName,
            ),
            _SummaryRow(
              icon: Icons.payments_outlined,
              label: 'Agreed amount',
              value: project.formattedAmount,
            ),
            _SummaryRow(
              icon: Icons.calendar_month_outlined,
              label: 'Deadline',
              value: project.deadlineLabel,
            ),
            _SummaryRow(
              icon: Icons.replay_rounded,
              label: 'Included revisions',
              value: project.includedRevisions.toString(),
            ),
            _SummaryRow(
              icon: Icons.tag_rounded,
              label: 'Contract reference',
              value: project.contractShortId,
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.outlineVariant),
            const SizedBox(height: 13),
            Text(
              'Agreed scope',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              project.scopeOfWork,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            _EligibilityNotice(status: project.contractStatus),
          ],
        ),
      ),
    );
  }
}

class _DeliveryForm extends StatelessWidget {
  const _DeliveryForm({required this.controller});

  final SubmitProjectWorkController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canDeliver = _isDeliverableStatus(
      controller.selectedProject?.contractStatus ?? '',
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your delivery',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Summarize what you completed and point out anything the Client should review.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 19),
            Text(
              'Handover note',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.noteController,
              enabled: canDeliver && !controller.isSubmitting.value,
              minLines: 6,
              maxLines: 10,
              maxLength: 5000,
              onChanged: controller.updateNote,
              decoration: InputDecoration(
                hintText: 'Describe the completed work, list the files included, and share any important handover instructions...',
                alignLabelWithHint: true,
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.papaya,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Delivery files',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${controller.pendingFiles.length}/${20}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            OutlinedButton.icon(
              onPressed:
                  canDeliver &&
                      !controller.isPickingFile.value &&
                      !controller.isSubmitting.value &&
                      controller.pendingFiles.length < 20
                  ? controller.pickFile
                  : null,
              icon: controller.isPickingFile.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file_rounded),
              label: Text(
                controller.isPickingFile.value
                    ? 'Selecting file...'
                    : 'Add a file',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brand,
                side: const BorderSide(color: AppColors.brandTint),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Up to 20 files • 25 MB per file • PDF, Office, images, ZIP, CSV, TXT, DWG and DXF',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
                height: 1.45,
              ),
            ),
            if (controller.pendingFiles.isNotEmpty) ...[
              const SizedBox(height: 13),
              for (final item in controller.pendingFiles)
                _PendingFileTile(
                  item: item,
                  enabled: !controller.isSubmitting.value,
                  onRemove: () => controller.removeFile(item),
                ),
            ],
            if (controller.formErrorMessage.value.isNotEmpty) ...[
              const SizedBox(height: 14),
              _InlineNotice(
                icon: Icons.error_outline_rounded,
                message: controller.formErrorMessage.value,
                color: AppColors.error,
                surface: AppColors.errorSoft,
              ),
            ],
            const SizedBox(height: 19),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: controller.canSubmit
                    ? () async {
                        final submitted = await controller.submit();
                        if (submitted) Get.back<bool>(result: true);
                      }
                    : null,
                icon: controller.isSubmitting.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  controller.isSubmitting.value
                      ? 'Uploading and submitting...'
                      : controller.submitButtonLabel,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.disabled,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Submitting sends this delivery to the Client for review. It does not automatically approve the work or release payment.',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingFileTile extends StatelessWidget {
  const _PendingFileTile({
    required this.item,
    required this.enabled,
    required this.onRemove,
  });

  final PendingDeliveryFile item;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 7),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, color: AppColors.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  item.formattedSize,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove file',
            onPressed: enabled ? onRemove : null,
            icon: const Icon(Icons.close_rounded, size: 19),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _DeliveryHistory extends StatelessWidget {
  const _DeliveryHistory({required this.controller});

  final SubmitProjectWorkController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded, color: AppColors.papayaDark),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Delivery history',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (controller.isLoadingHistory.value)
                  const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (controller.deliveryHistory.isEmpty &&
                !controller.isLoadingHistory.value)
              Text(
                'No delivery has been submitted for this project yet.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else
              for (final item in controller.deliveryHistory)
                _DeliveryHistoryTile(delivery: item),
          ],
        ),
      ),
    );
  }
}

class _DeliveryHistoryTile extends StatelessWidget {
  const _DeliveryHistoryTile({required this.delivery});

  final ProjectDeliveryModel delivery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (delivery.status) {
      'approved' => AppColors.success,
      'revision_requested' => AppColors.warning,
      'superseded' => AppColors.textTertiary,
      _ => AppColors.info,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Submission #${delivery.submissionNumber}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  delivery.statusLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            delivery.formattedDate,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            delivery.message,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          if (delivery.files.isNotEmpty) ...[
            const SizedBox(height: 9),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: delivery.files
                  .map((file) => _HistoryFilePill(file: file))
                  .toList(growable: false),
            ),
          ],
          if (delivery.reviewNote?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Client feedback: ${delivery.reviewNote}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.warningInk,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryFilePill extends StatelessWidget {
  const _HistoryFilePill({required this.file});

  final ProjectDeliveryFile file;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.attach_file_rounded,
            size: 14,
            color: AppColors.brand,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              file.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EligibilityNotice extends StatelessWidget {
  const _EligibilityNotice({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final allowed = _isDeliverableStatus(status);
    final title = allowed ? 'Ready for delivery' : _lockedTitle(status);
    final message = allowed
        ? status == 'revision_requested'
              ? 'The Client requested changes. Submit the updated files and explain what you revised.'
              : 'Review the agreed scope, attach your final files and send the handover note.'
        : _lockedMessage(status);
    final color = allowed ? AppColors.success : AppColors.warning;
    final surface = allowed ? AppColors.successSoft : AppColors.warningSoft;

    return _InlineNotice(
      icon: allowed
          ? Icons.check_circle_outline_rounded
          : Icons.lock_outline_rounded,
      title: title,
      message: message,
      color: color,
      surface: surface,
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.message,
    required this.color,
    required this.surface,
    this.title,
  });

  final IconData icon;
  final String? title;
  final String message;
  final Color color;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.textTertiary),
          const SizedBox(width: 9),
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, surface) = switch (status) {
      'awaiting_payment' => (
        'Awaiting payment',
        AppColors.warning,
        AppColors.warningSoft,
      ),
      'funded' => ('Funded', AppColors.success, AppColors.successSoft),
      'in_progress' => ('In progress', AppColors.info, AppColors.infoSoft),
      'submitted' => (
        'In review',
        AppColors.saffronDark,
        AppColors.saffronSoft,
      ),
      'revision_requested' => (
        'Revision requested',
        AppColors.warning,
        AppColors.warningSoft,
      ),
      'completed' => ('Completed', AppColors.success, AppColors.successSoft),
      _ => ('Project status', AppColors.textSecondary, AppColors.surfaceAlt),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyProjectState extends StatelessWidget {
  const _EmptyProjectState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.assignment_late_outlined,
                size: 44,
                color: AppColors.warning,
              ),
              const SizedBox(height: 13),
              Text(
                'Project not selected',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message.isEmpty
                    ? 'Open Submit completed work from a project in your workspace.'
                    : message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.tonal(
                onPressed: () => Get.offNamed<void>(AppRoutes.engineerProjects),
                child: const Text('Back to projects'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isDeliverableStatus(String status) =>
    const {'funded', 'in_progress', 'revision_requested'}.contains(status);

String _lockedTitle(String status) {
  switch (status) {
    case 'awaiting_payment':
      return 'Waiting for payment confirmation';
    case 'submitted':
      return 'Delivery already submitted';
    case 'completed':
      return 'Project completed';
    case 'disputed':
      return 'Project under dispute';
    case 'cancelled':
      return 'Project cancelled';
    default:
      return 'Delivery not available';
  }
}

String _lockedMessage(String status) {
  switch (status) {
    case 'awaiting_payment':
      return 'The Client must complete payment through an approved provider before work can be submitted.';
    case 'submitted':
      return 'Your latest delivery is already with the Client for review. Wait for approval or revision feedback.';
    case 'completed':
      return 'This project has already been marked as completed.';
    case 'disputed':
      return 'Delivery submission is paused while the project is under dispute.';
    case 'cancelled':
      return 'A cancelled project cannot accept new deliveries.';
    default:
      return 'This project is not currently eligible for delivery submission.';
  }
}
