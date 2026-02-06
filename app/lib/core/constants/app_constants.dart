import '../config/environment.dart';

class AppConstants {
  static String get appName => EnvironmentConfig.appName;
  static const String appVersion = '1.0.0';

  // API - 환경에 따라 자동 설정
  static String get baseUrl => EnvironmentConfig.apiBaseUrl;

  // 사용자 유형
  static const String userTypeConsumer = 'consumer';
  static const String userTypeReviewer = 'reviewer';
  static const String userTypeBusiness = 'business';

  // 리뷰어 등급
  static const String gradeRookie = 'rookie';
  static const String gradeRegular = 'regular';
  static const String gradeSenior = 'senior';
  static const String gradeMaster = 'master';

  // 배지 등급
  static const String badgeNone = 'none';
  static const String badgeBronze = 'bronze';
  static const String badgeSilver = 'silver';
  static const String badgeGold = 'gold';
  static const String badgePlatinum = 'platinum';

  // 미션 상태
  static const String missionPendingPayment = 'pending_payment';
  static const String missionRecruiting = 'recruiting';
  static const String missionAssigned = 'assigned';
  static const String missionInProgress = 'in_progress';
  static const String missionReviewSubmitted = 'review_submitted';
  static const String missionPreviewPeriod = 'preview_period';
  static const String missionPublished = 'published';
  static const String missionCompleted = 'completed';

  // 저장소 키
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String onboardingKey = 'onboarding_completed';
}
