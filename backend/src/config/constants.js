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

  // 미션 보상 타입
  REWARD_TYPES: {
    CASH: 'cash',                       // 현금 정산(에스크로)
    FREE_EXPERIENCE: 'free_experience', // 무료 체험(가게 제공, 플랫폼 현금 지출 0)
  },

  // 구독 플랜별 정보
  // monthlyFreeExperience: 월 무료체험 미션 등록 한도 (-1 = 무제한)
  PLAN_DETAILS: {
    none: {
      price: 0,
      monthlyInspections: 0,
      monthlyFreeExperience: 0,
      features: []
    },
    starter: {
      price: 99000,
      monthlyInspections: 1,
      monthlyFreeExperience: 5,
      features: ['basic_report', 'bronze_badge']
    },
    growth: {
      price: 199000,
      monthlyInspections: 2,
      monthlyFreeExperience: 15,
      features: ['detailed_report', 'silver_badge', 'external_integration']
    },
    pro: {
      price: 349000,
      monthlyInspections: 4,
      monthlyFreeExperience: -1,
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

  // 미션 유형
  MISSION_TYPES: {
    VISIT: 'visit',       // 매장/업장 직접 방문
    DELIVERY: 'delivery', // 상품 주문 후 배송 수령 리뷰
    ONLINE: 'online',     // 온라인 서비스 체험 리뷰
    PHONE: 'phone',       // 전화 상담/서비스 리뷰
  },

  // 유형별 인증 요구사항
  VERIFICATION_REQUIREMENTS: {
    visit: {
      photos: { min: 3, description: '현장 사진 3장 이상' },
      receipt: { required: true, description: '영수증 필수' },
      gps: { optional: true, description: 'GPS 인증 (선택)' },
    },
    delivery: {
      photos: { min: 1, description: '언박싱 사진/영상' },
      receipt: { required: true, description: '영수증 필수' },
      deliveryScreenshot: { required: true, description: '배송확인 스크린샷' },
    },
    online: {
      screenshots: { min: 3, description: '서비스 이용 스크린샷 3장 이상' },
      receipt: { required: true, description: '영수증 필수' },
    },
    phone: {
      callScreenshot: { required: true, description: '통화 스크린샷' },
      memo: { required: true, description: '상담 내용 메모' },
    },
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
  PREVIEW_PERIOD_HOURS: 72,

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
  ],

  // 튜토리얼 보상 금액 (사용 중단 - 서약 시스템으로 전환)
  // TUTORIAL_REWARD_AMOUNT: 20000,

  // 서약 버전
  PLEDGE_VERSION: '1.0',

  // 추천인 보상 금액
  REFERRAL_REWARD_AMOUNT: 10000,

  // 미션 가시성
  MISSION_VISIBILITY: {
    NORMAL: 'normal',
    HIDDEN: 'hidden',
    SEASON: 'season'
  },

  // 해지 이유 카테고리
  CANCEL_REASONS: [
    'too_expensive',
    'not_useful',
    'found_alternative',
    'temporary_closure',
    'other'
  ],

  // 구독 일시정지
  MAX_PAUSE_COUNT: 2,
  PAUSE_DURATION_DAYS: 30,

  // 교육/인증 시스템
  CERTIFICATION_PASSING_SCORE: 80,
  MAX_QUIZ_ATTEMPTS: 3,
  RECERTIFICATION_INTERVAL_DAYS: 90,
  QUALITY_WARNING_THRESHOLD: 3,

  // GPS 구간별 체크인 설정
  GPS_ZONES: {
    GREEN: { max: 100, label: '정상', requiresPhoto: false },
    YELLOW: { max: 200, label: '경고', requiresPhoto: false },
    ORANGE: { max: 500, label: '수동인증', requiresPhoto: true },
    RED: { max: Infinity, label: '차단', requiresPhoto: false },
  },

  // 담합 방지 엔진
  COLLUSION_REPEAT_BLOCK_MONTHS: 6,
  COLLUSION_IP_MATCH_SEVERITY: 'high',
  COLLUSION_DEVICE_MATCH_SEVERITY: 'critical',
  FINGERPRINT_THROTTLE_MINUTES: 60,

  // 등급별 혜택 (리뷰 보수 배율)
  GRADE_BENEFITS: {
    rookie:  { payMultiplier: 1.0,  label: '루키',   hiddenMissions: false, priorityMatching: false },
    regular: { payMultiplier: 1.1,  label: '레귤러', hiddenMissions: false, priorityMatching: false },
    senior:  { payMultiplier: 1.2,  label: '시니어', hiddenMissions: true,  priorityMatching: true  },
    master:  { payMultiplier: 1.3,  label: '마스터', hiddenMissions: true,  priorityMatching: true  },
  },

  // 등급 승급 기준
  GRADE_PROMOTION: {
    regular: { minMissions: 5,  minTrustScore: 2.5 },
    senior:  { minMissions: 20, minTrustScore: 3.5 },
    master:  { minMissions: 50, minTrustScore: 4.0 },
  },

  // 품질 보너스 (양질의 리뷰에 대한 추가 보상)
  QUALITY_BONUSES: {
    DETAILED_REVIEW: { threshold: 500, bonus: 3000, label: '상세한 리뷰' },
    HELPFUL_MILESTONE: { threshold: 10, bonus: 5000, label: '도움 투표 10+' },
    BALANCED_REVIEW: { bonus: 2000, label: '균형 잡힌 리뷰' },
  },

  // 신뢰도 가중치 (평점 반영 시)
  TRUST_WEIGHT: {
    MIN_WEIGHT: 0.5,
    MAX_WEIGHT: 2.0,
    MIN_REVIEWS_FOR_WEIGHTED: 3,
  },

  // 내부 고발 보상
  WHISTLEBLOWER_REWARD: 50000,

  // 영구 차단
  PERMANENT_BAN_ACTIONS: ['forfeit_all_pending_payments', 'revoke_certification', 'block_reregistration'],
};
