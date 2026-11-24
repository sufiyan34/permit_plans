import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/bindings/client_dashboard_binding.dart';
import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/controllers/client_dashboard_controller.dart';
import 'package:permit_plans/models/client_dashboard_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

/// Client landing page for WorkBridge.
///
/// The page adapts to mobile and laptop widths. It currently loads the signed-in
/// client's profile from Supabase. Project counts, proposals and transactions
/// are intentionally not fabricated; those sections stay as honest empty
/// states until the task, contract and payment modules are implemented.
class ClientDashboardScreen extends StatelessWidget {
  const ClientDashboardScreen({super.key});

  static const double _wideContentBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ClientDashboardController>();

    return AppShell(
      title: 'Client workspace',
      currentIndex: 0,
      destinations: const [
        ShellDestination(
          icon: Icons.grid_view_outlined,
          selectedIcon: Icons.grid_view_rounded,
          label: 'Overview',
          route: AppRoutes.clientHome,
        ),
        ShellDestination(
          icon: Icons.folder_open_outlined,
          selectedIcon: Icons.folder_rounded,
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
          icon: Icons.fact_check_outlined,
          label: 'Delivery reviews',
          route: AppRoutes.clientDeliveryReviews,
        ),
        SidebarItem(
          icon: Icons.verified_outlined,
          label: 'Final approved files',
          route: AppRoutes.clientFinalApproval,
        ),
        SidebarItem(icon: Icons.receipt_long_outlined, label: 'Payments'),
        SidebarItem(
          icon: Icons.person_outline_rounded,
          label: 'My profile',
          route: AppRoutes.clientEditProfile,
        ),
        SidebarItem(icon: Icons.help_outline_rounded, label: 'Help & support'),
        SidebarItem(icon: Icons.settings_outlined, label: 'Settings'),
      ],
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => Get.toNamed<void>(AppRoutes.notifications),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      body: _ClientDashboardBody(
        controller: controller,
        wideBreakpoint: _wideContentBreakpoint,
      ),
    );
  }
}

class _ClientDashboardBody extends StatelessWidget {
  const _ClientDashboardBody({
    required this.controller,
    required this.wideBreakpoint,
  });

  final ClientDashboardController controller;
  final double wideBreakpoint;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = controller.profile.value;
      final isLoading = controller.isLoading.value;
      final error = controller.errorMessage.value;

      if (profile == null && isLoading) {
        return const _DashboardLoading();
      }

      if (profile == null && error.isNotEmpty) {
        return _DashboardError(
          message: error,
          onRetry: () {
            controller.loadProfile();
          },
        );
      }

      if (profile == null) return const _DashboardLoading();

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
                      _WelcomeHero(
                        profile: profile,
                        isWide: isWide,
                        onPostTask: _openPostTask,
                        onBrowseEngineers: _openFindEngineers,
                      ),
                      const SizedBox(height: 26),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _ProjectActivityCard(isWide: true),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 4,
                              child: Column(
                                children: [
                                  _QuickActionsCard(
                                    onPostTask: _openPostTask,
                                    onBrowseEngineers: _openFindEngineers,
                                    onMessages: _openMessages,
                                    onReviewDeliveries: _openDeliveries,
                                  ),
                                  const SizedBox(height: 20),
                                  _ProfileSummaryCard(profile: profile),
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _QuickActionsCard(
                          onPostTask: _openPostTask,
                          onBrowseEngineers: _openFindEngineers,
                          onMessages: _openMessages,
                          onReviewDeliveries: _openDeliveries,
                        ),
                        const SizedBox(height: 18),
                        _ProjectActivityCard(isWide: false),
                        const SizedBox(height: 18),
                        _ProfileSummaryCard(profile: profile),
                      ],
                      const SizedBox(height: 24),
                      _HowItWorksSection(isWide: isWide),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'Built for good work and great connections.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textTertiary,
                              ),
                          textAlign: TextAlign.center,
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

  void _openPostTask() => Get.toNamed<void>(
        AppRoutes.comingSoonFor('Create a task'),
      );

  void _openFindEngineers() => Get.toNamed<void>(
        AppRoutes.clientBrowseEngineers,
      );

  void _openMessages() => Get.toNamed<void>(AppRoutes.projectChats);

