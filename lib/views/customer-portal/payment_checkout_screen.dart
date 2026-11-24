import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/controllers/payment_checkout_controller.dart';
import 'package:permit_plans/models/contract_confirmation_model.dart';

class PaymentCheckoutScreen extends GetView<PaymentCheckoutController> {
  const PaymentCheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            );
          }

          final contract = controller.contract.value;
          if (contract == null) {
            return _CheckoutErrorState(
              message: controller.errorMessage.value.isEmpty
                  ? 'The contract could not be loaded.'
                  : controller.errorMessage.value,
              onRetry: controller.loadContract,
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1000;
              final horizontalPadding = isWide ? 36.0 : 18.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  22,
                  horizontalPadding,
                  36,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CheckoutTopBar(isWide: isWide),
                        const SizedBox(height: 28),
                        _CheckoutHeading(isWide: isWide),
                        const SizedBox(height: 22),
                        const _CheckoutSteps(),
                        const SizedBox(height: 24),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: _MainCheckoutColumn(
                                  contract: contract,
                                  isAlreadyFunded: controller.isAlreadyFunded,
                                ),
                              ),
                              const SizedBox(width: 24),
                              SizedBox(
                                width: 360,
                                child: _CheckoutSummaryColumn(
                                  controller: controller,
                                  contract: contract,
                                  isAlreadyFunded: controller.isAlreadyFunded,
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _MainCheckoutColumn(
                                contract: contract,
                                isAlreadyFunded: controller.isAlreadyFunded,
                              ),
                              const SizedBox(height: 18),
                              _CheckoutSummaryColumn(
                                controller: controller,
                                contract: contract,
                                isAlreadyFunded: controller.isAlreadyFunded,
                              ),
                            ],
                          ),
                        const SizedBox(height: 22),
                        const _SecurityFooter(),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'WorkBridge · Secure project payments',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _CheckoutTopBar extends StatelessWidget {
  const _CheckoutTopBar({required this.isWide});
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: () => Get.back<void>(),
          icon: const Icon(Icons.arrow_back_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.brandSoft,
            foregroundColor: AppColors.brand,
          ),
          tooltip: 'Back',
        ),
        const SizedBox(width: 12),
        Text(
          'WorkBridge',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.brand,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
              ),
        ),
        const Spacer(),
        if (isWide)
          const Row(
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 16, color: AppColors.success),
              SizedBox(width: 7),
              Text(
                'Secure checkout preview',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          )
        else
          const Icon(Icons.verified_user_outlined,
              color: AppColors.success, size: 21),
      ],
    );
  }
}

class _CheckoutHeading extends StatelessWidget {
  const _CheckoutHeading({required this.isWide});
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
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_rounded,
                  color: AppColors.saffronDark, size: 15),
              SizedBox(width: 7),
              Text(
                'CONTRACT CONFIRMED',
                style: TextStyle(
                  color: AppColors.saffronDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Text(
          'Review your checkout',
          style: (isWide
                  ? theme.textTheme.headlineLarge
                  : theme.textTheme.headlineMedium)
              ?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.1,
          ),
        ),
        const SizedBox(height: 7),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            'Your project terms are agreed. Review the amount and payment process before moving to the payment provider.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckoutSteps extends StatelessWidget {
  const _CheckoutSteps();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: const Row(
        children: [
          _StepItem(number: '01', label: 'Agreement', done: true),
          Expanded(child: _StepLine(done: true)),
          _StepItem(number: '02', label: 'Payment', active: true),
          Expanded(child: _StepLine(done: false)),
          _StepItem(number: '03', label: 'Funded'),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.number,
    required this.label,
    this.done = false,
    this.active = false,
  });
  final String number;
  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = done || active ? AppColors.brand : AppColors.textTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 29,
          height: 29,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done ? AppColors.successSoft :
                active ? AppColors.brandSoft : AppColors.surfaceAlt,
            shape: BoxShape.circle,
          ),
          child: done
              ? const Icon(Icons.check_rounded,
                  size: 16, color: AppColors.success)
              : Text(
                  number,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: active || done ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.done});
  final bool done;

  @override
  Widget build(BuildContext context) => Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: done ? AppColors.success.withValues(alpha: 0.45) : AppColors.outlineVariant,
      );
}

class _MainCheckoutColumn extends StatelessWidget {
  const _MainCheckoutColumn({
    required this.contract,
    required this.isAlreadyFunded,
  });

  final ContractConfirmationModel contract;
  final bool isAlreadyFunded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PaymentStatusBanner(isAlreadyFunded: isAlreadyFunded),
        const SizedBox(height: 16),
        _ProjectCard(contract: contract),
        const SizedBox(height: 16),
        _PaymentMethodCard(),
        const SizedBox(height: 16),
        const _ProtectionCard(),
      ],
    );
  }
}

class _PaymentStatusBanner extends StatelessWidget {
  const _PaymentStatusBanner({required this.isAlreadyFunded});
  final bool isAlreadyFunded;

