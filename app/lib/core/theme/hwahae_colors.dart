import 'package:flutter/material.dart';

/// 암행어흥 컬러 시스템 — 호랭이 털색과 먹색
///
/// 이름이 암행어사 + 어흥이니 색도 호랑이에서 가져온다. 다만 형광 노랑 + 검정은
/// 쓰지 않는다. 그 조합은 경고 테이프 색이고, 신뢰를 파는 제품이 입을 옷이 아니다.
/// 민화 까치호랑이의 실제 색인 황토·치자색을 쓰고, 그림 귀퉁이의 붉은 낙관을
/// 지적사항 색으로 삼는다.
///
/// - primary   호랭이 털 — 주 동작
/// - secondary 낙관 붉은색 — 감찰과 지적에만
/// - accent    풀색 — 개선이 확인된 항목
///
/// 먹색은 순검정(#000)이 아니라 따뜻한 갈색이다. 순검정은 차갑고, 차가우면
/// 귀엽지 않다.
class HwahaeColors {
  HwahaeColors._();

  // === Primary Colors - 호랭이 털 ===
  static const Color primary = Color(0xFFF2B33D);
  static const Color primaryLight = Color(0xFFF7C868);
  static const Color primaryDark = Color(0xFFD98E1F);
  static const Color primaryContainer = Color(0xFFFDEBC8);

  /// 골드 위의 글자는 흰색이 아니라 먹색이다. 흰색은 대비가 모자란다.
  static const Color onPrimary = Color(0xFF3D2E1F);

  // === Secondary/Accent - 낙관 붉은색 (감찰 · 지적) ===
  static const Color secondary = Color(0xFFD9482F);
  static const Color secondaryLight = Color(0xFFF5896F);
  static const Color secondaryDark = Color(0xFFB0341F);
  static const Color secondaryContainer = Color(0xFFFCE4DE);
  static const Color onSecondary = Color(0xFFFDF6E9);

  // === Accent - 풀색 (개선 확인) ===
  static const Color accent = Color(0xFF4E8C5B);
  static const Color accentLight = Color(0xFF7FBE93);
  static const Color accentDark = Color(0xFF3A6B44);
  static const Color accentContainer = Color(0xFFE4F0E4);

  // === Background & Surface - 크림 ===
  static const Color background = Color(0xFFFDF6E9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF6EAD3);
  static const Color surfaceContainer = Color(0xFFF0E2C6);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // === Text Colors - 먹 ===
  static const Color textPrimary = Color(0xFF3D2E1F);
  static const Color textSecondary = Color(0xFF7A6A55);
  static const Color textTertiary = Color(0xFFA89880);
  static const Color textDisabled = Color(0xFFD8C7A8);
  static const Color textOnDark = Color(0xFFFDF6E9);

  // === Status Colors ===
  static const Color success = Color(0xFF4E8C5B);
  static const Color successLight = Color(0xFFE4F0E4);
  static const Color warning = Color(0xFFD98E1F);
  static const Color warningLight = Color(0xFFFDEBC8);
  static const Color error = Color(0xFFD9482F);
  static const Color errorLight = Color(0xFFFCE4DE);

  /// 파란 info 는 쓰지 않는다. 팔레트에서 유일하게 튀는 색이 되기 때문에
  /// 중립 정보는 따뜻한 회갈색으로 처리한다.
  static const Color info = Color(0xFF7A6A55);
  static const Color infoLight = Color(0xFFF6EAD3);

  // === Grade Colors (리뷰어 등급) ===
  static const Color gradeRookie = Color(0xFFC4B69C);
  static const Color gradeBronze = Color(0xFFB0700F);
  static const Color gradeSilver = Color(0xFFA89880);
  static const Color gradeGold = Color(0xFFF2B33D);
  static const Color gradePlatinum = Color(0xFF4E8C5B);
  static const Color gradeDiamond = Color(0xFFD9482F);

  // === Mission Type Colors (미션 유형) ===
  static const Color missionRegular = Color(0xFF7A6A55);
  static const Color missionHidden = Color(0xFF3D2E1F);
  static const Color missionSeason = Color(0xFFD9482F);
  static const Color missionUrgent = Color(0xFFB0341F);
  static const Color missionPremium = Color(0xFFF2B33D);

