import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/auths/auth_screen_components.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/services/auth_service.dart';

/// Responsive registration screen for new Client or Engineer accounts.
///
/// Pass [onSignUp] to connect the form to Supabase Auth and profile creation.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    this.onSignUp,
    this.onSignIn,
    this.initialRole = MarketplaceAccountRole.client,
    this.showRoleSelection = true,
    this.brandName = 'WorkBridge',
    super.key,
  });

  final Future<void> Function(SignUpFormData data)? onSignUp;
  final VoidCallback? onSignIn;
  final MarketplaceAccountRole initialRole;
  final bool showRoleSelection;
  final String brandName;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late MarketplaceAccountRole _selectedRole;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      showAuthMessage(
        context,
        'Please accept the Terms of Service to continue.',
      );
      return;
    }

    final callback = widget.onSignUp;
    if (callback == null) {
      showAuthMessage(
        context,
        'Sign-up UI is ready. Connect onSignUp to Supabase Auth.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await callback(
        SignUpFormData(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
        ),
      );
    } catch (error) {
      if (mounted) {
        showAuthMessage(
          context,
          error is AuthServiceException
              ? error.message
              : 'Unable to create your account. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _openSignIn() {
    if (widget.onSignIn != null) {
      widget.onSignIn!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return AuthResponsiveLayout(
      brandName: widget.brandName,
      eyebrow: 'MAKE YOUR NEXT MOVE',
      heroTitle: 'A good connection can change everything.',
      heroDescription: 'Join a community where clients find thoughtful talent and engineers find projects worth doing.',
      formTitle: 'Create your account',
      formDescription: 'A few details to get your WorkBridge journey started.',
      form: _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showRoleSelection) ...[
              _RoleSelector(
                selectedRole: _selectedRole,
                onChanged: (role) => setState(() => _selectedRole = role),
              ),
              const SizedBox(height: 22),
            ],
            AuthTextField(
              controller: _nameController,
              label: 'Full name',
              hint: 'Enter your full name',
              prefixIcon: Icons.person_outline_rounded,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                final name = value?.trim() ?? '';
                if (name.isEmpty) return 'Please enter your name.';
                if (name.length < 2)
                  return 'Name must contain at least 2 characters.';
                return null;
              },
            ),
            const SizedBox(height: 17),
            AuthTextField(
              controller: _emailController,
              label: 'Email address',
              hint: 'you@example.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Please enter your email address.';
                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                  return 'Enter a valid email address.';
                }
                return null;
              },
            ),
            const SizedBox(height: 17),
            AuthTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Create a password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: () => setState(() {
                  _obscurePassword = !_obscurePassword;
                }),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Create a password.';
                if (value.length < 8) return 'Use at least 8 characters.';
                return null;
              },
            ),
            const SizedBox(height: 17),
            AuthTextField(
              controller: _confirmPasswordController,
              label: 'Confirm password',
              hint: 'Enter your password again',
              prefixIcon: Icons.verified_user_outlined,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _submit(),
              suffixIcon: IconButton(
                tooltip: _obscureConfirmPassword
                    ? 'Show password'
                    : 'Hide password',
                onPressed: () => setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                }),
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Confirm your password.';
                if (value != _passwordController.text)
                  return 'Passwords do not match.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox.adaptive(
                  value: _acceptedTerms,
                  onChanged: (value) =>
                      setState(() => _acceptedTerms = value ?? false),
                  activeColor: AppColors.brand,
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 3,
                      runSpacing: 1,
                      children: [
                        Text(
                          'I agree to the',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        InkWell(
                          onTap: () => Get.toNamed<void>(
                            AppRoutes.legalPoliciesFor('terms'),
                          ),
                          child: Text(
                            'Terms & Conditions',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          'and',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        InkWell(
                          onTap: () => Get.toNamed<void>(
                            AppRoutes.legalPoliciesFor('privacy'),
                          ),
                          child: Text(
                            'Privacy Policy',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          '.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            AuthPrimaryButton(
              label: 'Create account',
              isLoading: _isSubmitting,
              onPressed: _submit,
              icon: Icons.arrow_forward_rounded,
            ),
            const SizedBox(height: 22),
            AuthSwitchPrompt(
              prompt: 'Already have an account?',
              actionLabel: 'Sign in',
              onPressed: _openSignIn,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.selectedRole, required this.onChanged});

  final MarketplaceAccountRole selectedRole;
  final ValueChanged<MarketplaceAccountRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I want to join as',
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _RoleCard(
                title: 'Client',
                subtitle: 'Hire talent',
                icon: Icons.business_center_outlined,
                isSelected: selectedRole == MarketplaceAccountRole.client,
                onTap: () => onChanged(MarketplaceAccountRole.client),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RoleCard(
                title: 'Engineer',
                subtitle: 'Find projects',
                icon: Icons.code_rounded,
                isSelected: selectedRole == MarketplaceAccountRole.engineer,
                onTap: () => onChanged(MarketplaceAccountRole.engineer),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppColors.brand : AppColors.outlineVariant;
    final background = isSelected ? AppColors.brandSoft : AppColors.surface;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brand : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.papayaDark,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
