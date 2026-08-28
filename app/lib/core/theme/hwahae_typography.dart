import 'package:flutter/material.dart';
import 'hwahae_colors.dart';

/// 암행어흥 타이포그래피 시스템 - 모던하고 힙한 스타일
class HwahaeTypography {
  HwahaeTypography._();

  // === Font Family ===
  /// 표시 서체 — 제목 · 숫자 · 어흥이 말투. 둥글어서 친근하다.
  /// pubspec 에 번들된 유일한 서체다.
  static const String fontFamilyDisplay = 'Jua';

  /// 본문 서체는 시스템 한글 서체를 그대로 쓴다(null = 플랫폼 기본).
  /// 한글 본문 서체는 웨이트당 5MB 가까이 되어 번들이 감당되지 않고,
  /// 지적사항처럼 또렷해야 하는 곳에는 시스템 서체가 오히려 낫다.
  ///
  /// 이전에는 'Pretendard' 로 선언돼 있었지만 자산이 없어 조용히 폴백되고
  /// 있었다. 없는 서체를 선언하느니 시스템 서체를 명시한다.
  static const String? fontFamily = null;

  static const String fontFamilyMono = 'JetBrains Mono';

  // === Display - 대형 제목 ===
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 40,
    fontWeight: FontWeight.w400,
    height: 1.15,
    letterSpacing: -0.75,
    color: HwahaeColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    height: 1.2,
    letterSpacing: -0.5,
    color: HwahaeColors.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 28,
    fontWeight: FontWeight.w400,
    height: 1.25,
    letterSpacing: -0.38,
    color: HwahaeColors.textPrimary,
  );

  // === Headline - 중형 제목 ===
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: -0.25,
    color: HwahaeColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: -0.2,
    color: HwahaeColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: -0.15,
    color: HwahaeColors.textPrimary,
  );

  // === Title - 소형 제목 ===
  static const TextStyle titleLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.2,
    color: HwahaeColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.45,
    letterSpacing: -0.15,
    color: HwahaeColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.45,
    letterSpacing: -0.1,
    color: HwahaeColors.textPrimary,
  );

  // === Body - 본문 ===
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0,
    color: HwahaeColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.55,
    letterSpacing: 0,
    color: HwahaeColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,
    color: HwahaeColors.textPrimary,
  );

  // === Label - 라벨 ===
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.2,
    color: HwahaeColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.15,
    color: HwahaeColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
    color: HwahaeColors.textPrimary,
  );

  // === Caption - 캡션 ===
  static const TextStyle captionLarge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.15,
    color: HwahaeColors.textSecondary,
  );

  static const TextStyle captionMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.1,
    color: HwahaeColors.textSecondary,
  );

  static const TextStyle captionSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: 0.1,
    color: HwahaeColors.textSecondary,
  );

  // === Special Styles ===
  static const TextStyle badge = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.2,
    letterSpacing: 0.5,
    color: HwahaeColors.textPrimary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.2,
    letterSpacing: 0.2,
    color: HwahaeColors.textPrimary,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.2,
    letterSpacing: 0.2,
    color: HwahaeColors.textPrimary,
  );

  static const TextStyle price = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1.2,
    letterSpacing: -0.25,
    color: HwahaeColors.textPrimary,
  );

  static const TextStyle priceSmall = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.25,
    letterSpacing: -0.15,
    color: HwahaeColors.textPrimary,
  );

  static const TextStyle bottomNav = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.2,
    letterSpacing: 0.1,
    color: HwahaeColors.textSecondary,
  );

  static const TextStyle chip = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: 0.1,
    color: HwahaeColors.textPrimary,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 1.5,
    color: HwahaeColors.textSecondary,
  );

  static const TextStyle mono = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0,
    fontFamily: fontFamilyMono,
    color: HwahaeColors.textPrimary,
  );
}
