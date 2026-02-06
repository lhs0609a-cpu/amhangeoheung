import 'package:flutter/material.dart';

// Hwahae 테마 시스템 re-export
export 'hwahae_colors.dart';
export 'hwahae_typography.dart';
export 'hwahae_theme.dart';

import 'hwahae_colors.dart';
import 'hwahae_theme.dart';

/// AppColors - HwahaeColors에 대한 별칭 (하위 호환성)
/// 기존 코드에서 AppColors를 사용하는 부분을 위해 유지
class AppColors {
  AppColors._();

  // Primary Colors - 민트 그린 (화해 시그니처)
  static const Color primary = HwahaeColors.primary;
  static const Color primaryLight = HwahaeColors.primaryLight;
  static const Color primaryDark = HwahaeColors.primaryDark;
  static const Color onPrimary = HwahaeColors.onPrimary;

  // Secondary Colors
  static const Color secondary = HwahaeColors.secondary;
  static const Color secondaryLight = HwahaeColors.secondaryLight;

  // Background Colors
  static const Color background = HwahaeColors.background;
  static const Color surface = HwahaeColors.surface;
  static const Color surfaceVariant = HwahaeColors.surfaceVariant;

  // Text Colors
  static const Color textPrimary = HwahaeColors.textPrimary;
  static const Color textSecondary = HwahaeColors.textSecondary;
  static const Color textTertiary = HwahaeColors.textTertiary;

  // Status Colors
  static const Color success = HwahaeColors.success;
  static const Color warning = HwahaeColors.warning;
  static const Color error = HwahaeColors.error;
  static const Color info = HwahaeColors.info;

  // Badge Colors (리뷰어 등급)
  static const Color badgeBronze = HwahaeColors.gradeBronze;
  static const Color badgeSilver = HwahaeColors.gradeSilver;
  static const Color badgeGold = HwahaeColors.gradeGold;
  static const Color badgePlatinum = HwahaeColors.gradePlatinum;

  // Divider & Border
  static const Color divider = HwahaeColors.divider;
  static const Color border = HwahaeColors.border;
}

/// AppTheme - HwahaeTheme에 대한 별칭 (하위 호환성)
class AppTheme {
  static ThemeData get lightTheme => HwahaeTheme.lightTheme;
}
