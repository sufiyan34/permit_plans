import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/controllers/engineer_directory_controller.dart';
import 'package:permit_plans/models/engineer_directory_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

/// Client-facing engineer directory. The directory is loaded through the
/// privacy-filtered Supabase browse_engineers RPC, never by reading private
/// profile tables directly.
class BrowseEngineersScreen extends GetView<EngineerDirectoryController> {
  const BrowseEngineersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Find engineers',
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
      body: _BrowseEngineersBody(controller: controller),
    );
  }
}

class _BrowseEngineersBody extends StatelessWidget {
  const _BrowseEngineersBody({required this.controller});

  final EngineerDirectoryController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isLoading.value;
      final error = controller.errorMessage.value;
      final engineers = controller.engineers;

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 960;
          final pagePadding = isWide ? 32.0 : 18.0;

          return RefreshIndicator(
            onRefresh: () => controller.loadEngineers(refresh: true),
            color: AppColors.papaya,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(pagePadding, 24, pagePadding, 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DirectoryHeading(isWide: isWide),
                      const SizedBox(height: 22),
                      _SearchAndFilters(controller: controller),
                      const SizedBox(height: 18),
                      _DirectoryToolbar(controller: controller),
                      const SizedBox(height: 16),
                      if (isLoading && engineers.isEmpty)
                        const _DirectoryLoading()
                      else if (error.isNotEmpty && engineers.isEmpty)
                        _DirectoryError(
                          message: error,
                          onRetry: controller.loadEngineers,
                        )
                      else if (engineers.isEmpty)
                        _DirectoryEmpty(
                          hasFilters: controller.hasActiveFilters ||
                              controller.searchController.text.trim().isNotEmpty,
                          onClear: controller.clearFilters,
                        )
                      else ...[
                        _EngineerResultsGrid(engineers: engineers),
                        if (controller.hasMore) ...[
                          const SizedBox(height: 22),
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: controller.isLoadingMore.value
                                  ? null
                                  : controller.loadMore,
                              icon: controller.isLoadingMore.value
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.expand_more_rounded),
                              label: Text(controller.isLoadingMore.value
                                  ? 'Loading...' : 'Load more engineers'),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 28),
                      const _DirectoryFooterNote(),
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
}

class _DirectoryHeading extends StatelessWidget {
  const _DirectoryHeading({required this.isWide});
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 30 : 22),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: AppRadii.card,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brandDark],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: isWide ? 34 : 0,
            top: -24,
            child: Icon(
              Icons.diversity_3_rounded,
              size: isWide ? 150 : 100,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: const Text(
                  'WORK WITH GREAT PEOPLE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 600 : 290),
                child: Text(
                  'Find the right person for your next big idea.',
                  style: (isWide ? theme.textTheme.headlineMedium : theme.textTheme.headlineSmall)
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1.15),
                ),
              ),
              const SizedBox(height: 9),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 590 : 280),
                child: Text(
                  'Explore completed engineer profiles, compare skills and invite the right professional to your project.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({required this.controller});
  final EngineerDirectoryController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final search = TextField(
          controller: controller.searchController,
          onChanged: controller.onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search by name, skill or expertise...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: Obx(() => controller.searchText.value.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      controller.searchController.clear();
                      controller.searchText.value = '';
                      controller.loadEngineers();
                    },
                    icon: const Icon(Icons.close_rounded),
                  )),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: AppRadii.input,
              borderSide: BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.input,
              borderSide: BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.input,
              borderSide: const BorderSide(color: AppColors.papaya, width: 1.5),
            ),
          ),
        );

        final filterButton = OutlinedButton.icon(
          onPressed: () => _showFilters(context),
          icon: const Icon(Icons.tune_rounded),
          label: Obx(() => Text(controller.hasActiveFilters ? 'Filters applied' : 'Filters')),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(wide ? 142 : double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: AppRadii.input),
          ),
        );

        if (wide) {
          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 12),
              filterButton,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [search, const SizedBox(height: 10), filterButton],
        );
      },
    );
  }

  Future<void> _showFilters(BuildContext context) async {
    final result = await showModalBottomSheet<_DirectoryFilterValues>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.dialog),
      builder: (_) => _DirectoryFilterSheet(
        initialCountry: controller.countryFilter.value,
        initialSkill: controller.skillFilter.value,
        initialExperience: controller.experienceFilter.value,
        initialAvailability: controller.availabilityFilter.value,
      ),
    );

    if (result != null) {
      await controller.applyFilters(
        country: result.country,
        skill: result.skill,
        experience: result.experience,
        availability: result.availability,
      );
    }
  }
}

