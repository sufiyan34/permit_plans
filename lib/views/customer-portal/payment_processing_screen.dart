import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/controllers/payment_processing_controller.dart';
import 'package:permit_plans/models/contract_confirmation_model.dart';

/// Screen 19 — local payment-result demonstration.
///
/// A demo success/failure is not a real transaction. It never marks the
/// contract as funded and must not be used as proof of payment.
class PaymentProcessingScreen extends GetView<PaymentProcessingController> {
  const PaymentProcessingScreen({super.key});

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
            return _PaymentLoadError(
              message: controller.errorMessage.value.isEmpty
                  ? 'The contract could not be loaded.'
                  : controller.errorMessage.value,
              onRetry: controller.loadContract,
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              final horizontal = isWide ? 34.0 : 18.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(horizontal, 22, horizontal, 34),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopBar(isWide: isWide),
                        const SizedBox(height: 28),
                        _PageHeading(isWide: isWide),
                        const SizedBox(height: 22),
                        const _PaymentSteps(),
                        const SizedBox(height: 22),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: Column(
                                  children: [
                                    _StatusPanel(controller: controller),
                                    const SizedBox(height: 18),
                                    _ContractCard(contract: contract),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 22),
                              SizedBox(
                                width: 330,
                                child: _AmountCard(contract: contract),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _StatusPanel(controller: controller),
                              const SizedBox(height: 16),
                              _AmountCard(contract: contract),
                              const SizedBox(height: 16),
                              _ContractCard(contract: contract),
                            ],
                          ),
                        const SizedBox(height: 18),
                        _DemoActions(controller: controller),
                        const SizedBox(height: 18),
                        const _DemoSafetyNote(),
                        const SizedBox(height: 18),
                        Center(
                          child: Text(
                            'WorkBridge · Payment flow preview',
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.isWide});
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: () => Get.back<void>(),
          tooltip: 'Back to checkout',
          icon: const Icon(Icons.arrow_back_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.brandSoft,
            foregroundColor: AppColors.brand,
          ),
        ),
        const SizedBox(width: 10),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warningSoft,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.saffron.withValues(alpha: .4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.science_outlined,
                    size: 16, color: AppColors.warningInk),
                SizedBox(width: 7),
                Text(
                  'MOCK PAYMENT MODE',
                  style: TextStyle(
                    color: AppColors.warningInk,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: .65,
                  ),
                ),
              ],
            ),
          )
        else
          const Icon(Icons.science_outlined, color: AppColors.warningInk),
      ],
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.isWide});
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
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'SCREEN 19  ·  PAYMENT RESULT',
            style: TextStyle(
              color: AppColors.brand,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: .75,
            ),
          ),
        ),
        const SizedBox(height: 13),
        Text(
          'Payment processing',
          style: (isWide
                  ? theme.textTheme.headlineLarge
                  : theme.textTheme.headlineMedium)
              ?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 7),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            'Preview the payment journey using a safe local simulation. Choose a success or failure scenario to test the next states.',
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

class _PaymentSteps extends StatelessWidget {
  const _PaymentSteps();

