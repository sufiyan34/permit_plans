import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/controllers/assign_task_controller.dart';
import 'package:permit_plans/models/engineer_directory_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

class AssignTaskScreen extends GetView<AssignTaskController> {
  const AssignTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Assign a task',
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
      body: Builder(
        builder: (context) {
          final engineer = controller.engineer;
          if (engineer == null) {
            return _MissingEngineer(
              onBack: () => Get.offNamed<void>(AppRoutes.clientBrowseEngineers),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 960;
              final horizontalPadding = isWide ? 32.0 : 18.0;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1320),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: _MainFormColumn(controller: controller),
                              ),
                              const SizedBox(width: 24),
                              SizedBox(
                                width: 320,
                                child: _AssignmentAside(engineer: engineer),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _PageHeading(),
                              const SizedBox(height: 18),
                              _EngineerSummaryCard(engineer: engineer, compact: false),
                              const SizedBox(height: 18),
                              _TaskForm(controller: controller),
                              const SizedBox(height: 18),
                              const _NoPaymentNotice(),
                              const SizedBox(height: 18),
                              _SubmitButton(controller: controller),
                            ],
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MainFormColumn extends StatelessWidget {
  const _MainFormColumn({required this.controller});

  final AssignTaskController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _PageHeading(),
        const SizedBox(height: 20),
        _TaskForm(controller: controller),
        const SizedBox(height: 18),
        _SubmitButton(controller: controller),
      ],
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => Get.back<void>(),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Back to engineer profile'),
          style: TextButton.styleFrom(foregroundColor: AppColors.brand),
        ),
        const SizedBox(height: 10),
        Text(
          'Tell the engineer what you need',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Send a task invitation with the scope, budget guidance and files. The engineer will review it and send a quote.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _TaskForm extends StatelessWidget {
  const _TaskForm({required this.controller});

  final AssignTaskController controller;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FormSection(
            number: '01',
            title: 'Task details',
            subtitle: 'Give your project a clear title and explain the work.',
            child: Column(
              children: [
                TextFormField(
                  controller: controller.titleController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 120,
                  validator: controller.validateTitle,
                  decoration: const InputDecoration(
                    labelText: 'Task title',
                    hintText: 'e.g. Build a booking website for my business',
                    prefixIcon: Icon(Icons.title_rounded),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: controller.descriptionController,
                  minLines: 5,
                  maxLines: 9,
                  maxLength: 10000,
                  textCapitalization: TextCapitalization.sentences,
                  validator: controller.validateDescription,
                  decoration: const InputDecoration(
                    labelText: 'Project description',
                    hintText: 'Describe the outcome you need, key requirements, any constraints and what a successful delivery should include...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => DropdownButtonFormField<String>(
                      value: controller.selectedCategory.value.isEmpty
                          ? null
                          : controller.selectedCategory.value,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      hint: const Text('Choose a project category'),
                      items: AssignTaskController.categories
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category, overflow: TextOverflow.ellipsis),
                              ))
                          .toList(growable: false),
                      onChanged: (value) => controller.selectedCategory.value = value ?? '',
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FormSection(
            number: '02',
            title: 'Skills and requirements',
            subtitle: 'Add the specific skills this task needs. These help the engineer understand the scope.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.skillController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => controller.addSkill(),
                        decoration: const InputDecoration(
                          labelText: 'Required skill',
                          hintText: 'e.g. Flutter, Figma, PostgreSQL',
                          prefixIcon: Icon(Icons.auto_awesome_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: controller.addSkill,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
                        ),
                        child: const Icon(Icons.add_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(() {
                  if (controller.requiredSkills.isEmpty) {
                    return Text(
                      'No required skills added. You can leave this blank.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: controller.requiredSkills
                        .map((skill) => InputChip(
                              label: Text(skill),
                              onDeleted: () => controller.removeSkill(skill),
                              deleteIconColor: AppColors.brand,
                              backgroundColor: AppColors.brandSoft,
                              side: BorderSide.none,
                            ))
                        .toList(growable: false),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FormSection(
            number: '03',
            title: 'Budget and deadline',
            subtitle: 'Optional guidance only. The engineer will send their own quote after reviewing your task.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(() => DropdownButtonFormField<String>(
                      value: controller.selectedCurrency.value,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        prefixIcon: Icon(Icons.currency_exchange_rounded),
                      ),
                      items: AssignTaskController.currencies
                          .map((currency) => DropdownMenuItem(
                                value: currency,
                                child: Text(currency),
                              ))
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) controller.selectedCurrency.value = value;
                      },
                    )),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 560;
                    final minField = TextFormField(
                      controller: controller.budgetMinController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: controller.validateBudgetMin,
                      decoration: const InputDecoration(
                        labelText: 'Minimum budget (optional)',
                        hintText: 'e.g. 300',
                        prefixIcon: Icon(Icons.south_west_rounded),
                      ),
                    );
                    final maxField = TextFormField(
                      controller: controller.budgetMaxController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: controller.validateBudgetMax,
                      decoration: const InputDecoration(
                        labelText: 'Maximum budget (optional)',
                        hintText: 'e.g. 600',
                        prefixIcon: Icon(Icons.north_east_rounded),
                      ),
                    );
                    if (stacked) {
                      return Column(
                        children: [minField, const SizedBox(height: 12), maxField],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: minField),
                        const SizedBox(width: 12),
                        Expanded(child: maxField),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                Obx(() {
                  final deadline = controller.deadlineAt.value;
                  return InkWell(
                    onTap: () => controller.selectDeadline(context),
                    borderRadius: AppRadii.input,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Expected delivery date (optional)',
                        prefixIcon: const Icon(Icons.calendar_month_outlined),
                        suffixIcon: deadline == null
                            ? const Icon(Icons.keyboard_arrow_down_rounded)
                            : IconButton(
                                tooltip: 'Clear deadline',
                                onPressed: controller.clearDeadline,
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                      child: Text(
                        deadline == null
                            ? 'Choose a target date'
                            : MaterialLocalizations.of(context).formatMediumDate(deadline),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: deadline == null
                                  ? AppColors.textTertiary
                                  : AppColors.textPrimary,
                            ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FormSection(
            number: '04',
            title: 'Reference files',
            subtitle: 'Attach briefs, examples, screenshots or documents that help explain the work.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: controller.pickAttachments,
                  icon: const Icon(Icons.attach_file_rounded),
                  label: const Text('Choose files'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Up to 5 files · 10 MB each · PDF, Office documents, images, ZIP, CSV or TXT',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
                Obx(() {
                  if (controller.attachments.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: controller.attachments
                          .map((file) => _AttachmentRow(
                                file: file,
                                sizeBytes: controller.attachmentSize(file),
                                onRemove: () => controller.removeAttachment(file),
                              ))
                          .toList(growable: false),
                    ),
                  );
                }),
              ],
            ),
          ),
          Obx(() {
            final error = controller.errorMessage.value;
            if (error.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _InlineError(message: error),
            );
          }),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String number;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.papayaSoft,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: AppColors.papayaDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _EngineerSummaryCard extends StatelessWidget {
  const _EngineerSummaryCard({required this.engineer, required this.compact});

  final EngineerDirectoryProfile engineer;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatar = engineer.avatarUrl;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
        child: Row(
          children: [
            CircleAvatar(
              radius: compact ? 26 : 30,
              backgroundColor: AppColors.brandSoft,
              backgroundImage: avatar == null || avatar.isEmpty ? null : NetworkImage(avatar),
              child: avatar == null || avatar.isEmpty
                  ? Text(
                      engineer.initials,
                      style: const TextStyle(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sending invitation to',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    engineer.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    engineer.headline,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _SmallTag(
                        icon: Icons.workspace_premium_outlined,
                        label: engineer.levelLabel,
                      ),
                      _SmallTag(
                        icon: Icons.location_on_outlined,
                        label: (engineer.countryName?.trim().isNotEmpty ?? false)
                            ? engineer.countryName!.trim()
                            : 'Country not listed',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!compact)
              IconButton(
                tooltip: 'Back to profile',
                onPressed: () => Get.back<void>(),
                icon: const Icon(Icons.open_in_new_rounded),
              ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentAside extends StatelessWidget {
  const _AssignmentAside({required this.engineer});

  final EngineerDirectoryProfile engineer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EngineerSummaryCard(engineer: engineer, compact: true),
        const SizedBox(height: 16),
        const _NoPaymentNotice(),
        const SizedBox(height: 16),
        const _WhatHappensNextCard(),
      ],
    );
  }
}

class _NoPaymentNotice extends StatelessWidget {
  const _NoPaymentNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: AppColors.success, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No payment at this stage',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Sending an invitation is free. The engineer will respond with a quote. You only proceed to payment after both sides agree on the final terms.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    height: 1.5,
                    fontSize: 12,
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

class _WhatHappensNextCard extends StatelessWidget {
  const _WhatHappensNextCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What happens next?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            const _NextStep(
              number: '1',
              title: 'Engineer reviews',
              subtitle: 'They can reject the task or send a quote.',
            ),
            const _NextStep(
              number: '2',
              title: 'You agree on a quote',
              subtitle: 'Accept, reject or negotiate the offer.',
            ),
            const _NextStep(
              number: '3',
              title: 'Fund the project',
              subtitle: 'Payment comes after the final agreement.',
            ),
          ],
        ),
      ),
    );
  }
}

class _NextStep extends StatelessWidget {
  const _NextStep({required this.number, required this.title, required this.subtitle});

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.brandSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.brand,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
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

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.controller});

  final AssignTaskController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isSubmitting.value;
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: isLoading ? null : controller.submit,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded),
          label: Text(isLoading ? 'Sending invitation...' : 'Send task invitation'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 54),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
          ),
        ),
      );
    });
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({
    required this.file,
    required this.sizeBytes,
    required this.onRemove,
  });

  final PlatformFile file;
  final int sizeBytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final extension = (file.extension ?? 'file').toUpperCase();
    return Container(
      margin: const EdgeInsets.only(top: 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, color: AppColors.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                Text(
                  '$extension · ${_formatBytes(sizeBytes)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove file',
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.brand),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.brand,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: AppRadii.input,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingEngineer extends StatelessWidget {
  const _MissingEngineer({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_search_outlined, size: 52, color: AppColors.papaya),
              const SizedBox(height: 14),
              Text(
                'No engineer selected',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Go back to the engineer directory and choose someone to invite.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Browse engineers'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
