import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/controllers/auth_controller.dart';
import 'package:permit_plans/controllers/client_edit_profile_controller.dart';
import 'package:permit_plans/controllers/client_dashboard_controller.dart';
import 'package:permit_plans/models/client_profile_model.dart';
import 'package:permit_plans/widgets/app_shell.dart';
import 'package:permit_plans/widgets/app_sidebar.dart';

class ClientEditProfileScreen extends StatefulWidget {
  const ClientEditProfileScreen({super.key});

  @override
  State<ClientEditProfileScreen> createState() => _ClientEditProfileScreenState();
}

class _ClientEditProfileScreenState extends State<ClientEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _country = TextEditingController();
  final _phone = TextEditingController();
  final _companyName = TextEditingController();
  final _website = TextEditingController();
  final _about = TextEditingController();
  final _picker = ImagePicker();

  late final ClientEditProfileController _controller;
  Worker? _profileWorker;
  String _accountType = 'individual';
  String? _avatarUrl;
  XFile? _avatarFile;
  Uint8List? _avatarBytes;
  bool _formLoaded = false;
  bool _isPickingAvatar = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ClientEditProfileController>();
    _profileWorker = ever<ClientProfileModel?>(_controller.profile, (profile) {
      if (profile != null) _populateForm(profile);
    });
    final existing = _controller.profile.value;
    if (existing != null) _populateForm(existing);
  }

  void _populateForm(ClientProfileModel profile) {
    if (!mounted) return;
    _name.text = profile.fullName;
    _country.text = profile.countryName;
    _phone.text = profile.phoneNumber ?? '';
    _companyName.text = profile.companyName ?? '';
    _website.text = profile.companyWebsite ?? '';
    _about.text = profile.about ?? '';
    setState(() {
      _accountType = profile.accountType;
      _avatarUrl = profile.avatarUrl;
      _formLoaded = true;
      _avatarFile = null;
      _avatarBytes = null;
    });
  }

  @override
  void dispose() {
    _profileWorker?.dispose();
    _name.dispose();
    _country.dispose();
    _phone.dispose();
    _companyName.dispose();
    _website.dispose();
    _about.dispose();
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

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final current = _controller.profile.value;
    final updated = ClientProfileModel(
      fullName: _name.text.trim(),
      countryName: _country.text.trim(),
      accountType: _accountType,
      phoneNumber: _phone.text.trim(),
      companyName: _accountType == 'company' ? _companyName.text.trim() : null,
      companyWebsite: _accountType == 'company' ? _website.text.trim() : null,
      about: _about.text.trim(),
      avatarUrl: _avatarUrl ?? current?.avatarUrl,
    );

    final saved = await _controller.save(updated, avatar: _avatarFile);
    if (!mounted) return;
    if (saved) {
      _avatarFile = null;
      _avatarBytes = null;
      _avatarUrl = _controller.profile.value?.avatarUrl;
      if (Get.isRegistered<ClientDashboardController>()) {
        Get.find<ClientDashboardController>().loadProfile();
      }
      Get.snackbar(
        'Profile updated',
        'Your client profile changes have been saved.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.successSoft,
        colorText: AppColors.ink,
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    Get.snackbar('Profile photo', message, snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    final email = Get.find<AuthController>().currentUser.value?.email ?? '';

    return AppShell(
      title: 'Edit client profile',
      currentIndex: 0,
      destinations: const [
        ShellDestination(icon: Icons.grid_view_outlined, selectedIcon: Icons.grid_view_rounded, label: 'Overview', route: AppRoutes.clientHome),
        ShellDestination(icon: Icons.folder_open_outlined, selectedIcon: Icons.folder_rounded, label: 'Quotes', route: AppRoutes.clientQuotes),
        ShellDestination(icon: Icons.fact_check_outlined, selectedIcon: Icons.fact_check_rounded, label: 'Deliveries', route: AppRoutes.clientDeliveryReviews),
        ShellDestination(icon: Icons.search_rounded, label: 'Find engineers', route: AppRoutes.clientBrowseEngineers),
        ShellDestination(icon: Icons.chat_bubble_outline_rounded, selectedIcon: Icons.chat_bubble_rounded, label: 'Messages', route: AppRoutes.projectChats),
      ],
      sidebarItems: const [
        SidebarItem(icon: Icons.fact_check_outlined, label: 'Delivery reviews', route: AppRoutes.clientDeliveryReviews),
        SidebarItem(icon: Icons.verified_outlined, label: 'Final approved files', route: AppRoutes.clientFinalApproval),
        SidebarItem(icon: Icons.person_outline_rounded, label: 'My profile', route: AppRoutes.clientEditProfile),
        SidebarItem(icon: Icons.help_outline_rounded, label: 'Help & support'),
        SidebarItem(icon: Icons.settings_outlined, label: 'Settings'),
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
            final wide = constraints.maxWidth >= 900;
            final horizontal = wide ? 34.0 : 18.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontal, 26, horizontal, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
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
                              width: 280,
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
      decoration: _cardDecoration(theme),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Personal information', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text('Keep your hiring profile accurate so engineers know who they are working with.', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 22),
            _SectionLabel(title: 'Basic details'),
            const SizedBox(height: 13),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name *', prefixIcon: Icon(Icons.person_outline_rounded)),
              validator: (value) => value == null || value.trim().length < 2 ? 'Enter your full name.' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _country,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Country *', prefixIcon: Icon(Icons.public_rounded)),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter your country.' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number (optional)', prefixIcon: Icon(Icons.phone_outlined)),
            ),
            const SizedBox(height: 23),
            _SectionLabel(title: 'Hiring as'),
            const SizedBox(height: 7),
            Text('Choose how your client account is presented.', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _AccountTypeChip(
                  label: 'Individual',
                  icon: Icons.person_outline_rounded,
                  selected: _accountType == 'individual',
                  onTap: () => setState(() => _accountType = 'individual'),
                ),
                _AccountTypeChip(
                  label: 'Company',
                  icon: Icons.apartment_rounded,
                  selected: _accountType == 'company',
                  onTap: () => setState(() => _accountType = 'company'),
                ),
              ],
            ),
            if (_accountType == 'company') ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _companyName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Company name *', prefixIcon: Icon(Icons.business_outlined)),
                validator: (value) => _accountType == 'company' && (value == null || value.trim().isEmpty) ? 'Enter your company name.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _website,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'Company website (optional)', hintText: 'https://example.com', prefixIcon: Icon(Icons.link_rounded)),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final uri = Uri.tryParse(text);
                  return uri == null || !uri.hasScheme || uri.host.isEmpty ? 'Enter a valid website including https://.' : null;
                },
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _about,
              minLines: 4,
              maxLines: 6,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'About you (optional)', hintText: 'Tell engineers about your business, goals or the type of projects you usually hire for.'),
            ),
            Obx(() {
              final error = _controller.errorMessage.value;
              if (error.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.errorSoft, borderRadius: BorderRadius.circular(12)),
                child: Text(error, style: const TextStyle(color: AppColors.error)),
              );
            }),
            const SizedBox(height: 20),
            Obx(() => SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _controller.isSaving.value ? null : _save,
                icon: _controller.isSaving.value
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined),
                label: Text(_controller.isSaving.value ? 'Saving changes...' : 'Save changes'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            )),
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
          decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(15)),
          child: const Icon(Icons.manage_accounts_outlined, color: AppColors.brand, size: 25),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit your profile', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              Text('Update the details shown to engineers.', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        OutlinedButton.icon(onPressed: onCancel, icon: const Icon(Icons.close_rounded, size: 17), label: const Text('Close')),
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
    final initial = fullName.trim().isEmpty ? '?' : fullName.trim()[0].toUpperCase();
    Widget avatar;
    if (avatarBytes != null) {
      avatar = Image.memory(avatarBytes!, fit: BoxFit.cover);
    } else if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      avatar = Image.network(avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _AvatarFallback(initial: initial));
    } else {
      avatar = _AvatarFallback(initial: initial);
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(alignment: Alignment.centerLeft, child: Text('Profile photo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
          const SizedBox(height: 20),
          ClipOval(
            child: SizedBox(width: 112, height: 112, child: avatar),
          ),
          const SizedBox(height: 14),
          Text(fullName.isEmpty ? 'Your name' : fullName, textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(email, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isPicking ? null : onPick,
              icon: isPicking ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(isPicking ? 'Opening photos...' : 'Change photo'),
            ),
          ),
          const SizedBox(height: 9),
          Text('JPG, PNG or WebP · Up to 5 MB', textAlign: TextAlign.center, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textTertiary)),
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
    child: Text(initial, style: const TextStyle(color: AppColors.brand, fontSize: 40, fontWeight: FontWeight.w800)),
  );
}

class _AccountTypeChip extends StatelessWidget {
  const _AccountTypeChip({required this.label, required this.icon, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(icon, size: 18, color: selected ? AppColors.brand : AppColors.textSecondary),
      label: Text(label),
      selectedColor: AppColors.brandSoft,
      side: BorderSide(color: selected ? AppColors.brand : AppColors.outlineVariant),
      labelStyle: TextStyle(color: selected ? AppColors.brand : AppColors.ink, fontWeight: FontWeight.w700),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.brand),
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
      decoration: BoxDecoration(color: AppColors.infoSoft, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.info.withValues(alpha: .16))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded, color: AppColors.info),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Your sign-in email${email.isEmpty ? '' : ' ($email)'} is managed by your account security settings and cannot be changed on this page. Profile changes are saved to your own WorkBridge account.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.info, height: 1.45),
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
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 42, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
          ],
        ),
      ),
    ),
  );
}

BoxDecoration _cardDecoration(ThemeData theme) => BoxDecoration(
  color: theme.colorScheme.surface,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: theme.colorScheme.outlineVariant),
  boxShadow: AppColors.cardShadow,
);
