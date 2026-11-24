import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/controllers/engineer_task_invitations_controller.dart';
import 'package:permit_plans/models/engineer_task_invitation_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

/// Engineer inbox for direct invitations sent by Clients.
///
/// Engineers can inspect an invitation, reject it, or continue to the quote
/// flow. The quote composer is the next screen in the implementation sequence.
class EngineerTaskInvitationsScreen
    extends GetView<EngineerTaskInvitationsController> {
  const EngineerTaskInvitationsScreen({super.key});

  static const double _wideBreakpoint = 960;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Task invitations',
      currentIndex: 1,
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
          icon: Icons.assignment_outlined,
          label: 'Negotiations',
          route: AppRoutes.engineerNegotiations,
        ),
        ShellDestination(icon: Icons.folder_open_outlined, label: 'Projects'),
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
          tooltip: 'Refresh invitations',
          onPressed: controller.refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      body: _InvitationInboxBody(
        controller: controller,
        wideBreakpoint: _wideBreakpoint,
      ),
    );
  }
}

class _InvitationInboxBody extends StatelessWidget {
  const _InvitationInboxBody({
    required this.controller,
    required this.wideBreakpoint,
  });

  final EngineerTaskInvitationsController controller;
  final double wideBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= wideBreakpoint;
        return Obx(() {
          final loading = controller.isLoading.value;
          final error = controller.errorMessage.value;
          final invitations = controller.filteredInvitations;

          if (loading && controller.invitations.isEmpty) {
            return const _LoadingState();
          }

          if (error.isNotEmpty && controller.invitations.isEmpty) {
            return _ErrorState(message: error, onRetry: controller.refresh);
          }

          return RefreshIndicator(
            onRefresh: controller.refresh,
            color: AppColors.papaya,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                isWide ? 34 : 18,
                isWide ? 28 : 20,
                isWide ? 34 : 18,
                36,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PageHeader(
                        count: controller.invitations.length,
                        isWide: isWide,
                      ),
                      const SizedBox(height: 22),
                      _InboxSummary(count: controller.invitations.length),
                      const SizedBox(height: 22),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _InvitationsColumn(
                                controller: controller,
                                invitations: invitations,
                                isWide: true,
                              ),
                            ),
                            const SizedBox(width: 22),
                            const Expanded(
                              flex: 3,
                              child: _InvitationHelpPanel(),
                            ),
                          ],
                        )
                      else ...[
                        _InvitationsColumn(
                          controller: controller,
                          invitations: invitations,
                          isWide: false,
                        ),
                        const SizedBox(height: 18),
                        const _InvitationHelpPanel(),
                      ],
                      if (error.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _InlineWarning(message: error),
                      ],
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
  const _PageHeader({required this.count, required this.isWide});

  final int count;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR INBOX',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.papayaDark,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Task invitations',
          style:
              (isWide
                      ? theme.textTheme.headlineMedium
                      : theme.textTheme.headlineSmall)
                  ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        Text(
          count == 0
              ? 'Clients can invite you directly when they think you are a good fit.'
              : 'Review each project, then decide whether to prepare a quote or decline.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _InboxSummary extends StatelessWidget {
  const _InboxSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.brandTint),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(
              Icons.mark_email_unread_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count pending ${count == 1 ? 'invitation' : 'invitations'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.brandDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Only invitations awaiting your response are shown here.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return card;
  }
}

class _InvitationsColumn extends StatelessWidget {
  const _InvitationsColumn({
    required this.controller,
    required this.invitations,
    required this.isWide,
  });

