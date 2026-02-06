import 'package:flutter/material.dart';
import '../theme/hwahae_colors.dart';

/// 리뷰어 등급 시스템
/// 등급별 혜택, 요건, 특권을 정의
class ReviewerGrades {
  /// 등급 목록 (낮은 순서)
  static const List<String> orderedGrades = ['rookie', 'regular', 'senior', 'master'];

  /// 등급 정보 조회
  static ReviewerGradeInfo getGradeInfo(String grade) {
    return _gradeInfoMap[grade] ?? _gradeInfoMap['rookie']!;
  }

  /// 다음 등급 정보 조회
  static ReviewerGradeInfo? getNextGrade(String currentGrade) {
    final currentIndex = orderedGrades.indexOf(currentGrade);
    if (currentIndex < 0 || currentIndex >= orderedGrades.length - 1) {
      return null;
    }
    return getGradeInfo(orderedGrades[currentIndex + 1]);
  }

  /// 등급 업그레이드 진행률 계산
  static double calculateProgress(String grade, int completedMissions, double trustScore) {
    final nextGrade = getNextGrade(grade);
    if (nextGrade == null) return 1.0; // 최고 등급

    final current = getGradeInfo(grade);
    final missionProgress = (completedMissions - current.requiredMissions) /
        (nextGrade.requiredMissions - current.requiredMissions);
    final trustProgress = (trustScore - current.requiredTrustScore) /
        (nextGrade.requiredTrustScore - current.requiredTrustScore);

    return ((missionProgress + trustProgress) / 2).clamp(0.0, 1.0);
  }

