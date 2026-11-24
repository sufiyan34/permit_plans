import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/controllers/contract_confirmation_controller.dart';
import 'package:permit_plans/models/contract_confirmation_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

/// Client-facing final review of a quote that both parties have accepted.
/// Confirming creates an immutable contract snapshot; it does not charge a card.
class ContractConfirmationScreen
    extends GetView<ContractConfirmationController> {
  const ContractConfirmationScreen({super.key});

  static const double _wideBreakpoint = 960;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Contract confirmation',
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
        SidebarItem(icon: Icons.folder_open_outlined, label: 'My projects'),
        SidebarItem(icon: Icons.receipt_long_outlined, label: 'Payments'),
        SidebarItem(icon: Icons.person_outline_rounded, label: 'My profile'),
        SidebarItem(icon: Icons.help_outline_rounded, label: 'Help & support'),
        SidebarItem(icon: Icons.settings_outlined, label: 'Settings'),
      ],
      actions: [
        IconButton(
          tooltip: 'Refresh contract',
          onPressed: controller.loadPreview,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      body: _ContractConfirmationBody(
        controller: controller,
        wideBreakpoint: _wideBreakpoint,
      ),
    );
  }
}

class _ContractConfirmationBody extends StatelessWidget {
  const _ContractConfirmationBody({
    required this.controller,
    required this.wideBreakpoint,
  });

  final ContractConfirmationController controller;
  final double wideBreakpoint;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.preview.value == null) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.papaya),
        );
      }
      if (controller.errorMessage.value.isNotEmpty &&
          controller.preview.value == null) {
        return _ContractErrorState(
          message: controller.errorMessage.value,
          onRetry: controller.loadPreview,
          onBack: () => Get.back<void>(),
        );
      }

      final data = controller.preview.value;
      if (data == null) {
        return const Center(child: Text('Contract details are unavailable.'));
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= wideBreakpoint;
          final horizontal = isWide ? 34.0 : 18.0;
          final main = _ContractMainColumn(
            controller: controller,
            contract: data,
          );
          final summary = _ContractSummaryCard(
            contract: data,
            isConfirmed: controller.isConfirmed,
          );

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1380),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PageHeading(isWide: isWide, isConfirmed: controller.isConfirmed),
                    const SizedBox(height: 22),
                    if (controller.errorMessage.value.isNotEmpty)
                      _InlineError(message: controller.errorMessage.value),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: main),
                          const SizedBox(width: 22),
                          Expanded(flex: 4, child: summary),
                        ],
                      )
                    else ...[
                      main,
                      const SizedBox(height: 18),
                      summary,
                    ],
                    const SizedBox(height: 18),
                    const _PaymentBoundaryNotice(),
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
  const _PageHeading({required this.isWide, required this.isConfirmed});
  final bool isWide;
  final bool isConfirmed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: isConfirmed ? AppColors.successSoft : AppColors.saffronSoft,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Text(
            isConfirmed ? 'AGREEMENT RECORDED' : 'FINAL REVIEW',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isConfirmed ? AppColors.success : AppColors.warningInk,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isConfirmed ? 'Your contract is confirmed' : 'Review the agreement',
          style: (isWide ? theme.textTheme.headlineMedium : theme.textTheme.headlineSmall)
              ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.ink),
        ),
        const SizedBox(height: 7),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(
            isConfirmed
                ? 'The accepted quote has been saved as a contract. The next step is secure payment.'
                : 'Both sides have agreed to this quote. Check the project terms carefully before confirming the contract.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContractMainColumn extends StatelessWidget {
  const _ContractMainColumn({
    required this.controller,
    required this.contract,
  });

  final ContractConfirmationController controller;
  final ContractConfirmationModel contract;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EngineerCard(contract: contract),
        const SizedBox(height: 16),
        _TermsCard(contract: contract),
        const SizedBox(height: 16),
        if (controller.isConfirmed)
          _ConfirmedCard(contract: contract)
        else
          _ConfirmActionCard(controller: controller),
      ],
    );
  }
}

class _EngineerCard extends StatelessWidget {
  const _EngineerCard({required this.contract});
  final ContractConfirmationModel contract;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SurfaceCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: AppColors.brandSoft,
            backgroundImage: contract.engineerAvatarUrl == null
                ? null
                : NetworkImage(contract.engineerAvatarUrl!),
            child: contract.engineerAvatarUrl == null
                ? Text(
                    contract.engineerInitials,
                    style: const TextStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contract.engineerName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if ((contract.engineerHeadline ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    contract.engineerHeadline!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if ((contract.engineerCountry ?? '').isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 3),
                      Text(
                        contract.engineerCountry!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const _SmallStatusChip(
            label: 'Quote agreed',
            color: AppColors.success,
            background: AppColors.successSoft,
          ),
        ],
      ),
    );
  }
}

