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

  // 미션 관련
  MISSION_EXPIRED: 'mission_expired',
  MISSION_ASSIGNED: 'mission_assigned',
  MISSION_NEW: 'mission_new',

  // 일반
  SYSTEM: 'system',
};

module.exports = NOTIFICATION_TYPES;
