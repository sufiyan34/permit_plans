import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/controllers/engineer_dashboard_controller.dart';
import 'package:permit_plans/models/engineer_dashboard_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

/// Engineer home page for WorkBridge.
///
/// Engineer profile information is fetched from Supabase. Project, revision
/// and messaging destinations lead to their respective WorkBridge modules;
/// this screen never invents marketplace totals.
class EngineerDashboardScreen extends StatelessWidget {
  const EngineerDashboardScreen({super.key});

  static const double _wideBreakpoint = 960;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EngineerDashboardController>();

    return AppShell(
      title: 'Engineer workspace',
      currentIndex: 0,
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
          icon: Icons.rate_review_outlined,
          selectedIcon: Icons.rate_review_rounded,
          label: 'Revisions',
          route: AppRoutes.engineerRevisionRequests,
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
          icon: Icons.notifications_none_rounded,
          label: 'Notifications',
          route: AppRoutes.notifications,
        ),
        SidebarItem(
          icon: Icons.tune_rounded,
          label: 'Notification preferences',
          route: AppRoutes.notificationPreferences,
        ),
        SidebarItem(
          icon: Icons.rate_review_outlined,
          label: 'Revision requests',
          route: AppRoutes.engineerRevisionRequests,
        ),
        SidebarItem(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Earnings',
          route: AppRoutes.engineerEarnings,
        ),
        SidebarItem(
          icon: Icons.payments_outlined,
          label: 'Payout management',
          route: AppRoutes.engineerPayoutManagement,
        ),
        SidebarItem(
          icon: Icons.person_outline_rounded,
          label: 'My profile',
          route: AppRoutes.engineerEditProfile,
        ),
        SidebarItem(icon: Icons.settings_outlined, label: 'Settings'),
        SidebarItem(icon: Icons.help_outline_rounded, label: 'Help & support'),
      ],
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => Get.toNamed<void>(AppRoutes.notifications),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      body: _EngineerDashboardBody(
        controller: controller,
        wideBreakpoint: _wideBreakpoint,
      ),
    );
  }
}

class _EngineerDashboardBody extends StatelessWidget {
  const _EngineerDashboardBody({
    required this.controller,
    required this.wideBreakpoint,
  });

  final EngineerDashboardController controller;
  final double wideBreakpoint;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = controller.profile.value;
      final loading = controller.isLoading.value;
      final error = controller.errorMessage.value;

      if (profile == null && loading) return const _LoadingState();
      if (profile == null && error.isNotEmpty) {
        return _ErrorState(
          message: error,
          onRetry: () {
            controller.loadProfile();
          },
        );
      }
      if (profile == null) return const _LoadingState();

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= wideBreakpoint;
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
                      _WelcomeHeader(profile: profile, isWide: isWide),
                      const SizedBox(height: 24),
                      _HeroCard(
                        profile: profile,
                        isWide: isWide,
                        onFindTasks: _openFindTasks,
                        onViewProposals: _openProposals,
                      ),
                      const SizedBox(height: 24),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: Column(
                                children: [
                                  _WorkspaceOverview(isWide: true),
                                  const SizedBox(height: 20),
                                  _SkillsCard(profile: profile),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 4,
                              child: Column(
                                children: [
                                  _ProfileSnapshotCard(profile: profile),
                                  const SizedBox(height: 20),
                                  _GettingStartedCard(
                                    onFindTasks: _openFindTasks,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _WorkspaceOverview(isWide: false),
                        const SizedBox(height: 18),
                        _GettingStartedCard(onFindTasks: _openFindTasks),
                        const SizedBox(height: 18),
                        _SkillsCard(profile: profile),
                        const SizedBox(height: 18),
                        _ProfileSnapshotCard(profile: profile),
                      ],
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Good work starts with a great connection.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textTertiary),
                        ),
                      ),
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

  void _openFindTasks() => Get.toNamed<void>(AppRoutes.engineerInvitations);

  void _openProposals() => Get.toNamed<void>(AppRoutes.engineerNegotiations);
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.profile, required this.isWide});

  final EngineerDashboardProfile profile;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR WORKSPACE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.papayaDark,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Hello, ${profile.firstName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    (isWide
                            ? theme.textTheme.headlineLarge
                            : theme.textTheme.headlineSmall)
                        ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(
                'Make your next great piece of work happen.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _Avatar(profile: profile, radius: isWide ? 27 : 23),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile, required this.radius});

  final EngineerDashboardProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = profile.avatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.brandSoft,
      foregroundImage: (url != null && url.isNotEmpty)
          ? NetworkImage(url)
          : null,
      child: Text(
        profile.firstName.isNotEmpty ? profile.firstName[0].toUpperCase() : 'E',
        style: TextStyle(
          color: AppColors.brand,
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.profile,
    required this.isWide,
    required this.onFindTasks,
    required this.onViewProposals,
  });

  final EngineerDashboardProfile profile;
  final bool isWide;
  final VoidCallback onFindTasks;
  final VoidCallback onViewProposals;

  @override
  Widget build(BuildContext context) {
    final title = profile.profileCompleted
        ? 'Your next opportunity\nstarts here.'
        : 'Finish setting up\nyour profile.';
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Text(
            profile.profileCompleted
                ? 'ENGINEER WORKSPACE'
                : 'PROFILE INCOMPLETE',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style:
              (isWide
                      ? Theme.of(context).textTheme.headlineMedium
                      : Theme.of(context).textTheme.headlineSmall)
                  ?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
        ),
        const SizedBox(height: 10),
        Text(
          profile.profileCompleted
              ? 'Your professional profile is ready. Explore the marketplace and find work that matches your skills.'
              : 'Add the missing details to help clients understand what you do.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.82),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: onFindTasks,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.papaya,
                foregroundColor: const Color(0xFF351C16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
              ),
              icon: const Icon(Icons.inbox_outlined, size: 18),
              label: const Text('Task invitations'),
            ),
            OutlinedButton.icon(
              onPressed: onViewProposals,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
              ),
              icon: const Icon(Icons.assignment_outlined, size: 18),
              label: const Text('Negotiations'),
            ),
          ],
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 30 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandDark, AppColors.brand, Color(0xFF70485F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: AppColors.cardShadow,
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(flex: 7, child: content),
                const SizedBox(width: 24),
                const Expanded(flex: 4, child: _HeroIllustration()),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 20),
                const _HeroIllustration(),
              ],
            ),
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 15,
            right: 25,
            child: _Orb(
              size: 38,
              color: AppColors.saffron.withValues(alpha: 0.95),
            ),
          ),
          Positioned(
            bottom: 13,
            left: 27,
            child: _Orb(
              size: 24,
              color: AppColors.papaya.withValues(alpha: 0.95),
            ),
          ),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              size: 48,
              color: AppColors.brand,
            ),
          ),
          Positioned(
            right: 70,
            bottom: 25,
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.saffron,
              size: 23,
            ),
          ),
          Positioned(
            left: 70,
            top: 22,
            child: Icon(
              Icons.add,
              color: Colors.white.withValues(alpha: 0.75),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _WorkspaceOverview extends StatelessWidget {
  const _WorkspaceOverview({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final items = const [
      _OverviewItem(
        icon: Icons.assignment_outlined,
        title: 'Negotiations',
        detail: 'Client counteroffers and quote decisions will appear here.',
        tag: 'Open negotiation inbox',
      ),
      _OverviewItem(
        icon: Icons.folder_open_outlined,
        title: 'Active projects',
        detail: 'Confirmed contracts, funding status and delivery terms.',
        tag: 'Open Projects tab',
      ),
      _OverviewItem(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Earnings',
        detail: 'Payout and earnings history will appear here.',
        tag: 'Payments not connected',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          title: 'Your workspace',
          subtitle: 'A quick look at your work on WorkBridge.',
        ),
        const SizedBox(height: 13),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0) const SizedBox(width: 12),
                Expanded(child: _OverviewCard(item: items[index])),
              ],
            ],
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OverviewCard(item: item),
            ),
          ),
      ],
    );
  }
}

