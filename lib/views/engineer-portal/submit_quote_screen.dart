import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/controllers/submit_quote_controller.dart';
import 'package:permit_plans/models/engineer_task_invitation_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

/// Quote composer shown after an Engineer opens a pending task invitation.
/// It is responsive: stacked on mobile and two-column on laptop/desktop.
class SubmitQuoteScreen extends GetView<SubmitQuoteController> {
  const SubmitQuoteScreen({super.key});

  static const double _wideBreakpoint = 960;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Submit a quote',
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
          icon: Icons.request_quote_outlined,
          selectedIcon: Icons.request_quote_rounded,
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
          tooltip: 'Back to invitations',
          onPressed: controller.goBack,
          icon: const Icon(Icons.close_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _wideBreakpoint;
          return _SubmitQuoteBody(
            controller: controller,
            isWide: isWide,
          );
        },
      ),
    );
  }
}

class _SubmitQuoteBody extends StatelessWidget {
  const _SubmitQuoteBody({
    required this.controller,
    required this.isWide,
  });

  final SubmitQuoteController controller;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final horizontal = isWide ? 32.0 : 18.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageIntro(invitation: controller.invitation),
              const SizedBox(height: 24),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _QuoteForm(controller: controller)),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 4,
                      child: _QuoteSidePanel(
                        controller: controller,
                        invitation: controller.invitation,
                      ),
                    ),
                  ],
                )
              else ...[
                _QuoteSidePanel(
                  controller: controller,
                  invitation: controller.invitation,
                  compact: true,
                ),
                const SizedBox(height: 18),
                _QuoteForm(controller: controller),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PageIntro extends StatelessWidget {
  const _PageIntro({required this.invitation});

  final EngineerTaskInvitation invitation;

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
            'INVITATION RESPONSE  ·  STEP 1 OF 2',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.warningInk,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ),
        const SizedBox(height: 13),
        Text(
          'Prepare your quote',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Review the Client’s request and send a clear offer. You can discuss changes after the Client reviews it.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _QuoteSidePanel extends StatelessWidget {
  const _QuoteSidePanel({
    required this.controller,
    required this.invitation,
    this.compact = false,
  });

  final SubmitQuoteController controller;
  final EngineerTaskInvitation invitation;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: AppRadii.card,
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: AppRadii.chip,
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'PROJECT INVITATION',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  _SmallPill(
                    label: 'Pending',
                    background: AppColors.saffron,
                    foreground: AppColors.ink,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                invitation.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    backgroundImage: invitation.clientAvatarUrl == null
                        ? null
                        : NetworkImage(invitation.clientAvatarUrl!),
                    child: invitation.clientAvatarUrl == null
                        ? Text(
                            invitation.clientInitials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      invitation.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.white.withValues(alpha: 0.18)),
              const SizedBox(height: 10),
              _DarkInfoRow(
                icon: Icons.category_outlined,
                label: 'Category',
                value: invitation.category,
              ),
              const SizedBox(height: 10),
              _DarkInfoRow(
                icon: Icons.event_outlined,
                label: 'Requested deadline',
                value: invitation.deadlineLabel,
              ),
              const SizedBox(height: 10),
              _DarkInfoRow(
                icon: Icons.attach_file_rounded,
                label: 'Reference files',
                value: '${invitation.attachmentCount} attached',
              ),
              const SizedBox(height: 10),
              _DarkInfoRow(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Client budget guide',
                value: invitation.budgetLabel,
              ),
            ],
          ),
        ),
        if (invitation.requiredSkills.isNotEmpty) ...[
          const SizedBox(height: 16),
          _WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Requested skills',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: invitation.requiredSkills
                      .map((skill) => _SkillChip(label: skill))
                      .toList(growable: false),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                compact ? 'Your estimated earnings' : 'Quote breakdown',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                final amount = controller.amountMinor.value;
                final net = controller.estimatedEngineerNetMinor;
                return Column(
                  children: [
                    _BreakdownRow(
                      label: 'Your quote',
                      value: amount == null
                          ? '—'
                          : _formatMinor(invitation.currency, amount),
                    ),
                    const SizedBox(height: 9),
                    _BreakdownRow(
                      label: 'Platform fee (5%)',
                      value: amount == null
                          ? '—'
                          : _formatMinor(
                              invitation.currency,
                              amount - (net ?? amount),
                            ),
                      valueColor: AppColors.textSecondary,
                    ),
                    const Divider(height: 22),
                    _BreakdownRow(
                      label: 'Estimated you receive',
                      value: net == null
                          ? '—'
                          : _formatMinor(invitation.currency, net),
                      valueColor: AppColors.success,
                      emphasized: true,
                    ),
                  ],
                );
              }),
              const SizedBox(height: 10),
              Text(
                'Payment processing fees, taxes and currency conversion are not included. No payment is collected at this stage.',
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
  }
}

