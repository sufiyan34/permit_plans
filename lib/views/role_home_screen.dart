import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/controllers/auth_controller.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

/// Temporary landing page for each role, wrapped in [AppShell] so the app bar,
/// bottom navigation bar (mobile) / navigation rail (web) and the end-drawer
/// sidebar are visible on every dashboard.
///
/// Tabs without a real page yet open the "Coming soon" screen. When a real page
/// exists, give that tab a `route` below.
class RoleHomeScreen extends StatelessWidget {
  const RoleHomeScreen({
    required this.role,
    required this.title,
    required this.description,
    required this.icon,
    super.key,
  });

  /// 'client', 'engineer' or 'admin'.
  final String role;
  final String title;
  final String description;
  final IconData icon;

  List<ShellDestination> get _destinations {
    final home = ShellDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
      route: AppRoutes.homeForRole(role),
    );

    switch (role) {
      case 'engineer':
        return [
          home,
          const ShellDestination(
            icon: Icons.search_rounded,
            label: 'Find work',
          ),
          const ShellDestination(
            icon: Icons.request_quote_outlined,
            label: 'My bids',
          ),
          const ShellDestination(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Messages',
          ),
          const ShellDestination(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
          ),
        ];
      case 'admin':
        return [
          home,
          const ShellDestination(icon: Icons.group_outlined, label: 'Users'),
          const ShellDestination(
            icon: Icons.work_outline_rounded,
            label: 'Projects',
          ),
          const ShellDestination(
            icon: Icons.payments_outlined,
            label: 'Payments',
          ),
          const ShellDestination(
            icon: Icons.settings_outlined,
            label: 'Settings',
          ),
        ];
      case 'client':
      default:
        return [
          home,
          const ShellDestination(
            icon: Icons.work_outline_rounded,
            label: 'Projects',
          ),
          const ShellDestination(
            icon: Icons.description_outlined,
            label: 'Proposals',
          ),
          const ShellDestination(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Messages',
          ),
          const ShellDestination(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
          ),
        ];
    }
  }

  List<SidebarItem> get _sidebarItems => [
    SidebarItem(
      icon: Icons.home_outlined,
      label: 'Dashboard',
      route: AppRoutes.homeForRole(role),
    ),
    const SidebarItem(icon: Icons.person_outline_rounded, label: 'My profile'),
    const SidebarItem(
      icon: Icons.notifications_none_rounded,
      label: 'Notifications',
      route: AppRoutes.notifications,
    ),
    const SidebarItem(icon: Icons.settings_outlined, label: 'Settings'),
    const SidebarItem(
      icon: Icons.help_outline_rounded,
      label: 'Help & support',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Get.find<AuthController>();

    return AppShell(
      title: title,
      currentIndex: 0,
      destinations: _destinations,
      sidebarItems: _sidebarItems,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: AppRadii.card,
                    ),
                    child: Icon(
                      icon,
                      size: 34,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Obx(() {
                    final email = auth.currentUser.value?.email;
                    final currentRole = auth.currentRole.value;
                    return Text(
                      [
                        if (email != null) 'Signed in as $email',
                        if (currentRole != null) '($currentRole)',
                      ].join(' '),
                      style: theme.textTheme.labelMedium,
                      textAlign: TextAlign.center,
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
