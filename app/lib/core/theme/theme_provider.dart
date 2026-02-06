import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hwahae_colors.dart';
import 'dark_theme_colors.dart';
import 'hwahae_typography.dart';

/// 테마 모드
enum AppThemeMode {
  light,
  dark,
  system,
}

/// 테마 상태
class ThemeState {
  final AppThemeMode mode;
  final ThemeData lightTheme;
  final ThemeData darkTheme;

  ThemeState({
    required this.mode,
    required this.lightTheme,
    required this.darkTheme,
  });

  /// 현재 적용해야 할 테마
  ThemeData get currentTheme {
    switch (mode) {
      case AppThemeMode.light:
        return lightTheme;
      case AppThemeMode.dark:
        return darkTheme;
      case AppThemeMode.system:
        final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.dark ? darkTheme : lightTheme;
    }
  }

  /// 다크 모드 여부
  bool get isDarkMode {
    switch (mode) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.system:
        final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.dark;
    }
  }

  ThemeState copyWith({
    AppThemeMode? mode,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
    );
  }
}

/// 테마 노티파이어
class ThemeNotifier extends StateNotifier<ThemeState> {
  static const String _themeKey = 'app_theme_mode';

  ThemeNotifier()
      : super(ThemeState(
          mode: AppThemeMode.system,
          lightTheme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
        )) {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themeKey);

    if (savedMode != null) {
      final mode = AppThemeMode.values.firstWhere(
        (e) => e.name == savedMode,
        orElse: () => AppThemeMode.system,
      );
      state = state.copyWith(mode: mode);
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  void toggleTheme() {
    final newMode = state.mode == AppThemeMode.dark
        ? AppThemeMode.light
        : AppThemeMode.dark;
    setThemeMode(newMode);
  }

  /// 라이트 테마 빌드
  static ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: HwahaeColors.primary,
        onPrimary: HwahaeColors.onPrimary,
        primaryContainer: HwahaeColors.primaryContainer,
        secondary: HwahaeColors.secondary,
        onSecondary: HwahaeColors.onSecondary,
        secondaryContainer: HwahaeColors.secondaryContainer,
        surface: HwahaeColors.surface,
        error: HwahaeColors.error,
      ),
      scaffoldBackgroundColor: HwahaeColors.background,
      cardColor: HwahaeColors.surface,
      dividerColor: HwahaeColors.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: HwahaeColors.surface,
        foregroundColor: HwahaeColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: HwahaeTypography.titleMedium.copyWith(
          color: HwahaeColors.textPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: HwahaeColors.surface,
        selectedItemColor: HwahaeColors.primary,
        unselectedItemColor: HwahaeColors.textTertiary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HwahaeColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HwahaeColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HwahaeColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HwahaeColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HwahaeColors.error),
        ),
        hintStyle: HwahaeTypography.bodyMedium.copyWith(
          color: HwahaeColors.textTertiary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HwahaeColors.primary,
          foregroundColor: HwahaeColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HwahaeColors.primary,
          side: BorderSide(color: HwahaeColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: HwahaeColors.primary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: HwahaeColors.surfaceVariant,
        selectedColor: HwahaeColors.primaryContainer,
        labelStyle: HwahaeTypography.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: HwahaeColors.textPrimary,
        contentTextStyle: HwahaeTypography.bodyMedium.copyWith(
          color: HwahaeColors.textOnDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: HwahaeColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: HwahaeColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  /// 다크 테마 빌드
  static ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: DarkThemeColors.primary,
        onPrimary: DarkThemeColors.onPrimary,
        primaryContainer: DarkThemeColors.primaryContainer,
        secondary: DarkThemeColors.secondary,
        onSecondary: DarkThemeColors.onSecondary,
        secondaryContainer: DarkThemeColors.secondaryContainer,
        surface: DarkThemeColors.surface,
        error: DarkThemeColors.error,
      ),
      scaffoldBackgroundColor: DarkThemeColors.background,
      cardColor: DarkThemeColors.surface,
      dividerColor: DarkThemeColors.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: DarkThemeColors.surface,
        foregroundColor: DarkThemeColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: HwahaeTypography.titleMedium.copyWith(
          color: DarkThemeColors.textPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: DarkThemeColors.surface,
        selectedItemColor: DarkThemeColors.primary,
        unselectedItemColor: DarkThemeColors.textTertiary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DarkThemeColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DarkThemeColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DarkThemeColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DarkThemeColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DarkThemeColors.error),
        ),
        hintStyle: HwahaeTypography.bodyMedium.copyWith(
          color: DarkThemeColors.textTertiary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DarkThemeColors.primary,
          foregroundColor: DarkThemeColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DarkThemeColors.primary,
          side: BorderSide(color: DarkThemeColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DarkThemeColors.primary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: DarkThemeColors.surfaceVariant,
        selectedColor: DarkThemeColors.primaryContainer,
        labelStyle: HwahaeTypography.labelMedium.copyWith(
          color: DarkThemeColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DarkThemeColors.surfaceElevated,
        contentTextStyle: HwahaeTypography.bodyMedium.copyWith(
          color: DarkThemeColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: DarkThemeColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: DarkThemeColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}

/// 테마 프로바이더
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});
