import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/controllers/engineer_profile_details_controller.dart';
import 'package:permit_plans/models/engineer_directory_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

/// Client-facing full professional profile for a selected engineer.
/// Receives only the public-safe profile returned by browse_engineers RPC.
class EngineerProfileDetailsScreen
    extends GetView<EngineerProfileDetailsController> {
  const EngineerProfileDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Engineer profile',
      currentIndex: 3,
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
        SidebarItem(icon: Icons.receipt_long_outlined, label: 'Payments'),
        SidebarItem(icon: Icons.person_outline_rounded, label: 'My profile'),
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
      body: _ProfileDetailsBody(controller: controller),
    );
  }
}

class _ProfileDetailsBody extends StatelessWidget {
  const _ProfileDetailsBody({required this.controller});

  final EngineerProfileDetailsController controller;

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile;
    if (profile == null) {
      return _MissingProfile(onBack: controller.goBack);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 960;
        final pagePadding = isWide ? 32.0 : 18.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pagePadding, 24, pagePadding, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackLink(onPressed: controller.goBack),
                  const SizedBox(height: 18),
                  _ProfileHero(profile: profile, isWide: isWide),
                  const SizedBox(height: 20),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: _ProfileInformation(profile: profile),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 310,
                          child: _InvitePanel(
                            profile: profile,
                            onAssign: controller.assignTask,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _InvitePanel(
                          profile: profile,
                          onAssign: controller.assignTask,
                        ),
                        const SizedBox(height: 16),
                        _ProfileInformation(profile: profile),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_back_rounded, size: 18),
      label: const Text('Back to engineers'),
      style: TextButton.styleFrom(foregroundColor: AppColors.brand),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile, required this.isWide});

  final EngineerDirectoryProfile profile;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = Column(
      crossAxisAlignment: isWide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Wrap(
          alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _HeroTag(
              label: profile.levelLabel,
              icon: Icons.workspace_premium_outlined,
              background: Colors.white.withValues(alpha: 0.13),
            ),
            _HeroTag(
              label: profile.availabilityLabel,
              icon: profile.availability == 'unavailable'
                  ? Icons.do_not_disturb_on_outlined
                  : Icons.check_circle_outline_rounded,
              background: Colors.white.withValues(alpha: 0.13),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          profile.fullName,
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: (isWide
                  ? theme.textTheme.headlineMedium
                  : theme.textTheme.headlineSmall)
              ?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          profile.headline,
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.88),
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            _HeroMeta(
              icon: Icons.location_on_outlined,
              label: (profile.countryName?.trim().isNotEmpty ?? false)
                  ? profile.countryName!.trim()
                  : 'Location not provided',
            ),
            _HeroMeta(
              icon: Icons.work_outline_rounded,
              label: profile.experienceLabel,
            ),
          ],
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 30 : 22),
      decoration: BoxDecoration(
        borderRadius: AppRadii.card,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brandDark],
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -38,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: isWide ? 190 : 130,
              color: Colors.white.withValues(alpha: 0.055),
            ),
          ),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ProfileAvatar(profile: profile, radius: 54),
                const SizedBox(width: 24),
                Expanded(child: details),
              ],
            )
          else
            Column(
              children: [
                _ProfileAvatar(profile: profile, radius: 48),
                const SizedBox(height: 18),
                details,
              ],
            ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile, required this.radius});
  final EngineerDirectoryProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final url = profile.avatarUrl;

    return Container(
      width: size + 8,
      height: size + 8,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.brandSoft,
        child: ClipOval(
          child: url == null || url.trim().isEmpty
              ? _Initials(profile: profile, radius: radius)
              : Image.network(
                  url,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _Initials(profile: profile, radius: radius),
                ),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.profile, required this.radius});
  final EngineerDirectoryProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Center(
        child: Text(
          profile.initials,
          style: TextStyle(
            color: AppColors.brand,
            fontWeight: FontWeight.w900,
            fontSize: radius * 0.72,
          ),
        ),
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({
    required this.label,
    required this.icon,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.saffron),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.84),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ProfileInformation extends StatelessWidget {
  const _ProfileInformation({required this.profile});
  final EngineerDirectoryProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InformationCard(
          title: 'About',
          icon: Icons.person_outline_rounded,
          child: Text(
            profile.bio.trim().isEmpty
                ? 'This engineer has not added a professional introduction yet.'
                : profile.bio.trim(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.65,
                ),
          ),
        ),
        const SizedBox(height: 16),
        _InformationCard(
          title: 'Skills & expertise',
          icon: Icons.auto_awesome_outlined,
          child: profile.skills.isEmpty
              ? const _EmptySectionText(text: 'No skills have been added yet.')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.skills
                      .map((skill) => _SkillChip(label: skill))
                      .toList(growable: false),
                ),
        ),
        const SizedBox(height: 16),
        _InformationCard(
          title: 'Professional experience',
          icon: Icons.workspace_premium_outlined,
          child: Row(
            children: [
              Expanded(
                child: _ExperienceTile(
                  label: 'Experience level',
                  value: profile.levelLabel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ExperienceTile(
                  label: 'Years of experience',
                  value: profile.yearsExperience == 1
                      ? '1 year'
                      : '${profile.yearsExperience} years',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InformationCard(
          title: 'Languages',
          icon: Icons.translate_rounded,
          child: profile.languages.isEmpty
              ? const _EmptySectionText(text: 'No languages have been listed.')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.languages
                      .map((language) => _LanguageChip(label: language))
                      .toList(growable: false),
                ),
        ),
        const SizedBox(height: 16),
        _PortfolioCard(profile: profile),
      ],
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.card,
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(icon, size: 19, color: AppColors.brand),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ExperienceTile extends StatelessWidget {
  const _ExperienceTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink)),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.brandTint),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.brand,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.saffronSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.warningInk,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({required this.profile});
  final EngineerDirectoryProfile profile;

  @override
  Widget build(BuildContext context) {
    return _InformationCard(
      title: 'Portfolio',
      icon: Icons.folder_open_outlined,
      child: profile.portfolioLinks.isEmpty
          ? const _EmptySectionText(text: 'This engineer has not added portfolio links yet.')
          : Column(
              children: [
                for (final link in profile.portfolioLinks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _PortfolioLinkTile(link: link),
                  ),
              ],
            ),
    );
  }
}

class _PortfolioLinkTile extends StatelessWidget {
  const _PortfolioLinkTile({required this.link});
  final String link;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: AppColors.brand, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              link,
              maxLines: 2,
              style: const TextStyle(
                color: AppColors.papayaDark,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copy link',
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              Get.snackbar(
                'Link copied',
                'Portfolio link copied to your clipboard.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.brand,
                colorText: AppColors.white,
                margin: const EdgeInsets.all(14),
                duration: const Duration(seconds: 2),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 17),
          ),
        ],
      ),
    );
  }
}

class _EmptySectionText extends StatelessWidget {
  const _EmptySectionText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textTertiary,
          ),
    );
  }
}

class _InvitePanel extends StatelessWidget {
  const _InvitePanel({required this.profile, required this.onAssign});

  final EngineerDirectoryProfile profile;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = profile.availability == 'available';
    final limited = profile.availability == 'limited';
    final statusColor = available
        ? AppColors.success
        : limited
            ? AppColors.saffronDark
            : AppColors.error;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.card,
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interested in working together?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send this engineer a task invitation. They can review the requirements and respond with a quote.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CURRENT AVAILABILITY',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          profile.availabilityLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: profile.canReceiveAssignment ? onAssign : null,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Assign a task'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.papaya,
                  foregroundColor: AppColors.ink,
                  disabledBackgroundColor: AppColors.disabled,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadii.button,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'You will agree on the price and delivery terms before payment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingProfile extends StatelessWidget {
  const _MissingProfile({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.brandSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  color: AppColors.brand,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Engineer profile unavailable',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Open an engineer from the Browse Engineers directory to view their professional profile.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to engineers'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
