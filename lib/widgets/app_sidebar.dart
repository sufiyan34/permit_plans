import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import 'package:permit_plans/auths/auth_screen_components.dart';
import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/controllers/auth_controller.dart';
import 'package:permit_plans/services/auth_service.dart';

/// One row in the [AppSidebar].
///
/// - [route] set          -> navigates there.
/// - [route] null         -> opens the "Coming soon" placeholder page.
/// - [onTap] set          -> runs instead of any navigation.
/// - [badge]              -> small counter pill, e.g. unread notifications.
class SidebarItem {
  const SidebarItem({
    required this.icon,
    required this.label,
    this.route,
    this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String? route;
  final VoidCallback? onTap;
  final String? badge;
}

/// WorkBridge logo tile. Reused by the app bar and the navigation rail.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 40, this.onDark = false, super.key});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: onDark
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.brand, AppColors.brandDark],
              ),
        color: onDark ? Colors.white.withValues(alpha: 0.12) : null,
        border: onDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.16))
            : null,
      ),
      child: Icon(Icons.hub_rounded, color: AppColors.saffron, size: size * 0.55),
    );
  }
}

/// Round avatar with the signed-in user's initial and a papaya→saffron ring.
class UserAvatar extends StatelessWidget {
  const UserAvatar({this.size = 40, this.ring = 2, super.key});

  final double size;
  final double ring;

  Widget _build(String initial) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ring),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.papaya, AppColors.saffron],
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.brand,
        ),
        child: Center(
          child: Text(
            initial,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.40,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AuthController>()) return _build('?');
    final auth = Get.find<AuthController>();
    return Obx(() {
      final email = auth.currentUser.value?.email ?? '';
      return _build(email.isEmpty ? '?' : email[0].toUpperCase());
    });
  }
}

/// End drawer (right-side sidebar): gradient profile header, animated menu
/// items, and a confirm-before sign out.
///
/// Open it with `Scaffold.of(context).openEndDrawer()`; [AppShell] does this
/// through the profile button in its app bar.
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    required this.items,
    this.brandName = 'WorkBridge',
    super.key,
  });

  final List<SidebarItem> items;
  final String brandName;

  void _open(BuildContext context, SidebarItem item) {
    Navigator.of(context).pop(); // close the drawer first

    if (item.onTap != null) {
      item.onTap!();
      return;
    }

    final target = _routeForSidebarItem(item) ??
        AppRoutes.comingSoonFor(item.label);
    if (target == Get.currentRoute) return;
    Get.toNamed<void>(target);
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to get back to your workspace.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      // The auth controller / guards route the user to login afterwards.
      await Get.find<AuthController>().signOut();
    } on AuthServiceException catch (error) {
      if (context.mounted) showAuthMessage(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentRoute = Get.currentRoute;

    return Drawer(
      width: 340,
      backgroundColor: theme.scaffoldBackgroundColor,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidebarHeader(brandName: brandName),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                  child: Text(
                    'MENU',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                for (var i = 0; i < items.length; i++)
                  _SidebarTile(
                    item: items[i],
                    selected: _routeForSidebarItem(items[i]) == currentRoute,
                    onTap: () => _open(context, items[i]),
                  )
                      .animate(delay: Duration(milliseconds: 45 * i))
                      .fadeIn(duration: 280.ms)
                      .slideX(
                        begin: 0.12,
                        end: 0,
                        duration: 280.ms,
                        curve: Curves.easeOutCubic,
                      ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (Get.currentRoute != AppRoutes.legalPolicies) {
                          Get.toNamed<void>(AppRoutes.legalPolicies);
                        }
                      },
                      icon: const Icon(Icons.policy_outlined, size: 18),
                      label: const Text('Legal & Policies'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.brand,
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmSignOut(context),
                      icon: const Icon(Icons.logout_rounded, size: 19),
                      label: const Text('Sign out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(
                          color: theme.colorScheme.error.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$brandName · Independent work. Better together.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.brandName});

  final String brandName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brandDark],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -50,
            child: _Orb(size: 190, color: AppColors.papaya.withValues(alpha: 0.24)),
          ),
          Positioned(
            bottom: -70,
            left: -40,
            child: _Orb(size: 170, color: AppColors.saffron.withValues(alpha: 0.16)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topInset + 16, 12, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const BrandMark(size: 34, onDark: true),
                    const SizedBox(width: 10),
                    Text(
                      brandName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _HeaderProfile(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final registered = Get.isRegistered<AuthController>();

    Widget details(String email, String? role) {
      return Row(
        children: [
          const UserAvatar(size: 62, ring: 3),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email.isEmpty ? 'Welcome' : email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (role != null && role.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.saffron.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppColors.saffron.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      role[0].toUpperCase() + role.substring(1),
                      style: const TextStyle(
                        color: AppColors.saffron,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    if (!registered) return details('', null);
    final auth = Get.find<AuthController>();
    return Obx(
      () => details(auth.currentUser.value?.email ?? '', auth.currentRole.value),
    );
  }
}

String? _routeForSidebarItem(SidebarItem item) {
  if (item.route != null) return item.route;
  if (item.label.trim().toLowerCase() == 'settings') {
    return AppRoutes.accountSettings;
  }
  if (item.label.trim().toLowerCase() == 'help & support') {
    return AppRoutes.helpSupport;
  }
  return null;
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final SidebarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final soon = _routeForSidebarItem(item) == null && item.onTap == null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: selected
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.brandSoft)
                  : Colors.transparent,
              border: Border.all(
                color: selected
                    ? AppColors.brand.withValues(alpha: 0.18)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: selected
                        ? AppColors.brand
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : AppColors.surfaceAlt),
                  ),
                  child: Icon(
                    item.icon,
                    size: 21,
                    color: selected ? Colors.white : colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                if (item.badge != null)
                  _Pill(
                    label: item.badge!,
                    background: AppColors.papaya,
                    foreground: Colors.white,
                  )
                else if (soon)
                  const _Pill(
                    label: 'Soon',
                    background: AppColors.saffronSoft,
                    foreground: AppColors.saffronDark,
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