  static final Map<String, ReviewerGradeInfo> _gradeInfoMap = {
    'rookie': ReviewerGradeInfo(
      grade: 'rookie',
      label: '루키',
      description: '암행어흥에 오신 것을 환영합니다!',
      icon: Icons.emoji_people_rounded,
      colors: [const Color(0xFF94A3B8), const Color(0xFF64748B)],
      requiredMissions: 0,
      requiredTrustScore: 0,
      benefits: [
        GradeBenefit(
          icon: Icons.flag_rounded,
          title: '기본 미션 참여',
          description: '일반 미션에 참여할 수 있어요',
        ),
        GradeBenefit(
          icon: Icons.school_rounded,
          title: '튜토리얼 미션',
          description: '리뷰 작성 방법을 배워요',
        ),
        GradeBenefit(
          icon: Icons.support_agent_rounded,
          title: '기본 고객 지원',
          description: '이메일 문의 가능',
        ),
      ],
      restrictions: [
        '프리미엄 미션 참여 불가',
        '우선 배정 혜택 없음',
        '보상 기본 요율 적용',
      ],
    ),
    'regular': ReviewerGradeInfo(
      grade: 'regular',
      label: '레귤러',
      description: '믿을 수 있는 리뷰어로 성장했어요!',
      icon: Icons.verified_rounded,
      colors: HwahaeColors.gradientPrimary,
      requiredMissions: 5,
      requiredTrustScore: 3.5,
      benefits: [
        GradeBenefit(
          icon: Icons.flag_rounded,
          title: '모든 일반 미션',
          description: '모든 일반 미션에 참여 가능',
        ),
        GradeBenefit(
          icon: Icons.add_circle_rounded,
          title: '보상 +10%',
          description: '기본 보상에 10% 추가 지급',
          isHighlighted: true,
        ),
        GradeBenefit(
          icon: Icons.access_time_rounded,
          title: '빠른 정산',
          description: '정산 소요 시간 단축',
        ),
        GradeBenefit(
          icon: Icons.phone_rounded,
          title: '채팅 고객 지원',
          description: '실시간 채팅 상담 가능',
        ),
      ],
      restrictions: [
        'VIP 미션 참여 제한',
        '우선 배정 혜택 없음',
      ],
      unlockMessage: '5개 미션 완료 + 신뢰도 3.5점 이상',
    ),
    'senior': ReviewerGradeInfo(
      grade: 'senior',
      label: '시니어',
      description: '전문 리뷰어의 길을 걷고 있어요!',
      icon: Icons.workspace_premium_rounded,
      colors: HwahaeColors.gradientWarm,
      requiredMissions: 20,
      requiredTrustScore: 4.0,
      benefits: [
        GradeBenefit(
          icon: Icons.star_rounded,
          title: 'VIP 미션 참여',
          description: '고보상 VIP 미션 참여 가능',
          isHighlighted: true,
        ),
        GradeBenefit(
          icon: Icons.add_circle_rounded,
          title: '보상 +20%',
          description: '기본 보상에 20% 추가 지급',
          isHighlighted: true,
        ),
        GradeBenefit(
          icon: Icons.speed_rounded,
          title: '우선 배정',
          description: '인기 미션 우선 배정 혜택',
          isHighlighted: true,
        ),
        GradeBenefit(
          icon: Icons.flash_on_rounded,
          title: '빠른 정산 (2일)',
          description: '영업일 기준 2일 내 정산',
        ),
        GradeBenefit(
          icon: Icons.verified_user_rounded,
          title: '인증 배지',
          description: '프로필에 시니어 배지 표시',
        ),
        GradeBenefit(
          icon: Icons.headset_mic_rounded,
          title: '전담 고객 지원',
          description: '전담 상담사 배정',
        ),
      ],
      restrictions: [
        '마스터 전용 미션 제외',
      ],
      unlockMessage: '20개 미션 완료 + 신뢰도 4.0점 이상',
    ),
    'master': ReviewerGradeInfo(
      grade: 'master',
      label: '마스터',
      description: '암행어흥 최고의 리뷰어입니다!',
      icon: Icons.diamond_rounded,
      colors: [const Color(0xFFE11D48), const Color(0xFFF43F5E)],
      requiredMissions: 50,
      requiredTrustScore: 4.5,
      benefits: [
        GradeBenefit(
          icon: Icons.all_inclusive_rounded,
          title: '모든 미션 참여',
          description: '마스터 전용 미션 포함 모든 미션',
          isHighlighted: true,
        ),
        GradeBenefit(
          icon: Icons.add_circle_rounded,
          title: '보상 +30%',
          description: '기본 보상에 30% 추가 지급',
          isHighlighted: true,
        ),
        GradeBenefit(
          icon: Icons.bolt_rounded,
          title: '최우선 배정',
          description: '모든 미션 최우선 배정',
          isHighlighted: true,
        ),
        GradeBenefit(
          icon: Icons.flash_on_rounded,
          title: '즉시 정산 (1일)',
          description: '영업일 기준 1일 내 정산',
          isHighlighted: true,
        ),
        GradeBenefit(
          icon: Icons.verified_user_rounded,
          title: '마스터 배지',
          description: '프로필에 마스터 배지 표시',
        ),
        GradeBenefit(
          icon: Icons.local_offer_rounded,
          title: '업체 제휴 혜택',
          description: '제휴 업체 특별 할인',
        ),
        GradeBenefit(
          icon: Icons.vip_rounded,
          title: 'VIP 고객 지원',
          description: '전용 핫라인 및 최우선 처리',
        ),
        GradeBenefit(
          icon: Icons.event_rounded,
          title: '마스터 모임',
          description: '분기별 마스터 리뷰어 네트워킹',
        ),
      ],
      restrictions: [],
      unlockMessage: '50개 미션 완료 + 신뢰도 4.5점 이상',
    ),
  };
}

/// 리뷰어 등급 정보
class ReviewerGradeInfo {
  final String grade;
  final String label;
  final String description;
  final IconData icon;
  final List<Color> colors;
  final int requiredMissions;
  final double requiredTrustScore;
  final List<GradeBenefit> benefits;
  final List<String> restrictions;
  final String? unlockMessage;

  const ReviewerGradeInfo({
    required this.grade,
    required this.label,
    required this.description,
    required this.icon,
    required this.colors,
    required this.requiredMissions,
    required this.requiredTrustScore,
    required this.benefits,
    this.restrictions = const [],
    this.unlockMessage,
  });

