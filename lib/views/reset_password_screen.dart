import 'package:flutter/material.dart';

import 'package:permit_plans/auths/auth_screen_components.dart';
import 'package:permit_plans/services/auth_service.dart';

/// Lets a user who followed a password-recovery email link choose a new
/// password. Pass [onSubmit] to save it through Supabase Auth.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    this.onSubmit,
    this.brandName = 'WorkBridge',
    super.key,
  });

  final Future<void> Function(String newPassword)? onSubmit;
  final String brandName;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final callback = widget.onSubmit;
    if (callback == null) {
      showAuthMessage(context, 'Connect onSubmit to Supabase Auth.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await callback(_passwordController.text);
    } catch (error) {
      if (mounted) {
        showAuthMessage(
          context,
          error is AuthServiceException
              ? error.message
              : 'Unable to update your password. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthResponsiveLayout(
      brandName: widget.brandName,
      eyebrow: 'ACCOUNT RECOVERY',
      heroTitle: 'A fresh start, in one step.',
      heroDescription:
          'Choose a new password and you will be right back to your projects.',
      formTitle: 'Set a new password',
      formDescription: 'Use at least 8 characters you have not used before.',
      form: _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthTextField(
              controller: _passwordController,
              label: 'New password',
              hint: 'Create a new password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Create a new password.';
                }
                if (value.length < 8) return 'Use at least 8 characters.';
                return null;
              },
            ),
            const SizedBox(height: 17),
            AuthTextField(
              controller: _confirmController,
              label: 'Confirm new password',
              hint: 'Enter the password again',
              prefixIcon: Icons.verified_user_outlined,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _submit(),
              suffixIcon: IconButton(
                tooltip: _obscureConfirm ? 'Show password' : 'Hide password',
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirm your new password.';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match.';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            AuthPrimaryButton(
              label: 'Update password',
              isLoading: _isSubmitting,
              onPressed: _submit,
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