  void _openDeliveries() => Get.toNamed<void>(AppRoutes.clientDeliveryReviews);
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.profile, required this.isWide});

  final ClientDashboardProfile profile;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
                style: (isWide
                        ? theme.textTheme.headlineLarge
                        : theme.textTheme.headlineSmall)
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Let’s make your next idea happen.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _ProfileAvatar(profile: profile, radius: isWide ? 26 : 22),
      ],
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({
    required this.profile,
    required this.isWide,
    required this.onPostTask,
    required this.onBrowseEngineers,
  });

  final ClientDashboardProfile profile;
  final bool isWide;
  final VoidCallback onPostTask;
  final VoidCallback onBrowseEngineers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 32 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandDark, AppColors.brand, Color(0xFF75475F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppColors.cardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: isWide ? 70 : 6,
            top: -64,
            child: _HeroOrb(size: isWide ? 210 : 140, opacity: .08),
          ),
          Positioned(
            right: isWide ? 10 : -32,
            bottom: -85,
            child: _HeroOrb(size: isWide ? 180 : 130, opacity: .06),
          ),
          isWide
              ? Row(
                  children: [
                    Expanded(child: _heroCopy(context, theme)),
                    const SizedBox(width: 28),
                    const _HeroArtwork(),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _heroCopy(context, theme),
                    const SizedBox(height: 18),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: _HeroArtwork(compact: true),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _heroCopy(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: Colors.white.withValues(alpha: .18)),
          ),
          child: const Text(
            'YOUR NEXT PROJECT STARTS HERE',
            style: TextStyle(
              color: Color(0xFFFFD7C8),
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Bring your\nbig idea to life.',
          style: (theme.textTheme.headlineLarge ?? const TextStyle()).copyWith(
            color: Colors.white,
            fontSize: MediaQuery.sizeOf(context).width < 420 ? 30 : 36,
            height: 1.12,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: Text(
            'Describe what you need, meet the right independent talent, and keep every project organised in one place.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: .82),
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: onPostTask,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.papaya,
                foregroundColor: const Color(0xFF351C16),
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.button,
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Post a task'),
            ),
            OutlinedButton.icon(
              onPressed: onBrowseEngineers,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: .42)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.button,
                ),
              ),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Find engineers'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Task posting and talent search are the next modules to be connected.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: .62),
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 150.0 : 214.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * .88,
            height: size * .88,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .13)),
            ),
          ),
          Container(
            width: size * .64,
            height: size * .64,
            decoration: BoxDecoration(
              color: AppColors.saffron,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .14),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              size: size * .34,
              color: AppColors.brandDark,
            ),
          ),
          Positioned(
            top: size * .05,
            right: size * .02,
            child: _FloatingIcon(
              icon: Icons.auto_awesome_rounded,
              background: AppColors.papaya,
              size: compact ? 37 : 46,
            ),
          ),
          Positioned(
            bottom: size * .08,
            left: size * .02,
            child: _FloatingIcon(
              icon: Icons.handshake_outlined,
              background: const Color(0xFFFFF8F0),
              foreground: AppColors.brand,
              size: compact ? 40 : 50,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingIcon extends StatelessWidget {
  const _FloatingIcon({
    required this.icon,
    required this.background,
    this.foreground = const Color(0xFF351C16),
    required this.size,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
        boxShadow: AppColors.cardShadow,
      ),
      child: Icon(icon, color: foreground, size: size * .52),
    );
  }
}

class _HeroOrb extends StatelessWidget {
  const _HeroOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.papaya.withValues(alpha: opacity),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.onPostTask,
    required this.onBrowseEngineers,
    required this.onMessages,
    required this.onReviewDeliveries,
  });

  final VoidCallback onPostTask;
  final VoidCallback onBrowseEngineers;
  final VoidCallback onMessages;
  final VoidCallback onReviewDeliveries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick actions', style: theme.textTheme.titleLarge),
          const SizedBox(height: 5),
          Text(
            'Pick up where you want to begin.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          _ActionTile(
            icon: Icons.add_task_rounded,
            iconColor: AppColors.papayaDark,
            iconBackground: AppColors.papayaSoft,
            title: 'Post a new task',
            subtitle: 'Explain the work you need done',
            onTap: onPostTask,
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.manage_search_rounded,
            iconColor: AppColors.brand,
            iconBackground: AppColors.brandSoft,
            title: 'Find an engineer',
            subtitle: 'Explore talent for your project',
            onTap: onBrowseEngineers,
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: AppColors.saffronDark,
            iconBackground: AppColors.saffronSoft,
            title: 'Open messages',
            subtitle: 'Keep project conversations together',
            onTap: onMessages,
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.fact_check_outlined,
            iconColor: AppColors.success,
            iconBackground: AppColors.successSoft,
            title: 'Review deliveries',
            subtitle: 'Check submitted project work',
            onTap: onReviewDeliveries,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectActivityCard extends StatelessWidget {
  const _ProjectActivityCard({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Project activity', style: theme.textTheme.titleLarge),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.saffronSoft,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: const Text(
                  'WORKSPACE',
                  style: TextStyle(
                    color: AppColors.saffronDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Your project updates will appear here.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 18,
              vertical: isWide ? 34 : 26,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: AppRadii.card,
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.brandSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.work_outline_rounded,
                    color: AppColors.brand,
                    size: 29,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Your next project starts here',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 370),
                  child: Text(
                    'Once task posting is available, your projects, proposals and delivery updates will be organised in this space.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const _ModuleStatusPill(label: 'Project tools coming next'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _ActivityLegend(),
        ],
      ),
    );
  }
}

class _ActivityLegend extends StatelessWidget {
  const _ActivityLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        );
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        _LegendItem(color: AppColors.saffron, label: 'Awaiting proposals', style: style),
        _LegendItem(color: AppColors.papaya, label: 'In progress', style: style),
        _LegendItem(color: AppColors.success, label: 'Completed', style: style),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label, this.style});

  final Color color;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.profile});

  final ClientDashboardProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Your profile', style: theme.textTheme.titleLarge),
              ),
              const Icon(Icons.verified_user_outlined, color: AppColors.success, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ProfileAvatar(profile: profile, radius: 25),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.accountLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _ProfileDetail(
            icon: Icons.location_on_outlined,
            label: profile.countryName?.trim().isNotEmpty == true
                ? profile.countryName!
                : 'Country not provided',
          ),
          if (profile.accountType == 'company' &&
              profile.companyName?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 9),
            _ProfileDetail(
              icon: Icons.business_outlined,
              label: profile.companyName!,
            ),
          ],
          const SizedBox(height: 13),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Get.toNamed<void>(AppRoutes.clientEditProfile),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit profile'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 17, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = const [
      _HowStep(
        number: '01',
        icon: Icons.edit_note_rounded,
        title: 'Describe your task',
        description: 'Share the outcome, scope and deadline you have in mind.',
      ),
      _HowStep(
        number: '02',
        icon: Icons.people_alt_outlined,
        title: 'Choose your engineer',
        description: 'Review proposals and agree on the project details.',
      ),
      _HowStep(
        number: '03',
        icon: Icons.task_alt_rounded,
        title: 'Review the delivery',
        description: 'Receive the work, request changes or approve it.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('A clearer way to get work done', style: theme.textTheme.titleLarge),
        const SizedBox(height: 5),
        Text(
          'Three simple steps from idea to delivery.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                Expanded(child: _HowStepCard(step: items[i])),
                if (i != items.length - 1) const SizedBox(width: 14),
              ],
            ],
          )
        else
          Column(
            children: [
              for (final item in items) ...[
                _HowStepCard(step: item),
                const SizedBox(height: 10),
              ],
            ],
          ),
      ],
    );
  }
}

