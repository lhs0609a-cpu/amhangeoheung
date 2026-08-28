import 'package:flutter/material.dart';

/// 암행어흥 다크 모드 컬러 시스템 — 밤의 호랭이
///
/// 라이트 모드의 크림/먹을 뒤집되, 순검정 바탕은 쓰지 않는다. 먹색을 더 진하게
/// 내린 갈색 바탕이라야 호랭이 털색이 위에서 살아난다. 순검정 위의 금색은
/// 싸구려 금박처럼 보인다.
class DarkThemeColors {
  DarkThemeColors._();

  // === Primary Colors - 호랭이 털 (어두운 바탕에서 살짝 밝게) ===
  static const Color primary = Color(0xFFF7C868);
  static const Color primaryLight = Color(0xFFFAD98F);
  static const Color primaryDark = Color(0xFFF2B33D);
  static const Color primaryContainer = Color(0xFF4C3A27);
  static const Color onPrimary = Color(0xFF241A11);

  // === Secondary/Accent - 낙관 붉은색 (감찰 · 지적) ===
  static const Color secondary = Color(0xFFF5896F);
  static const Color secondaryLight = Color(0xFFFAA894);
  static const Color secondaryDark = Color(0xFFD9482F);
  static const Color secondaryContainer = Color(0xFF4A2A22);
  static const Color onSecondary = Color(0xFF241A11);

  // === Accent - 풀색 (개선 확인) ===
  static const Color accent = Color(0xFF7FBE93);
  static const Color accentLight = Color(0xFF9FD1AF);
  static const Color accentDark = Color(0xFF4E8C5B);
  static const Color accentContainer = Color(0xFF27402D);

  // === Background & Surface - 밤의 먹 ===
  static const Color background = Color(0xFF201810);
  static const Color surface = Color(0xFF2C2116);
  static const Color surfaceVariant = Color(0xFF3D2E1F);
  static const Color surfaceContainer = Color(0xFF352819);
  static const Color surfaceElevated = Color(0xFF4C3A27);

  // === Text Colors ===
  static const Color textPrimary = Color(0xFFFDF6E9);
  static const Color textSecondary = Color(0xFFCBBB9E);
  static const Color textTertiary = Color(0xFFA89880);
  static const Color textDisabled = Color(0xFF6B5540);
  static const Color textOnDark = Color(0xFFFDF6E9);

  // === Status Colors (다크 모드에서 더 밝게) ===
  static const Color success = Color(0xFF7FBE93);
  static const Color successLight = Color(0xFF27402D);
  static const Color warning = Color(0xFFF7C868);
  static const Color warningLight = Color(0xFF4C3A27);
  static const Color error = Color(0xFFF5896F);
  static const Color errorLight = Color(0xFF4A2A22);
  static const Color info = Color(0xFFCBBB9E);
  static const Color infoLight = Color(0xFF3D2E1F);

  // === Border & Divider ===
  static const Color divider = Color(0xFF3D2E1F);
  static const Color border = Color(0xFF54402B);
  static const Color borderLight = Color(0xFF6B5540);
  static const Color borderFocused = Color(0xFFF7C868);

  // === Rating Colors ===
  static const Color ratingStar = Color(0xFFF7C868);
  static const Color ratingStarEmpty = Color(0xFF54402B);

  // === 인장 · 캐릭터 ===
  static const Color sealInk = Color(0xFFF5896F);
  static const Color sealBackground = Color(0xFF4A2A22);
  static const Color tigerFur = Color(0xFFF2B33D);
  static const Color tigerEar = Color(0xFFE09A28);
  static const Color tigerBlush = Color(0xFFF5896F);
  static const Color tigerMuzzle = Color(0xFFFDF6E9);
  static const Color satoSkin = Color(0xFFF7DFC0);

  // === Gradient Colors (다크 모드용) ===
  static const List<Color> gradientPrimary = [
    Color(0xFFF7C868),
    Color(0xFFF2B33D),
  ];

  static const List<Color> gradientAccent = [
    Color(0xFF7FBE93),
    Color(0xFF4E8C5B),
  ];

  static const List<Color> gradientWarm = [
    Color(0xFFF7C868),
    Color(0xFFF5896F),
  ];

  static const List<Color> gradientCool = [
    Color(0xFFCBBB9E),
    Color(0xFF7A6A55),
  ];

  // === Card Elevation Shadow ===
  static const Color cardShadow = Color(0x33241A11);
}