class _QuoteForm extends StatelessWidget {
  const _QuoteForm({required this.controller});

  final SubmitQuoteController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _WhiteCard(
      padding: const EdgeInsets.all(22),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your proposal',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Set a realistic price and explain exactly what the Client will receive.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            _FieldLabel(
              title: 'Your total price',
              requiredField: true,
              trailing: _SmallPill(
                label: controller.invitation.currency,
                background: AppColors.brandSoft,
                foreground: AppColors.brand,
              ),
            ),
            TextFormField(
              controller: controller.amountController,
              onChanged: controller.onAmountChanged,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              validator: controller.validateAmount,
              decoration: InputDecoration(
                hintText: controller.currencyDecimals == 0 ? 'e.g. 500' : 'e.g. 500.00',
                prefixIcon: const Icon(Icons.payments_outlined),
                suffixText: controller.invitation.currency,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'This is the amount the Client will be asked to fund if your quote is accepted.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            _FieldLabel(title: 'Estimated delivery time', requiredField: true),
            TextFormField(
              controller: controller.deliveryDaysController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: controller.validateDeliveryDays,
              decoration: const InputDecoration(
                hintText: 'e.g. 7',
                prefixIcon: Icon(Icons.calendar_month_outlined),
                suffixText: 'days',
              ),
            ),
            const SizedBox(height: 20),
            _FieldLabel(title: 'Scope of work', requiredField: true),
            TextFormField(
              controller: controller.scopeController,
              minLines: 5,
              maxLines: 8,
              maxLength: 6000,
              textCapitalization: TextCapitalization.sentences,
              validator: controller.validateScope,
              decoration: const InputDecoration(
                hintText: 'Explain the work you will complete, what is included, and what the Client will receive...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            _FieldLabel(title: 'Included revisions', requiredField: true),
            TextFormField(
              controller: controller.revisionsController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: controller.validateRevisions,
              decoration: const InputDecoration(
                hintText: '2',
                prefixIcon: Icon(Icons.replay_rounded),
                suffixText: 'revisions',
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Choose 0–10 revisions. Additional work outside the agreed scope can be discussed separately.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            _FieldLabel(title: 'Additional message', requiredField: false),
            TextFormField(
              controller: controller.notesController,
              minLines: 3,
              maxLines: 5,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Add a short note for the Client (optional)...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final error = controller.errorMessage.value;
              if (error.isEmpty) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.errorSoft,
                  borderRadius: AppRadii.chip,
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 19),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        error,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            Obx(() {
              final busy = controller.isSubmitting.value;
              return SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : controller.submitQuote,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(busy ? 'Submitting quote...' : 'Send quote to Client'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'You can negotiate changes after the Client reviews your quote.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.title,
    this.requiredField = false,
    this.trailing,
  });

  final String title;
  final bool requiredField;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: style,
                children: [
                  TextSpan(text: title),
                  if (requiredField)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.papaya),
                    ),
                ],
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _DarkInfoRow extends StatelessWidget {
  const _DarkInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Row(
      children: [
        Icon(icon, size: 17, color: Colors.white.withValues(alpha: 0.72)),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: style?.copyWith(color: Colors.white.withValues(alpha: 0.72)),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: style?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: (emphasized ? theme.textTheme.titleSmall : theme.textTheme.bodySmall)
                ?.copyWith(
              color: emphasized ? AppColors.ink : AppColors.textSecondary,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: (emphasized ? theme.textTheme.titleSmall : theme.textTheme.bodySmall)
              ?.copyWith(
            color: valueColor ?? AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.brand,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

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
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

String _formatMinor(String currency, int minor) {
  final decimals = _fractionDigitsForFormat(currency);
  final divisor = decimals == 0 ? 1 : (decimals == 3 ? 1000 : 100);
  final formatter = NumberFormat.currency(
    name: currency,
    decimalDigits: decimals,
  );
  return formatter.format(minor / divisor);
}

int _fractionDigitsForFormat(String currency) {
  final code = currency.toUpperCase();
  if (const {'BIF', 'CLP', 'DJF', 'GNF', 'ISK', 'JPY', 'KMF', 'KRW', 'PYG', 'RWF', 'UGX', 'VND', 'VUV', 'XAF', 'XOF', 'XPF'}.contains(code)) {
    return 0;
  }
  if (const {'BHD', 'IQD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND'}.contains(code)) {
    return 3;
  }
  return 2;
}
