import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/controllers/engineer_negotiation_controller.dart';
import 'package:permit_plans/models/engineer_negotiation_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

/// Engineer inbox for responding to Client counteroffers.
/// Acceptance only moves the task to `awaiting_payment`; no payment is taken.
class EngineerNegotiationScreen extends GetView<EngineerNegotiationController> {
  const EngineerNegotiationScreen({super.key});

  static const double _wideBreakpoint = 960;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Quote negotiations',
      currentIndex: 2,
      destinations: const [
        ShellDestination(
          icon: Icons.grid_view_outlined,
          selectedIcon: Icons.grid_view_rounded,
          label: 'Overview',
          route: AppRoutes.engineerHome,
        ),
        ShellDestination(
          icon: Icons.inbox_outlined,
          selectedIcon: Icons.inbox_rounded,
          label: 'Invitations',
          route: AppRoutes.engineerInvitations,
        ),
        ShellDestination(
          icon: Icons.compare_arrows_outlined,
          selectedIcon: Icons.compare_arrows_rounded,
          label: 'Negotiations',
          route: AppRoutes.engineerNegotiations,
        ),
        ShellDestination(
          icon: Icons.folder_open_outlined,
          label: 'Projects',
        ),
      ],
      sidebarItems: const [
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
          tooltip: 'Refresh negotiations',
          onPressed: controller.refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      body: _NegotiationBody(controller: controller),
    );
  }
}

class _NegotiationBody extends StatelessWidget {
  const _NegotiationBody({required this.controller});
  final EngineerNegotiationController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= EngineerNegotiationScreen._wideBreakpoint;
        final horizontal = isWide ? 34.0 : 18.0;
        return Obx(() {
          if (controller.isLoading.value && controller.negotiations.isEmpty) {
            return const _LoadingState();
          }
          if (controller.errorMessage.value.isNotEmpty &&
              controller.negotiations.isEmpty) {
            return _ErrorState(
              message: controller.errorMessage.value,
              onRetry: controller.refresh,
            );
          }

          final items = controller.filteredNegotiations;
          return RefreshIndicator(
            color: AppColors.papaya,
            onRefresh: controller.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PageHeader(isWide: isWide),
                      const SizedBox(height: 22),
                      _SummaryCards(controller: controller),
                      const SizedBox(height: 22),
                      _SearchAndFilters(controller: controller),
                      if (controller.errorMessage.value.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _InlineWarning(message: controller.errorMessage.value),
                      ],
                      const SizedBox(height: 18),
                      if (items.isEmpty)
                        _EmptyState(filter: controller.activeFilter.value)
                      else
                        _NegotiationGrid(
                          controller: controller,
                          items: items,
                          isWide: isWide,
                        ),
                      const SizedBox(height: 22),
                      const _PaymentNotice(),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.isWide});
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ENGINEER WORKSPACE  ·  QUOTES',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.papayaDark,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Negotiation room',
          style: (isWide ? theme.textTheme.headlineMedium : theme.textTheme.headlineSmall)
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.7),
        ),
        const SizedBox(height: 7),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(
            'Review Client counteroffers, compare them with your original quote, and agree on the project terms before payment.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.controller});
  final EngineerNegotiationController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = [
        _SummaryData(
          label: 'Needs your response',
          value: controller.needsResponseCount,
          icon: Icons.mark_email_unread_outlined,
          color: AppColors.papayaDark,
          soft: AppColors.papayaSoft,
        ),
        _SummaryData(
          label: 'Waiting for client',
          value: controller.waitingForClientCount,
          icon: Icons.hourglass_top_rounded,
          color: AppColors.saffronDark,
          soft: AppColors.saffronSoft,
        ),
        _SummaryData(
          label: 'Agreed',
          value: controller.acceptedCount,
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.success,
          soft: AppColors.successSoft,
        ),
      ];
      return LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          return Row(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                Expanded(child: _SummaryCard(data: items[index], compact: compact)),
                if (index != items.length - 1) SizedBox(width: compact ? 8 : 14),
              ],
            ],
          );
        },
      );
    });
  }
}