  final EngineerTaskInvitationsController controller;
  final List<EngineerTaskInvitation> invitations;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: controller.updateSearch,
          decoration: InputDecoration(
            hintText: 'Search invitations, skills or clients',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: Obx(
              () => controller.searchQuery.value.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () => controller.updateSearch(''),
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: AppRadii.input,
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.input,
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                'Waiting for your response',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${invitations.length} found',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (invitations.isEmpty)
          _EmptyState(hasSearch: controller.searchQuery.value.isNotEmpty)
        else if (isWide)
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1000 ? 2 : 1;
              return GridView.builder(
                itemCount: invitations.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 390,
                ),
                itemBuilder: (context, index) => _InvitationCard(
                  invitation: invitations[index],
                  controller: controller,
                  onView: () => _showInvitationDetails(
                    context,
                    invitations[index],
                    controller,
                  ),
                  onReject: () =>
                      _confirmReject(context, invitations[index], controller),
                ),
              );
            },
          )
        else
          ...invitations.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InvitationCard(
                invitation: item,
                controller: controller,
                onView: () => _showInvitationDetails(context, item, controller),
                onReject: () => _confirmReject(context, item, controller),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmReject(
    BuildContext context,
    EngineerTaskInvitation invitation,
    EngineerTaskInvitationsController controller,
  ) async {
    final accepted = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Decline this invitation?'),
        content: Text(
          'You will decline “${invitation.title}”. The Client will be able to see that you are not taking this task.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('Keep invitation'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back<bool>(result: true),
            child: const Text('Decline invitation'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await controller.rejectInvitation(invitation);
    }
  }

  void _showInvitationDetails(
    BuildContext context,
    EngineerTaskInvitation invitation,
    EngineerTaskInvitationsController controller,
  ) {
    Get.dialog<void>(
      _InvitationDetailsDialog(
        invitation: invitation,
        onReject: () async {
          Get.back<void>();
          await _confirmReject(context, invitation, controller);
        },
        onMakeQuote: () {
          Get.back<void>();
          Get.toNamed<void>(AppRoutes.comingSoonFor('Submit a quote'));
        },
      ),
      barrierDismissible: true,
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    required this.controller,
    required this.onView,
    required this.onReject,
  });

  final EngineerTaskInvitation invitation;
  final EngineerTaskInvitationsController controller;
  final VoidCallback onView;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.card,
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ClientAvatar(invitation: invitation, radius: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (invitation.clientCountryName?.isNotEmpty == true)
                            invitation.clientCountryName!,
                          'Invited ${invitation.sentAtLabel}',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusPill(label: 'New invitation'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              invitation.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              invitation.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _MetaChip(
                  icon: Icons.category_outlined,
                  label: invitation.category,
                ),
                _MetaChip(
                  icon: Icons.payments_outlined,
                  label: invitation.budgetLabel,
                ),
                _MetaChip(
                  icon: Icons.event_outlined,
                  label: invitation.deadlineLabel,
                ),
              ],
            ),
            if (invitation.requiredSkills.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: invitation.requiredSkills
                    .take(4)
                    .map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.papayaSoft,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          skill,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.papayaDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                if (invitation.attachmentCount > 0) ...[
                  const Icon(
                    Icons.attach_file_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${invitation.attachmentCount} reference file${invitation.attachmentCount == 1 ? '' : 's'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: onReject,
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Decline'),
                ),
                const SizedBox(width: 5),
                FilledButton(
                  onPressed: onView,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadii.button,
                    ),
                  ),
                  child: const Text('Review'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitationDetailsDialog extends StatelessWidget {
  const _InvitationDetailsDialog({
    required this.invitation,
    required this.onReject,
    required this.onMakeQuote,
  });

  final EngineerTaskInvitation invitation;
  final VoidCallback onReject;
  final VoidCallback onMakeQuote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      shape: RoundedRectangleBorder(borderRadius: AppRadii.dialog),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Invitation details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Get.back<void>(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ClientAvatar(invitation: invitation, radius: 22),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invitation.clientName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                invitation.clientCountryName ?? 'Client',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _StatusPill(label: 'Pending response'),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      invitation.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      invitation.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(
                          icon: Icons.category_outlined,
                          label: invitation.category,
                        ),
                        _MetaChip(
                          icon: Icons.payments_outlined,
                          label: invitation.budgetLabel,
                        ),
                        _MetaChip(
                          icon: Icons.event_outlined,
                          label: invitation.deadlineLabel,
                        ),
                        _MetaChip(
                          icon: Icons.attach_file_rounded,
                          label:
                              '${invitation.attachmentCount} reference files',
                        ),
                      ],
                    ),
                    if (invitation.requiredSkills.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Required skills',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: invitation.requiredSkills
                            .map((skill) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.papayaSoft,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.pill,
                                  ),
                                ),
                                child: Text(
                                  skill,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppColors.papayaDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            })
                            .toList(growable: false),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.saffronSoft,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: AppColors.saffronDark,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'The Client’s budget is guidance only. You will submit your own price and delivery estimate in your quote.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.warningInk,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Decline invitation'),
                  ),
                  FilledButton.icon(
                    onPressed: onMakeQuote,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.papaya,
                      foregroundColor: const Color(0xFF351C16),
                    ),
                    icon: const Icon(Icons.request_quote_outlined),
                    label: const Text('Prepare a quote'),
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

class _ClientAvatar extends StatelessWidget {
  const _ClientAvatar({required this.invitation, required this.radius});

  final EngineerTaskInvitation invitation;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = invitation.clientAvatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.brandSoft,
      foregroundImage: (url != null && url.isNotEmpty)
          ? NetworkImage(url)
          : null,
      child: Text(
        invitation.clientInitials,
        style: TextStyle(
          color: AppColors.brand,
          fontSize: radius * 0.65,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.saffronSoft,
      borderRadius: BorderRadius.circular(AppRadii.pill),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.saffronDark,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadii.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.brand),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _InvitationHelpPanel extends StatelessWidget {
  const _InvitationHelpPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.papayaSoft,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(
              Icons.handshake_outlined,
              color: AppColors.papayaDark,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'How invitations work',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A Client has selected you for a project. Review the requirements, then either decline or prepare a quote with your price and delivery estimate.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          const _HelpStep(
            number: '01',
            text: 'Review the scope and reference files.',
          ),
          const _HelpStep(
            number: '02',
            text: 'Decide if the project suits your skills.',
          ),
          const _HelpStep(
            number: '03',
            text: 'Send a quote or decline the invitation.',
          ),
          const SizedBox(height: 12),
          Text(
            'No payment is taken at this stage.',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpStep extends StatelessWidget {
  const _HelpStep({required this.number, required this.text});
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            color: AppColors.papayaDark,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch});
  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: AppColors.brandSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              color: AppColors.brand,
              size: 34,
            ),
          ),
          const SizedBox(height: 17),
          Text(
            hasSearch ? 'No matching invitations' : 'No invitations yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Text(
              hasSearch ? 'Try another task title, client name or skill.' : 'When a Client assigns a task to you, the invitation will appear here. You can review it before deciding whether to quote or decline.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 17),
            OutlinedButton.icon(
              onPressed: () =>
                  Get.find<EngineerTaskInvitationsController>().refresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh inbox'),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(48),
      child: CircularProgressIndicator(color: AppColors.papaya),
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
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.warning,
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              'Could not load invitations',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
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

class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.warningSoft,
      borderRadius: BorderRadius.circular(AppRadii.md),
    ),
    child: Text(
      message,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: AppColors.warningInk),
    ),
  );
}
