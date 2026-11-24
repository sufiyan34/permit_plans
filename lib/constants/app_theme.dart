import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permit_plans/constants/app_colors.dart';

export 'app_colors.dart';

/// Application-wide Material 3 theme.
///
/// Usage:
/// MaterialApp(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
///   themeMode: ThemeMode.system,
/// );
///
/// Brand direction: Aubergine + Papaya + Saffron.
class AppTheme {
  AppTheme._();

  static final ThemeData light = _buildTheme(Brightness.light);
  static final ThemeData dark = _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final palette = isDark ? _ThemePalette.dark : _ThemePalette.light;

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.brand,
          brightness: brightness,
        ).copyWith(
          primary: palette.primary,
          onPrimary: palette.onPrimary,
          primaryContainer: palette.primaryContainer,
          onPrimaryContainer: palette.onPrimaryContainer,
          secondary: palette.secondary,
          onSecondary: palette.onSecondary,
          secondaryContainer: palette.secondaryContainer,
          onSecondaryContainer: palette.onSecondaryContainer,
          tertiary: palette.tertiary,
          onTertiary: palette.onTertiary,
          error: isDark ? const Color(0xFFFF8D91) : AppColors.error,
          surface: palette.surface,
          onSurface: palette.textPrimary,
          outline: palette.outline,
          outlineVariant: palette.outlineVariant,
        );

    final baseTextTheme = _buildTextTheme(
      primary: palette.textPrimary,
      secondary: palette.textSecondary,
    );
    final textTheme = baseTextTheme.apply(
      fontFamily: GoogleFonts.manrope().fontFamily,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.canvas,
      canvasColor: palette.surface,
      dividerColor: palette.outlineVariant,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        MarketplaceSemanticColors(
          success: isDark ? const Color(0xFF83D5A8) : AppColors.success,
          onSuccess: isDark ? const Color(0xFF102D20) : Colors.white,
          warning: isDark ? const Color(0xFFF0C36A) : AppColors.warning,
          onWarning: isDark ? const Color(0xFF35240A) : AppColors.warningInk,
          info: isDark ? const Color(0xFFA7C1DF) : AppColors.info,
          onInfo: isDark ? const Color(0xFF172638) : Colors.white,
        ),
      ],

      // App bars
      appBarTheme: AppBarTheme(
        backgroundColor: palette.canvas,
        foregroundColor: palette.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppSpacing.lg,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: palette.textPrimary, size: 22),
      ),

      // Cards and surfaces
      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.22 : 0.035),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.card,
          side: BorderSide(color: palette.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Form fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textTertiary),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: palette.textSecondary,
        ),
        floatingLabelStyle: textTheme.labelLarge?.copyWith(
          color: palette.primary,
        ),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: palette.textSecondary,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
        border: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(color: palette.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(color: palette.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(color: palette.outlineVariant),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          disabledBackgroundColor: palette.disabled,
          disabledForegroundColor: palette.textTertiary,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          side: BorderSide(color: palette.outline),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: palette.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.textSecondary,
          minimumSize: const Size(40, 40),
        ),
      ),

      // Navigation
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: palette.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? palette.primary : palette.textSecondary,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: palette.surface,
        indicatorColor: palette.primary.withValues(alpha: 0.12),
        selectedIconTheme: IconThemeData(color: palette.primary),
        unselectedIconTheme: IconThemeData(color: palette.textSecondary),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: palette.primary,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: palette.textSecondary,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: palette.primary,
        unselectedLabelColor: palette.textSecondary,
        indicatorColor: palette.primary,
        dividerColor: palette.outlineVariant,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
      ),

      // Supporting components
      chipTheme: ChipThemeData(
        backgroundColor: palette.chipBackground,
        selectedColor: palette.primary.withValues(alpha: 0.14),
        disabledColor: palette.disabled,
        side: BorderSide(color: palette.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.chip),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.dialog),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: palette.surface,
        showDragHandle: true,
        dragHandleColor: palette.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF3A2C38)
            : AppColors.adminSidebar,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: isDark ? const Color(0xFFFFB08F) : AppColors.papaya,
        elevation: 4,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF3A2C38) : AppColors.adminSidebar,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.textSecondary,
        textColor: palette.textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.primary;
          return null;
        }),
        checkColor: WidgetStatePropertyAll(palette.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xs),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.primary;
          return palette.textTertiary;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.onPrimary;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.primary;
          }
          return null;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.primary,
        linearTrackColor: palette.outlineVariant,
        circularTrackColor: palette.outlineVariant,
      ),
      dividerTheme: DividerThemeData(
        color: palette.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static TextTheme _buildTextTheme({
    required Color primary,
    required Color secondary,
  }) {
    return TextTheme(
          displayLarge: const TextStyle(
            fontSize: 36,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
          displayMedium: const TextStyle(
            fontSize: 32,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
          headlineLarge: const TextStyle(
            fontSize: 28,
            height: 1.25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
          headlineMedium: const TextStyle(
            fontSize: 24,
            height: 1.25,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          headlineSmall: const TextStyle(
            fontSize: 20,
            height: 1.3,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: const TextStyle(
            fontSize: 18,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
          titleSmall: const TextStyle(
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: const TextStyle(fontSize: 16, height: 1.6),
          bodyMedium: const TextStyle(fontSize: 14, height: 1.5),
          bodySmall: const TextStyle(fontSize: 12, height: 1.45),
          labelLarge: const TextStyle(
            fontSize: 14,
            height: 1.3,
            fontWeight: FontWeight.w700,
          ),
          labelMedium: const TextStyle(
            fontSize: 12,
            height: 1.3,
            fontWeight: FontWeight.w700,
          ),
          labelSmall: const TextStyle(
            fontSize: 11,
            height: 1.3,
            fontWeight: FontWeight.w700,
          ),
        )
        .apply(bodyColor: primary, displayColor: primary)
        .copyWith(
          bodySmall: TextStyle(fontSize: 12, height: 1.45, color: secondary),
          labelSmall: TextStyle(
            fontSize: 11,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: secondary,
          ),
        );
  }
}

/// Semantic colors for project, payment and verification status indicators.
class MarketplaceSemanticColors
    extends ThemeExtension<MarketplaceSemanticColors> {
  const MarketplaceSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
  });

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color info;
  final Color onInfo;

  @override
  MarketplaceSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
  }) {
    return MarketplaceSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
    );
  }

  @override
  MarketplaceSemanticColors lerp(
    covariant MarketplaceSemanticColors? other,
    double t,
  ) {
    if (other == null) return this;
    return MarketplaceSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
    );
  }
}

/// Shared spacing scale. Values are logical pixels.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 48;
}

