import 'package:flutter/material.dart';

/// 암행어흥 컬러 시스템 - 힙하고 모던한 테마
class HwahaeColors {
  HwahaeColors._();

  // === Primary Colors - 딥 바이올렛 ===
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFF8B7CF6);
  static const Color primaryDark = Color(0xFF5541D9);
  static const Color primaryContainer = Color(0xFFF0EEFF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // === Secondary/Accent - 네온 민트 ===
  static const Color secondary = Color(0xFF00D4AA);
  static const Color secondaryLight = Color(0xFF5EEAD4);
  static const Color secondaryDark = Color(0xFF00B894);
  static const Color secondaryContainer = Color(0xFFE6FBF6);
  static const Color onSecondary = Color(0xFF0A0A0A);

  // === Accent - 핫핑크 ===
  static const Color accent = Color(0xFFFF6B9D);
  static const Color accentLight = Color(0xFFFF8FB3);
  static const Color accentDark = Color(0xFFE84A7F);
  static const Color accentContainer = Color(0xFFFFF0F5);

  // === Background & Surface ===
  static const Color background = Color(0xFFFAFAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF4F4F8);
  static const Color surfaceContainer = Color(0xFFEEEEF2);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // === Text Colors ===
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B6B80);
  static const Color textTertiary = Color(0xFF8E8E9E);
  static const Color textDisabled = Color(0xFFD0D0D8);
  static const Color textOnDark = Color(0xFFFAFAFC);

  // === Status Colors ===
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // === Grade Colors (리뷰어 등급) ===
  static const Color gradeRookie = Color(0xFFD1D5DB); // 연회색 (새싹)
  static const Color gradeBronze = Color(0xFFD97706);
  static const Color gradeSilver = Color(0xFFC0C0C0); // 은빛
  static const Color gradeGold = Color(0xFFF59E0B);
  static const Color gradePlatinum = Color(0xFF06B6D4);
  static const Color gradeDiamond = Color(0xFF8B5CF6);

  // === Mission Type Colors (미션 유형) ===
  static const Color missionRegular = Color(0xFF3B82F6);     // 일반 미션 - 블루
  static const Color missionHidden = Color(0xFF8B5CF6);      // 히든 미션 - 퍼플
  static const Color missionSeason = Color(0xFFEC4899);      // 시즌 미션 - 핑크
  static const Color missionUrgent = Color(0xFFEF4444);      // 긴급 미션 - 레드
  static const Color missionPremium = Color(0xFFF59E0B);     // 프리미엄 미션 - 골드

  // === Rating Semantic Colors ===
  static const Color ratingExcellent = Color(0xFF10B981);    // 4.5+ 녹색
  static const Color ratingGood = Color(0xFFF59E0B);         // 3.5~4.4 골드
  static const Color ratingAverage = Color(0xFFF97316);      // 3.0~3.4 주황
  static const Color ratingPoor = Color(0xFFEF4444);         // 3.0 미만 빨강

  /// 평점에 따른 시맨틱 색상 반환
  static Color getRatingColor(double rating) {
    if (rating >= 4.5) return ratingExcellent;
    if (rating >= 3.5) return ratingGood;
    if (rating >= 3.0) return ratingAverage;
    return ratingPoor;
  }

  /// 미션 유형별 색상 반환
  static Color getMissionTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'hidden':
        return missionHidden;
      case 'season':
        return missionSeason;
      case 'urgent':
        return missionUrgent;
      case 'premium':
        return missionPremium;
      default:
        return missionRegular;
    }
  }

  // === Border & Divider ===
  static const Color divider = Color(0xFFE8E8EE);
  static const Color border = Color(0xFFE2E2EA);
  static const Color borderLight = Color(0xFFF0F0F4);
  static const Color borderFocused = Color(0xFF6C5CE7);

  // === Rating Colors ===
  static const Color ratingStar = Color(0xFFFBBF24);
  static const Color ratingStarEmpty = Color(0xFFE5E7EB);

  // === Gradient Colors ===
  static const List<Color> gradientPrimary = [
    Color(0xFF6C5CE7),
    Color(0xFF8B5CF6),
  ];

  static const List<Color> gradientAccent = [
    Color(0xFF00D4AA),
    Color(0xFF00B4D8),
  ];

  static const List<Color> gradientWarm = [
    Color(0xFFFF6B9D),
    Color(0xFFFF8E53),
  ];

  static const List<Color> gradientCool = [
    Color(0xFF667EEA),
    Color(0xFF764BA2),
  ];

  static const List<Color> gradientSunset = [
    Color(0xFFF093FB),
    Color(0xFFF5576C),
  ];

  static const List<Color> gradientOcean = [
    Color(0xFF4FACFE),
    Color(0xFF00F2FE),
  ];

  /// 등급별 색상 반환
  static Color getGradeColor(String grade) {
    switch (grade.toLowerCase()) {
      case 'diamond':
        return gradeDiamond;
      case 'platinum':
        return gradePlatinum;
      case 'gold':
        return gradeGold;
      case 'silver':
        return gradeSilver;
      case 'bronze':
        return gradeBronze;
      default:
        return gradeRookie;
    }
  }

  /// 등급별 배경 색상 반환
  static Color getGradeBackgroundColor(String grade) {
    switch (grade.toLowerCase()) {
      case 'diamond':
        return gradeDiamond.withOpacity(0.12);
      case 'platinum':
        return gradePlatinum.withOpacity(0.12);
      case 'gold':
        return gradeGold.withOpacity(0.12);
      case 'silver':
        return gradeSilver.withOpacity(0.12);
      case 'bronze':
        return gradeBronze.withOpacity(0.12);
      default:
        return gradeRookie.withOpacity(0.08);
    }
  }

  /// 등급별 그라디언트 반환
  static List<Color> getGradeGradient(String grade) {
    switch (grade.toLowerCase()) {
      case 'diamond':
        return [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)];
      case 'platinum':
        return [const Color(0xFF06B6D4), const Color(0xFF22D3EE)];
      case 'gold':
        return [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
      case 'silver':
        return [const Color(0xFFA8A8B3), const Color(0xFFC0C0C0)];
      case 'bronze':
        return [const Color(0xFFD97706), const Color(0xFFF59E0B)];
      default:
        return [const Color(0xFFBBBBC5), const Color(0xFFD1D5DB)];
    }
  }
}
