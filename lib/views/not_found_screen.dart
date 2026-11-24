import 'package:flutter/material.dart';
import 'package:permit_plans/constants/app_colors.dart';

/// Responsive 404 screen for WorkBridge.
///
/// - Mobile: centered, stacked layout.
/// - Laptop / desktop: two-column editorial layout.
///
/// The callbacks are optional, so `const NotFoundScreen()` works without
/// requiring a route name or a navigation package. By default, the home action
/// returns to the first route in the Navigator stack and the back action tries
/// to pop the current route.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({
    this.onGoHome,
    this.onGoBack,
    this.brandName = 'WorkBridge',
    super.key,
  });

  final VoidCallback? onGoHome;
  final VoidCallback? onGoBack;
  final String brandName;

  void _handleGoHome(BuildContext context) {
    if (onGoHome != null) {
      onGoHome!();
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _handleGoBack(BuildContext context) {
    if (onGoBack != null) {
      onGoBack!();
      return;
    }

    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLaptop = constraints.maxWidth >= 960;

            if (isLaptop) {
              return _LaptopNotFoundView(
                brandName: brandName,
                onGoHome: () => _handleGoHome(context),
                onGoBack: () => _handleGoBack(context),
              );
            }

            return _MobileNotFoundView(
              brandName: brandName,
              onGoHome: () => _handleGoHome(context),
              onGoBack: () => _handleGoBack(context),
            );
          },
        ),
      ),
    );
  }
}

class _MobileNotFoundView extends StatelessWidget {
  const _MobileNotFoundView({
    required this.brandName,
    required this.onGoHome,
    required this.onGoBack,
  });

  final String brandName;
  final VoidCallback onGoHome;
  final VoidCallback onGoBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BrandHeader(brandName: brandName),
                  const SizedBox(height: 28),
                  const _ErrorIllustration(height: 245),
                  const SizedBox(height: 24),
                  _ErrorPill(),
                  const SizedBox(height: 14),
                  Text(
                    'Well, this is\na little unexpected.',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                      height: 1.13,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: Text(
                      "We couldn't find the page you're looking for. It may have moved, or the link might be out of date.",
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  _NotFoundActions(
                    onGoHome: onGoHome,
                    onGoBack: onGoBack,
                    isCompact: true,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'A better way to get good work done.',
                    textAlign: TextAlign.center,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LaptopNotFoundView extends StatelessWidget {
  const _LaptopNotFoundView({
    required this.brandName,
    required this.onGoHome,
    required this.onGoBack,
  });

  final String brandName;
  final VoidCallback onGoHome;
  final VoidCallback onGoBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 680),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 34),
              child: Column(
                children: [
                  _BrandHeader(brandName: brandName),
                  const SizedBox(height: 34),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 10,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 42),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const _ErrorPill(),
                              const SizedBox(height: 24),
                              Text(
                                'Looks like this\npage took a detour.',
                                style: textTheme.displaySmall?.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w800,
                                  height: 1.08,
                                  letterSpacing: -1.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 480),
                                child: Text(
                                  "The page you tried to reach isn't here. The address may be incorrect, or the page may have been moved.",
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    height: 1.65,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              _NotFoundActions(
                                onGoHome: onGoHome,
                                onGoBack: onGoBack,
                                isCompact: false,
                              ),
                              const SizedBox(height: 30),
                              Row(
                                children: [
                                  Icon(
                                    Icons.tips_and_updates_outlined,
                                    size: 17,
                                    color: AppColors.saffron,
                                  ),
                                  const SizedBox(width: 9),
                                  Text(
                                    'Try checking the URL for typos.',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Expanded(
                        flex: 9,
                        child: _ErrorIllustration(height: 470),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Divider(color: colors.outlineVariant),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        brandName,
                        style: textTheme.labelLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'A better way to get good work done.',
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.brandName});

  final String brandName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.workspaces_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 11),
        Text(
          brandName,
          style: textTheme.titleLarge?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Text(
            'ERROR 404',
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorPill extends StatelessWidget {
  const _ErrorPill();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.papaya.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.route_rounded,
            size: 15,
            color: AppColors.papayaDark,
          ),
          const SizedBox(width: 7),
          Text(
            'OFF THE MAP',
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotFoundActions extends StatelessWidget {
  const _NotFoundActions({
    required this.onGoHome,
    required this.onGoBack,
    required this.isCompact,
  });

  final VoidCallback onGoHome;
  final VoidCallback onGoBack;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final homeButton = FilledButton.icon(
      onPressed: onGoHome,
      icon: const Icon(Icons.home_rounded, size: 19),
      label: const Text('Go to homepage'),
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        minimumSize: Size(isCompact ? double.infinity : 190, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );

    final backButton = OutlinedButton.icon(
      onPressed: onGoBack,
      icon: const Icon(Icons.arrow_back_rounded, size: 18),
      label: const Text('Go back'),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.onSurface,
        minimumSize: Size(isCompact ? double.infinity : 140, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        side: BorderSide(color: colors.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          homeButton,
          const SizedBox(height: 11),
          backButton,
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [homeButton, backButton],
    );
  }
}

class _ErrorIllustration extends StatelessWidget {
  const _ErrorIllustration({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final artBackground = isDark
              ? colors.surfaceContainerHighest
              : AppColors.surfaceAlt;

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: width * 0.88,
                height: height * 0.82,
                decoration: BoxDecoration(
                  color: artBackground,
                  borderRadius: BorderRadius.circular(38),
                ),
              ),
              Positioned(
                top: height * 0.08,
                left: width * 0.10,
                child: _DecorativeDot(
                  size: 17,
                  color: AppColors.saffron,
                ),
              ),
              Positioned(
                top: height * 0.17,
                right: width * 0.12,
                child: _DecorativeDot(
                  size: 11,
                  color: AppColors.papaya,
                ),
              ),
              Positioned(
                bottom: height * 0.12,
                left: width * 0.16,
                child: Transform.rotate(
                  angle: -0.22,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.saffron.withValues(alpha: 0.23),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.near_me_rounded,
                      color: AppColors.saffron,
                      size: 25,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: height * 0.12,
                right: width * 0.13,
                child: _DecorativeDot(
                  size: 27,
                  color: AppColors.papaya.withValues(alpha: 0.65),
                ),
              ),
              Container(
                width: width * 0.62,
                constraints: const BoxConstraints(maxWidth: 270),
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(color: colors.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.07),
                      blurRadius: 28,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _WindowDot(color: AppColors.papaya),
                        const SizedBox(width: 5),
                        _WindowDot(color: AppColors.saffron),
                        const SizedBox(width: 5),
                        _WindowDot(color: AppColors.success),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '404',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: height > 300 ? 92 : 76,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: -5,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      width: 92,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.papaya,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      'PAGE NOT FOUND',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: width * 0.08,
                top: height * 0.43,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surface, width: 5),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.location_off_rounded,
                    color: colors.onPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DecorativeDot extends StatelessWidget {
  const _DecorativeDot({required this.size, required this.color});

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

class _WindowDot extends StatelessWidget {
  const _WindowDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