class _SummaryData {
  const _SummaryData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.soft,
  });
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color soft;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data, required this.compact});
  final _SummaryData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 17),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 30 : 38,
                height: compact ? 30 : 38,
                decoration: BoxDecoration(color: data.soft, borderRadius: BorderRadius.circular(AppRadii.sm)),
                child: Icon(data.icon, color: data.color, size: compact ? 17 : 20),
              ),
              const Spacer(),
              Text(
                data.value.toString(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            data.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({required this.controller});
  final EngineerNegotiationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: controller.setSearch,
          decoration: InputDecoration(
            hintText: 'Search by project, client or category',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
              borderRadius: AppRadii.input,
              borderSide: BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.input,
              borderSide: BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.input,
              borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final filters = const [
            ('needs_response', 'Needs your response'),
            ('waiting', 'Waiting for client'),
            ('closed', 'Closed'),
            ('all', 'All quotes'),
          ];
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in filters) ...[
                  ChoiceChip(
                    label: Text(filter.$2),
                    selected: controller.activeFilter.value == filter.$1,
                    onSelected: (_) => controller.setFilter(filter.$1),
                    selectedColor: AppColors.brandSoft,
                    side: BorderSide(
                      color: controller.activeFilter.value == filter.$1
                          ? AppColors.brandTint
                          : AppColors.outlineVariant,
                    ),
                    labelStyle: TextStyle(
                      color: controller.activeFilter.value == filter.$1
                          ? AppColors.brand
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _NegotiationGrid extends StatelessWidget {
  const _NegotiationGrid({
    required this.controller,
    required this.items,
    required this.isWide,
  });
  final EngineerNegotiationController controller;
  final List<EngineerNegotiationItem> items;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100 ? 2 : 1;
        final gap = 16.0;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _NegotiationCard(controller: controller, item: item),
              ),
          ],
        );
      },
    );
  }
}

class _NegotiationCard extends StatelessWidget {
  const _NegotiationCard({required this.controller, required this.item});
  final EngineerNegotiationController controller;
  final EngineerNegotiationItem item;

