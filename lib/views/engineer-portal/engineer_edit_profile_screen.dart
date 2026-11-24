import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/controllers/auth_controller.dart';
import 'package:permit_plans/controllers/engineer_dashboard_controller.dart';
import 'package:permit_plans/controllers/engineer_edit_profile_controller.dart';
import 'package:permit_plans/models/engineer_profile_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

class EngineerEditProfileScreen extends StatefulWidget {
  const EngineerEditProfileScreen({super.key});

  @override
  State<EngineerEditProfileScreen> createState() =>
      _EngineerEditProfileScreenState();
}

class _EngineerEditProfileScreenState extends State<EngineerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _country = TextEditingController();
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final _years = TextEditingController();
  final _skillInput = TextEditingController();
  final _languages = TextEditingController();
  final _portfolioLinks = TextEditingController();
  final _picker = ImagePicker();

  late final EngineerEditProfileController _controller;
  Worker? _profileWorker;
  String _experienceLevel = 'intermediate';
  String _availability = 'available';
  String? _avatarUrl;
  XFile? _avatarFile;
  Uint8List? _avatarBytes;
  List<String> _skills = <String>[];
  bool _formLoaded = false;
  bool _isPickingAvatar = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<EngineerEditProfileController>();
    _profileWorker = ever<EngineerProfileModel?>(
      _controller.profile,
      (profile) {
        if (profile != null) _populateForm(profile);
      },
    );
    final existing = _controller.profile.value;
    if (existing != null) _populateForm(existing);
  }

  void _populateForm(EngineerProfileModel profile) {
    if (!mounted) return;
    _name.text = profile.fullName;
    _country.text = profile.countryName;
    _headline.text = profile.headline;
    _bio.text = profile.bio;
    _years.text = profile.yearsExperience.toString();
    _languages.text = profile.languages.join(', ');
    _portfolioLinks.text = profile.portfolioLinks.join('\n');
    setState(() {
      _experienceLevel = profile.experienceLevel;
      _availability = profile.availability;
      _skills = List<String>.from(profile.skills);
      _avatarUrl = profile.avatarUrl;
      _avatarFile = null;
      _avatarBytes = null;
      _formLoaded = true;
    });
  }

  @override
  void dispose() {
    _profileWorker?.dispose();
    _name.dispose();
    _country.dispose();
    _headline.dispose();
    _bio.dispose();
    _years.dispose();
    _skillInput.dispose();
    _languages.dispose();
    _portfolioLinks.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    if (_isPickingAvatar) return;
    setState(() => _isPickingAvatar = true);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 86,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        _showMessage('Choose an image smaller than 5 MB.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _avatarFile = file;
        _avatarBytes = bytes;
      });
    } catch (_) {
      _showMessage('Could not open your photo library. Please try again.');
    } finally {
      if (mounted) setState(() => _isPickingAvatar = false);
    }
  }

  void _addSkill() {
    final value = _skillInput.text.trim();
    if (value.isEmpty) return;
    if (_skills.any((item) => item.toLowerCase() == value.toLowerCase())) {
      _skillInput.clear();
      return;
    }
    if (_skills.length >= 15) {
      _showMessage('You can add up to 15 skills.');
      return;
    }
    setState(() {
      _skills.add(value);
      _skillInput.clear();
    });
  }

  List<String> _splitList(String value) => value
      .split(RegExp(r'[,\n]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();

  String? _validatePortfolioLinks(String? value) {
    final links = _splitList(value ?? '');
    for (final link in links) {
      final uri = Uri.tryParse(link);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        return 'Use complete links, including https://.';
      }
    }
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    _addSkill();
    if (_skills.isEmpty) {
      _showMessage('Add at least one professional skill.');
      return;
    }

    final current = _controller.profile.value;
    final updated = EngineerProfileModel(
      fullName: _name.text.trim(),
      countryName: _country.text.trim(),
      headline: _headline.text.trim(),
      bio: _bio.text.trim(),
      experienceLevel: _experienceLevel,
      yearsExperience: int.tryParse(_years.text.trim()) ?? 0,
      availability: _availability,
      skills: List<String>.unmodifiable(_skills),
      languages: _splitList(_languages.text),
      portfolioLinks: _splitList(_portfolioLinks.text),
      avatarUrl: _avatarUrl ?? current?.avatarUrl,
    );

    final saved = await _controller.save(updated, avatar: _avatarFile);
    if (!mounted) return;
    if (saved) {
      _avatarFile = null;
      _avatarBytes = null;
      _avatarUrl = _controller.profile.value?.avatarUrl;
      if (Get.isRegistered<EngineerDashboardController>()) {
        await Get.find<EngineerDashboardController>().loadProfile(refresh: true);
      }
      Get.snackbar(
        'Profile updated',
        'Your professional profile changes have been saved.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.successSoft,
        colorText: AppColors.ink,
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    Get.snackbar(
      'Engineer profile',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = Get.find<AuthController>().currentUser.value?.email ?? '';

    return AppShell(
      title: 'Edit engineer profile',
      currentIndex: 0,
      destinations: const [
        ShellDestination(
          icon: Icons.grid_view_outlined,
          selectedIcon: Icons.grid_view_rounded,
          label: 'Overview',
          route: AppRoutes.engineerHome,
        ),
        ShellDestination(
          icon: Icons.search_rounded,
          label: 'Invitations',
          route: AppRoutes.engineerInvitations,
        ),
        ShellDestination(
          icon: Icons.assignment_outlined,
          label: 'Negotiations',
          route: AppRoutes.engineerNegotiations,
        ),
        ShellDestination(
          icon: Icons.folder_open_outlined,
          selectedIcon: Icons.folder_rounded,
          label: 'Projects',
          route: AppRoutes.engineerProjects,
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
          icon: Icons.rate_review_outlined,
          label: 'Revision requests',
          route: AppRoutes.engineerRevisionRequests,
        ),
        SidebarItem(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Earnings',
          route: AppRoutes.engineerEarnings,
        ),
        SidebarItem(
          icon: Icons.payments_outlined,
          label: 'Payout management',
          route: AppRoutes.engineerPayoutManagement,
        ),
        SidebarItem(
          icon: Icons.person_outline_rounded,
          label: 'My profile',
          route: AppRoutes.engineerEditProfile,
        ),
        SidebarItem(icon: Icons.settings_outlined, label: 'Settings'),
        SidebarItem(icon: Icons.help_outline_rounded, label: 'Help & support'),
      ],
      body: Obx(() {
        if (_controller.isLoading.value && !_formLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_controller.errorMessage.value.isNotEmpty && !_formLoaded) {
          return _LoadError(
            message: _controller.errorMessage.value,
            onRetry: _controller.loadProfile,
          );
        }
        if (!_formLoaded) return const Center(child: CircularProgressIndicator());

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 920;
            final horizontal = wide ? 34.0 : 18.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontal, 26, horizontal, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PageHeading(onCancel: () => Get.back<void>()),
                      const SizedBox(height: 22),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 285,
                              child: _ProfilePhotoCard(
                                fullName: _name.text,
                                email: email,
                                avatarUrl: _avatarUrl,
                                avatarBytes: _avatarBytes,
                                isPicking: _isPickingAvatar,
                                onPick: _pickAvatar,
                              ),
                            ),
                            const SizedBox(width: 22),
                            Expanded(child: _formCard()),
                          ],
                        )
                      else ...[
                        _ProfilePhotoCard(
                          fullName: _name.text,
                          email: email,
                          avatarUrl: _avatarUrl,
                          avatarBytes: _avatarBytes,
                          isPicking: _isPickingAvatar,
                          onPick: _pickAvatar,
                        ),
                        const SizedBox(height: 18),
                        _formCard(),
                      ],
                      const SizedBox(height: 18),
                      _SecurityNote(email: email),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _formCard() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: AppColors.cardShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Professional information',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Keep your skills and experience accurate so clients can understand what you offer.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            const _SectionLabel(title: 'Basic details'),
            const SizedBox(height: 13),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full name *',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => value == null || value.trim().length < 2
                  ? 'Enter your full name.'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _country,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Country *',
                prefixIcon: Icon(Icons.public_rounded),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your country.'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _headline,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Professional headline *',
                hintText: 'e.g. Flutter Developer | Supabase Specialist',
                prefixIcon: Icon(Icons.work_outline_rounded),
              ),
              validator: (value) => value == null || value.trim().length < 5
                  ? 'Add a headline of at least 5 characters.'
                  : null,
            ),
            const SizedBox(height: 10),
            const _SectionLabel(
              title: 'Skills and experience',
              subtitle: 'Add the skills clients should be able to find you for.',
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _skillInput,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Add a skill',
                      hintText: 'e.g. Flutter',
                      prefixIcon: Icon(Icons.auto_awesome_outlined),
                    ),
                    onSubmitted: (_) => _addSkill(),
                  ),
                ),
                const SizedBox(width: 9),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _addSkill,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.papaya,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 17),
                      ),
                      child: const Icon(Icons.add_rounded),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_skills.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _skills
                    .map(
                      (skill) => InputChip(
                        label: Text(skill),
                        onDeleted: () => setState(() => _skills.remove(skill)),
                        backgroundColor: AppColors.brandSoft,
                        side: BorderSide.none,
                        labelStyle: const TextStyle(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                    .toList(),
              )
            else
              Text(
                'Add at least one technical skill.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              value: _experienceLevel,
              decoration: const InputDecoration(
                labelText: 'Experience level *',
                prefixIcon: Icon(Icons.workspace_premium_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                DropdownMenuItem(
                  value: 'intermediate',
                  child: Text('Intermediate'),
                ),
                DropdownMenuItem(value: 'expert', child: Text('Expert')),
              ],
              onChanged: (value) => setState(
                () => _experienceLevel = value ?? 'intermediate',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _years,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Years of experience',
                prefixIcon: Icon(Icons.timeline_rounded),
              ),
              validator: (value) {
                final number = int.tryParse((value ?? '').trim());
                if (number == null || number < 0 || number > 60) {
                  return 'Enter a number from 0 to 60.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _availability,
              decoration: const InputDecoration(
                labelText: 'Availability',
                prefixIcon: Icon(Icons.event_available_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'available',
                  child: Text('Available for work'),
                ),
                DropdownMenuItem(
                  value: 'limited',
                  child: Text('Limited availability'),
                ),
                DropdownMenuItem(
                  value: 'unavailable',
                  child: Text('Not available right now'),
                ),
              ],
              onChanged: (value) => setState(
                () => _availability = value ?? 'available',
              ),
            ),
            const SizedBox(height: 25),
            const _SectionLabel(
              title: 'About and portfolio',
              subtitle: 'Help clients understand your work and background.',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _bio,
              minLines: 4,
              maxLines: 7,
              maxLength: 1200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Professional bio *',
                hintText:
                    'Describe your experience, strengths and the projects you enjoy.',
              ),
              validator: (value) => value == null || value.trim().length < 30
                  ? 'Write at least 30 characters about your experience.'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _languages,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Languages (optional)',
                hintText: 'English, Urdu, German',
                prefixIcon: Icon(Icons.translate_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _portfolioLinks,
              minLines: 2,
              maxLines: 4,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Portfolio links (optional)',
                hintText: 'https://portfolio.example.com',
                prefixIcon: Icon(Icons.link_rounded),
              ),
              validator: _validatePortfolioLinks,
            ),
            Obx(() {
              final error = _controller.errorMessage.value;
              if (error.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  error,
                  style: const TextStyle(color: AppColors.error),
                ),
              );
            }),
            const SizedBox(height: 20),
            Obx(
              () => SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _controller.isSaving.value ? null : _save,
                  icon: _controller.isSaving.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _controller.isSaving.value
                        ? 'Saving changes...'
                        : 'Save changes',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.onCancel});
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.manage_accounts_outlined,
            color: AppColors.brand,
            size: 25,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit your professional profile',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Update the information clients see when they discover you.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onCancel,
          icon: const Icon(Icons.close_rounded, size: 17),
          label: const Text('Close'),
        ),
      ],
    );
  }
}

