import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:permit_plans/constants/app_colors.dart';

class ProfileSetupLayout extends StatelessWidget {
  const ProfileSetupLayout({
    required this.roleLabel,
    required this.title,
    required this.description,
    required this.icon,
    required this.highlights,
    required this.form,
    super.key,
  });

  final String roleLabel;
  final String title;
  final String description;
  final IconData icon;
  final List<String> highlights;
  final Widget form;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 1000) {
              return Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: _ProfileBrandPanel(
                      roleLabel: roleLabel,
                      title: title,
                      description: description,
                      icon: icon,
                      highlights: highlights,
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 44,
                          vertical: 36,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: form,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                constraints.maxWidth < 380 ? 18 : 24,
                18,
                constraints.maxWidth < 380 ? 18 : 24,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MobileProfileHeader(
                        roleLabel: roleLabel,
                        title: title,
                        description: description,
                        icon: icon,
                      ),
                      const SizedBox(height: 24),
                      form,
                      const SizedBox(height: 12),
                      Text(
                        'Your information is stored securely and can be updated later.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
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
}

class _ProfileBrandPanel extends StatelessWidget {
  const _ProfileBrandPanel({
    required this.roleLabel,
    required this.title,
    required this.description,
    required this.icon,
    required this.highlights,
  });

  final String roleLabel;
  final String title;
  final String description;
  final IconData icon;
  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.all(18),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brandDark],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -110,
            top: -90,
            child: _GlowCircle(
              color: AppColors.papaya.withValues(alpha: .23),
              size: 330,
            ),
          ),
          Positioned(
            left: -125,
            bottom: -130,
            child: _GlowCircle(
              color: AppColors.saffron.withValues(alpha: .15),
              size: 360,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(42, 38, 42, 42),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .18),
                        ),
                      ),
                      child: const Icon(Icons.hub_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'WorkBridge',
                      style: text.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.4,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.papaya.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AppColors.papaya.withValues(alpha: .48),
                    ),
                  ),
                  child: Text(
                    roleLabel.toUpperCase(),
                    style: text.labelSmall?.copyWith(
                      color: const Color(0xFFFFC2AC),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  title,
                  style: text.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  description,
                  style: text.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: .78),
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 30),
                ...highlights.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.saffron,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item,
                            style: text.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: .9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(icon, color: AppColors.papaya, size: 19),
                    const SizedBox(width: 9),
                    Text(
                      'Built for better work, together.',
                      style: text.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: .72),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileProfileHeader extends StatelessWidget {
  const _MobileProfileHeader({
    required this.roleLabel,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String roleLabel;
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.hub_rounded, color: Colors.white),
            ),
            const SizedBox(width: 11),
            Text(
              'WorkBridge',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Icon(icon, color: AppColors.papaya, size: 25),
          ],
        ),
        const SizedBox(height: 30),
        Text(
          roleLabel.toUpperCase(),
          style: text.labelSmall?.copyWith(
            color: AppColors.papayaDark,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: text.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          description,
          style: text.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class ProfileFormCard extends StatelessWidget {
  const ProfileFormCard({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }
}

class ProfileAvatarPicker extends StatelessWidget {
  const ProfileAvatarPicker({
    required this.imageBytes,
    required this.onTap,
    this.size = 92,
    super.key,
  });

  final Uint8List? imageBytes;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size),
          child: Stack(
            children: [
              CircleAvatar(
                radius: size / 2,
                backgroundColor: AppColors.brandSoft,
                backgroundImage: imageBytes == null
                    ? null
                    : MemoryImage(imageBytes!),
                child: imageBytes == null
                    ? const Icon(
                        Icons.person_rounded,
                        size: 42,
                        color: AppColors.brand,
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    color: AppColors.papaya,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 17),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile photo',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Optional · JPG, PNG or WebP · up to 5 MB',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.upload_outlined, size: 17),
                label: const Text('Choose photo'),
                style: TextButton.styleFrom(foregroundColor: AppColors.brand),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileSectionTitle extends StatelessWidget {
  const ProfileSectionTitle({required this.title, this.subtitle, super.key});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: text.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class ProfilePrimaryButton extends StatelessWidget {
  const ProfilePrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label),
                  const SizedBox(width: 9),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
      ),
    );
  }
}

/// Decorative radial glow used by the desktop profile brand panel.
/// It is intentionally non-interactive and clipped by the parent panel.
class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
              stops: const [0, 1],
            ),
          ),
        ),
      ),
    );
  }
}