  // === Rating Semantic Colors ===
  static const Color ratingExcellent = Color(0xFF4E8C5B);    // 4.5+
  static const Color ratingGood = Color(0xFFF2B33D);         // 3.5~4.4
  static const Color ratingAverage = Color(0xFFD98E1F);      // 3.0~3.4
  static const Color ratingPoor = Color(0xFFD9482F);         // 3.0 미만

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
  static const Color divider = Color(0xFFE8D9BC);
  static const Color border = Color(0xFFE8D9BC);
  static const Color borderLight = Color(0xFFF0E2C6);
  static const Color borderFocused = Color(0xFFF2B33D);

  // === Rating Colors ===
  static const Color ratingStar = Color(0xFFF2B33D);
  static const Color ratingStarEmpty = Color(0xFFE8D9BC);

  // === 인장 · 캐릭터 ===
  /// 감찰 인장의 붉은색과 그 배경. 감찰이 끝난 업체에만 찍힌다.
  static const Color sealInk = Color(0xFFD9482F);
  static const Color sealBackground = Color(0xFFFCE4DE);

  /// 어흥이 몸통과 귀 안쪽. 캐릭터를 그릴 때만 쓴다.
  static const Color tigerFur = Color(0xFFF2B33D);
  static const Color tigerEar = Color(0xFFE09A28);
  static const Color tigerBlush = Color(0xFFF5896F);
  static const Color tigerMuzzle = Color(0xFFFDF6E9);
  static const Color satoSkin = Color(0xFFF7DFC0);

  /// 스티커 그림자. 흐리지 않고 아래로 3px 딱 떨어뜨린다.
  static const Color stickerShadow = Color(0xFFE8D9BC);
  static const Color stickerShadowPrimary = Color(0xFFD98E1F);
  static const Color stickerShadowDark = Color(0xFF241A11);

  // === Gradient Colors ===
  // 새 시스템은 그라디언트를 쓰지 않는다. 남아 있는 호출부가 깨지지 않도록
  // 값만 남기되, 두 색의 차이를 좁혀 사실상 평면으로 보이게 한다.
  static const List<Color> gradientPrimary = [
    Color(0xFFF2B33D),
    Color(0xFFE5A32C),
  ];

  static const List<Color> gradientAccent = [
    Color(0xFF4E8C5B),
    Color(0xFF3A6B44),
  ];

  static const List<Color> gradientWarm = [
    Color(0xFFF2B33D),
    Color(0xFFE08A3C),
  ];

  static const List<Color> gradientCool = [
    Color(0xFF7A6A55),
    Color(0xFF3D2E1F),
  ];

  static const List<Color> gradientSunset = [
    Color(0xFFF5896F),
    Color(0xFFD9482F),
  ];

  static const List<Color> gradientOcean = [
    Color(0xFFF7C868),
    Color(0xFFF2B33D),
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
        return gradeDiamond.withValues(alpha: 0.12);
      case 'platinum':
        return gradePlatinum.withValues(alpha: 0.12);
      case 'gold':
        return gradeGold.withValues(alpha: 0.12);
      case 'silver':
        return gradeSilver.withValues(alpha: 0.12);
      case 'bronze':
        return gradeBronze.withValues(alpha: 0.12);
      default:
        return gradeRookie.withValues(alpha: 0.08);
    }
  }

  /// 등급별 그라디언트 반환
  static List<Color> getGradeGradient(String grade) {
    switch (grade.toLowerCase()) {
      case 'diamond':
        return [const Color(0xFFD9482F), const Color(0xFFF5896F)];
      case 'platinum':
        return [const Color(0xFF4E8C5B), const Color(0xFF7FBE93)];
      case 'gold':
        return [const Color(0xFFF2B33D), const Color(0xFFF7C868)];
      case 'silver':
        return [const Color(0xFFA89880), const Color(0xFFC4B69C)];
      case 'bronze':
        return [const Color(0xFFB0700F), const Color(0xFFD98E1F)];
      default:
        return [const Color(0xFFC4B69C), const Color(0xFFD8C7A8)];
    }
  }
}