class _OverviewItem {
  const _OverviewItem({
    required this.icon,
    required this.title,
    required this.detail,
    required this.tag,
  });
  final IconData icon;
  final String title;
  final String detail;
  final String tag;
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.item});
  final _OverviewItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(item.icon, color: AppColors.brand),
            ),
            const SizedBox(height: 14),
            Text(
              item.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.detail,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.saffronSoft,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                item.tag,
                style: const TextStyle(
                  color: AppColors.saffronDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillsCard extends StatelessWidget {
  const _SkillsCard({required this.profile});
  final EngineerDashboardProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeading(
              title: 'Your skills',
              subtitle: 'These help us match you with relevant projects.',
            ),
            const SizedBox(height: 14),
            if (profile.skills.isEmpty)
              const _InlineEmptyState(
                message: 'Add skills to your engineer profile.',
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.skills
                    .take(12)
                    .map(
                      (skill) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.papayaSoft,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          skill,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.papayaDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            if (profile.skills.length > 12) ...[
              const SizedBox(height: 8),
              Text(
                '+${profile.skills.length - 12} more',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileSnapshotCard extends StatelessWidget {
  const _ProfileSnapshotCard({required this.profile});
  final EngineerDashboardProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeading(
              title: 'Professional profile',
              subtitle: 'Your public introduction.',
            ),
            const SizedBox(height: 14),
            Text(
              profile.headline,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              profile.countryName?.isNotEmpty == true
                  ? profile.countryName!
                  : 'Country not added',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaPill(
                  icon: Icons.workspace_premium_outlined,
                  text: profile.experienceLabel,
                ),
                _MetaPill(
                  icon: Icons.timelapse_rounded,
                  text: '${profile.yearsExperience} years',
                ),
                _MetaPill(icon: Icons.circle, text: profile.availabilityLabel),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 17,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '${profile.portfolioLinks.length} portfolio link${profile.portfolioLinks.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Icon(
                  profile.profileCompleted
                      ? Icons.verified_rounded
                      : Icons.info_outline_rounded,
                  size: 18,
                  color: profile.profileCompleted
                      ? AppColors.success
                      : AppColors.warning,
                ),
                const SizedBox(width: 5),
                Text(
                  profile.profileCompleted ? 'Complete' : 'Incomplete',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: profile.profileCompleted
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Get.toNamed<void>(AppRoutes.engineerEditProfile),
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Edit profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.text});
  final IconData icon;
  final String text;

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
        Icon(icon, size: 13, color: AppColors.brand),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _GettingStartedCard extends StatelessWidget {
  const _GettingStartedCard({required this.onFindTasks});
  final VoidCallback onFindTasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.saffronSoft,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.saffron.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.saffronDark,
            size: 25,
          ),
          const SizedBox(height: 10),
          Text(
            'Ready for your first project?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The task marketplace is the next module we are building. Your profile and skills are ready to support it.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.warningInk,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onFindTasks,
            style: TextButton.styleFrom(foregroundColor: AppColors.brandDark),
            icon: const Icon(Icons.arrow_forward_rounded, size: 17),
            label: const Text('Explore marketplace'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(
        Icons.info_outline_rounded,
        color: AppColors.textTertiary,
        size: 18,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    ],
  );
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
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 42,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
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
