import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';
import 'package:permit_plans/widgets/floating_chat_widget.dart';

/// One tab in the bottom navigation bar (or side rail on wide screens).
///
/// [route] null -> opens the "Coming soon" placeholder for that tab.
class ShellDestination {
  const ShellDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.route,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final String? route;
}

/// Page frame used by every signed-in screen.
///
/// - App bar: logo + title, optional [actions], and a profile pill that opens
///   the end-drawer [AppSidebar].
/// - Phones / tablets (< [wideBreakpoint]): floating pill navigation bar whose
///   selected tab expands to show its label.
/// - Laptops / web (>= [wideBreakpoint]): floating gradient navigation rail on
///   the left (icons only below 1200px, icons + labels above).
///
/// ```dart
/// AppShell(
///   title: 'Dashboard',
///   currentIndex: 0,
///   destinations: const [
///     ShellDestination(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home', route: AppRoutes.clientHome),
///     ShellDestination(icon: Icons.chat_bubble_outline, label: 'Messages'), // -> Coming soon
///   ],
///   sidebarItems: const [SidebarItem(icon: Icons.settings_outlined, label: 'Settings')],
///   body: const MyPage(),
/// )
/// ```
class AppShell extends StatelessWidget {
  const AppShell({
    required this.body,
    required this.destinations,
    required this.currentIndex,
    this.title = 'WorkBridge',
    this.sidebarItems = const [],
    this.actions = const [],
    this.onDestinationSelected,
    this.floatingActionButton,
    this.wideBreakpoint = 960,
    super.key,
  });

  final Widget body;
  final List<ShellDestination> destinations;
  final int currentIndex;
  final String title;
  final List<SidebarItem> sidebarItems;

  /// Extra app bar buttons shown before the profile pill.
  final List<Widget> actions;

  /// Override the default navigation.
  final ValueChanged<int>? onDestinationSelected;

  final Widget? floatingActionButton;
  final double wideBreakpoint;

  void _select(int index) {
    if (onDestinationSelected != null) {
      onDestinationSelected!(index);
      return;
    }
    if (index == currentIndex) return;

    final item = destinations[index];
    if (item.route == null) {
      // Not built yet: stack the placeholder so Back returns here.
      Get.toNamed<void>(AppRoutes.comingSoonFor(item.label));
    } else {
      Get.offNamed<void>(item.route!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canNavigate = destinations.length >= 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= wideBreakpoint && canNavigate;
        final extended = constraints.maxWidth >= 1200;

        // Keep the assistant inside the page content instead of the Scaffold
        // FAB slot. The full-size overlay lets the chat panel expand without
        // being clipped by the small constraints normally given to a FAB.
        Widget withAssistantOverlay(Widget page) {
          return Stack(
            fit: StackFit.expand,
            children: [
              page,
              const Positioned.fill(child: FloatingChatWidget()),
            ],
          );
        }

        return Scaffold(
          appBar: _ShellAppBar(
            title: title,
            actions: actions,
            showBrand: !isWide,
          ),
          endDrawer: AppSidebar(items: sidebarItems),
          floatingActionButton: floatingActionButton,
          body: isWide
              ? Row(
                  children: [
                    _SideRail(
                      destinations: destinations,
                      currentIndex: currentIndex,
                      onSelected: _select,
                      extended: extended,
                    ),
                    Expanded(child: withAssistantOverlay(body)),
                  ],
                )
              : withAssistantOverlay(body),
          bottomNavigationBar: (!isWide && canNavigate)
              ? _FloatingNavBar(
                  destinations: destinations,
                  currentIndex: currentIndex,
                  onSelected: _select,
                )
              : null,
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// App bar
// -----------------------------------------------------------------------------

class _ShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ShellAppBar({
    required this.title,
    required this.actions,
    required this.showBrand,
  });

  final String title;
  final List<Widget> actions;
  final bool showBrand;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: [
              if (showBrand) ...[
                const BrandMark(size: 38),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (showBrand
                              ? theme.textTheme.titleLarge
                              : theme.textTheme.headlineSmall)
                          ?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                ),
              ),
              ...actions,
              if (actions.isNotEmpty) const SizedBox(width: 8),
              const _ProfileMenuButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuButton extends StatelessWidget {
  const _ProfileMenuButton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Builder gives a context *below* the Scaffold so openEndDrawer works.
    return Builder(
      builder: (context) => Tooltip(
        message: 'Menu',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => Scaffold.of(context).openEndDrawer(),
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const UserAvatar(size: 34, ring: 2),
                  const SizedBox(width: 8),
                  Icon(Icons.menu_rounded, size: 20, color: colors.onSurface),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Mobile: floating pill bar
// -----------------------------------------------------------------------------

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<ShellDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              height: 68,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.brandDark,
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandDark.withValues(alpha: 0.32),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, c) {
                  final n = destinations.length;
                  final selectedWidth = (c.maxWidth * 0.36)
                      .clamp(104.0, 148.0)
                      .toDouble();
                  final otherWidth = (c.maxWidth - selectedWidth) / (n - 1);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < n; i++)
                        _FloatingNavItem(
                          destination: destinations[i],
                          selected: i == currentIndex,
                          width: i == currentIndex ? selectedWidth : otherWidth,
                          onTap: () => onSelected(i),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingNavItem extends StatelessWidget {
  const _FloatingNavItem({
    required this.destination,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = selected
        ? (destination.selectedIcon ?? destination.icon)
        : destination.icon;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: width,
            height: 50,
            decoration: BoxDecoration(
              color: selected ? AppColors.papaya : Colors.transparent,
              borderRadius: BorderRadius.circular(26),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.papaya.withValues(alpha: 0.38),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Center(
              // FittedBox keeps the content from overflowing mid-animation.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 23,
                      color: selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.62),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 7),
                      Text(
                        destination.label,
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Web / laptop: floating gradient rail
// -----------------------------------------------------------------------------

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
    required this.extended,
  });

  final List<ShellDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: extended ? 248 : 96,
      margin: const EdgeInsets.fromLTRB(14, 14, 0, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.brand, AppColors.brandDark],
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          const SizedBox(height: 22),
          if (extended)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  const BrandMark(size: 40, onDark: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'WorkBridge',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const BrandMark(size: 44, onDark: true),
          const SizedBox(height: 26),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (var i = 0; i < destinations.length; i++)
                  _RailItem(
                    destination: destinations[i],
                    selected: i == currentIndex,
                    extended: extended,
                    onTap: () => onSelected(i),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : Colors.white.withValues(alpha: 0.68);
    final iconColor = selected ? AppColors.saffron : fg;
    final icon = selected
        ? (destination.selectedIcon ?? destination.icon)
        : destination.icon;

    final tile = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          hoverColor: Colors.white.withValues(alpha: 0.06),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: extended
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 13)
                : const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: selected
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.transparent,
              border: Border.all(
                color: selected
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.transparent,
              ),
            ),
            child: extended
                ? Row(
                    children: [
                      Icon(icon, size: 22, color: iconColor),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          destination.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: fg,
                            fontSize: 14,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 23, color: iconColor),
                      const SizedBox(height: 4),
                      Text(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fg,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: tile,
    );
  }
}
