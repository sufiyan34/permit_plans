import 'package:flutter/material.dart';
import 'package:permit_plans/constants/app_theme.dart';

/// Three-slide introduction for the WorkBridge marketplace.
///
/// Responsive behaviour:
/// - Mobile / narrow screens: stacked illustration and copy.
/// - Laptop / desktop screens: editorial two-column layout.
///
/// Connect [onComplete] to the next route (account type selection) from your
/// app's navigation layer. This screen deliberately does not assume a route
/// name or force GetX navigation, so it also works with your current
/// MaterialApp setup.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.onComplete,
    this.brandName = 'WorkBridge',
    super.key,
  });

  final VoidCallback onComplete;
  final String brandName;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      eyebrow: 'FOR CLIENTS',
      title: 'Your next great hire is closer than you think.',
      description:
          'Share what you need, compare thoughtful proposals, and choose the right person to bring your idea to life.',
      visualTitle: 'Find the right fit',
      visualSubtitle: 'A few good proposals. One great choice.',
    ),
    _OnboardingSlide(
      eyebrow: 'FOR ENGINEERS',
      title: 'Find projects that fit your craft.',
      description:
          'Discover meaningful projects, send a clear quote, and build client relationships around work you are proud of.',
      visualTitle: 'A project worth your skills',
      visualSubtitle: 'Fresh opportunities, all in one place.',
    ),
    _OnboardingSlide(
      eyebrow: 'FROM BRIEF TO DONE',
      title: 'Good work deserves a clearer process.',
      description:
          'Keep project details, conversations, files, revisions, and payment updates together in one organized workspace.',
      visualTitle: 'Everything in sync',
      visualSubtitle: 'The next step is always clear.',
    ),
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _slides.length - 1;

  void _nextPage() {
    if (_isLastPage) {
      widget.onComplete();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  void _skip() => widget.onComplete();

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
              return _LaptopOnboardingView(
                brandName: widget.brandName,
                pageController: _pageController,
                slides: _slides,
                currentPage: _currentPage,
                isLastPage: _isLastPage,
                onPageChanged: (index) => setState(() => _currentPage = index),
                onSkip: _skip,
                onNext: _nextPage,
                onPrevious: () => _goToPage(_currentPage - 1),
                onSelectPage: _goToPage,
              );
            }

            return _MobileOnboardingView(
              brandName: widget.brandName,
              pageController: _pageController,
              slides: _slides,
              currentPage: _currentPage,
              isLastPage: _isLastPage,
              onPageChanged: (index) => setState(() => _currentPage = index),
              onSkip: _skip,
              onNext: _nextPage,
              onPrevious: () => _goToPage(_currentPage - 1),
              onSelectPage: _goToPage,
            );
          },
        ),
      ),
    );
  }
}

class _MobileOnboardingView extends StatelessWidget {
  const _MobileOnboardingView({
    required this.brandName,
    required this.pageController,
    required this.slides,
    required this.currentPage,
    required this.isLastPage,
    required this.onPageChanged,
    required this.onSkip,
    required this.onNext,
    required this.onPrevious,
    required this.onSelectPage,
  });

