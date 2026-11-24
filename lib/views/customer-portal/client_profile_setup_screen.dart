import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/controllers/auth_controller.dart';
import 'package:permit_plans/controllers/client_profile_controller.dart';
import 'package:permit_plans/models/client_profile_model.dart';
import 'package:permit_plans/widgets/profile/profile_setup_components.dart';

class ClientProfileSetupScreen extends StatefulWidget {
  const ClientProfileSetupScreen({super.key});

  @override
  State<ClientProfileSetupScreen> createState() => _ClientProfileSetupScreenState();
}

class _ClientProfileSetupScreenState extends State<ClientProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _country = TextEditingController();
  final _phone = TextEditingController();
  final _companyName = TextEditingController();
  final _website = TextEditingController();
  final _about = TextEditingController();
  final _picker = ImagePicker();

  String _accountType = 'individual';
  XFile? _avatarFile;
  Uint8List? _avatarBytes;
  bool _isPickingImage = false;

  ClientProfileController get _controller => Get.find<ClientProfileController>();

  @override
  void initState() {
    super.initState();
    final user = Get.find<AuthController>().currentUser.value;
    _name.text = (user?.userMetadata?['full_name'] as String?) ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _country.dispose();
    _phone.dispose();
    _companyName.dispose();
    _website.dispose();
    _about.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 86,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) {
          _showMessage('Choose an image smaller than 5 MB.');
        } else if (mounted) {
          setState(() {
            _avatarFile = file;
            _avatarBytes = bytes;
          });
        }
      }
    } catch (_) {
      _showMessage('Could not open your photo library. Please try again.');
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await _controller.save(
      ClientProfileModel(
        fullName: _name.text.trim(),
        countryName: _country.text.trim(),
        accountType: _accountType,
        phoneNumber: _phone.text.trim(),
        companyName: _companyName.text.trim(),
        companyWebsite: _website.text.trim(),
        about: _about.text.trim(),
      ),
      avatar: _avatarFile,
    );

    if (!mounted) return;
    if (success) {
      Get.find<AuthController>().profileSetupCompleted();
      Get.snackbar(
        'Profile saved',
        'Your client workspace is ready.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    Get.snackbar('Profile photo', message, snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSetupLayout(
      roleLabel: 'Client account',
      title: 'Let’s set up your workspace.',
      description: 'Tell engineers a little about who you are and the kind of work you need done. You can update these details any time.',
      icon: Icons.business_center_outlined,
      highlights: const [
        'A clear profile builds trust with engineers.',
        'Company details are optional for individuals.',
        'Your profile is saved securely to your account.',
      ],
      form: _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ProfileFormCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Your client profile', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Complete the required details to continue.',
              style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 25),
            ProfileAvatarPicker(imageBytes: _avatarBytes, onTap: _pickAvatar),
            const SizedBox(height: 28),
            const ProfileSectionTitle(title: 'Basic information'),
            const SizedBox(height: 14),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name *', hintText: 'e.g. Alex Morgan', prefixIcon: Icon(Icons.person_outline)),
              validator: (value) => (value == null || value.trim().length < 2) ? 'Enter your full name.' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _country,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Country *', hintText: 'e.g. United Kingdom', prefixIcon: Icon(Icons.public_outlined)),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter your country.' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number (optional)', hintText: '+1 555 000 0000', prefixIcon: Icon(Icons.phone_outlined)),
            ),
            const SizedBox(height: 26),
            const ProfileSectionTitle(title: 'Account type', subtitle: 'Choose whether you are hiring as an individual or a company.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _AccountTypeChoice(
                  selected: _accountType == 'individual',
                  icon: Icons.person_outline,
                  label: 'Individual',
                  onTap: () => setState(() => _accountType = 'individual'),
                ),
                _AccountTypeChoice(
                  selected: _accountType == 'company',
                  icon: Icons.domain_outlined,
                  label: 'Company',
                  onTap: () => setState(() => _accountType = 'company'),
                ),
              ],
            ),
            if (_accountType == 'company') ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _companyName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Company name *', hintText: 'Your registered or trading name', prefixIcon: Icon(Icons.apartment_outlined)),
                validator: (value) => _accountType == 'company' && (value == null || value.trim().isEmpty) ? 'Enter your company name.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _website,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'Company website (optional)', hintText: 'https://example.com', prefixIcon: Icon(Icons.link_rounded)),
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _about,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'About you (optional)', hintText: 'What kind of projects do you usually work on?'),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final error = _controller.errorMessage.value;
              if (error.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.errorSoft, borderRadius: BorderRadius.circular(12)),
                child: Text(error, style: const TextStyle(color: AppColors.error)),
              );
            }),
            Obx(() => ProfilePrimaryButton(
                  label: 'Save and continue',
                  isLoading: _controller.isSaving.value,
                  onPressed: _save,
                )),
            const SizedBox(height: 12),
            Text(
              'You can edit your profile later from Settings.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTypeChoice extends StatelessWidget {
  const _AccountTypeChoice({required this.selected, required this.icon, required this.label, required this.onTap});
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandSoft : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.brand : Theme.of(context).colorScheme.outlineVariant, width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: selected ? AppColors.brand : Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? AppColors.brand : Theme.of(context).colorScheme.onSurface)),
            if (selected) ...[
              const SizedBox(width: 7),
              const Icon(Icons.check_circle_rounded, size: 17, color: AppColors.brand),
            ],
          ],
        ),
      ),
    );
  }
}