class _HowStep {
  const _HowStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final String number;
  final IconData icon;
  final String title;
  final String description;
}

class _HowStepCard extends StatelessWidget {
  const _HowStepCard({required this.step});

  final _HowStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.saffronSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(step.icon, color: AppColors.saffronDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.number,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.papayaDark,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(step.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
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

class _ModuleStatusPill extends StatelessWidget {
  const _ModuleStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile, required this.radius});

  final ClientDashboardProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = profile.avatarUrl;
    final initial = profile.firstName.isNotEmpty
        ? profile.firstName[0].toUpperCase()
        : 'W';

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.papaya, AppColors.saffron],
        ),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.brandSoft,
        backgroundImage: imageUrl != null && imageUrl.isNotEmpty
            ? NetworkImage(imageUrl)
            : null,
        child: imageUrl == null || imageUrl.isEmpty
            ? Text(
                initial,
                style: TextStyle(
                  color: AppColors.brand,
                  fontSize: radius * .8,
                  fontWeight: FontWeight.w800,
                ),
              )
            : null,
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
        color: Theme.of(context).cardTheme.color ?? AppColors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.papaya),
          SizedBox(height: 14),
          Text('Preparing your workspace...'),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 46, color: AppColors.papayaDark),
              const SizedBox(height: 16),
              Text('We couldn’t load your workspace', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
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
}