  @override
  Widget build(BuildContext context) {
    final needsResponse = item.needsEngineerResponse;
    final statusColor = needsResponse
        ? AppColors.papayaDark
        : item.isAccepted
            ? AppColors.success
            : item.isRejected
                ? AppColors.error
                : AppColors.saffronDark;
    final statusSoft = needsResponse
        ? AppColors.papayaSoft
        : item.isAccepted
            ? AppColors.successSoft
            : item.isRejected
                ? AppColors.errorSoft
                : AppColors.saffronSoft;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.brandSoft,
                backgroundImage: item.clientAvatarUrl == null
                    ? null
                    : NetworkImage(item.clientAvatarUrl!),
                child: item.clientAvatarUrl == null
                    ? Text(item.clientInitials, style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800))
                    : null,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.clientName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    Text(
                      [item.clientCountry, item.taskCategory].where((v) => v != null && v.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: item.statusLabel, color: statusColor, background: statusSoft),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.taskTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
          ),
          if (item.taskDescription.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              item.taskDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.45),
            ),
          ],
          const SizedBox(height: 16),
          _QuoteComparison(item: item),
          const SizedBox(height: 14),
          _DetailLine(icon: Icons.schedule_rounded, label: '${item.currentDeliveryDays} days delivery'),
          const SizedBox(height: 7),
          _DetailLine(icon: Icons.replay_rounded, label: '${item.currentIncludedRevisions} included revisions'),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _showHistory(context, controller, item),
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text('Negotiation history'),
              ),
              const Spacer(),
              if (needsResponse)
                Obx(() {
                  final busy = controller.isResponding.value && controller.busyQuoteId.value == item.quoteId;
                  return TextButton(
                    onPressed: busy ? null : () => _showCounterofferDialog(context, controller, item),
                    child: const Text('Counter'),
                  );
                }),
            ],
          ),
          if (needsResponse) ...[
            const SizedBox(height: 8),
            Obx(() {
              final busy = controller.isResponding.value && controller.busyQuoteId.value == item.quoteId;
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : () => _confirmReject(context, controller, item),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: busy ? null : () => _confirmAccept(context, controller, item),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: busy
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Accept counteroffer'),
                    ),
                  ),
                ],
              );
            }),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: statusSoft, borderRadius: BorderRadius.circular(AppRadii.md)),
              child: Text(
                item.isAccepted
                    ? 'You and the Client agreed on these terms. The Client’s next step is payment setup.'
                    : item.isRejected
                        ? 'This negotiation is closed. No payment has been taken.'
                        : 'Your quote is with the Client. You will be able to respond when they send a counteroffer.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: statusColor, height: 1.4, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmAccept(
    BuildContext context,
    EngineerNegotiationController controller,
    EngineerNegotiationItem item,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Accept Client counteroffer?'),
        content: Text(
          'You will agree to ${item.formattedCurrentAmount} with ${item.currentDeliveryDays} days delivery and ${item.currentIncludedRevisions} revisions. The next step is payment setup; this action does not charge a card.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Review again')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Accept terms')),
        ],
      ),
    );
    if (accepted == true) await controller.acceptCounteroffer(item);
  }

  Future<void> _confirmReject(
    BuildContext context,
    EngineerNegotiationController controller,
    EngineerNegotiationItem item,
  ) async {
    final rejected = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject this counteroffer?'),
        content: const Text('Rejecting closes this quote negotiation. No payment will be taken.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Keep negotiating')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reject quote'),
          ),
        ],
      ),
    );
    if (rejected == true) await controller.rejectCounteroffer(item);
  }

  Future<void> _showCounterofferDialog(
    BuildContext context,
    EngineerNegotiationController controller,
    EngineerNegotiationItem item,
  ) async {
    final draft = await showDialog<_EngineerCounterofferDraft>(
      context: context,
      builder: (_) => _EngineerCounterofferDialog(item: item),
    );
    if (draft == null) return;
    await controller.sendCounteroffer(
      item: item,
      amountText: draft.amount,
      deliveryDaysText: draft.deliveryDays,
      scopeOfWork: draft.scope,
      revisionsText: draft.revisions,
      notes: draft.notes,
    );
  }

  Future<void> _showHistory(
    BuildContext context,
    EngineerNegotiationController controller,
    EngineerNegotiationItem item,
  ) {
    final future = controller.loadHistory(item.quoteId);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.dialog),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Negotiation history', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                    IconButton(onPressed: () => Navigator.pop(dialogContext), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                const SizedBox(height: 5),
                Text(item.taskTitle, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 18),
                Expanded(
                  child: FutureBuilder<List<EngineerQuoteRevision>>(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('Could not load history.'));
                      }
                      final rows = snapshot.data ?? const <EngineerQuoteRevision>[];
                      if (rows.isEmpty) return const Center(child: Text('No negotiation history yet.'));
                      return ListView.separated(
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 22),
                        itemBuilder: (context, index) {
                          final revision = rows[index];
                          final by = revision.proposedBy == controller.currentUserId ? 'You' : 'Client';
                          final actionLabel = switch (revision.action) {
                            'initial' => 'Original quote',
                            'client_counteroffer' => 'Client counteroffer',
                            'engineer_counteroffer' => 'Your counteroffer',
                            _ => revision.action.replaceAll('_', ' '),
                          };
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text('Round ${revision.revisionNumber} · $actionLabel', style: const TextStyle(fontWeight: FontWeight.w800))),
                                  Text(revision.formattedAmount, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brand)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('$by · ${revision.deliveryDays} days · ${revision.includedRevisions} revisions', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              if (revision.scopeOfWork.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(revision.scopeOfWork, style: const TextStyle(height: 1.4)),
                              ],
                              if (revision.notes?.isNotEmpty == true) ...[
                                const SizedBox(height: 6),
                                Text(revision.notes!, style: const TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                              ],
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuoteComparison extends StatelessWidget {
  const _QuoteComparison({required this.item});
  final EngineerNegotiationItem item;

  @override
  Widget build(BuildContext context) {
    final changed = item.originalAmountMinor != item.currentAmountMinor ||
        item.originalDeliveryDays != item.currentDeliveryDays;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PriceColumn(
              label: 'Your original quote',
              amount: _formatAmount(item.originalAmountMinor, item.currency),
              delivery: '${item.originalDeliveryDays} days',
              muted: true,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward_rounded, color: AppColors.papayaDark, size: 19),
          ),
          Expanded(
            child: _PriceColumn(
              label: 'Client counteroffer',
              amount: item.formattedCurrentAmount,
              delivery: '${item.currentDeliveryDays} days',
              muted: false,
            ),
          ),
          if (changed)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.swap_horiz_rounded, color: AppColors.saffronDark, size: 18),
            ),
        ],
      ),
    );
  }

  String _formatAmount(int minor, String currency) {
    final digits = const {'BIF', 'CLP', 'DJF', 'GNF', 'ISK', 'JPY', 'KMF', 'KRW', 'PYG', 'RWF', 'UGX', 'VND', 'VUV', 'XAF', 'XOF', 'XPF'}.contains(currency.toUpperCase())
        ? 0
        : const {'BHD', 'IQD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND'}.contains(currency.toUpperCase())
            ? 3
            : 2;
    final divisor = digits == 0 ? 1 : digits == 3 ? 1000 : 100;
    return '${currency.toUpperCase()} ${(minor / divisor).toStringAsFixed(digits)}';
  }
}

class _PriceColumn extends StatelessWidget {
  const _PriceColumn({required this.label, required this.amount, required this.delivery, required this.muted});
  final String label;
  final String amount;
  final String delivery;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 5),
        Text(amount, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: muted ? AppColors.textSecondary : AppColors.brand)),
        const SizedBox(height: 3),
        Text(delivery, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 17, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
        ],
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color, required this.background});
  final String label;
  final Color color;
  final Color background;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadii.pill)),
        child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
      );
}