class _DirectoryToolbar extends StatelessWidget {
  const _DirectoryToolbar({required this.controller});
  final EngineerDirectoryController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = controller.totalCount.value;
      return Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Text(
            controller.isLoading.value
                ? 'Finding engineers...'
                : '$count ${count == 1 ? 'engineer' : 'engineers'} found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sort by', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.sortBy.value,
                  borderRadius: AppRadii.input,
                  items: const [
                    DropdownMenuItem(value: 'recent', child: Text('Recently updated')),
                    DropdownMenuItem(value: 'experience', child: Text('Most experienced')),
                  ],
                  onChanged: (value) {
                    if (value != null) controller.setSort(value);
                  },
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _EngineerResultsGrid extends StatelessWidget {
  const _EngineerResultsGrid({required this.engineers});
  final List<EngineerDirectoryProfile> engineers;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1220 ? 3 :
            constraints.maxWidth >= 760 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: engineers.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: columns == 1 ? 310 : 330,
          ),
          itemBuilder: (context, index) => _EngineerCard(profile: engineers[index]),
        );
      },
    );
  }
}

class _EngineerCard extends StatelessWidget {
  const _EngineerCard({required this.profile});
  final EngineerDirectoryProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = profile.availability == 'available';
    final isLimited = profile.availability == 'limited';
    final statusColor = isAvailable ? AppColors.success :
        isLimited ? AppColors.saffronDark : theme.colorScheme.error;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.card,
        side: BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EngineerAvatar(profile: profile, radius: 27),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.fullName, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(profile.headline, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.35)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _InfoPill(icon: Icons.location_on_outlined,
                    label: (profile.countryName?.isNotEmpty == true) ? profile.countryName! : 'Location not added'),
                _InfoPill(icon: Icons.workspace_premium_outlined, label: profile.levelLabel),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 7),
                Expanded(child: Text(profile.availabilityLabel,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700))),
                Text(profile.experienceLabel,
                    style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textTertiary)),
              ],
            ),
            const SizedBox(height: 11),
            Text(profile.bio, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.45)),
            const SizedBox(height: 11),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final skill in profile.skills.take(4))
                  _SkillChip(label: skill),
                if (profile.skills.length > 4)
                  _SkillChip(label: '+${profile.skills.length - 4} more', muted: true),
              ],
            ),
            const Spacer(),
            const Divider(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _showDetails,
                    child: const Text('View profile'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: FilledButton(
                    onPressed: profile.canReceiveAssignment
                        ? () => _showAssignComingSoon(profile)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.papaya,
                      foregroundColor: AppColors.ink,
                    ),
                    child: const Text('Assign task'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails() {
    Get.toNamed<void>(
      AppRoutes.clientEngineerProfileDetails,
      arguments: profile,
    );
  }

  void _showAssignComingSoon(EngineerDirectoryProfile profile) {
    Get.snackbar(
      'Engineer selected',
      'Task assignment is the next module. ${profile.fullName} is ready to be invited.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.brand,
      colorText: Colors.white,
      margin: const EdgeInsets.all(14),
    );
  }
}

class _EngineerAvatar extends StatelessWidget {
  const _EngineerAvatar({required this.profile, required this.radius});
  final EngineerDirectoryProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = profile.avatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.brandSoft,
      child: ClipOval(
        child: url == null || url.isEmpty
            ? SizedBox(
                width: radius * 2,
                height: radius * 2,
                child: Center(child: Text(profile.initials,
                    style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: radius * 0.7))),
              )
            : Image.network(
                url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(child: Text(profile.initials,
                    style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: radius * 0.7))),
              ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: AppColors.brand),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.ink, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label, this.muted = false});
  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: muted ? AppColors.surfaceAlt : AppColors.brandSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(label, style: TextStyle(
        color: muted ? AppColors.textSecondary : AppColors.brand,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      )),
    );
  }
}

class _DirectoryLoading extends StatelessWidget {
  const _DirectoryLoading();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 70),
      child: Center(child: CircularProgressIndicator(color: AppColors.papaya)),
    );
  }
}

