import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/controllers/client_quote_review_controller.dart';
import 'package:permit_plans/models/client_quote_review_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

/// Client inbox for Engineer quotations. Accepting a quote does not charge a
/// card; it only moves the task to `awaiting_payment`.
class ClientQuoteReviewScreen extends GetView<ClientQuoteReviewController> {
  const ClientQuoteReviewScreen({super.key});

  static const double _wideBreakpoint = 960;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Quote review',
      currentIndex: 1,
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
          icon: Icons.folder_open_outlined,
          label: 'My projects',
        ),
        SidebarItem(
          icon: Icons.receipt_long_outlined,
          label: 'Payments',
        ),
        SidebarItem(
          icon: Icons.person_outline_rounded,
          label: 'My profile',
        ),
        SidebarItem(
          icon: Icons.help_outline_rounded,
          label: 'Help & support',
        ),
        SidebarItem(
          icon: Icons.settings_outlined,
          label: 'Settings',
        ),
      ],
      actions: [
        IconButton(
          tooltip: 'Refresh quotes',
          onPressed: controller.refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      body: _ClientQuoteReviewBody(
        controller: controller,
        wideBreakpoint: _wideBreakpoint,
      ),
    );
  }
}

class _ClientQuoteReviewBody extends StatelessWidget {
  const _ClientQuoteReviewBody({
    required this.controller,
    required this.wideBreakpoint,
  });

  final ClientQuoteReviewController controller;
  final double wideBreakpoint;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.quotes.isEmpty) {
        return const _QuoteLoadingState();
      }
      if (controller.errorMessage.value.isNotEmpty &&
          controller.quotes.isEmpty) {
        return _QuoteErrorState(
          message: controller.errorMessage.value,
          onRetry: () => controller.loadQuotes(),
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= wideBreakpoint;
          final horizontal = isWide ? 34.0 : 18.0;
          final quotes = controller.filteredQuotes.value.toList(growable: false);

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
                      _QuoteStats(controller: controller),
                      const SizedBox(height: 22),
                      _SearchAndFilters(controller: controller),
                      const SizedBox(height: 20),
                      if (controller.errorMessage.value.isNotEmpty)
                        _InlineError(message: controller.errorMessage.value),
                      if (quotes.isEmpty)
                        _QuoteEmptyState(
                          filter: controller.activeFilter.value,
                          onFindEngineers: () => Get.toNamed<void>(
                            AppRoutes.clientBrowseEngineers,
                          ),
                        )
                      else
                        _QuoteGrid(
                          controller: controller,
                          quotes: quotes,
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
        },
      );
    });
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.saffronSoft,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Text(
            'CLIENT WORKSPACE  ·  QUOTES',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.warningInk,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 13),
        Text(
          'Review engineer quotes',
          style: (isWide
                  ? theme.textTheme.headlineMedium
                  : theme.textTheme.headlineSmall)
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8),
        ),
        const SizedBox(height: 7),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(
            'Compare the proposed price, delivery time and scope. Accept, reject or send a counteroffer to keep the discussion moving.',
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

class _QuoteStats extends StatelessWidget {
  const _QuoteStats({required this.controller});

  final ClientQuoteReviewController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stats = [
        _StatData(
          label: 'Needs review',
          filterKey: 'needs_action',
          value: controller.needsActionCount.toString(),
          icon: Icons.mark_email_unread_outlined,
          color: AppColors.papaya,
          soft: AppColors.papayaSoft,
        ),
        _StatData(
          label: 'Negotiating',
          filterKey: 'negotiating',
          value: controller.negotiatingCount.toString(),
          icon: Icons.compare_arrows_rounded,
          color: AppColors.saffronDark,
          soft: AppColors.saffronSoft,
        ),
        _StatData(
          label: 'Accepted',
          filterKey: 'accepted',
          value: controller.acceptedCount.toString(),
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.success,
          soft: AppColors.successSoft,
        ),
      ];
      return LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;
          return Row(
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                Expanded(
                  child: _StatCard(
                    data: stats[i],
                    compact: compact,
                    isSelected: controller.activeFilter.value == stats[i].filterKey,
                    onTap: () => controller.setFilter(stats[i].filterKey),
                  ),
                ),
                if (i != stats.length - 1)
                  SizedBox(width: compact ? 8 : 14),
              ],
            ],
          );
        },
      );
    });
  }
}

class _StatData {
  const _StatData({
    required this.label,
    required this.filterKey,
    required this.value,
    required this.icon,
    required this.color,
    required this.soft,
  });