class _TermsCard extends StatelessWidget {
  const _TermsCard({required this.contract});
  final ContractConfirmationModel contract;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project agreement',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Review the final terms that came from the accepted quote.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            contract.taskTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _MetaChip(icon: Icons.folder_outlined, label: contract.taskCategory),
              const SizedBox(width: 8),
              _MetaChip(
                icon: Icons.schedule_rounded,
                label: '${contract.deliveryDays} days',
              ),
            ],
          ),
          if (contract.taskDescription.isNotEmpty) ...[
            const SizedBox(height: 15),
            Text(
              contract.taskDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _TermBlock(
            icon: Icons.checklist_rounded,
            title: 'Agreed scope of work',
            value: contract.scopeOfWork,
          ),
          const SizedBox(height: 16),
          _TermBlock(
            icon: Icons.replay_rounded,
            title: 'Included revisions',
            value: '${contract.includedRevisions} revision(s)',
          ),
          if ((contract.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            _TermBlock(
              icon: Icons.sticky_note_2_outlined,
              title: 'Additional agreement notes',
              value: contract.notes!,
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfirmActionCard extends StatelessWidget {
  const _ConfirmActionCard({required this.controller});
  final ContractConfirmationController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm the contract',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Confirm that this summary matches the price, scope and delivery terms both sides accepted.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.brand,
                value: controller.hasAcceptedTerms.value,
                onChanged: controller.isConfirming.value
                    ? null
                    : (value) => controller.hasAcceptedTerms.value = value ?? false,
                title: const Text(
                  'I have reviewed and agree to the contract terms above.',
                ),
                subtitle: const Text(
                  'This records the accepted quote as the project contract. Payment is a separate step.',
                ),
              )),
          const SizedBox(height: 12),
          Obx(() => SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: controller.isConfirming.value
                      ? null
                      : controller.confirmContract,
                  icon: controller.isConfirming.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.verified_outlined),
                  label: Text(
                    controller.isConfirming.value
                        ? 'Confirming…'
                        : 'Confirm agreement',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              )),
          const SizedBox(height: 9),
          Text(
            'No card will be charged on this screen.',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractSummaryCard extends StatelessWidget {
  const _ContractSummaryCard({
    required this.contract,
    required this.isConfirmed,
  });

  final ContractConfirmationModel contract;
  final bool isConfirmed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial summary',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          _MoneyRow(label: 'Agreed project price', value: contract.formattedAmount),
          const SizedBox(height: 12),
          _MoneyRow(
            label: 'Platform commission (${contract.commissionPercent}%)',
            value: contract.formattedPlatformFee,
            subdued: true,
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Engineer estimated net',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contract.formattedEngineerNet,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _MoneyRow(
            label: 'Delivery estimate',
            value: '${contract.deliveryDays} days',
            subdued: true,
          ),
          const SizedBox(height: 8),
          _MoneyRow(
            label: 'Included revisions',
            value: '${contract.includedRevisions}',
            subdued: true,
          ),
          const SizedBox(height: 17),
          if (isConfirmed)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Get.toNamed<void>(
                  AppRoutes.clientPaymentCheckout,
                  arguments: {
                    'quote_id': contract.quoteId,
                    'contract_id': contract.contractId,
                  },
                ),
                icon: const Icon(Icons.lock_outline_rounded),
                label: const Text('Continue to payment'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.papaya,
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          else
            const _SmallStatusChip(
              label: 'Payment not taken yet',
              color: AppColors.warningInk,
              background: AppColors.saffronSoft,
            ),
          const SizedBox(height: 10),
          Text(
            'The 5% platform commission is calculated from the agreed project amount and deducted from the Engineer side. Processing fees, taxes and currency conversion are separate.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmedCard extends StatelessWidget {
  const _ConfirmedCard({required this.contract});
  final ContractConfirmationModel contract;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.success, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contract confirmed',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Your agreement is saved${contract.contractId == null ? '' : ' (ID: ${contract.contractId})'}. Continue to the separate payment step when it is available.',
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

class _PaymentBoundaryNotice extends StatelessWidget {
  const _PaymentBoundaryNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.saffronSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: AppColors.warningInk),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Important: confirming this contract only records the agreed terms. No card is charged and no funds are held here. A separate payment-provider checkout must be completed before the Engineer starts work.',
              style: TextStyle(
                color: AppColors.warningInk,
                height: 1.45,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermBlock extends StatelessWidget {
  const _TermBlock({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Icon(icon, size: 19, color: AppColors.brand),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
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
  });
  final String label;
  final String value;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    final color = subdued ? AppColors.textSecondary : AppColors.textPrimary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _SmallStatusChip extends StatelessWidget {
  const _SmallStatusChip({
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

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );
  }
}

class _ContractErrorState extends StatelessWidget {
  const _ContractErrorState({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description_outlined,
                  size: 48, color: AppColors.brand),
              const SizedBox(height: 14),
              Text(
                'Contract unavailable',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: onBack,
                    child: const Text('Back'),
                  ),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Try again'),
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