class _PaymentNotice extends StatelessWidget {
  const _PaymentNotice();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.saffronSoft,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.saffron.withValues(alpha: 0.35)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline_rounded, color: AppColors.saffronDark),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No card is charged during negotiation. If both sides agree, the Client will move to the separate payment step. Funds are not held by this app.',
                style: TextStyle(color: AppColors.warningInk, height: 1.45, fontSize: 12),
              ),
            ),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});
  final String filter;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: AppRadii.card,
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppColors.brandSoft, shape: BoxShape.circle),
              child: const Icon(Icons.handshake_outlined, color: AppColors.brand, size: 30),
            ),
            const SizedBox(height: 15),
            Text(
              filter == 'needs_response' ? 'No counteroffers waiting' : 'Nothing to show yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'When a Client replies to your quote with a counteroffer, it will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.45),
            ),
          ],
        ),
      );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 38, color: AppColors.error),
              const SizedBox(height: 12),
              const Text('Could not load negotiations', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 14),
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
            ],
          ),
        ),
      );
}

class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.errorSoft, borderRadius: BorderRadius.circular(AppRadii.md)),
        child: Text(message, style: const TextStyle(color: AppColors.error)),
      );
}

class _EngineerCounterofferDraft {
  const _EngineerCounterofferDraft({
    required this.amount,
    required this.deliveryDays,
    required this.scope,
    required this.revisions,
    this.notes,
  });
  final String amount;
  final String deliveryDays;
  final String scope;
  final String revisions;
  final String? notes;
}

class _EngineerCounterofferDialog extends StatefulWidget {
  const _EngineerCounterofferDialog({required this.item});
  final EngineerNegotiationItem item;

  @override
  State<_EngineerCounterofferDialog> createState() => _EngineerCounterofferDialogState();
}

class _EngineerCounterofferDialogState extends State<_EngineerCounterofferDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _days;
  late final TextEditingController _scope;
  late final TextEditingController _revisions;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: _formatCurrentAmount());
    _days = TextEditingController(text: widget.item.currentDeliveryDays.toString());
    _scope = TextEditingController(text: widget.item.currentScopeOfWork);
    _revisions = TextEditingController(text: widget.item.currentIncludedRevisions.toString());
    _notes = TextEditingController();
  }

  String _formatCurrentAmount() {
    final currency = widget.item.currency;
    final digits = const {'BIF', 'CLP', 'DJF', 'GNF', 'ISK', 'JPY', 'KMF', 'KRW', 'PYG', 'RWF', 'UGX', 'VND', 'VUV', 'XAF', 'XOF', 'XPF'}.contains(currency.toUpperCase())
        ? 0
        : const {'BHD', 'IQD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND'}.contains(currency.toUpperCase())
            ? 3
            : 2;
    final divisor = digits == 0 ? 1 : digits == 3 ? 1000 : 100;
    return (widget.item.currentAmountMinor / divisor).toStringAsFixed(digits);
  }

  @override
  void dispose() {
    _amount.dispose();
    _days.dispose();
    _scope.dispose();
    _revisions.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadii.dialog),
      title: const Text('Send a counteroffer'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Client proposed ${widget.item.formattedCurrentAmount}. You can revise the terms below.', style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'Your price (${widget.item.currency})', prefixIcon: const Icon(Icons.payments_outlined)),
                  validator: (value) => EngineerNegotiationController.parseAmountToMinor(value ?? '', widget.item.currency) == null ? 'Enter a valid positive amount.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _days,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Delivery time (days)', prefixIcon: Icon(Icons.schedule_rounded)),
                  validator: (value) {
                    final days = int.tryParse((value ?? '').trim());
                    return days == null || days < 1 || days > 3650 ? 'Enter between 1 and 3650 days.' : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _scope,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 6000,
                  decoration: const InputDecoration(labelText: 'Scope of work', alignLabelWithHint: true),
                  validator: (value) => (value?.trim().length ?? 0) < 30 ? 'Describe the scope in at least 30 characters.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _revisions,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Included revisions (0–10)', prefixIcon: Icon(Icons.replay_rounded)),
                  validator: (value) {
                    final count = int.tryParse((value ?? '').trim());
                    return count == null || count < 0 || count > 10 ? 'Enter 0 to 10 revisions.' : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  maxLength: 2000,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Message to Client (optional)', alignLabelWithHint: true),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.pop(
              context,
              _EngineerCounterofferDraft(
                amount: _amount.text.trim(),
                deliveryDays: _days.text.trim(),
                scope: _scope.text.trim(),
                revisions: _revisions.text.trim(),
                notes: _notes.text.trim(),
              ),
            );
          },
          child: const Text('Send counteroffer'),
        ),
      ],
    );
  }
}