  final String brandName;
  final PageController pageController;
  final List<_OnboardingSlide> slides;
  final int currentPage;
  final bool isLastPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final ValueChanged<int> onSelectPage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
      child: Column(
        children: [
          _OnboardingHeader(brandName: brandName, onSkip: onSkip),
          const SizedBox(height: 8),
          Expanded(
            child: PageView.builder(
              controller: pageController,
              itemCount: slides.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) {
                return _MobileSlideContent(slide: slides[index], index: index);
              },
            ),
          ),
          const SizedBox(height: 10),
          _PageIndicators(
            count: slides.length,
            currentPage: currentPage,
            onSelectPage: onSelectPage,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (currentPage > 0)
                TextButton.icon(
                  onPressed: onPrevious,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                const SizedBox(width: 76),
              const Spacer(),
              _PrimaryActionButton(
                label: isLastPage ? 'Get started' : 'Continue',
                onPressed: onNext,
                compact: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LaptopOnboardingView extends StatelessWidget {
  const _LaptopOnboardingView({
    required this.brandName,
    required this.pageController,
    required this.slides,
    required this.currentPage,
    required this.isLastPage,
    required this.onPageChanged,
    required this.onSkip,
    required this.onNext,
    required this.onPrevious,
    required this.onSelectPage,
  });

  final String brandName;
  final PageController pageController;
  final List<_OnboardingSlide> slides;
  final int currentPage;
  final bool isLastPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final ValueChanged<int> onSelectPage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(64, 20, 64, 28),
          child: Column(
            children: [
              _OnboardingHeader(brandName: brandName, onSkip: onSkip),
              const SizedBox(height: 16),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surface
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: slides.length,
                      onPageChanged: onPageChanged,
                      itemBuilder: (context, index) {
                        return _LaptopSlideContent(
                          slide: slides[index],
                          index: index,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Text(
                    'A better way to get great work done.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  _PageIndicators(
                    count: slides.length,
                    currentPage: currentPage,
                    onSelectPage: onSelectPage,
                  ),
                  const Spacer(),
                  if (currentPage > 0)
                    IconButton(
                      tooltip: 'Previous slide',
                      onPressed: onPrevious,
                      style: IconButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface,
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                        fixedSize: const Size(48, 48),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  const SizedBox(width: 10),
                  _PrimaryActionButton(
                    label: isLastPage ? 'Get started' : 'Continue',
                    onPressed: onNext,
                    compact: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.brandName, required this.onSkip});

  final String brandName;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.brand, AppColors.brandDark],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.handshake_rounded,
            color: Colors.white,
            size: 23,
          ),
        ),
        const SizedBox(width: 11),
        Text(
          brandName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.65,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onSkip,
          child: const Text('Skip'),
        ),
      ],
    );
  }
}

class _MobileSlideContent extends StatelessWidget {
  const _MobileSlideContent({required this.slide, required this.index});

  final _OnboardingSlide slide;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IllustrationPanel(index: index, slide: slide, compact: true),
          const SizedBox(height: 26),
          _EyebrowLabel(text: slide.eyebrow),
          const SizedBox(height: 12),
          Text(
            slide.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LaptopSlideContent extends StatelessWidget {
  const _LaptopSlideContent({required this.slide, required this.index});

  final _OnboardingSlide slide;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 54, vertical: 38),
      child: Row(
        children: [
          Expanded(
            flex: 9,
            child: Padding(
              padding: const EdgeInsets.only(right: 38),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EyebrowLabel(text: slide.eyebrow),
                  const SizedBox(height: 22),
                  Text(
                    slide.title,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.8,
                      height: 1.04,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 470),
                    child: Text(
                      slide.description,
                      style: theme.textTheme.titleMedium?.copyWith(
                        height: 1.65,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _BenefitLine(
                    icon: Icons.verified_user_outlined,
                    text: 'Clear expectations from the start',
                  ),
                  const SizedBox(height: 13),
                  _BenefitLine(
                    icon: Icons.forum_outlined,
                    text: 'Project details stay in one workspace',
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 11,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final visualHeight = constraints.maxHeight
                    .clamp(300.0, 430.0)
                    .toDouble();

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 630),
                    child: _IllustrationPanel(
                      index: index,
                      slide: slide,
                      compact: false,
                      height: visualHeight,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IllustrationPanel extends StatelessWidget {
  const _IllustrationPanel({
    required this.index,
    required this.slide,
    required this.compact,
    this.height,
  });

  final int index;
  final _OnboardingSlide slide;
  final bool compact;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final panelHeight = height ?? (compact ? 235.0 : 430.0);

    return SizedBox(
      height: panelHeight,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final cardWidth = width * (compact ? 0.78 : 0.72);

          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.adminSidebar : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(compact ? 24 : 30),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  top: -height * 0.34,
                  right: -width * 0.10,
                  child: _DecorativeOrb(
                    size: height * 0.85,
                    color: AppColors.saffron.withValues(alpha: 0.24),
                  ),
                ),
                Positioned(
                  bottom: -height * 0.40,
                  left: -width * 0.08,
                  child: _DecorativeOrb(
                    size: height * 0.92,
                    color: AppColors.papaya.withValues(alpha: 0.20),
                  ),
                ),
                Positioned(
                  left: width * (compact ? 0.08 : 0.10),
                  top: height * (compact ? 0.19 : 0.18),
                  width: cardWidth,
                  height: height * (compact ? 0.68 : 0.58),
                  child: _MainMockCard(
                    index: index,
                    compact: compact,
                    title: slide.visualTitle,
                    subtitle: slide.visualSubtitle,
                  ),
                ),
                Positioned(
                  top: height * (compact ? 0.09 : 0.10),
                  right: width * 0.055,
                  child: _FloatingBadge(
                    icon: index == 2
                        ? Icons.lock_outline_rounded
                        : Icons.auto_awesome_rounded,
                    label: index == 0
                        ? 'Great matches'
                        : index == 1
                            ? 'New opportunity'
                            : 'Project on track',
                    compact: compact,
                  ),
                ),
                Positioned(
                  bottom: height * (compact ? 0.075 : 0.09),
                  right: width * 0.055,
                  child: _MiniStatusCard(index: index, compact: compact),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MainMockCard extends StatelessWidget {
  const _MainMockCard({
    required this.index,
    required this.compact,
    required this.title,
    required this.subtitle,
  });

  final int index;
  final bool compact;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final icon = index == 0
        ? Icons.design_services_rounded
        : index == 1
            ? Icons.phone_iphone_rounded
            : Icons.dashboard_customize_rounded;

    return Card(
      margin: EdgeInsets.zero,
      color: isDark ? const Color(0xFF493341) : AppColors.surface,
      elevation: 10,
      shadowColor: AppColors.brand.withValues(alpha: 0.13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 16 : 22),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: compact ? 30 : 40,
                  height: compact ? 30 : 40,
                  decoration: BoxDecoration(
                    color: AppColors.papayaSoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.papayaDark,
                    size: compact ? 17 : 21,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.more_horiz_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: compact ? 18 : 23,
                ),
              ],
            ),
            SizedBox(height: compact ? 9 : 17),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: compact ? 12 : 18,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: compact ? 9 : 12,
              ),
            ),
            SizedBox(height: compact ? 10 : 18),
            if (index == 0)
              _PeopleAvatars(compact: compact)
            else if (index == 1)
              Wrap(
                spacing: compact ? 4 : 7,
                runSpacing: 4,
                children: const [
                  _SmallTag(label: 'Flutter'),
                  _SmallTag(label: 'UI/UX'),
                  _SmallTag(label: 'Figma'),
                ],
              )
            else
              _ProgressStrip(compact: compact),
            const Spacer(),
            Divider(height: compact ? 12 : 20),
            Row(
              children: [
                Icon(
                  index == 2 ? Icons.folder_open_outlined : Icons.star_rounded,
                  size: compact ? 12 : 16,
                  color: AppColors.saffronDark,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    index == 0
                        ? '12 proposals to review'
                        : index == 1
                            ? 'Fixed-price project'
                            : 'Files and updates in one place',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: compact ? 8 : 11,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: compact ? 13 : 17,
                  color: AppColors.brand,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PeopleAvatars extends StatelessWidget {
  const _PeopleAvatars({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 25.0 : 34.0;
    const colors = [AppColors.brand, AppColors.papaya, AppColors.saffron];

    return Row(
      children: [
        SizedBox(
          width: size * 2.25,
          height: size,
          child: Stack(
            children: List.generate(3, (index) {
              return Positioned(
                left: index * size * 0.62,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: size * 0.58,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'Skilled people, ready to help',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: compact ? 8 : 11,
                ),
          ),
        ),
      ],
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Project progress',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: compact ? 8 : 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '75%',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: compact ? 8 : 10,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 5 : 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: 0.75,
            minHeight: compact ? 5 : 7,
            backgroundColor: AppColors.surfaceAlt,
            color: AppColors.papaya,
          ),
        ),
      ],
    );
  }
}

class _MiniStatusCard extends StatelessWidget {
  const _MiniStatusCard({required this.index, required this.compact});

  final int index;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = index == 0
        ? 'Shortlist made'
        : index == 1
            ? 'Proposal sent'
            : 'Delivery shared';
    final icon = index == 0
        ? Icons.check_circle_rounded
        : index == 1
            ? Icons.send_rounded
            : Icons.task_alt_rounded;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 14,
        vertical: compact ? 7 : 11,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(13),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.success,
            size: compact ? 13 : 17,
          ),
          SizedBox(width: compact ? 5 : 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 8 : 11,
                ),
          ),
        ],
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({
    required this.icon,
    required this.label,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 6 : 9,
      ),
      decoration: BoxDecoration(
        color: AppColors.saffronSoft,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.saffronDark, size: compact ? 11 : 15),
          SizedBox(width: compact ? 4 : 7),
          Text(
            label,
            style: TextStyle(
              color: AppColors.warningInk,
              fontSize: compact ? 8 : 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.brand,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EyebrowLabel extends StatelessWidget {
  const _EyebrowLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.papayaSoft,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.papayaDark,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.15,
        ),
      ),
    );
  }
}

class _BenefitLine extends StatelessWidget {
  const _BenefitLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.successSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.success,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _PageIndicators extends StatelessWidget {
  const _PageIndicators({
    required this.count,
    required this.currentPage,
    required this.onSelectPage,
  });

  final int count;
  final int currentPage;
  final ValueChanged<int> onSelectPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final selected = index == currentPage;

        return Semantics(
          button: true,
          selected: selected,
          label: 'Go to introduction page ${index + 1}',
          child: InkWell(
            onTap: () => onSelectPage(index),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: selected ? 27 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: selected ? AppColors.brand : AppColors.outline,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.onPressed,
    required this.compact,
  });

  final String label;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.textOnBrand,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 24 : 22,
          vertical: compact ? 20 : 17,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.button,
        ),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _DecorativeOrb extends StatelessWidget {
  const _DecorativeOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.visualTitle,
    required this.visualSubtitle,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String visualTitle;
  final String visualSubtitle;
}
