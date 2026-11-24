import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permit_plans/auths/auth_screen_components.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';

/// Lets a new visitor choose which marketplace experience to create.
///
/// This screen is responsive:
/// - Mobile: a vertical, single-column selection flow.
/// - Laptop/desktop: a two-panel layout with a brand introduction and the
///   account choices side by side.
///
/// By default, Continue opens the named sign-up route with `?role=<role>`, so
/// the URL is shareable and survives a web refresh. Supply [onContinue] to
/// control navigation yourself.
class AccountTypeSelectionScreen extends StatefulWidget {
  const AccountTypeSelectionScreen({
    this.onContinue,
    this.onLogin,
    this.onBack,
    this.brandName = 'WorkBridge',
    super.key,
  });

  /// Called with `client` or `engineer` when the user continues.
  final ValueChanged<MarketplaceAccountRole>? onContinue;

  /// Optional override for the Sign in action.
  final VoidCallback? onLogin;

  /// Optional override for the back action.
  final VoidCallback? onBack;

  final String brandName;

  @override
  State<AccountTypeSelectionScreen> createState() =>
      _AccountTypeSelectionScreenState();
}

class _AccountTypeSelectionScreenState
    extends State<AccountTypeSelectionScreen> {
  MarketplaceAccountRole? _selectedRole;

  void _continue() {
    final role = _selectedRole;
    if (role == null) return;

    if (widget.onContinue != null) {
      widget.onContinue!(role);
      return;
    }

    Get.toNamed<void>(AppRoutes.signUp, parameters: {'role': role.name});
  }

  void _openLogin() {
    if (widget.onLogin != null) {
      widget.onLogin!();
      return;
    }

    Get.toNamed<void>(AppRoutes.login);
  }

  void _goBack() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    // Opened directly by URL there is nothing to pop, so go to the start of
    // the guest flow instead of doing nothing.
    if (Navigator.of(context).canPop()) {
      Get.back<void>();
    } else {
      Get.offAllNamed<void>(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Uses the light palette directly, so pin the light theme (see
    // AuthResponsiveLayout for the reason).
    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 960) {
                return _buildDesktop(context);
              }
              return _buildMobile(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBar(brandName: widget.brandName, onBack: _goBack, compact: true),
          const SizedBox(height: 34),
          const _StepLabel(),
          const SizedBox(height: 13),
          Text(
            'How will you use\nWorkBridge?',
            style: textTheme.headlineMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
              height: 1.12,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            'Choose the experience that fits you. We’ll tailor your workspace around what you want to do.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 26),
          _RoleChoiceCard(
            role: MarketplaceAccountRole.client,
            selected: _selectedRole == MarketplaceAccountRole.client,
            onTap: () =>
                setState(() => _selectedRole = MarketplaceAccountRole.client),
            compact: true,
          ),
          const SizedBox(height: 14),
          _RoleChoiceCard(
            role: MarketplaceAccountRole.engineer,
            selected: _selectedRole == MarketplaceAccountRole.engineer,
            onTap: () =>
                setState(() => _selectedRole = MarketplaceAccountRole.engineer),
            compact: true,
          ),
          const SizedBox(height: 25),
          _ContinueButton(
            enabled: _selectedRole != null,
            onPressed: _continue,
            label: _selectedRole == null
                ? 'Choose an account type'
                : 'Continue as ${_selectedRole == MarketplaceAccountRole.client ? 'Client' : 'Engineer'}',
          ),
          const SizedBox(height: 22),
          _LoginPrompt(onLogin: _openLogin),
          const SizedBox(height: 18),
          const _TrustNote(),
        ],
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                flex: 9,
                child: _DesktopBrandPanel(brandName: widget.brandName),
              ),
              const SizedBox(width: 26),
              Expanded(
                flex: 11,
                child: Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.outlineVariant),
                    boxShadow: AppColors.cardShadow,
                  ),
                  // Scrolls on short windows instead of overflowing, and
                  // stays vertically centred on tall ones.
                  child: LayoutBuilder(
                    builder: (context, box) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(38, 30, 38, 30),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: (box.maxHeight - 60)
                                .clamp(0.0, double.infinity)
                                .toDouble(),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _TopBar(
                                brandName: widget.brandName,
                                onBack: _goBack,
                                showBrand: false,
                              ),
                              const SizedBox(height: 32),
                              const _StepLabel(),
                              const SizedBox(height: 13),
                              Text(
                                'Choose your\nstarting point.',
                                style: textTheme.headlineLarge?.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w800,
                                  height: 1.08,
                                  letterSpacing: -1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 560,
                                ),
                                child: Text(
                                  'Tell us what brings you here. You’ll get a workspace designed for the way you work.',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // IntrinsicHeight fixes the crash: `stretch`
                              // needs a bounded height, and a Column gives
                              // its children an unbounded one.
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _RoleChoiceCard(
                                        role: MarketplaceAccountRole.client,
                                        selected:
                                            _selectedRole ==
                                            MarketplaceAccountRole.client,
                                        onTap: () => setState(
                                          () => _selectedRole =
                                              MarketplaceAccountRole.client,
                                        ),
                                        compact: false,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: _RoleChoiceCard(
                                        role: MarketplaceAccountRole.engineer,
                                        selected:
                                            _selectedRole ==
                                            MarketplaceAccountRole.engineer,
                                        onTap: () => setState(
                                          () => _selectedRole =
                                              MarketplaceAccountRole.engineer,
                                        ),
                                        compact: false,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 27),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ContinueButton(
                                      enabled: _selectedRole != null,
                                      onPressed: _continue,
                                      label: _selectedRole == null
                                          ? 'Choose an account type'
                                          : 'Continue as ${_selectedRole == MarketplaceAccountRole.client ? 'Client' : 'Engineer'}',
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Flexible(
                                    child: _LoginPrompt(onLogin: _openLogin),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const _TrustNote(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.brandName,
    required this.onBack,
    this.compact = false,
    this.showBrand = true,
  });

  final String brandName;
  final VoidCallback onBack;
  final bool compact;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(
              width: 42,
              height: 42,
              child: Icon(Icons.arrow_back_rounded, color: AppColors.brand),
            ),
          ),
        ),
        if (showBrand) ...[
          SizedBox(width: compact ? 13 : 16),
          Text(
            brandName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.brand,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
        const Spacer(),
        if (!compact)
          Text(
            'INDEPENDENT WORK. BETTER TOGETHER.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.papaya,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          'STEP 1 OF 2  ·  ACCOUNT TYPE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.brand,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _RoleChoiceCard extends StatelessWidget {
  const _RoleChoiceCard({
    required this.role,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  final MarketplaceAccountRole role;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  bool get isClient => role == MarketplaceAccountRole.client;

  Color get accent => isClient ? AppColors.brand : AppColors.papaya;
  Color get softAccent => isClient ? AppColors.brandSoft : AppColors.papayaSoft;
  IconData get icon =>
      isClient ? Icons.business_center_rounded : Icons.terminal_rounded;
  String get title => isClient ? 'I’m a Client' : 'I’m an Engineer';
  String get subtitle => isClient
      ? 'I have work to get done and want to hire great talent.'
      : 'I have skills to offer and want to work on great projects.';
  List<String> get benefits => isClient
      ? const ['Post projects', 'Compare proposals', 'Pay securely']
      : const ['Find projects', 'Send proposals', 'Earn from your skills'];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected
            ? softAccent.withValues(alpha: 0.62)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected ? accent : AppColors.outlineVariant,
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.10),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(21),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(21),
          child: Padding(
            padding: EdgeInsets.all(compact ? 19 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: compact ? 52 : 56,
                      height: compact ? 52 : 56,
                      decoration: BoxDecoration(
                        color: softAccent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: accent, size: 27),
                    ),
                    const Spacer(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 23,
                      height: 23,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? accent : Colors.transparent,
                        border: Border.all(
                          color: selected ? accent : AppColors.outline,
                          width: 1.5,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: benefits
                      .map(
                        (benefit) => _BenefitChip(
                          label: benefit,
                          accent: accent,
                          background: softAccent,
                        ),
                      )
                      .toList(),
                ),
                if (!compact) const SizedBox(height: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({
    required this.label,
    required this.accent,
    required this.background,
  });

  final String label;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 12, color: accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: accent, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.enabled,
    required this.onPressed,
    required this.label,
  });

  final bool enabled;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: AppColors.textTertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: Theme.of(context).textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: onLogin,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.papayaDark,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Sign in'),
        ),
      ],
    );
  }
}

class _TrustNote extends StatelessWidget {
  const _TrustNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          size: 14,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            'Your account type is tied to your account for a secure experience.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppColors.textTertiary, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _DesktopBrandPanel extends StatelessWidget {
  const _DesktopBrandPanel({required this.brandName});

  final String brandName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.brandDark,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -100,
            child: _DecorativeOrb(
              size: 330,
              color: AppColors.papaya.withValues(alpha: 0.20),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -90,
            child: _DecorativeOrb(
              size: 360,
              color: AppColors.saffron.withValues(alpha: 0.16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(42),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: const Icon(
                        Icons.hub_rounded,
                        color: AppColors.saffron,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      brandName,
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.13),
                    ),
                  ),
                  child: Text(
                    'A MARKETPLACE BUILT AROUND PEOPLE',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.saffron,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Make room for\nwork that matters.',
                  style: textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    height: 1.04,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.7,
                  ),
                ),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Text(
                    'Whether you’re building a business or building your craft, start with the workspace that’s right for you.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.76),
                      height: 1.65,
                    ),
                  ),
                ),
                const SizedBox(height: 34),
                const _BrandStatRow(),
                const Spacer(),
                Text(
                  'INDEPENDENT WORK. BETTER TOGETHER.',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.48),
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
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

class _BrandStatRow extends StatelessWidget {
  const _BrandStatRow();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        _MiniStat(label: 'Find', value: 'Talent', textTheme: textTheme),
        const SizedBox(width: 28),
        Container(
          width: 1,
          height: 34,
          color: Colors.white.withValues(alpha: 0.18),
        ),
        const SizedBox(width: 28),
        _MiniStat(label: 'Build', value: 'Trust', textTheme: textTheme),
        const SizedBox(width: 28),
        Container(
          width: 1,
          height: 34,
          color: Colors.white.withValues(alpha: 0.18),
        ),
        const SizedBox(width: 28),
        _MiniStat(label: 'Do', value: 'Great work', textTheme: textTheme),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.textTheme,
  });

  final String label;
  final String value;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.55),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DecorativeOrb extends StatelessWidget {
  const _DecorativeOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