  final String label;
  final String filterKey;
  final String value;
  final IconData icon;
  final Color color;
  final Color soft;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.data,
    required this.compact,
    required this.isSelected,
    required this.onTap,
  });

  final _StatData data;
  final bool compact;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadii.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.all(compact ? 12 : 17),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandSoft.withValues(alpha: 0.55)
                : Theme.of(context).cardColor,
            borderRadius: AppRadii.card,
            border: Border.all(
              color: isSelected ? AppColors.brandTint : AppColors.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (!compact) ...[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: data.soft,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(data.icon, color: data.color),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.value,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: data.color,
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
              if (isSelected)
                Icon(Icons.check_circle_rounded,
                    size: 17, color: AppColors.brand),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({required this.controller});

  final ClientQuoteReviewController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const filters = <(String, String)>[
      ('needs_action', 'Needs review'),
      ('negotiating', 'Negotiating'),
      ('accepted', 'Accepted'),
      ('rejected', 'Rejected'),
      ('all', 'All quotes'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: controller.setSearch,
          decoration: InputDecoration(
            hintText: 'Search by task or engineer...',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
              borderRadius: AppRadii.input,
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.input,
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 13),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Obx(
            () => Row(
              children: [
                for (final filter in filters) ...[
                  ChoiceChip(
                    label: Text(filter.$2),
                    selected: controller.activeFilter.value == filter.$1,
                    onSelected: (_) => controller.setFilter(filter.$1),
                    selectedColor: AppColors.brandSoft,
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                      color: controller.activeFilter.value == filter.$1
                          ? AppColors.brand
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(
                      color: controller.activeFilter.value == filter.$1
                          ? AppColors.brandTint
                          : AppColors.outlineVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuoteGrid extends StatelessWidget {
  const _QuoteGrid({
    required this.controller,
    required this.quotes,
    required this.isWide,
  });

  final ClientQuoteReviewController controller;
  final List<ClientQuoteReviewItem> quotes;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1180 ? 2 : 1;
        final gap = 18.0;
        final cardWidth = columns == 2
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final quote in quotes)
              SizedBox(
                width: cardWidth,
                child: _QuoteCard(
                  quote: quote,
                  controller: controller,
                  isWide: isWide,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.quote,
    required this.controller,
    required this.isWide,
  });

  final ClientQuoteReviewItem quote;
  final ClientQuoteReviewController controller;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusStyle = _statusStyle(quote.status);

    return Container(
      padding: const EdgeInsets.all(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: AppColors.brandSoft,
                backgroundImage: quote.engineerAvatarUrl == null
                    ? null
                    : NetworkImage(quote.engineerAvatarUrl!),
                child: quote.engineerAvatarUrl == null
                    ? Text(
                        quote.initials,
                        style: const TextStyle(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote.engineerName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      quote.engineerHeadline.isEmpty
                          ? 'Marketplace engineer'
                          : quote.engineerHeadline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if ((quote.engineerCountry ?? '').isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        quote.engineerCountry!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusPill(
                label: quote.statusLabel,
                color: statusStyle.$1,
                background: statusStyle.$2,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote.taskTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  quote.taskCategory,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (quote.taskDescription.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    quote.taskDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ENGINEER’S QUOTE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      quote.formattedAmount,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                      ),
                    ),
                  ],
                ),
              ),
              _InfoPill(
                icon: Icons.calendar_month_outlined,
                text: '${quote.deliveryDays} days',
              ),
              const SizedBox(width: 7),
              _InfoPill(
                icon: Icons.refresh_rounded,
                text: '${quote.includedRevisions} rev.',
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'SCOPE OF WORK',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            quote.scopeOfWork,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          if ((quote.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.outlineVariant),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text(
                'Engineer’s note: ${quote.notes}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _showHistory(context),
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text('Quote history'),
              ),
              const Spacer(),
              Text(
                DateFormat('d MMM yyyy').format(quote.submittedAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (quote.canRespond)
            Obx(() {
              final busy = controller.isResponding.value &&
                  controller.busyQuoteId.value == quote.quoteId;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: busy ? null : () => _confirmAccept(context),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Accept quote'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brand,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : () => _showCounteroffer(context),
                          icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                          label: const Text('Negotiate'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.brand,
                            side: const BorderSide(color: AppColors.brandTint),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: busy ? null : () => _confirmReject(context),
                      child: const Text('Reject quote'),
                    ),
                  ),
                ],
              );
            })
          else
            _ReadOnlyStatusNotice(quote: quote),
        ],
      ),
    );
  }

  Future<void> _confirmAccept(BuildContext context) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Accept this quote?'),
        content: Text(
          'You are agreeing to ${quote.formattedAmount} for “${quote.taskTitle}”. '
          'This does not charge your card. You will fund the project in the next step.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Get.back<bool>(result: true),
            child: const Text('Accept quote'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.acceptQuote(quote);
  }

  Future<void> _confirmReject(BuildContext context) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Reject this quote?'),
        content: const Text(
          'The quote will be marked as rejected and this task invitation will be closed. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('Keep quote'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Get.back<bool>(result: true),
            child: const Text('Reject quote'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.rejectQuote(quote);
  }

  Future<void> _showCounteroffer(BuildContext context) async {
    await Get.dialog<void>(
      _CounterofferDialog(quote: quote, controller: controller),
      barrierDismissible: false,
    );
  }

  Future<void> _showHistory(BuildContext context) async {
    await controller.loadHistory(quote.quoteId);
    await Get.dialog<void>(
      _QuoteHistoryDialog(quote: quote, controller: controller),
    );
  }
}

class _CounterofferDialog extends StatefulWidget {
  const _CounterofferDialog({
    required this.quote,
    required this.controller,
  });

  final ClientQuoteReviewItem quote;
  final ClientQuoteReviewController controller;

  @override
  State<_CounterofferDialog> createState() => _CounterofferDialogState();
}

class _CounterofferDialogState extends State<_CounterofferDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _days;
  late final TextEditingController _scope;
  late final TextEditingController _revisions;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final quote = widget.quote;
    _amount = TextEditingController(text: quote.amountInput);
    _days = TextEditingController(text: quote.deliveryDays.toString());
    _scope = TextEditingController(text: quote.scopeOfWork);
    _revisions = TextEditingController(text: quote.includedRevisions.toString());
    _notes = TextEditingController();
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
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: AppRadii.dialog),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 820),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Send a counteroffer', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  'Your counteroffer will be saved as a new revision. The Engineer will be able to accept it or respond with another offer.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.45),
                ),
                const SizedBox(height: 20),
                _DialogField(
                  label: 'Your proposed price (${widget.quote.currency})',
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => ClientQuoteReviewController.parseAmountToMinor(value ?? '', widget.quote.currency) == null
                      ? 'Enter a valid amount.'
                      : null,
                  prefix: widget.quote.currency,
                ),
                const SizedBox(height: 14),
                _DialogField(
                  label: 'Delivery time (days)',
                  controller: _days,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final days = int.tryParse((value ?? '').trim());
                    return days == null || days < 1 || days > 3650
                        ? 'Enter between 1 and 3650 days.'
                        : null;
                  },
                ),
                const SizedBox(height: 14),
                _DialogField(
                  label: 'Scope of work',
                  controller: _scope,
                  maxLines: 4,
                  validator: (value) => (value ?? '').trim().length < 30
                      ? 'Please provide at least 30 characters.'
                      : null,
                ),
                const SizedBox(height: 14),
                _DialogField(
                  label: 'Included revisions (0–10)',
                  controller: _revisions,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final number = int.tryParse((value ?? '').trim());
                    return number == null || number < 0 || number > 10
                        ? 'Enter a number from 0 to 10.'
                        : null;
                  },
                ),
                const SizedBox(height: 14),
                _DialogField(
                  label: 'Message to Engineer (optional)',
                  controller: _notes,
                  maxLines: 3,
                  validator: (value) => (value?.length ?? 0) > 2000
                      ? 'Keep your note under 2000 characters.'
                      : null,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.controller.isResponding.value
                            ? null
                            : () => Get.back<void>(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(
                        () => FilledButton.icon(
                          onPressed: widget.controller.isResponding.value
                              ? null
                              : _submit,
                          icon: widget.controller.isResponding.value
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, size: 17),
                          label: const Text('Send counteroffer'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brand,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await widget.controller.sendCounteroffer(
      quote: widget.quote,
      amountText: _amount.text,
      deliveryDaysText: _days.text,
      scopeOfWork: _scope.text,
      revisionsText: _revisions.text,
      notes: _notes.text,
    );
    if (success && mounted) Get.back<void>();
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.prefix,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            prefixText: prefix == null ? null : '$prefix ',
            filled: true,
            fillColor: AppColors.inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(borderRadius: AppRadii.input),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.input,
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuoteHistoryDialog extends StatelessWidget {
  const _QuoteHistoryDialog({required this.quote, required this.controller});

  final ClientQuoteReviewItem quote;
  final ClientQuoteReviewController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadii.dialog),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quote history', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(quote.taskTitle, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              SizedBox(
                height: 390,
                child: Obx(() {
                  if (controller.historyError.value.isNotEmpty) {
                    return Center(child: Text(controller.historyError.value));
                  }
                  if (controller.history.isEmpty) {
                    return const Center(child: Text('No negotiation history found.'));
                  }
                  return ListView.separated(
                    itemCount: controller.history.length,
                    separatorBuilder: (_, __) => const Divider(height: 22),
                    itemBuilder: (context, index) {
                      final revision = controller.history[index];
                      final isClient = revision.proposedBy == controller.currentUserId;
                      final actor = isClient ? 'Your offer' : 'Engineer’s offer';
                      final action = switch (revision.action) {
                        'initial' => 'Original quote',
                        'client_counteroffer' => 'Client counteroffer',
                        'engineer_counteroffer' => 'Engineer counteroffer',
                        _ => revision.action.replaceAll('_', ' '),
                      };
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: isClient ? AppColors.brandSoft : AppColors.papayaSoft,
                            child: Icon(
                              isClient ? Icons.person_outline_rounded : Icons.engineering_outlined,
                              size: 18,
                              color: isClient ? AppColors.brand : AppColors.papayaDark,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$actor · $action', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(
                                  '${revision.formattedAmount} · ${revision.deliveryDays} days · ${revision.includedRevisions} revisions',
                                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 5),
                                Text(revision.scopeOfWork, style: theme.textTheme.bodySmall?.copyWith(height: 1.4)),
                                if ((revision.notes ?? '').isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text('Note: ${revision.notes}', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                                  ),
                                const SizedBox(height: 5),
                                Text(DateFormat('d MMM yyyy, h:mm a').format(revision.createdAt), style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textTertiary)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.back<void>(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyStatusNotice extends StatelessWidget {
  const _ReadOnlyStatusNotice({required this.quote});

  final ClientQuoteReviewItem quote;

  @override
  Widget build(BuildContext context) {
    final isAccepted = quote.status == 'accepted';
    final isWaitingEngineer = quote.status == 'client_countered';
    final color = isAccepted ? AppColors.success : AppColors.textSecondary;
    final background = isAccepted ? AppColors.successSoft : AppColors.surfaceAlt;
    final message = isAccepted
        ? 'Both sides agreed to this quote. Review the final contract terms before moving to payment.'
        : isWaitingEngineer
            ? 'Your counteroffer has been sent. Waiting for the Engineer to respond.'
            : quote.status == 'rejected'
                ? 'You rejected this quote.'
                : 'This quote is no longer awaiting a response.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAccepted ? Icons.check_circle_outline : Icons.info_outline_rounded,
                color: color,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (isAccepted) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => Get.toNamed<void>(
                  AppRoutes.clientContractConfirmation,
                  arguments: quote.quoteId,
                ),
                icon: const Icon(Icons.description_outlined, size: 17),
                label: const Text('Review contract'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.brand),
          const SizedBox(width: 5),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.brand,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

(Color, Color) _statusStyle(String status) {
  switch (status) {
    case 'pending_client_review':
    case 'engineer_countered':
      return (AppColors.papayaDark, AppColors.papayaSoft);
    case 'client_countered':
      return (AppColors.warningInk, AppColors.saffronSoft);
    case 'accepted':
      return (AppColors.success, AppColors.successSoft);
    case 'rejected':
      return (AppColors.error, AppColors.errorSoft);
    default:
      return (AppColors.textSecondary, AppColors.surfaceAlt);
  }
}

class _QuoteEmptyState extends StatelessWidget {
  const _QuoteEmptyState({required this.filter, required this.onFindEngineers});

  final String filter;
  final VoidCallback onFindEngineers;

  @override
  Widget build(BuildContext context) {
    final isNeedsReview = filter == 'needs_action';
    return Container(
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
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: AppColors.brandSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.request_quote_outlined, color: AppColors.brand, size: 29),
          ),
          const SizedBox(height: 14),
          Text(
            isNeedsReview ? 'No quotes need your review' : 'No quotes here yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              isNeedsReview
                  ? 'When an invited Engineer sends a quote, it will appear here. You can accept, reject or negotiate the offer.'
                  : 'Try another filter or invite an Engineer to work on a task.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.45),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 17),
          OutlinedButton.icon(
            onPressed: onFindEngineers,
            icon: const Icon(Icons.search_rounded),
            label: const Text('Find engineers'),
          ),
        ],
      ),
    );
  }
}

class _PaymentNotice extends StatelessWidget {
  const _PaymentNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.saffronSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded, color: AppColors.warningInk),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Reviewing or accepting a quote does not charge your card. Payment happens only after both sides agree and you confirm the secure payment step.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.warningInk,
                height: 1.45,
              ),
            ),
          ),
        ],
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.error)),
    );
  }
}

class _QuoteLoadingState extends StatelessWidget {
  const _QuoteLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(color: AppColors.papaya),
      ),
    );
  }
}

class _QuoteErrorState extends StatelessWidget {
  const _QuoteErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 42, color: AppColors.error),
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
    );
  }
}