  /// 현재 등급에서 받는 보상 보너스 비율
  double get bonusRate {
    switch (grade) {
      case 'master':
        return 0.30;
      case 'senior':
        return 0.20;
      case 'regular':
        return 0.10;
      default:
        return 0.0;
    }
  }

  /// 정산 소요 일수
  int get settlementDays {
    switch (grade) {
      case 'master':
        return 1;
      case 'senior':
        return 2;
      case 'regular':
        return 3;
      default:
        return 5;
    }
  }
}

/// 등급 혜택
class GradeBenefit {
  final IconData icon;
  final String title;
  final String description;
  final bool isHighlighted;

  const GradeBenefit({
    required this.icon,
    required this.title,
    required this.description,
    this.isHighlighted = false,
  });
}

/// 업체 배지 시스템
class BusinessBadges {
  static const List<String> orderedBadges = ['none', 'bronze', 'silver', 'gold', 'platinum'];

  static BusinessBadgeInfo getBadgeInfo(String badge) {
    return _badgeInfoMap[badge] ?? _badgeInfoMap['none']!;
  }

  static final Map<String, BusinessBadgeInfo> _badgeInfoMap = {
    'none': BusinessBadgeInfo(
      badge: 'none',
      label: '일반',
      description: '아직 배지를 획득하지 않았어요',
      icon: Icons.storefront_rounded,
      colors: [Colors.grey, Colors.grey.shade400],
      requiredMonths: 0,
      requiredScore: 0,
      benefits: [],
    ),
    'bronze': BusinessBadgeInfo(
      badge: 'bronze',
      label: '브론즈',
      description: '신뢰받는 업체로의 첫걸음!',
      icon: Icons.shield_rounded,
      colors: [const Color(0xFFCD7F32), const Color(0xFFB87333)],
      requiredMonths: 1,
      requiredScore: 3.5,
      benefits: [
        '브론즈 배지 표시',
        '검색 결과 상단 노출',
      ],
    ),
    'silver': BusinessBadgeInfo(
      badge: 'silver',
      label: '실버',
      description: '꾸준히 좋은 평가를 받고 있어요',
      icon: Icons.verified_rounded,
      colors: [const Color(0xFFC0C0C0), const Color(0xFFA8A8A8)],
      requiredMonths: 3,
      requiredScore: 4.0,
      benefits: [
        '실버 배지 표시',
        '검색 결과 우선 노출',
        '프리미엄 리뷰어 매칭',
      ],
    ),
    'gold': BusinessBadgeInfo(
      badge: 'gold',
      label: '골드',
      description: '최상위 신뢰도를 자랑하는 업체!',
      icon: Icons.workspace_premium_rounded,
      colors: [const Color(0xFFFFD700), const Color(0xFFFFC107)],
      requiredMonths: 6,
      requiredScore: 4.3,
      benefits: [
        '골드 배지 표시',
        '검색 결과 최상단 노출',
        '시니어+ 리뷰어 매칭',
        '홈 화면 추천 대상',
      ],
    ),
    'platinum': BusinessBadgeInfo(
      badge: 'platinum',
      label: '플래티넘',
      description: '암행어흥 최고의 신뢰 업체!',
      icon: Icons.diamond_rounded,
      colors: [const Color(0xFFE5E4E2), const Color(0xFF8E8E8E)],
      requiredMonths: 12,
      requiredScore: 4.5,
      benefits: [
        '플래티넘 배지 표시',
        '모든 검색에서 최우선 노출',
        '마스터 리뷰어 우선 매칭',
        '홈 화면 상시 추천',
        '월간 신뢰도 리포트 제공',
      ],
    ),
  };
}

/// 업체 배지 정보
class BusinessBadgeInfo {
  final String badge;
  final String label;
  final String description;
  final IconData icon;
  final List<Color> colors;
  final int requiredMonths;
  final double requiredScore;
  final List<String> benefits;

  const BusinessBadgeInfo({
    required this.badge,
    required this.label,
    required this.description,
    required this.icon,
    required this.colors,
    required this.requiredMonths,
    required this.requiredScore,
    required this.benefits,
  });
}