/// Shared corner-radius scale. Numeric values are radii; use the BorderRadius
/// constants when a widget asks for BorderRadiusGeometry.
class AppRadii {
  AppRadii._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;

  static final BorderRadius chip = BorderRadius.circular(sm);
  static final BorderRadius input = BorderRadius.circular(md);
  static final BorderRadius button = BorderRadius.circular(md);
  static final BorderRadius card = BorderRadius.circular(lg);
  static final BorderRadius dialog = BorderRadius.circular(xl);
}

class _ThemePalette {
  const _ThemePalette({
    required this.canvas,
    required this.surface,
    required this.inputFill,
    required this.chipBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.outline,
    required this.outlineVariant,
    required this.disabled,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
  });

  final Color canvas;
  final Color surface;
  final Color inputFill;
  final Color chipBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color outline;
  final Color outlineVariant;
  final Color disabled;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;

  static const light = _ThemePalette(
    canvas: AppColors.canvas,
    surface: AppColors.surface,
    inputFill: AppColors.inputFill,
    chipBackground: AppColors.surfaceAlt,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    disabled: AppColors.disabled,
    primary: AppColors.brand,
    onPrimary: Colors.white,
    primaryContainer: AppColors.brandSoft,
    onPrimaryContainer: AppColors.brandDark,
    secondary: AppColors.papaya,
    onSecondary: Color(0xFF351C16),
    secondaryContainer: AppColors.papayaSoft,
    onSecondaryContainer: Color(0xFF71331F),
    tertiary: AppColors.saffron,
    onTertiary: Color(0xFF35270A),
  );

  static const dark = _ThemePalette(
    canvas: Color(0xFF191319),
    surface: Color(0xFF241B24),
    inputFill: Color(0xFF302430),
    chipBackground: Color(0xFF3A2B39),
    textPrimary: Color(0xFFF7F0EA),
    textSecondary: Color(0xFFC8B9C1),
    textTertiary: Color(0xFF9D8995),
    outline: Color(0xFF604D5B),
    outlineVariant: Color(0xFF423441),
    disabled: Color(0xFF493A46),
    primary: Color(0xFFE3B5C8),
    onPrimary: Color(0xFF3C2332),
    primaryContainer: Color(0xFF5A344B),
    onPrimaryContainer: Color(0xFFFFE8F1),
    secondary: Color(0xFFFFA080),
    onSecondary: Color(0xFF3A1E16),
    secondaryContainer: Color(0xFF713D2D),
    onSecondaryContainer: Color(0xFFFFE3D8),
    tertiary: Color(0xFFEAC979),
    onTertiary: Color(0xFF34270E),
  );
}
