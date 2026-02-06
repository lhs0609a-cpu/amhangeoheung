module.exports = {
  // 사용자 유형
  USER_TYPES: {
    CONSUMER: 'consumer',
    REVIEWER: 'reviewer',
    BUSINESS: 'business'
  },

  // 리뷰어 등급
  REVIEWER_GRADES: {
    ROOKIE: 'rookie',
    REGULAR: 'regular',
    SENIOR: 'senior',
    MASTER: 'master'
  },

  // 업체 배지 등급
  BADGE_LEVELS: {
    NONE: 'none',
    BRONZE: 'bronze',
    SILVER: 'silver',
    GOLD: 'gold',
    PLATINUM: 'platinum'
  },

  // 구독 플랜
  SUBSCRIPTION_PLANS: {
    NONE: 'none',
    STARTER: 'starter',    // 월 99,000원
    GROWTH: 'growth',      // 월 199,000원
    PRO: 'pro',            // 월 349,000원
    ENTERPRISE: 'enterprise'
  },

  // 구독 플랜별 정보
  PLAN_DETAILS: {
    starter: {
      price: 99000,
      monthlyInspections: 1,
      features: ['basic_report', 'bronze_badge']
    },
    growth: {
      price: 199000,
      monthlyInspections: 2,
      features: ['detailed_report', 'silver_badge', 'external_integration']
    },
    pro: {
      price: 349000,
      monthlyInspections: 4,
      features: ['premium_report', 'gold_badge', 'consulting', 'external_integration']
    }
  },

  // 미션 상태
  MISSION_STATUS: {
    PENDING_PAYMENT: 'pending_payment',
    RECRUITING: 'recruiting',
    ASSIGNED: 'assigned',
    IN_PROGRESS: 'in_progress',
    REVIEW_SUBMITTED: 'review_submitted',
    PREVIEW_PERIOD: 'preview_period',
    PUBLISHED: 'published',
    DISPUTED: 'disputed',
    COMPLETED: 'completed',
    CANCELLED: 'cancelled'
  },

  // 플랫폼 수수료율
  PLATFORM_FEE_RATE: 0.10, // 10%

  // 리뷰 유효기간 (개월)
  REVIEW_VALIDITY: {
    restaurant: 6,
    hospital: 12,
    beauty: 6,
    ecommerce: 12
  },

  // 업체 선공개 기간 (시간)
  PREVIEW_PERIOD_HOURS: 48,

  // 자동 에스크로 해제 대기 (일)
  AUTO_RELEASE_DAYS: 7,

  // 카테고리
  OFFLINE_CATEGORIES: [
    { id: 'restaurant', name: '음식점', subcategories: ['한식', '중식', '일식', '양식', '분식', '카페'] },
    { id: 'hospital', name: '병원/의원', subcategories: ['내과', '외과', '피부과', '치과', '한의원'] },
    { id: 'beauty', name: '미용', subcategories: ['미용실', '네일샵', '피부관리', '속눈썹'] },
    { id: 'education', name: '학원', subcategories: ['입시', '어학', '예체능', '취미'] },
    { id: 'fitness', name: '운동', subcategories: ['헬스장', '필라테스', '요가', '수영장'] }
  ],

  ECOMMERCE_CATEGORIES: [
    { id: 'electronics', name: '전자기기' },
    { id: 'fashion', name: '패션의류' },
    { id: 'beauty', name: '뷰티' },
    { id: 'baby', name: '육아용품' },
    { id: 'food', name: '식품' },
    { id: 'home', name: '홈/리빙' }
  ]
};
