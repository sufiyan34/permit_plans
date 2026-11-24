import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/controllers/client_final_approval_controller.dart';
import 'package:permit_plans/models/client_delivery_review_model.dart';
import 'package:permit_plans/models/project_delivery_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

/// Screen 25 — final approved work and secure re-access to delivered files.
/// The actual approval decision is made on Screen 23.
class ClientFinalApprovalScreen extends GetView<ClientFinalApprovalController> {
  const ClientFinalApprovalScreen({super.key});

  static const double _wideBreakpoint = 1080;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Final approved work',
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
      ],
      actions: [
        IconButton(
          tooltip: 'Refresh final files',
          onPressed: controller.refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      body: _FinalApprovalBody(
        controller: controller,
        wideBreakpoint: _wideBreakpoint,
      ),
    );
  }
}

class _FinalApprovalBody extends StatelessWidget {
  const _FinalApprovalBody({
    required this.controller,
    required this.wideBreakpoint,
  });

  final ClientFinalApprovalController controller;
  final double wideBreakpoint;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.approvedDeliveries.isEmpty) {
        return const _FinalLoadingState();
      }
      if (controller.errorMessage.value.isNotEmpty &&
          controller.approvedDeliveries.isEmpty) {
        return _FinalErrorState(
          message: controller.errorMessage.value,
          onRetry: controller.refresh,
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= wideBreakpoint;
          final horizontalPadding = isWide ? 30.0 : 17.0;
          final selected = controller.selectedDelivery;

          return RefreshIndicator(
            color: AppColors.papaya,
            onRefresh: controller.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                24,
                horizontalPadding,
                42,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FinalHeading(isWide: isWide),
                      const SizedBox(height: 20),
                      _FinalStats(controller: controller),
                      const SizedBox(height: 18),
                      _FinalSearchField(onChanged: controller.setSearch),
                      if (controller.errorMessage.value.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _InlineError(message: controller.errorMessage.value),
                      ],
                      const SizedBox(height: 17),
                      if (isWide)
                        SizedBox(
                          height: 680,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: constraints.maxWidth >= 1300 ? 390 : 340,
                                child: _FinalProjectList(controller: controller),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: _FinalProjectDetails(
                                  controller: controller,
                                  delivery: selected,
                                  scrollable: true,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        _FinalProjectList(controller: controller),
                        const SizedBox(height: 16),
                        _FinalProjectDetails(
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

class _FinalHeading extends StatelessWidget {
  const _FinalHeading({required this.isWide});
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
            color: AppColors.successSoft,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.verified_rounded,
            color: AppColors.success,
            size: 25,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CLIENT WORKSPACE · COMPLETED WORK',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.success,
                  letterSpacing: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Final approved files',
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
                'Your accepted project handovers in one place. Open the final files again whenever you need them.',
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

class _FinalStats extends StatelessWidget {
  const _FinalStats({required this.controller});
  final ClientFinalApprovalController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final cards = [
          _StatTile(
            icon: Icons.task_alt_rounded,
            color: AppColors.success,
            background: AppColors.successSoft,
            value: controller.completedProjectCount.toString(),
            label: 'Completed projects',
          ),
          _StatTile(
            icon: Icons.folder_zip_outlined,
            color: AppColors.brand,
            background: AppColors.brandSoft,
            value: controller.finalFileCount.toString(),
            label: 'Final files',
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

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.background,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String value;
  final String label;

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
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
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
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
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

class _FinalSearchField extends StatelessWidget {
  const _FinalSearchField({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search by project or Engineer...',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
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

class _FinalProjectList extends StatelessWidget {
  const _FinalProjectList({required this.controller});
  final ClientFinalApprovalController controller;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 16, 17, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Completed projects',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    '${items.length}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.outlineVariant),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: _EmptyListState(),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(10),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 7),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected =
                      item.deliveryId == controller.selectedDeliveryId.value;
                  return _FinalProjectTile(
                    delivery: item,
                    selected: selected,
                    onTap: () => controller.selectDelivery(item),
                  );
                },
              ),
          ],
        ),
      );
    });
  }
}

class _FinalProjectTile extends StatelessWidget {
  const _FinalProjectTile({
    required this.delivery,
    required this.selected,
    required this.onTap,
  });

  final ClientDeliveryReviewModel delivery;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? AppColors.successSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.success.withValues(alpha: .35) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: AppColors.brandSoft,
                child: Text(
                  delivery.engineerInitials,
                  style: const TextStyle(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delivery.taskTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      delivery.engineerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Approved · ${DateFormat('dd MMM yyyy').format((delivery.reviewedAt ?? delivery.createdAt).toLocal())}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinalProjectDetails extends StatelessWidget {
  const _FinalProjectDetails({
    required this.controller,
    required this.delivery,
    required this.scrollable,
  });

  final ClientFinalApprovalController controller;
  final ClientDeliveryReviewModel? delivery;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    if (delivery == null) {
      return const _NoFinalSelection();
    }
    final item = delivery!;
    final theme = Theme.of(context);
    final content = Column(
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
                    item.taskTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${item.taskCategory} · ${item.engineerName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const _ApprovedBadge(),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _InfoPill(
              icon: Icons.event_available_outlined,
              label: 'Approved ${_approvedDate(item)}',
            ),
            _InfoPill(
              icon: Icons.receipt_long_outlined,
              label: 'Contract ${item.formattedAmount}',
            ),
            _InfoPill(
              icon: Icons.folder_outlined,
              label: '${item.files.length} final files',
            ),
          ],
        ),
        const SizedBox(height: 21),
        const _SectionTitle(
          icon: Icons.task_alt_rounded,
          title: 'Engineer handover note',
        ),
        const SizedBox(height: 9),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(14),
          ),
          child: SelectableText(
            item.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.ink,
              height: 1.55,
            ),
          ),
        ),
        if ((item.reviewNote ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 17),
          const _SectionTitle(
            icon: Icons.notes_rounded,
            title: 'Client approval note',
          ),
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              item.reviewNote!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                height: 1.5,
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(
              child: _SectionTitle(
                icon: Icons.folder_zip_outlined,
                title: 'Final deliverable files',
              ),
            ),
            Text(
              '${item.files.length}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (item.files.isEmpty)
          const _NoFilesNotice()
        else
          ...item.files.map(
            (file) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _FinalFileTile(
                file: file,
                controller: controller,
              ),
            ),
          ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => controller.openProjectChat(item),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Open project conversation'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brand,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _FinalAccessNotice(),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: scrollable
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: content,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(17),
              child: content,
            ),
    );
  }

  String _approvedDate(ClientDeliveryReviewModel item) {
    final date = item.reviewedAt ?? item.createdAt;
    return '${date.day.toString().padLeft(2, '0')} '
        '${_month(date.month)} ${date.year}';
  }

  String _month(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}

class _FinalFileTile extends StatelessWidget {
  const _FinalFileTile({
    required this.file,
    required this.controller,
  });

  final ProjectDeliveryFile file;
  final ClientFinalApprovalController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = file.fileName.contains('.')
        ? file.fileName.split('.').last.toUpperCase()
        : 'FILE';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                ext.length > 4 ? ext.substring(0, 4) : ext,
                style: const TextStyle(
                  color: AppColors.brand,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${file.formattedSize} · $ext',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            final busy = controller.openingFileId.value == file.id;
            return IconButton.filledTonal(
              tooltip: 'Open final file',
              onPressed: controller.openingFileId.value.isNotEmpty
                  ? null
                  : () => controller.openFile(file),
              icon: busy
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              style: IconButton.styleFrom(
                foregroundColor: AppColors.brand,
                backgroundColor: AppColors.brandSoft,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.brand),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _ApprovedBadge extends StatelessWidget {
  const _ApprovedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Text(
        'Approved',
        style: TextStyle(
          color: AppColors.success,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Text(
        'This approved delivery has no file attachments. You can still review the Engineer’s handover note.',
        style: TextStyle(color: AppColors.textSecondary, height: 1.45),
      ),
    );
  }
}

class _FinalAccessNotice extends StatelessWidget {
  const _FinalAccessNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: AppColors.info, size: 19),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Files are private. WorkBridge creates a short-lived secure link when you open a file; access is limited to the project parties.',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
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
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: .22)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: AppColors.warningInk),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Final work approval and payment release are separate. This page provides access to accepted files; it does not charge a card, hold funds, or release an Engineer payout.',
              style: TextStyle(
                color: AppColors.warningInk,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoFinalSelection extends StatelessWidget {
  const _NoFinalSelection();

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
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_outlined, size: 38, color: AppColors.textTertiary),
          SizedBox(height: 11),
          Text(
            'No approved project selected',
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Select a completed project to view its final files.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _EmptyListState extends StatelessWidget {
  const _EmptyListState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(Icons.verified_outlined, size: 34, color: AppColors.textTertiary),
        SizedBox(height: 9),
        Text(
          'No final files yet',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 5),
        Text(
          'When you approve an Engineer’s delivery on the Delivery Reviews page, it will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.45),
        ),
      ],
    );
  }
}

class _FinalLoadingState extends StatelessWidget {
  const _FinalLoadingState();

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

class _FinalErrorState extends StatelessWidget {
  const _FinalErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 38, color: AppColors.error),
              const SizedBox(height: 12),
              const Text(
                'Could not load final files',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
