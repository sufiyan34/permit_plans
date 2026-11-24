import 'package:flutter/material.dart';
import 'package:permit_plans/auths/auth_screen_components.dart';
import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/services/auth_service.dart';
import 'package:permit_plans/views/signup_screen.dart';

/// Responsive login screen for Client and Engineer accounts.
///
/// Authentication is intentionally supplied through [onLogin] so the screen
/// can be connected to Supabase Auth without coupling UI to backend code.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    this.onLogin,
    this.onForgotPassword,
    this.onCreateAccount,
    this.brandName = 'WorkBridge',
    super.key,
  });

  final Future<void> Function(String email, String password)? onLogin;
  final ValueChanged<String>? onForgotPassword;
  final VoidCallback? onCreateAccount;
  final String brandName;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final callback = widget.onLogin;
    if (callback == null) {
      showAuthMessage(
        context,
        'Login UI is ready. Connect onLogin to your Supabase Auth service.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await callback(_emailController.text.trim(), _passwordController.text);
    } catch (error) {
      if (mounted) {
        showAuthMessage(
          context,
          error is AuthServiceException
              ? error.message
              : 'Unable to sign in. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _forgotPassword() {
    final email = _emailController.text.trim();
    if (widget.onForgotPassword == null) {
      showAuthMessage(
        context,
        'Connect onForgotPassword to your password recovery flow.',
      );
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      showAuthMessage(context, 'Enter your email address first.');
      return;
    }
    widget.onForgotPassword!(email);
  }

  void _openSignUp() {
    if (widget.onCreateAccount != null) {
      widget.onCreateAccount!();
      return;
    }
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SignUpScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AuthResponsiveLayout(
      brandName: widget.brandName,
      eyebrow: 'WELCOME BACK',
      heroTitle: 'Your next chapter starts right here.',
      heroDescription: 'Pick up where you left off. Your projects, conversations and next great collaboration are waiting.',
      formTitle: 'Welcome back',
      formDescription: 'Sign in to continue to your WorkBridge workspace.',
      form: _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthTextField(
              controller: _emailController,
              label: 'Email address',
              hint: 'you@example.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Please enter your email address.';
                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                  return 'Enter a valid email address.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            AuthTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
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
                if (value == null || value.isEmpty) {
                  return 'Please enter your password.';
                }
                // No minimum length here: accounts created before the 8-char
                // rule (Supabase's default minimum is 6) must still sign in.
                return null;
              },
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          'Secure session on this device',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _forgotPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.papayaDark,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            AuthPrimaryButton(
              label: 'Sign in',
              isLoading: _isSubmitting,
              onPressed: _submit,
              icon: Icons.arrow_forward_rounded,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'OR',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.outlineVariant)),
              ],
            ),
            const SizedBox(height: 22),
            AuthSwitchPrompt(
              prompt: "Don't have an account?",
              actionLabel: 'Create account',
              onPressed: _openSignUp,
            ),
          ],
        ),
      ),
    );
  }
}