  @override
  Widget build(BuildContext context) {
    final color = isAlreadyFunded ? AppColors.success : AppColors.warningInk;
    final background = isAlreadyFunded ? AppColors.successSoft : AppColors.saffronSoft;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isAlreadyFunded ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
            color: color,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAlreadyFunded ? 'Project payment is funded' : 'Contract confirmed · awaiting payment',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  isAlreadyFunded
                      ? 'The payment provider has already marked this contract as funded. Do not pay again.'
                      : 'The agreed project terms are saved. The Engineer should begin only after the payment provider confirms funding.',
                  style: TextStyle(color: color.withValues(alpha: 0.88), height: 1.4, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.contract});
  final ContractConfirmationModel contract;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SurfaceCard(
      title: 'Project summary',
      subtitle: 'The agreed contract you are funding',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.brandSoft,
                backgroundImage: contract.engineerAvatarUrl == null
                    ? null
                    : NetworkImage(contract.engineerAvatarUrl!),
                child: contract.engineerAvatarUrl == null
                    ? Text(
                        contract.engineerInitials,
                        style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w900),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contract.engineerName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    if ((contract.engineerHeadline ?? '').isNotEmpty)
                      Text(contract.engineerHeadline!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    if ((contract.engineerCountry ?? '').isNotEmpty)
                      Text(contract.engineerCountry!, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textTertiary)),
                  ],
                ),
              ),
              const Icon(Icons.verified_user_outlined, color: AppColors.success),
            ],
          ),
          const SizedBox(height: 17),
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: 15),
          Text(
            contract.taskTitle,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: AppColors.ink),
          ),
          const SizedBox(height: 5),
          Text(
            contract.taskCategory,
            style: theme.textTheme.labelMedium?.copyWith(color: AppColors.papayaDark, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            contract.taskDescription,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _InfoPill(icon: Icons.calendar_today_outlined, text: '${contract.deliveryDays} days'),
              _InfoPill(icon: Icons.replay_rounded, text: '${contract.includedRevisions} revisions'),
              _InfoPill(icon: Icons.sell_outlined, text: contract.currency),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SurfaceCard(
      title: 'Payment method',
      subtitle: 'Your card will be entered on the payment provider’s secure page.',
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.credit_card_rounded, color: AppColors.brand, size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Credit or debit card', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text('Added securely on the provider checkout', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(color: AppColors.saffronSoft, borderRadius: BorderRadius.circular(20)),
              child: const Text('Not connected', style: TextStyle(color: AppColors.saffronDark, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
      footer: Text(
        'WorkBridge will not ask you to type or store your full card number or CVV in this app.',
        style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, height: 1.45),
      ),
    );
  }
}

class _ProtectionCard extends StatelessWidget {
  const _ProtectionCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.brandDark,
        borderRadius: BorderRadius.circular(19),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.shield_moon_outlined, color: AppColors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment protection', style: theme.textTheme.titleSmall?.copyWith(color: AppColors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(
                  'Funds will be treated as secured only after the approved payment provider confirms the transaction. Release to the Engineer will follow the contract approval process.',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.82), height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutSummaryColumn extends StatelessWidget {
  const _CheckoutSummaryColumn({
    required this.controller,
    required this.contract,
    required this.isAlreadyFunded,
  });

  final PaymentCheckoutController controller;
  final ContractConfirmationModel contract;
  final bool isAlreadyFunded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SurfaceCard(
      title: 'Payment summary',
      subtitle: 'Review the amount agreed in your contract',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Project amount', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              contract.formattedAmount,
              style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.brand, fontWeight: FontWeight.w900, letterSpacing: -0.8),
            ),
          ),
          const SizedBox(height: 15),
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: 13),
          _SummaryLine(label: 'Agreed project price', value: contract.formattedAmount),
          const SizedBox(height: 10),
          const _SummaryLine(label: 'WorkBridge client fee', value: 'No extra fee'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: AppColors.saffronSoft, borderRadius: BorderRadius.circular(12)),
            child: Text(
              'The 5% marketplace commission is deducted from the Engineer’s agreed payout, not added as a separate Client fee. Any provider fees, taxes or currency conversion will be shown by the payment provider before payment.',
              style: theme.textTheme.labelSmall?.copyWith(color: AppColors.warningInk, height: 1.45),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: 13),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Contract total', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
              Text(contract.formattedAmount, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isAlreadyFunded ? null : controller.openPaymentPreview,
              icon: Icon(isAlreadyFunded ? Icons.check_circle_outline : Icons.lock_outline_rounded),
              label: Text(isAlreadyFunded ? 'Already funded' : 'Continue to payment preview'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.papaya,
                foregroundColor: AppColors.ink,
                disabledBackgroundColor: AppColors.successSoft,
                disabledForegroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: controller.loadContract,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Refresh contract status'),
              style: TextButton.styleFrom(foregroundColor: AppColors.brand),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityFooter extends StatelessWidget {
  const _SecurityFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.privacy_tip_outlined, color: AppColors.success, size: 19),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Security note: card details and CVV must be entered only on the approved payment provider’s hosted checkout. They must never be stored in Supabase or application logs.',
              style: TextStyle(color: AppColors.success, fontSize: 11, height: 1.45, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutErrorState extends StatelessWidget {
  const _CheckoutErrorState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(color: AppColors.errorSoft, shape: BoxShape.circle),
                child: const Icon(Icons.receipt_long_outlined, color: AppColors.error, size: 30),
              ),
              const SizedBox(height: 18),
              Text('Checkout unavailable', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: AppColors.white),
              ),
              TextButton(onPressed: () => Get.back<void>(), child: const Text('Go back')),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.title,
    this.subtitle,
    this.footer,
  });
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: theme.textTheme.titleMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w900)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 17),
          ],
          child,
          if (footer != null) ...[
            const SizedBox(height: 14),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(30)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
          const SizedBox(width: 12),
          Text(value, style: const TextStyle(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      );
}