  @override
  Widget build(BuildContext context) {
    const steps = <(String, IconData)>[
      ('Contract confirmed', Icons.verified_outlined),
      ('Checkout reviewed', Icons.receipt_long_outlined),
      ('Payment result', Icons.payments_outlined),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        children: [
          for (var i = 0; i < steps.length; i++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: i == 2
                      ? AppColors.brand
                      : AppColors.successSoft,
                  child: Icon(
                    steps[i].$2,
                    size: 15,
                    color: i == 2 ? AppColors.white : AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  steps[i].$1,
                  style: TextStyle(
                    color: i == 2 ? AppColors.brand : AppColors.textSecondary,
                    fontWeight: i == 2 ? FontWeight.w900 : FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.controller});
  final PaymentProcessingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final status = controller.status.value;
      final config = _statusConfig(status);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: config.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: config.color.withValues(alpha: .22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: .12),
                    shape: BoxShape.circle,
                  ),
                  child: status == PaymentDemoStatus.processing
                      ? Padding(
                          padding: const EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: config.color,
                          ),
                        )
                      : Icon(config.icon, color: config.color, size: 28),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        config.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (status == PaymentDemoStatus.processing) ...[
              const SizedBox(height: 20),
              const LinearProgressIndicator(
                minHeight: 5,
                borderRadius: BorderRadius.all(Radius.circular(10)),
                color: AppColors.brand,
                backgroundColor: AppColors.brandTint,
              ),
              const SizedBox(height: 9),
              const Text(
                'Running the selected demo scenario…',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (status == PaymentDemoStatus.success ||
                status == PaymentDemoStatus.failed) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: .8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Simulation result only. No transaction was created, no funds were collected, and the contract remains awaiting real provider payment.',
                  style: TextStyle(
                    color: AppColors.warningInk,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  _StatusConfig _statusConfig(PaymentDemoStatus status) {
    switch (status) {
      case PaymentDemoStatus.ready:
        return const _StatusConfig(
          title: 'Ready for demo',
          description:
              'The confirmed contract is ready. Select one of the test outcomes below to preview the payment result screen.',
          icon: Icons.science_outlined,
          color: AppColors.warning,
          background: AppColors.warningSoft,
        );
      case PaymentDemoStatus.processing:
        return const _StatusConfig(
          title: 'Processing demo scenario',
          description:
              'WorkBridge is displaying the processing state. This is a short local animation, not a payment request.',
          icon: Icons.sync_rounded,
          color: AppColors.brand,
          background: AppColors.brandSoft,
        );
      case PaymentDemoStatus.success:
        return const _StatusConfig(
          title: 'Success scenario completed',
          description:
              'The successful payment path is now displayed for interface testing. No real payment has been made.',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          background: AppColors.successSoft,
        );
      case PaymentDemoStatus.failed:
        return const _StatusConfig(
          title: 'Failure scenario displayed',
          description:
              'This test shows how WorkBridge handles an unsuccessful payment. No money was taken; you can try another scenario.',
          icon: Icons.cancel_rounded,
          color: AppColors.error,
          background: AppColors.errorSoft,
        );
      case PaymentDemoStatus.alreadyFunded:
        return const _StatusConfig(
          title: 'Contract already funded',
          description:
              'The saved contract status is already funded. A second payment must not be attempted.',
          icon: Icons.verified_rounded,
          color: AppColors.success,
          background: AppColors.successSoft,
        );
    }
  }
}

class _StatusConfig {
  const _StatusConfig({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.background,
  });
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color background;
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({required this.contract});
  final ContractConfirmationModel contract;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project details',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            contract.taskTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Engineer: ${contract.engineerName}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 9,
            runSpacing: 8,
            children: [
              _DetailPill(
                icon: Icons.folder_outlined,
                label: contract.taskCategory,
              ),
              _DetailPill(
                icon: Icons.calendar_today_outlined,
                label: '${contract.deliveryDays} day delivery',
              ),
              _DetailPill(
                icon: Icons.replay_rounded,
                label: '${contract.includedRevisions} revisions',
              ),
            ],
          ),
          if (contract.contractId != null &&
              contract.contractId!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.outlineVariant),
            const SizedBox(height: 12),
            Text(
              'Contract reference: ${contract.contractId}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.contract});
  final ContractConfirmationModel contract;

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
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment summary',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 19),
          _MoneyLine(label: 'Project total', value: contract.formattedAmount),
          const SizedBox(height: 11),
          _MoneyLine(
            label: 'Platform commission',
            value: '${contract.commissionPercent}%',
            subdued: true,
          ),
          const SizedBox(height: 11),
          _MoneyLine(
            label: 'Engineer net payout',
            value: contract.formattedEngineerNet,
            subdued: true,
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'Client amount (demo)',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            contract.formattedAmount,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.brand,
              fontWeight: FontWeight.w900,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.saffronSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Text(
              'The 5% marketplace commission is deducted from the Engineer payout, not added to the Client total. Provider fees and taxes are not simulated here.',
              style: TextStyle(
                color: AppColors.warningInk,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  const _MoneyLine({
    required this.label,
    required this.value,
    this.subdued = false,
  });
  final String label;
  final String value;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: subdued ? AppColors.textSecondary : AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: subdued ? AppColors.textSecondary : AppColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DemoActions extends StatelessWidget {
  const _DemoActions({required this.controller});
  final PaymentProcessingController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = controller.status.value;
      final busy = status == PaymentDemoStatus.processing;
      final funded = status == PaymentDemoStatus.alreadyFunded;

      if (busy || funded) {
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : Get.back<void>,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to checkout'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  foregroundColor: AppColors.brand,
                ),
              ),
            ),
          ],
        );
      }

      final isResult = status == PaymentDemoStatus.success ||
          status == PaymentDemoStatus.failed;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isResult)
            FilledButton.icon(
              onPressed: controller.resetDemo,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Choose another demo scenario'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            )
          else ...[
            FilledButton.icon(
              onPressed: () { controller.simulateSuccess(); },
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Simulate successful payment'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () { controller.simulateFailure(); },
              icon: const Icon(Icons.error_outline_rounded),
              label: const Text('Simulate failed payment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => Get.back<void>(),
            icon: const Icon(Icons.arrow_back_rounded, size: 17),
            label: const Text('Back to checkout'),
          ),
        ],
      );
    });
  }
}

class _DemoSafetyNote extends StatelessWidget {
  const _DemoSafetyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withValues(alpha: .16)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.info, size: 19),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Development mode: a simulated success does not activate the project, create a receipt, release funds, or change the Supabase contract status. In production, these actions must follow a server-verified payment-provider webhook.',
              style: TextStyle(
                color: AppColors.info,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentLoadError extends StatelessWidget {
  const _PaymentLoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 42, color: AppColors.warning),
                const SizedBox(height: 14),
                Text(
                  'Unable to open payment preview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 9),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: AppColors.white,
                  ),
                ),
                TextButton(
                  onPressed: () => Get.offAllNamed<void>(AppRoutes.clientHome),
                  child: const Text('Go to dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
