/**
 * 알림 타입 상수
 * 프론트엔드 라우팅과 일치해야 함
 */
const NOTIFICATION_TYPES = {
  // 정산 관련
  SETTLEMENT_COMPLETE: 'settlement_complete',
  SETTLEMENT_FAILED: 'settlement_failed',

  // 리뷰 관련
  REVIEW_PUBLISHED: 'review_published',
  REVIEW_SUBMITTED: 'review_submitted',

  // 이의 제기 관련
  DISPUTE_FILED: 'dispute_filed',
  DISPUTE_RESOLVED: 'dispute_resolved',

  // 미션 관련
  MISSION_EXPIRED: 'mission_expired',
  MISSION_ASSIGNED: 'mission_assigned',
  MISSION_NEW: 'mission_new',

  // 일반
  SYSTEM: 'system',

  // 튜토리얼
  TUTORIAL_REWARD_AVAILABLE: 'tutorial_reward_available',

  // 히든/시즌 미션
  HIDDEN_MISSION_AVAILABLE: 'hidden_mission_available',
  SEASON_STARTED: 'season_started',

  // 추천인
  REFERRAL_REGISTERED: 'referral_registered',
  REFERRAL_REWARDED: 'referral_rewarded',

  // 경쟁 알림
  COMPETITION_ALERT: 'competition_alert',

  // 리뷰 요청
  REVIEW_REQUEST_THRESHOLD: 'review_request_threshold',

  // 교육/인증
  CERTIFICATION_DAY_UNLOCKED: 'certification_day_unlocked',
  CERTIFICATION_COMPLETED: 'certification_completed',
  CERTIFICATION_SUSPENDED: 'certification_suspended',
  RECERTIFICATION_DUE: 'recertification_due',
  QUALITY_WARNING: 'quality_warning',

  // 역탐지 테스트
  DETECTION_TEST_AVAILABLE: 'detection_test_available',
  DETECTION_TEST_RESULT: 'detection_test_result',
  STEALTH_WARNING: 'stealth_warning',

  // 담합 방지
  COLLUSION_WARNING: 'collusion_warning',
  ASSIGNMENT_BLOCKED: 'assignment_blocked',
};

module.exports = NOTIFICATION_TYPES;
