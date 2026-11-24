import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/controllers/account_settings_controller.dart';
import 'package:permit_plans/models/account_settings_model.dart';

class AccountSettingsScreen extends GetView<AccountSettingsController> {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Account settings'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Refresh account settings',
            onPressed: controller.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.snapshot.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.snapshot.value == null) {
          return _LoadError(
            message: controller.errorMessage.value,
            onRetry: controller.load,
          );
        }

        final data = controller.snapshot.value!;
        return RefreshIndicator(
          onRefresh: controller.load,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 960;
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      wide ? 32 : 18,
                      24,
                      wide ? 32 : 18,
                      40,
                    ),
                    children: [
                      _PageHeading(wide: wide),
                      const SizedBox(height: 22),
                      _AccountCard(snapshot: data),
                      const SizedBox(height: 18),
                      _PasswordCard(controller: controller, wide: wide),
                      const SizedBox(height: 18),
                      _SessionCard(onSignOut: controller.signOut),
                      const SizedBox(height: 18),
                      _DeletionCard(
                        request: data.deletionRequest,
                        isSubmitting: controller.isSubmittingDeletion,
                        onRequest: (reason) =>
                            controller.requestAccountDeletion(reason),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account settings & security',
          style: (wide ? theme.textTheme.headlineMedium : theme.textTheme.headlineSmall)
              ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 7),
        Text(
          'Manage your sign-in details and keep your WorkBridge account secure.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.snapshot});
  final AccountSettingsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = snapshot.role.isEmpty
        ? 'Account'
        : '${snapshot.role[0].toUpperCase()}${snapshot.role.substring(1)}';
    final memberSince = snapshot.createdAt == null
        ? 'Not available'
        : _formatDate(snapshot.createdAt!);

    return _SectionCard(
      title: 'Account information',
      subtitle: 'Your sign-in identity and marketplace role.',
      icon: Icons.account_circle_outlined,
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email address',
            value: snapshot.email.isEmpty ? 'Not available' : snapshot.email,
          ),
          const Divider(height: 24),
          _InfoRow(icon: Icons.badge_outlined, label: 'Account type', value: role),
          const Divider(height: 24),
          _InfoRow(
            icon: Icons.calendar_month_outlined,
            label: 'Member since',
            value: memberSince,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.info),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Email changes are not available here yet. Contact support if you need to update your sign-in email.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.ink,
                      height: 1.4,
                    ),
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

class _PasswordCard extends StatelessWidget {
  const _PasswordCard({required this.controller, required this.wide});
  final AccountSettingsController controller;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Change password',
      subtitle: 'Confirm your current password before choosing a new one.',
      icon: Icons.lock_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => _PasswordField(
              controller: controller.currentPasswordController,
              label: 'Current password',
              obscure: controller.obscureCurrentPassword.value,
              onToggle: () => controller.obscureCurrentPassword.toggle(),
            ),
          ),
          const SizedBox(height: 14),
          if (wide)
            Row(
              children: [
                Expanded(child: _newPasswordField()),
                const SizedBox(width: 14),
                Expanded(child: _confirmPasswordField()),
              ],
            )
          else ...[
            _newPasswordField(),
            const SizedBox(height: 14),
            _confirmPasswordField(),
          ],
          const SizedBox(height: 10),
          Text(
            'Use at least 8 characters. A mix of letters and numbers is recommended.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          Obx(
            () => FilledButton.icon(
              onPressed: controller.isChangingPassword.value
                  ? null
                  : controller.changePassword,
              icon: controller.isChangingPassword.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                controller.isChangingPassword.value
                    ? 'Updating password...'
                    : 'Update password',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _newPasswordField() => Obx(
        () => _PasswordField(
          controller: controller.newPasswordController,
          label: 'New password',
          obscure: controller.obscureNewPassword.value,
          onToggle: () => controller.obscureNewPassword.toggle(),
        ),
      );

  Widget _confirmPasswordField() => Obx(
        () => _PasswordField(
          controller: controller.confirmPasswordController,
          label: 'Confirm new password',
          obscure: controller.obscureConfirmPassword.value,
          onToggle: () => controller.obscureConfirmPassword.toggle(),
        ),
      );
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.onSignOut});
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Session',
      subtitle: 'Sign out of WorkBridge on this device.',
      icon: Icons.devices_outlined,
      child: Row(
        children: [
          const Expanded(
            child: Text('You can sign in again with your email and password.'),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _DeletionCard extends StatelessWidget {
  const _DeletionCard({
    required this.request,
    required this.isSubmitting,
    required this.onRequest,
  });

  final AccountDeletionRequest? request;
  final RxBool isSubmitting;
  final Future<bool> Function(String reason) onRequest;

  @override
  Widget build(BuildContext context) {
    final active = request?.isActive == true;
    return _SectionCard(
      title: 'Delete account',
      subtitle: 'Request a review of your account deletion.',
      icon: Icons.delete_outline_rounded,
      danger: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Submitting a request does not immediately delete your account. Support must review the request and check any active projects, payment records and legal data-retention requirements.',
          ),
          if (request != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: active ? AppColors.warningSoft : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    active ? Icons.hourglass_top_rounded : Icons.info_outline,
                    color: active ? AppColors.warningInk : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Latest request: ${request!.readableStatus}${request!.requestedAt == null ? '' : ' • ${_formatDate(request!.requestedAt!)}'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Obx(
            () => OutlinedButton.icon(
              onPressed: active || isSubmitting.value
                  ? null
                  : () => _showDeletionDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              icon: isSubmitting.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_forever_outlined),
              label: Text(
                active ? 'Deletion request submitted' : 'Request account deletion',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeletionDialog(BuildContext context) async {
    final reasonController = TextEditingController();
    final confirmController = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request account deletion?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This sends a request to WorkBridge support. Your account will remain active until the request is reviewed and any required follow-up is completed.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'Tell us why you want to delete your account',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(
                  labelText: 'Type DELETE to confirm',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              if (confirmController.text.trim() != 'DELETE') {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Type DELETE exactly to confirm.')),
                );
                return;
              }
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Submit request'),
          ),
        ],
      ),
    );

    if (accepted == true) {
      await onRequest(reasonController.text);
    }
    reasonController.dispose();
    confirmController.dispose();
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.danger = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: danger
              ? AppColors.error.withValues(alpha: 0.28)
              : theme.colorScheme.outlineVariant,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: danger ? AppColors.errorSoft : AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: danger ? AppColors.error : AppColors.brand,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20),
        const SizedBox(width: 12),
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 42),
            const SizedBox(height: 12),
            Text(message.isEmpty ? 'Unable to load account settings.' : message),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
