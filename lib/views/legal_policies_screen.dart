import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/controllers/legal_policies_controller.dart';
import 'package:permit_plans/models/legal_policy_model.dart';

class LegalPoliciesScreen extends GetView<LegalPoliciesController> {
  const LegalPoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.balance_rounded,
                  color: AppColors.saffron, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Legal & Policies',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 920;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 28 : 16,
                    14,
                    wide ? 28 : 16,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _pageHeading(context, wide),
                      const SizedBox(height: 18),
                      const _DraftNotice(),
                      const SizedBox(height: 18),
                      Expanded(
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 250,
                                    child: _PolicyNavigation(
                                      controller: controller,
                                      vertical: true,
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: _PolicyContent(
                                      controller: controller,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _PolicyNavigation(
                                    controller: controller,
                                    vertical: false,
                                  ),
                                  const SizedBox(height: 14),
                                  Expanded(
                                    child: _PolicyContent(
                                      controller: controller,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _pageHeading(BuildContext context, bool wide) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Understand how WorkBridge works',
          style: (wide
                  ? theme.textTheme.headlineMedium
                  : theme.textTheme.headlineSmall)
              ?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Review the platform terms, privacy approach, age eligibility and payment rules.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _DraftNotice extends StatelessWidget {
  const _DraftNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gavel_rounded, color: AppColors.warningInk),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DRAFT — NOT READY FOR PUBLICATION',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.warningInk,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'These policy templates describe the current product plan. The operating company, launch countries, governing law, provider terms, support contacts and age requirements must be confirmed and reviewed by a qualified legal professional before launch.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warningInk,
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

class _PolicyNavigation extends StatelessWidget {
  const _PolicyNavigation({
    required this.controller,
    required this.vertical,
  });

  final LegalPoliciesController controller;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    if (!vertical) {
      return SizedBox(
        height: 48,
        child: Obx(
          () => ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: LegalPolicyDocuments.all.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final document = LegalPolicyDocuments.all[index];
              final selected = controller.selectedPolicyId.value == document.id;
              return ChoiceChip(
                label: Text(document.shortTitle),
                selected: selected,
                onSelected: (_) => controller.selectPolicy(document.id),
                selectedColor: AppColors.brandSoft,
                labelStyle: TextStyle(
                  color: selected ? AppColors.brandDark : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(
                  color: selected ? AppColors.brand : AppColors.outlineVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              );
            },
          ),
        ),
      );
    }

    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'DOCUMENTS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          for (final document in LegalPolicyDocuments.all) ...[
            _PolicyNavTile(
              document: document,
              selected: controller.selectedPolicyId.value == document.id,
              onTap: () => controller.selectPolicy(document.id),
            ),
            const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }
}

class _PolicyNavTile extends StatelessWidget {
  const _PolicyNavTile({
    required this.document,
    required this.selected,
    required this.onTap,
  });

  final LegalPolicyDocument document;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon {
    switch (document.id) {
      case 'privacy':
        return Icons.shield_outlined;
      case 'age':
        return Icons.person_outline_rounded;
      case 'payments':
        return Icons.payments_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brandSoft : AppColors.surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? AppColors.brand.withValues(alpha: 0.35) : AppColors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(_icon, color: selected ? AppColors.brand : AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  document.shortTitle,
                  style: TextStyle(
                    color: selected ? AppColors.brandDark : AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.chevron_right_rounded, color: AppColors.brand),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicyContent extends StatelessWidget {
  const _PolicyContent({required this.controller});

  final LegalPoliciesController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final document = controller.selectedDocument;
      final sections = controller.visibleSections;
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              document.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              document.summary,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.warningSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'DRAFT',
                          style: TextStyle(
                            color: AppColors.warningInk,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.searchController,
                    onChanged: controller.setSearch,
                    decoration: InputDecoration(
                      hintText: 'Search this policy',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: controller.searchQuery.value.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: controller.clearSearch,
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: AppColors.inputFill,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: sections.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No matching sections found.'),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                      itemCount: sections.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 7),
                      itemBuilder: (context, index) => _PolicySectionTile(
                        section: sections[index],
                        initiallyExpanded: index == 0 && controller.searchQuery.value.isEmpty,
                      ),
                    ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.outlineVariant)),
              ),
              child: Text(
                'Draft copy · Publication date not set · Contact details pending',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _PolicySectionTile extends StatelessWidget {
  const _PolicySectionTile({
    required this.section,
    required this.initiallyExpanded,
  });

  final LegalPolicySection section;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(15, 0, 15, 16),
        iconColor: AppColors.brand,
        collapsedIconColor: AppColors.textSecondary,
        title: Text(
          section.title,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        children: [
          for (final paragraph in section.paragraphs) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                paragraph,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