class _ProfilePhotoCard extends StatelessWidget {
  const _ProfilePhotoCard({
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    required this.avatarBytes,
    required this.isPicking,
    required this.onPick,
  });

  final String fullName;
  final String email;
  final String? avatarUrl;
  final Uint8List? avatarBytes;
  final bool isPicking;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmed = fullName.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();

    Widget avatar;
    if (avatarBytes != null) {
      avatar = Image.memory(avatarBytes!, fit: BoxFit.cover);
    } else if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      avatar = Image.network(
        avatarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _AvatarFallback(initial: initial),
      );
    } else {
      avatar = _AvatarFallback(initial: initial);
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Profile photo',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ClipOval(
            child: SizedBox(width: 112, height: 112, child: avatar),
          ),
          const SizedBox(height: 14),
          Text(
            trimmed.isEmpty ? 'Your name' : trimmed,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isPicking ? null : onPick,
              icon: isPicking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(isPicking ? 'Opening photos...' : 'Change photo'),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'JPG, PNG or WebP · Up to 5 MB',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.brandSoft,
        alignment: Alignment.center,
        child: Text(
          initial,
          style: const TextStyle(
            color: AppColors.brand,
            fontSize: 40,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.brand,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      );
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.info.withValues(alpha: .16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded, color: AppColors.info),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Your sign-in email${email.isEmpty ? '' : ' ($email)'} is managed by account security settings and cannot be changed here. Profile edits are saved to your own Engineer account.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.info,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 42,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
}
