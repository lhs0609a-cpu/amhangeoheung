import 'package:flutter/material.dart';

/// 암행어흥 컬러 시스템 - 먹색·한지·호랑이·주홍 인장
class HwahaeColors {
  HwahaeColors._();

  // === Primary Colors - 먹색 ===
  static const Color primary = Color(0xFF253A35);
  static const Color primaryLight = Color(0xFF496158);
  static const Color primaryDark = Color(0xFF182523);
  static const Color primaryContainer = Color(0xFFEEE8DC);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // === Secondary/Accent - 절제된 녹청 ===
  static const Color secondary = Color(0xFF253A35);
  static const Color secondaryLight = Color(0xFFD7B875);
  static const Color secondaryDark = Color(0xFF182523);
  static const Color secondaryContainer = Color(0xFFF4E7C8);
  static const Color onSecondary = Color(0xFF0A0A0A);

  // === Accent - 주홍 인장 ===
  static const Color accent = Color(0xFFBC4938);
  static const Color accentLight = Color(0xFFD3755F);
  static const Color accentDark = Color(0xFF913626);
  static const Color accentContainer = Color(0xFFF9E8E0);

  // === Background & Surface ===
  static const Color background = Color(0xFFF8F3E8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0EADF);
  static const Color surfaceContainer = Color(0xFFE8DFD0);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // === Text Colors ===
  static const Color textPrimary = Color(0xFF182523);
  static const Color textSecondary = Color(0xFF6A685F);
  static const Color textTertiary = Color(0xFF78736A);
  static const Color textDisabled = Color(0xFFD0D0D8);
  static const Color textOnDark = Color(0xFFF8F3E8);

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
  static const Color missionRegular = Color(0xFF3B82F6); // 일반 미션 - 블루
  static const Color missionHidden = Color(0xFF8B5CF6); // 히든 미션 - 퍼플
  static const Color missionSeason = Color(0xFFEC4899); // 시즌 미션 - 핑크
  static const Color missionUrgent = Color(0xFFEF4444); // 긴급 미션 - 레드
  static const Color missionPremium = Color(0xFFF59E0B); // 프리미엄 미션 - 골드

  // === Rating Semantic Colors ===
  static const Color ratingExcellent = Color(0xFF10B981); // 4.5+ 녹색
  static const Color ratingGood = Color(0xFFF59E0B); // 3.5~4.4 골드
  static const Color ratingAverage = Color(0xFFF97316); // 3.0~3.4 주황
  static const Color ratingPoor = Color(0xFFEF4444); // 3.0 미만 빨강

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
  static const Color divider = Color(0xFFE8DFD0);
  static const Color border = Color(0xFFDED4C4);
  static const Color borderLight = Color(0xFFF0F4F2);
  static const Color borderFocused = Color(0xFF253A35);

  // === Rating Colors ===
  static const Color ratingStar = Color(0xFFFBBF24);
  static const Color ratingStarEmpty = Color(0xFFE5E7EB);

  // === Gradient Colors ===
  static const List<Color> gradientPrimary = [
    Color(0xFF253A35),
    Color(0xFF496158),
  ];

  static const List<Color> gradientAccent = [
    Color(0xFF253A35),
    Color(0xFF157A83),
  ];

  static const List<Color> gradientWarm = [
    Color(0xFFBC4938),
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
