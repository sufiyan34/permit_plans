import 'package:flutter/material.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_theme.dart';

/// Reusable placeholder for any page that is not available yet or is still
/// under development.
///
/// Use it directly:
/// ```dart
/// const ComingSoonScreen(title: 'Payments', icon: Icons.payments_outlined)
/// ```
/// or through the named route (see `AppRoutes.comingSoonFor`):
/// ```dart
/// Get.toNamed(AppRoutes.comingSoonFor('Payments'));
/// ```
///
/// Works with or without an [AppBar]: when [showAppBar] is true a back arrow is
/// shown automatically if the route can be popped.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    this.title = 'This page',
    this.description,
    this.icon = Icons.construction_rounded,
    this.badgeLabel = 'Coming soon',
    this.primaryActionLabel = 'Go back',
    this.onPrimaryAction,
    this.showAppBar = true,
    super.key,
  });

  /// Feature / page name, e.g. "Messages". Shown as the heading.
  final String title;

  /// Optional custom explanation. A sensible default is used when null.
  final String? description;

  final IconData icon;

  /// Text of the small status pill above the heading.
  final String badgeLabel;

  final String primaryActionLabel;

  /// Defaults to popping the current route (if possible).
  final VoidCallback? onPrimaryAction;

  final bool showAppBar;

  void _handlePrimary(BuildContext context) {
    if (onPrimaryAction != null) {
      onPrimaryAction!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              automaticallyImplyLeading: canPop,
              title: const Text('WorkBridge'),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconBadge(icon: icon),
                  const SizedBox(height: AppSpacing.lg),
                  _StatusPill(label: badgeLabel),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    description ??
                        "We're still building this page. "
                            'Please check back soon.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton.icon(
                    onPressed: () => _handlePrimary(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(primaryActionLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.papayaSoft,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.papaya.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, size: 44, color: AppColors.papayaDark),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.saffronSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            size: 14,
            color: AppColors.saffronDark,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.saffronDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