class _DirectoryError extends StatelessWidget {
  const _DirectoryError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return _StatePanel(
      icon: Icons.cloud_off_outlined,
      title: 'We could not load the directory',
      message: message,
      action: OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
    );
  }
}

class _DirectoryEmpty extends StatelessWidget {
  const _DirectoryEmpty({required this.hasFilters, required this.onClear});
  final bool hasFilters;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) {
    return _StatePanel(
      icon: Icons.person_search_rounded,
      title: hasFilters ? 'No engineers match those filters' : 'No engineer profiles yet',
      message: hasFilters
          ? 'Try changing your search or removing a filter.'
          : 'Completed engineer profiles will appear here when professionals join the marketplace.',
      action: hasFilters ? OutlinedButton(onPressed: onClear, child: const Text('Clear filters')) : null,
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({required this.icon, required this.title, required this.message, this.action});
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 54),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: AppRadii.card, border: Border.all(color: AppColors.outlineVariant)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 42, color: AppColors.papaya),
        const SizedBox(height: 13),
        Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 7),
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.45))),
        if (action != null) ...[const SizedBox(height: 17), action!],
      ]),
    );
  }
}

class _DirectoryFooterNote extends StatelessWidget {
  const _DirectoryFooterNote();
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      'Profiles shown here are shared by engineers for marketplace discovery. Final prices are agreed through task quotes.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
    ),
  );
}

class _DirectoryFilterValues {
  const _DirectoryFilterValues({required this.country, required this.skill, required this.experience, required this.availability});
  final String country;
  final String skill;
  final String experience;
  final String availability;
}

class _DirectoryFilterSheet extends StatefulWidget {
  const _DirectoryFilterSheet({
    required this.initialCountry,
    required this.initialSkill,
    required this.initialExperience,
    required this.initialAvailability,
  });
  final String initialCountry;
  final String initialSkill;
  final String initialExperience;
  final String initialAvailability;

  @override
  State<_DirectoryFilterSheet> createState() => _DirectoryFilterSheetState();
}

class _DirectoryFilterSheetState extends State<_DirectoryFilterSheet> {
  late final TextEditingController _countryController;
  late final TextEditingController _skillController;
  late String _experience;
  late String _availability;

  @override
  void initState() {
    super.initState();
    _countryController = TextEditingController(text: widget.initialCountry);
    _skillController = TextEditingController(text: widget.initialSkill);
    _experience = widget.initialExperience;
    _availability = widget.initialAvailability;
  }

  @override
  void dispose() {
    _countryController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 22, 22, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(child: Text('Filter engineers', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ]),
            const SizedBox(height: 14),
            TextField(
              controller: _countryController,
              decoration: const InputDecoration(labelText: 'Country', hintText: 'e.g. Pakistan', prefixIcon: Icon(Icons.public_rounded)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _skillController,
              decoration: const InputDecoration(labelText: 'Skill', hintText: 'e.g. Flutter, UI design, SQL', prefixIcon: Icon(Icons.code_rounded)),
            ),
            const SizedBox(height: 16),
            const Text('Experience level', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            DropdownButtonFormField<String>(
              value: _experience,
              decoration: const InputDecoration(filled: true),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Any experience level')),
                DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                DropdownMenuItem(value: 'expert', child: Text('Expert')),
              ],
              onChanged: (value) => setState(() => _experience = value ?? 'all'),
            ),
            const SizedBox(height: 16),
            const Text('Availability', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            DropdownButtonFormField<String>(
              value: _availability,
              decoration: const InputDecoration(filled: true),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Any availability')),
                DropdownMenuItem(value: 'available', child: Text('Available for work')),
                DropdownMenuItem(value: 'limited', child: Text('Limited availability')),
                DropdownMenuItem(value: 'unavailable', child: Text('Currently unavailable')),
              ],
              onChanged: (value) => setState(() => _availability = value ?? 'all'),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => Navigator.pop(context, _DirectoryFilterValues(
                country: _countryController.text,
                skill: _skillController.text,
                experience: _experience,
                availability: _availability,
              )),
              style: FilledButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
              child: const Text('Apply filters'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, const _DirectoryFilterValues(country: '', skill: '', experience: 'all', availability: 'all')),
              child: const Text('Reset filters'),
            ),
          ],
        ),
      ),
    );
  }
}
