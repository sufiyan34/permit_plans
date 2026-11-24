import 'package:flutter/material.dart';

/// WorkBridge's shared brand palette.
///
/// Palette direction: Aubergine + Papaya + Saffron.
/// Warm, editorial and confident; intentionally avoids the usual blue/teal SaaS look.
/// Keep all app-wide color tokens in this file.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Brand: deep aubergine
  // ---------------------------------------------------------------------------

  static const Color brand = Color(0xFF5A344B);
  static const Color brandDark = Color(0xFF3F2435);
  static const Color brandSoft = Color(0xFFF1E7EC);
  static const Color brandTint = Color(0xFFE4D1DB);

  // ---------------------------------------------------------------------------
  // Accent: papaya / warm coral
  // ---------------------------------------------------------------------------

  static const Color papaya = Color(0xFFE87651);
  static const Color papayaDark = Color(0xFFB84E32);
  static const Color papayaSoft = Color(0xFFFBE9E2);

  // ---------------------------------------------------------------------------
  // Highlight: muted saffron
  // ---------------------------------------------------------------------------

  static const Color saffron = Color(0xFFD5A845);
  static const Color saffronDark = Color(0xFF966D1D);
  static const Color saffronSoft = Color(0xFFF7EFD9);

  // ---------------------------------------------------------------------------
  // Light theme surfaces
  // ---------------------------------------------------------------------------

  static const Color canvas = Color(0xFFFAF6F0);
  static const Color surface = Color(0xFFFFFEFC);
  static const Color surfaceAlt = Color(0xFFF2EBE4);
  static const Color inputFill = Color(0xFFF8F2EC);

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------

  static const Color ink = Color(0xFF2C252B);
  static const Color textPrimary = Color(0xFF2C252B);
  static const Color textSecondary = Color(0xFF71656E);
  static const Color textTertiary = Color(0xFF9B8F96);
  static const Color textOnBrand = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Borders and disabled states
  // ---------------------------------------------------------------------------

  static const Color outline = Color(0xFFD8CCC5);
  static const Color outlineVariant = Color(0xFFEAE1DA);
  static const Color disabled = Color(0xFFE8E0DA);

  // ---------------------------------------------------------------------------
  // Semantic states (kept distinct from brand colors)
  // ---------------------------------------------------------------------------

  static const Color success = Color(0xFF28765A);
  static const Color successSoft = Color(0xFFE4F1E9);

  static const Color warning = Color(0xFFB77A22);
  static const Color warningInk = Color(0xFF4B310B);
  static const Color warningSoft = Color(0xFFFAF0DB);

  static const Color error = Color(0xFFB83F49);
  static const Color errorSoft = Color(0xFFF9E7E7);

  static const Color info = Color(0xFF5A718B);
  static const Color infoSoft = Color(0xFFE9EEF3);

  // ---------------------------------------------------------------------------
  // Common neutrals
  // ---------------------------------------------------------------------------

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF171317);

  // ---------------------------------------------------------------------------
  // Admin dashboard
  // ---------------------------------------------------------------------------

  static const Color adminSidebar = Color(0xFF352332);
  static const Color adminSidebarDeep = Color(0xFF241823);

  // ---------------------------------------------------------------------------
  // Shadows
  // ---------------------------------------------------------------------------

  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: brand.withValues(alpha: 0.07),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static final List<BoxShadow> featureShadow = [
    BoxShadow(
      color: papaya.withValues(alpha: 0.18),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Backwards-compatible aliases.
  // These keep older widgets compiling while screens are migrated to the
  // Aubergine + Papaya + Saffron names above.
  // ---------------------------------------------------------------------------

  @Deprecated('Use AppColors.brand instead.')
  static const Color primary = brand;

  @Deprecated('Use AppColors.brandDark instead.')
  static const Color primaryDark = brandDark;

  @Deprecated('Use AppColors.brandSoft instead.')
  static const Color primarySoft = brandSoft;

  @Deprecated('Use AppColors.canvas instead.')
  static const Color background = canvas;

  @Deprecated('Use AppColors.textTertiary instead.')
  static const Color textMuted = textTertiary;

  @Deprecated('Use AppColors.textOnBrand instead.')
  static const Color textOnPrimary = textOnBrand;

  @Deprecated('Use AppColors.saffron instead.')
  static const Color accentGold = saffron;

  @Deprecated('Use AppColors.saffronSoft instead.')
  static const Color accentGoldSoft = saffronSoft;

  @Deprecated('Use AppColors.papaya instead.')
  static const Color teal = papaya;

  @Deprecated('Use AppColors.papayaDark instead.')
  static const Color tealDark = papayaDark;

  @Deprecated('Use AppColors.papayaSoft instead.')
  static const Color tealSoft = papayaSoft;

  @Deprecated('Use AppColors.outlineVariant instead.')
  static const Color border = outlineVariant;

  @Deprecated('Use AppColors.error instead.')
  static const Color danger = error;
}
