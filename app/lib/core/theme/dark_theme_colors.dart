import 'package:flutter/material.dart';

/// 암행어흥 다크 모드 컬러 시스템
class DarkThemeColors {
  DarkThemeColors._();

  // === Primary Colors - 딥 바이올렛 (밝게 조정) ===
  static const Color primary = Color(0xFF8B7CF6);
  static const Color primaryLight = Color(0xFFA09AFF);
  static const Color primaryDark = Color(0xFF6C5CE7);
  static const Color primaryContainer = Color(0xFF2D2A4A);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // === Secondary/Accent - 네온 민트 ===
  static const Color secondary = Color(0xFF5EEAD4);
  static const Color secondaryLight = Color(0xFF7EEFC9);
  static const Color secondaryDark = Color(0xFF00D4AA);
  static const Color secondaryContainer = Color(0xFF1A3A35);
  static const Color onSecondary = Color(0xFF0A0A0A);

  // === Accent - 핫핑크 ===
  static const Color accent = Color(0xFFFF8FB3);
  static const Color accentLight = Color(0xFFFFABC8);
  static const Color accentDark = Color(0xFFFF6B9D);
  static const Color accentContainer = Color(0xFF3A2533);

  // === Background & Surface ===
  static const Color background = Color(0xFF0F0F14);
  static const Color surface = Color(0xFF1A1A24);
  static const Color surfaceVariant = Color(0xFF252532);
  static const Color surfaceContainer = Color(0xFF1F1F2C);
  static const Color surfaceElevated = Color(0xFF2A2A38);

  // === Text Colors ===
  static const Color textPrimary = Color(0xFFF0F0F8);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textTertiary = Color(0xFF707080);
  static const Color textDisabled = Color(0xFF505060);
  static const Color textOnDark = Color(0xFFFAFAFC);

  // === Status Colors (다크 모드에서 더 밝게) ===
  static const Color success = Color(0xFF34D399);
  static const Color successLight = Color(0xFF1A3A30);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningLight = Color(0xFF3A3520);
  static const Color error = Color(0xFFF87171);
  static const Color errorLight = Color(0xFF3A2525);
  static const Color info = Color(0xFF60A5FA);
  static const Color infoLight = Color(0xFF1E3A5F);

  // === Border & Divider ===
  static const Color divider = Color(0xFF2A2A38);
  static const Color border = Color(0xFF353545);
  static const Color borderLight = Color(0xFF404055);
  static const Color borderFocused = Color(0xFF8B7CF6);

  // === Rating Colors ===
  static const Color ratingStar = Color(0xFFFBBF24);
  static const Color ratingStarEmpty = Color(0xFF404050);

  // === Gradient Colors (다크 모드용) ===
  static const List<Color> gradientPrimary = [
    Color(0xFF8B7CF6),
    Color(0xFFA78BFA),
  ];

  static const List<Color> gradientAccent = [
    Color(0xFF5EEAD4),
    Color(0xFF38BDF8),
  ];

  static const List<Color> gradientWarm = [
    Color(0xFFFF8FB3),
    Color(0xFFFFA071),
  ];

  static const List<Color> gradientCool = [
    Color(0xFF818CF8),
    Color(0xFFA78BFA),
  ];

  // === Card Elevation Shadow ===
  static const Color cardShadow = Color(0x20000000);
}
