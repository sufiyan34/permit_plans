import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/controllers/auth_controller.dart';
import 'package:permit_plans/controllers/engineer_profile_controller.dart';
import 'package:permit_plans/models/engineer_profile_model.dart';
import 'package:permit_plans/widgets/profile/profile_setup_components.dart';

class EngineerProfileSetupScreen extends StatefulWidget {
  const EngineerProfileSetupScreen({super.key});

  @override
  State<EngineerProfileSetupScreen> createState() => _EngineerProfileSetupScreenState();
}

class _EngineerProfileSetupScreenState extends State<EngineerProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _country = TextEditingController();
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final _years = TextEditingController(text: '1');
  final _skillInput = TextEditingController();
  final _languages = TextEditingController();
  final _portfolioLinks = TextEditingController();
  final _picker = ImagePicker();

  String _experienceLevel = 'intermediate';
  String _availability = 'available';
  final List<String> _skills = [];
  XFile? _avatarFile;
  Uint8List? _avatarBytes;
  bool _isPickingImage = false;

  EngineerProfileController get _controller => Get.find<EngineerProfileController>();

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
    _headline.dispose();
    _bio.dispose();
    _years.dispose();
    _skillInput.dispose();
    _languages.dispose();
    _portfolioLinks.dispose();
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

  void _addSkill() {
    final value = _skillInput.text.trim();
    if (value.isEmpty) return;
    if (_skills.any((skill) => skill.toLowerCase() == value.toLowerCase())) {
      _skillInput.clear();
      return;
    }
    if (_skills.length >= 15) {
      _showMessage('You can add up to 15 skills.');
      return;
    }
    setState(() => _skills.add(value));
    _skillInput.clear();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    _addSkillIfPresent();
    if (!_formKey.currentState!.validate()) return;
    if (_skills.isEmpty) {
      _showMessage('Add at least one technical skill.');
      return;
    }

    final years = int.tryParse(_years.text.trim()) ?? 0;
    final success = await _controller.save(
      EngineerProfileModel(
        fullName: _name.text.trim(),
        countryName: _country.text.trim(),
        headline: _headline.text.trim(),
        bio: _bio.text.trim(),
        experienceLevel: _experienceLevel,
        yearsExperience: years,
        availability: _availability,
        skills: List<String>.unmodifiable(_skills),
        languages: _splitList(_languages.text),
        portfolioLinks: _splitList(_portfolioLinks.text),
      ),
      avatar: _avatarFile,
    );

    if (!mounted) return;
    if (success) {
      Get.find<AuthController>().profileSetupCompleted();
      Get.snackbar(
        'Profile saved',
        'Your engineer workspace is ready.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _addSkillIfPresent() {
    final value = _skillInput.text.trim();
    if (value.isNotEmpty && !_skills.any((s) => s.toLowerCase() == value.toLowerCase()) && _skills.length < 15) {
      _skills.add(value);
      _skillInput.clear();
    }
  }

  List<String> _splitList(String value) => value
      .split(RegExp(r'[,\n]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();

  void _showMessage(String message) {
    if (!mounted) return;
    Get.snackbar('Engineer profile', message, snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSetupLayout(
      roleLabel: 'Engineer account',
      title: 'Show clients what you do best.',
      description: 'Build a profile that makes your strengths clear. Add your skills, experience and a short introduction so clients know why you are a great fit.',
      icon: Icons.code_rounded,
      highlights: const [
        'Choose the skills you want to be hired for.',
        'Keep your experience and availability up to date.',
        'A strong profile helps clients assess your fit.',
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
            Text('Your professional profile', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Complete the required details to start finding projects.',
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
              decoration: const InputDecoration(labelText: 'Country *', hintText: 'e.g. Canada', prefixIcon: Icon(Icons.public_outlined)),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter your country.' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _headline,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Professional headline *', hintText: 'e.g. Flutter Developer | Supabase Specialist', prefixIcon: Icon(Icons.work_outline)),
              validator: (value) => (value == null || value.trim().length < 5) ? 'Add a headline of at least 5 characters.' : null,
            ),
            const SizedBox(height: 10),
            const ProfileSectionTitle(title: 'Skills and experience', subtitle: 'Add the skills clients should be able to find you for.'),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _skillInput,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Add a skill', hintText: 'e.g. Flutter', prefixIcon: Icon(Icons.auto_awesome_outlined)),
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
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.papaya, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 17)),
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
                children: _skills.map((skill) => InputChip(
                  label: Text(skill),
                  onDeleted: () => setState(() => _skills.remove(skill)),
                  backgroundColor: AppColors.brandSoft,
                  side: BorderSide.none,
                  labelStyle: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700),
                )).toList(),
              )
            else
              Text('Add at least one skill to continue.', style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              value: _experienceLevel,
              decoration: const InputDecoration(labelText: 'Experience level *', prefixIcon: Icon(Icons.stars_outlined)),
              items: const [
                DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                DropdownMenuItem(value: 'expert', child: Text('Expert')),
              ],
              onChanged: (value) => setState(() => _experienceLevel = value ?? 'intermediate'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _years,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Years of experience', hintText: 'e.g. 3', prefixIcon: Icon(Icons.timeline_rounded)),
              validator: (value) {
                final number = int.tryParse((value ?? '').trim());
                if (number == null || number < 0 || number > 60) return 'Enter a number from 0 to 60.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _availability,
              decoration: const InputDecoration(labelText: 'Availability', prefixIcon: Icon(Icons.event_available_outlined)),
              items: const [
                DropdownMenuItem(value: 'available', child: Text('Available for work')),
                DropdownMenuItem(value: 'limited', child: Text('Limited availability')),
                DropdownMenuItem(value: 'unavailable', child: Text('Not available right now')),
              ],
              onChanged: (value) => setState(() => _availability = value ?? 'available'),
            ),
            const SizedBox(height: 26),
            const ProfileSectionTitle(title: 'About and portfolio', subtitle: 'Help clients understand your work and background.'),
            const SizedBox(height: 14),
            TextFormField(
              controller: _bio,
              minLines: 4,
              maxLines: 7,
              maxLength: 1200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Professional bio *', hintText: 'Describe your experience, strengths and the type of projects you enjoy.'),
              validator: (value) => (value == null || value.trim().length < 30) ? 'Write at least 30 characters about your experience.' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _languages,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Languages (optional)', hintText: 'English, Urdu, German'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _portfolioLinks,
              minLines: 2,
              maxLines: 4,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Portfolio links (optional)', hintText: 'Add links separated by commas or new lines.'),
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
              'You can update your professional profile later.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
