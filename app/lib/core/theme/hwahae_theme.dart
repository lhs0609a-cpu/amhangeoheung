import 'package:flutter/material.dart';
import 'hwahae_colors.dart';
import 'hwahae_typography.dart';

/// 암행어흥 테마 시스템 - 힙하고 모던한 디자인
class HwahaeTheme {
  HwahaeTheme._();

  // === Border Radius ===
  static const double radiusXS = 6.0;
  static const double radiusSM = 10.0;
  static const double radiusMD = 14.0;
  static const double radiusLG = 18.0;
  static const double radiusXL = 24.0;
  static const double radiusXXL = 32.0;
  static const double radiusFull = 100.0;

  // === Spacing ===
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 12.0;
  static const double spacingLG = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 32.0;

  // === Shadow ===
  static List<BoxShadow> shadowSM = [
    BoxShadow(
      color: HwahaeColors.primary.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMD = [
    BoxShadow(
      color: HwahaeColors.primary.withOpacity(0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLG = [
    BoxShadow(
      color: HwahaeColors.primary.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> shadowXL = [
    BoxShadow(
      color: HwahaeColors.primary.withOpacity(0.12),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  // === Light Theme ===
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: HwahaeTypography.fontFamily,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: HwahaeColors.primary,
        primaryContainer: HwahaeColors.primaryContainer,
        secondary: HwahaeColors.secondary,
        secondaryContainer: HwahaeColors.secondaryContainer,
        tertiary: HwahaeColors.accent,
        tertiaryContainer: HwahaeColors.accentContainer,
        surface: HwahaeColors.surface,
        error: HwahaeColors.error,
        onPrimary: HwahaeColors.onPrimary,
        onSecondary: HwahaeColors.onSecondary,
        onSurface: HwahaeColors.textPrimary,
        onError: Colors.white,
        outline: HwahaeColors.border,
      ),

      // Scaffold
      scaffoldBackgroundColor: HwahaeColors.background,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: HwahaeColors.surface,
        foregroundColor: HwahaeColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: HwahaeTypography.titleMedium.copyWith(
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(
          color: HwahaeColors.textPrimary,
          size: 24,
        ),
        surfaceTintColor: Colors.transparent,
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: HwahaeColors.surface,
        selectedItemColor: HwahaeColors.primary,
        unselectedItemColor: HwahaeColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: HwahaeTypography.bottomNav,
        unselectedLabelStyle: HwahaeTypography.bottomNav,
      ),

      // Card
      cardTheme: CardTheme(
        color: HwahaeColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
        surfaceTintColor: Colors.transparent,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HwahaeColors.primary,
          foregroundColor: HwahaeColors.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: HwahaeTypography.button,
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HwahaeColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          side: const BorderSide(color: HwahaeColors.primary, width: 1.5),
          textStyle: HwahaeTypography.button,
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: HwahaeColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: HwahaeTypography.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSM),
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HwahaeColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: HwahaeColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: HwahaeColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: HwahaeColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: HwahaeTypography.bodyMedium.copyWith(
          color: HwahaeColors.textTertiary,
        ),
        prefixIconColor: HwahaeColors.textSecondary,
        suffixIconColor: HwahaeColors.textSecondary,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: HwahaeColors.surfaceVariant,
        selectedColor: HwahaeColors.primaryContainer,
        labelStyle: HwahaeTypography.chip,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        side: BorderSide.none,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: HwahaeColors.divider,
        thickness: 1,
        space: 1,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: HwahaeColors.textPrimary,
        contentTextStyle: HwahaeTypography.bodySmall.copyWith(
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        elevation: 0,
        insetPadding: const EdgeInsets.all(16),
      ),

      // Dialog
      dialogTheme: DialogTheme(
        backgroundColor: HwahaeColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
        titleTextStyle: HwahaeTypography.headlineSmall,
        contentTextStyle: HwahaeTypography.bodyMedium,
        surfaceTintColor: Colors.transparent,
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: HwahaeColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 0,
      ),

      // Tab Bar
      tabBarTheme: TabBarTheme(
        labelColor: HwahaeColors.primary,
        unselectedLabelColor: HwahaeColors.textSecondary,
        labelStyle: HwahaeTypography.labelLarge,
        unselectedLabelStyle: HwahaeTypography.labelMedium,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: HwahaeColors.primary, width: 3),
          borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: HwahaeColors.primary,
        linearTrackColor: HwahaeColors.surfaceVariant,
        circularTrackColor: HwahaeColors.surfaceVariant,
      ),

      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: HwahaeColors.primary,
        foregroundColor: HwahaeColors.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
      ),

      // ListTile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        titleTextStyle: HwahaeTypography.titleSmall,
        subtitleTextStyle: HwahaeTypography.captionMedium,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return HwahaeColors.onPrimary;
          }
          return HwahaeColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return HwahaeColors.primary;
          }
          return HwahaeColors.surfaceVariant;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return HwahaeColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(HwahaeColors.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: const BorderSide(color: HwahaeColors.border, width: 2),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return HwahaeColors.primary;
          }
          return HwahaeColors.textSecondary;
        }),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: HwahaeColors.primary,
        inactiveTrackColor: HwahaeColors.surfaceVariant,
        thumbColor: HwahaeColors.primary,
        overlayColor: HwahaeColors.primary.withOpacity(0.12),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: HwahaeColors.textPrimary,
        size: 24,
      ),

      // Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// 그라디언트 버튼 데코레이션
class GradientButtonDecoration extends BoxDecoration {
  GradientButtonDecoration({
    List<Color>? colors,
    double radius = HwahaeTheme.radiusMD,
  }) : super(
          gradient: LinearGradient(
            colors: colors ?? HwahaeColors.gradientPrimary,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(radius),
        );
}

/// 글래스모피즘 데코레이션
class GlassDecoration extends BoxDecoration {
  GlassDecoration({
    double blur = 10,
    double opacity = 0.1,
    double radius = HwahaeTheme.radiusLG,
    Color? borderColor,
  }) : super(
          color: Colors.white.withOpacity(opacity),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: borderColor ?? Colors.white.withOpacity(0.2),
            width: 1,
          ),
        );
}
