-- 암행어흥 Supabase PostgreSQL 스키마
-- Supabase 대시보드 > SQL Editor에서 실행하세요

-- UUID 확장 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. 사용자 테이블 (Users)
-- ============================================
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255), -- NULL 가능 (소셜 로그인 사용자)
  phone VARCHAR(20) UNIQUE,
  name VARCHAR(100) NOT NULL,

  -- 소셜 로그인
  auth_provider VARCHAR(20) DEFAULT 'email' CHECK (auth_provider IN ('email', 'google', 'apple', 'kakao')),
  is_social_only BOOLEAN DEFAULT FALSE,
  nickname VARCHAR(50) UNIQUE,
  profile_image TEXT,

  -- 사용자 유형: consumer, reviewer, business
  user_type VARCHAR(20) DEFAULT 'consumer' CHECK (user_type IN ('consumer', 'reviewer', 'business')),

  -- 본인 인증
  is_verified BOOLEAN DEFAULT FALSE,
  ci VARCHAR(255),
  di VARCHAR(255),
  verified_at TIMESTAMPTZ,
  verification_method VARCHAR(20),

  -- 리뷰어 정보
  reviewer_grade VARCHAR(20) DEFAULT 'rookie' CHECK (reviewer_grade IN ('rookie', 'regular', 'senior', 'master')),
  completed_missions INT DEFAULT 0,
  trust_score DECIMAL(3,2) DEFAULT 0 CHECK (trust_score >= 0 AND trust_score <= 5),
  specialties TEXT[], -- 전문 카테고리 배열
  bank_name VARCHAR(50),
  bank_account VARCHAR(50),
  bank_holder VARCHAR(50),
  bank_account_number VARCHAR(50),
  bank_account_holder VARCHAR(50),
  bank_verification_status VARCHAR(20) DEFAULT 'none' CHECK (bank_verification_status IN ('none', 'pending', 'verified', 'failed', 'verification_required')),
  bank_verification_failed_count INT DEFAULT 0,
  bank_verified_at TIMESTAMPTZ,

  -- 상태
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'banned')),
  suspended_until TIMESTAMPTZ,
  ban_reason TEXT,

  -- 프리미엄 구독
  premium_active BOOLEAN DEFAULT FALSE,
  premium_expires_at TIMESTAMPTZ,
  premium_plan VARCHAR(20),

  -- 알림 설정
  notify_push BOOLEAN DEFAULT TRUE,
  notify_email BOOLEAN DEFAULT TRUE,
  notify_sms BOOLEAN DEFAULT FALSE,

  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 2. 업체 테이블 (Businesses)
-- ============================================
CREATE TABLE businesses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID REFERENCES users(id) ON DELETE CASCADE,

  -- 업체 유형: offline, ecommerce
  business_type VARCHAR(20) NOT NULL CHECK (business_type IN ('offline', 'ecommerce')),

  -- 기본 정보
  name VARCHAR(200) NOT NULL,
  description TEXT,
  logo TEXT,
  images TEXT[],

  -- 사업자 정보
  business_number VARCHAR(20) UNIQUE NOT NULL,
  representative_name VARCHAR(50),
  business_address TEXT,
  is_business_verified BOOLEAN DEFAULT FALSE,

  -- 오프라인 업체 정보
  category VARCHAR(50),
  sub_category VARCHAR(50),
  address_full TEXT,
  address_city VARCHAR(50),
  address_district VARCHAR(50),
  address_detail TEXT,
  zip_code VARCHAR(10),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  phone VARCHAR(20),

  -- 이커머스 정보
  platforms TEXT[],
  store_urls TEXT[],
  product_categories TEXT[],

  -- 인증 배지
  badge_level VARCHAR(20) DEFAULT 'none' CHECK (badge_level IN ('none', 'bronze', 'silver', 'gold', 'platinum')),
  consecutive_months INT DEFAULT 0,
  average_score DECIMAL(3,2) DEFAULT 0,
  badge_earned_at TIMESTAMPTZ,

  -- 구독 정보
  subscription_plan VARCHAR(20) DEFAULT 'none' CHECK (subscription_plan IN ('none', 'starter', 'growth', 'pro', 'enterprise')),
  subscription_start TIMESTAMPTZ,
  subscription_end TIMESTAMPTZ,
  auto_renew BOOLEAN DEFAULT TRUE,
  monthly_inspections INT DEFAULT 0,
  used_inspections INT DEFAULT 0,

  -- 통계
  total_reviews INT DEFAULT 0,
  average_rating DECIMAL(3,2) DEFAULT 0,

  -- 상태
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'suspended', 'closed')),

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 위치 기반 검색을 위한 인덱스
CREATE INDEX idx_businesses_location ON businesses(latitude, longitude);
CREATE INDEX idx_businesses_category ON businesses(category);

-- ============================================
-- 3. 미션 테이블 (Missions)
-- ============================================
CREATE TABLE missions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,

  -- 미션 유형
  mission_type VARCHAR(20) NOT NULL CHECK (mission_type IN ('offline', 'ecommerce')),

  -- 상태
  status VARCHAR(30) DEFAULT 'pending_payment' CHECK (status IN (
    'pending_payment', 'recruiting', 'assigned', 'in_progress',
    'review_submitted', 'preview_period', 'published', 'disputed', 'completed', 'cancelled'
  )),

  -- 오프라인 미션 정보
  visit_date DATE,
  time_slot VARCHAR(20),
  check_in_lat DECIMAL(10, 8),
  check_in_lng DECIMAL(11, 8),
  check_in_time TIMESTAMPTZ,
  check_out_time TIMESTAMPTZ,
  min_stay_minutes INT DEFAULT 30,

  -- 이커머스 미션 정보
  product_name VARCHAR(200),
  product_url TEXT,
  product_price INT,
  product_options TEXT,
  order_number VARCHAR(100),
  order_date DATE,
  delivery_date DATE,
  tracking_number VARCHAR(100),

  -- 배정된 리뷰어
  assigned_reviewer_id UUID REFERENCES users(id),

  -- 모집 정보
  max_applicants INT DEFAULT 20,
  required_reviewers INT DEFAULT 1,
  recruitment_deadline TIMESTAMPTZ,

  -- 블라인드 정보
  blind_category VARCHAR(50),
  blind_region VARCHAR(50),

  -- 결제 정보
  product_cost INT DEFAULT 0,
  reviewer_fee INT DEFAULT 0,
  platform_fee INT DEFAULT 0,
  total_amount INT DEFAULT 0,
  payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'in_escrow', 'released', 'refunded')),
  paid_at TIMESTAMPTZ,
  transaction_id VARCHAR(100),

  -- 타임라인
  payment_at TIMESTAMPTZ,
  recruitment_ends_at TIMESTAMPTZ,
  assigned_at TIMESTAMPTZ,
  mission_start_at TIMESTAMPTZ,
  review_submitted_at TIMESTAMPTZ,
  preview_start_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,

  notes TEXT,
  tags TEXT[],

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 4. 미션 신청자 테이블 (Mission Applicants)
-- ============================================
CREATE TABLE mission_applicants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mission_id UUID REFERENCES missions(id) ON DELETE CASCADE,
  reviewer_id UUID REFERENCES users(id) ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'applied' CHECK (status IN ('applied', 'selected', 'rejected')),
  applied_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(mission_id, reviewer_id)
);

-- ============================================
-- 5. 리뷰 테이블 (Reviews)
-- ============================================
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mission_id UUID REFERENCES missions(id) ON DELETE CASCADE,
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
  reviewer_id UUID REFERENCES users(id) ON DELETE CASCADE,

  -- 상태
  status VARCHAR(20) DEFAULT 'draft' CHECK (status IN (
    'draft', 'submitted', 'under_review', 'preview', 'published', 'disputed', 'hidden'
  )),

  -- 총점
  total_score DECIMAL(3,2) CHECK (total_score >= 1 AND total_score <= 5),

  -- 리뷰 내용
  summary VARCHAR(500),
  pros TEXT[],
  cons TEXT[] NOT NULL, -- 단점 필수
  detailed_review TEXT,
  recommendation VARCHAR(30) CHECK (recommendation IN (
    'strongly_recommend', 'recommend', 'neutral', 'not_recommend', 'strongly_not_recommend'
  )),

  -- 증거 - GPS
  evidence_lat DECIMAL(10, 8),
  evidence_lng DECIMAL(11, 8),
  evidence_location_verified_at TIMESTAMPTZ,
  evidence_location_valid BOOLEAN,

  -- 증거 - 영수증
  receipt_image_url TEXT,
  receipt_store_name VARCHAR(200),
  receipt_amount INT,
  receipt_date DATE,
  receipt_verified BOOLEAN DEFAULT FALSE,

  -- 증거 - 언박싱 영상
  unboxing_video_url TEXT,
  unboxing_duration INT,
  unboxing_thumbnail TEXT,

  -- 증거 - 주문 정보
  order_platform VARCHAR(50),
  order_number VARCHAR(100),
  order_screenshot TEXT,
  delivery_screenshot TEXT,
  order_verified BOOLEAN DEFAULT FALSE,

  -- 체류 시간
  visit_check_in TIMESTAMPTZ,
  visit_check_out TIMESTAMPTZ,
  visit_minutes INT,

  -- 업체 응답
  business_response TEXT,
  business_response_at TIMESTAMPTZ,
  improvement_promise TEXT,

  -- 소비자 반응
  helpful_count INT DEFAULT 0,
  not_helpful_count INT DEFAULT 0,
  reported_count INT DEFAULT 0,

  -- 유효기간
  expires_at TIMESTAMPTZ,
  is_expired BOOLEAN DEFAULT FALSE,

  -- 분쟁
  is_disputed BOOLEAN DEFAULT FALSE,
  dispute_reason TEXT,
  dispute_filed_by VARCHAR(20),
  dispute_filed_at TIMESTAMPTZ,
  dispute_resolution TEXT,
  dispute_resolved_at TIMESTAMPTZ,

  -- 타임라인
  drafted_at TIMESTAMPTZ,
  submitted_at TIMESTAMPTZ,
  preview_start_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 6. 리뷰 점수 테이블 (Review Scores)
-- ============================================
CREATE TABLE review_scores (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  review_id UUID REFERENCES reviews(id) ON DELETE CASCADE,
  criteria_name VARCHAR(50) NOT NULL,
  score INT CHECK (score >= 1 AND score <= 5),
  comment TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 7. 리뷰 사진 테이블 (Review Photos)
-- ============================================
CREATE TABLE review_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  review_id UUID REFERENCES reviews(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  caption TEXT,
  taken_at TIMESTAMPTZ,
  photo_lat DECIMAL(10, 8),
  photo_lng DECIMAL(11, 8),
  is_verified BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 8. 에스크로 테이블 (Escrows)
-- ============================================
CREATE TABLE escrows (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mission_id UUID REFERENCES missions(id) ON DELETE CASCADE,
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
  reviewer_id UUID REFERENCES users(id),

  -- 금액
  product_cost INT NOT NULL,
  reviewer_fee INT DEFAULT 0,
  platform_fee INT NOT NULL,
  total_amount INT NOT NULL,

  -- 상태
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN (
    'pending', 'paid', 'hold', 'releasing', 'released', 'refunded', 'partial_refund', 'cancelled'
  )),

  -- 결제 정보
  payment_method VARCHAR(20),
  pg_provider VARCHAR(50),
  transaction_id VARCHAR(100),
  paid_at TIMESTAMPTZ,
  card_company VARCHAR(50),
  card_last4 VARCHAR(4),

  -- 지급 정보
  payout_amount INT,
  payout_bank VARCHAR(50),
  payout_account VARCHAR(50),
  payout_holder VARCHAR(50),
  payout_at TIMESTAMPTZ,
  payout_transaction_id VARCHAR(100),

  -- 환불 정보
  refund_amount INT,
  refund_reason TEXT,
  refund_requested_at TIMESTAMPTZ,
  refund_processed_at TIMESTAMPTZ,

  -- 분쟁
  is_disputed BOOLEAN DEFAULT FALSE,
  dispute_reason TEXT,
  dispute_filed_at TIMESTAMPTZ,
  dispute_resolution TEXT,
  dispute_resolved_at TIMESTAMPTZ,

  -- 자동 지급
  auto_release_at TIMESTAMPTZ,
  auto_release_executed BOOLEAN DEFAULT FALSE,

  -- P0-3: 정산 재시도 관련
  payout_retry_count INT DEFAULT 0,
  payout_error_message TEXT,
  payout_last_attempt_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 7일 후 추가 리뷰 (이커머스)
-- ============================================
CREATE TABLE follow_up_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  review_id UUID REFERENCES reviews(id) ON DELETE CASCADE,
  durability_score INT CHECK (durability_score >= 1 AND durability_score <= 5),
  usage_notes TEXT,
  issues TEXT[],
  photos TEXT[],
  submitted_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 인덱스 추가
-- ============================================
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_user_type ON users(user_type);
CREATE INDEX idx_missions_status ON missions(status);
CREATE INDEX idx_missions_business ON missions(business_id);
CREATE INDEX idx_reviews_business ON reviews(business_id);
CREATE INDEX idx_reviews_status ON reviews(status);

-- ============================================
-- Row Level Security (RLS) 정책
-- ============================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE escrows ENABLE ROW LEVEL SECURITY;

-- 사용자는 자신의 데이터만 수정 가능
CREATE POLICY "Users can view own data" ON users FOR SELECT USING (auth.uid()::text = id::text);
CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid()::text = id::text);

-- 리뷰는 공개된 것만 누구나 조회 가능
CREATE POLICY "Published reviews are public" ON reviews FOR SELECT USING (status = 'published');

-- ============================================
-- 업데이트 트리거
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER businesses_updated_at BEFORE UPDATE ON businesses FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER missions_updated_at BEFORE UPDATE ON missions FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER reviews_updated_at BEFORE UPDATE ON reviews FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER escrows_updated_at BEFORE UPDATE ON escrows FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- 소셜 계정 연결 테이블 (Social Accounts)
-- ============================================
CREATE TABLE social_accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,

  -- 소셜 프로바이더 정보
  provider VARCHAR(20) NOT NULL CHECK (provider IN ('google', 'apple', 'kakao')),
  provider_id VARCHAR(255) NOT NULL,

  -- 소셜 계정 정보
  email VARCHAR(255),
  name VARCHAR(100),
  profile_image TEXT,

  -- 토큰 (필요시 갱신용)
  access_token TEXT,
  id_token TEXT,
  refresh_token TEXT,
  token_expires_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- 같은 프로바이더의 같은 ID는 한 번만 연결 가능
  UNIQUE(provider, provider_id)
);

-- 인덱스
CREATE INDEX idx_social_accounts_user ON social_accounts(user_id);
CREATE INDEX idx_social_accounts_provider ON social_accounts(provider, provider_id);

-- RLS 정책
ALTER TABLE social_accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own social accounts" ON social_accounts FOR SELECT USING (auth.uid()::text = user_id::text);

-- 업데이트 트리거
CREATE TRIGGER social_accounts_updated_at BEFORE UPDATE ON social_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- 알림 테이블 (Notifications)
-- ============================================
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  type VARCHAR(50) NOT NULL,  -- mission_new, mission_selected, settlement_complete, review_published, etc.
  title VARCHAR(200) NOT NULL,
  message TEXT NOT NULL,
  data JSONB DEFAULT '{}',  -- 추가 데이터 (missionId, reviewId 등)
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_notifications_user ON notifications(user_id, is_read, created_at DESC);

-- ============================================
-- 디바이스 토큰 테이블 (FCM 푸시 알림)
-- ============================================
CREATE TABLE device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  token TEXT NOT NULL UNIQUE,
  platform VARCHAR(20) NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  is_active BOOLEAN DEFAULT TRUE,
  last_used_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_device_tokens_user ON device_tokens(user_id, is_active);

-- ============================================
-- Feature 1: 튜토리얼 미션 시스템
-- ============================================
ALTER TABLE users ADD COLUMN IF NOT EXISTS tutorial_completed BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS tutorial_completed_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS tutorial_reward_claimed BOOLEAN DEFAULT FALSE;

CREATE TABLE IF NOT EXISTS tutorial_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id VARCHAR(255) NOT NULL,
  steps_completed INT DEFAULT 0,
  total_steps INT DEFAULT 5,
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  converted_user_id UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_tutorial_sessions_device ON tutorial_sessions(device_id);

-- ============================================
-- Feature 3: 히든 미션 / 시즌 미션
-- ============================================
ALTER TABLE missions ADD COLUMN IF NOT EXISTS visibility VARCHAR(20) DEFAULT 'normal'
  CHECK (visibility IN ('normal', 'hidden', 'season'));
ALTER TABLE missions ADD COLUMN IF NOT EXISTS min_reviewer_grade VARCHAR(20);
ALTER TABLE missions ADD COLUMN IF NOT EXISTS bonus_rate DECIMAL(3,2) DEFAULT 0;

CREATE TABLE IF NOT EXISTS seasons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  theme VARCHAR(50) NOT NULL,
  description TEXT,
  banner_image TEXT,
  start_at TIMESTAMPTZ NOT NULL,
  end_at TIMESTAMPTZ NOT NULL,
  reward_bonus_rate DECIMAL(3,2) DEFAULT 0,
  min_grade VARCHAR(20) DEFAULT 'rookie',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE missions ADD COLUMN IF NOT EXISTS season_id UUID REFERENCES seasons(id);
CREATE INDEX IF NOT EXISTS idx_missions_visibility ON missions(visibility, status);
CREATE INDEX IF NOT EXISTS idx_missions_season ON missions(season_id);

-- ============================================
-- Feature 4: 추천인/초대 시스템
-- ============================================
CREATE TABLE IF NOT EXISTS referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id UUID REFERENCES users(id) NOT NULL,
  referred_id UUID REFERENCES users(id),
  referral_code VARCHAR(20) UNIQUE NOT NULL,
  status VARCHAR(20) DEFAULT 'pending'
    CHECK (status IN ('pending', 'registered', 'mission_completed', 'rewarded', 'expired')),
  reward_amount INT DEFAULT 10000,
  referrer_rewarded_at TIMESTAMPTZ,
  referred_rewarded_at TIMESTAMPTZ,
  region VARCHAR(50),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON referrals(referrer_id, status);
CREATE INDEX IF NOT EXISTS idx_referrals_code ON referrals(referral_code);

CREATE TABLE IF NOT EXISTS regional_demand (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  region VARCHAR(50) NOT NULL,
  category VARCHAR(50),
  pending_missions INT DEFAULT 0,
  active_reviewers INT DEFAULT 0,
  demand_score INT DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_regional_demand_region ON regional_demand(region);

ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_code VARCHAR(20) UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_referrals INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_earnings INT DEFAULT 0;

-- ============================================
-- Feature 5: 구독 해지 리텐션
-- ============================================
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS subscription_paused BOOLEAN DEFAULT FALSE;
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS subscription_pause_until TIMESTAMPTZ;
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS subscription_pause_count INT DEFAULT 0;

CREATE TABLE IF NOT EXISTS cancellation_reasons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID REFERENCES businesses(id) NOT NULL,
  reason_category VARCHAR(50) NOT NULL,
  reason_detail TEXT,
  was_retained BOOLEAN DEFAULT FALSE,
  retention_offer VARCHAR(50),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_cancellation_reasons_business ON cancellation_reasons(business_id);

-- ============================================
-- Feature 6: 지역 신뢰도 랭킹
-- ============================================
CREATE TABLE IF NOT EXISTS regional_rankings_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  region VARCHAR(50) NOT NULL,
  category VARCHAR(50),
  business_id UUID REFERENCES businesses(id),
  business_name VARCHAR(200),
  rank INT NOT NULL,
  trust_score DECIMAL(5,2),
  review_count INT,
  avg_rating DECIMAL(3,2),
  badge_level VARCHAR(20),
  period VARCHAR(20) DEFAULT 'monthly',
  cached_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_regional_rankings ON regional_rankings_cache(region, category, period, rank);

-- ============================================
-- Feature 8: 경쟁 알림
-- ============================================
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS competition_alerts_enabled BOOLEAN DEFAULT TRUE;
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS competition_alert_radius INT DEFAULT 2000;

-- ============================================
-- Feature 9: 분석 이벤트 트래킹
-- ============================================
CREATE TABLE IF NOT EXISTS analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  event_name VARCHAR(100) NOT NULL,
  event_category VARCHAR(50) NOT NULL,
  event_data JSONB DEFAULT '{}',
  session_id VARCHAR(100),
  device_id VARCHAR(255),
  platform VARCHAR(20),
  app_version VARCHAR(20),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_analytics_events_name ON analytics_events(event_name, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_events_user ON analytics_events(user_id, created_at DESC);

-- ============================================
-- Feature 10: 소비자 리뷰 요청
-- ============================================
CREATE TABLE IF NOT EXISTS review_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID REFERENCES users(id),
  business_id UUID REFERENCES businesses(id) NOT NULL,
  business_name VARCHAR(200),
  category VARCHAR(50),
  region VARCHAR(50),
  message TEXT,
  status VARCHAR(20) DEFAULT 'pending'
    CHECK (status IN ('pending', 'notified', 'mission_created', 'expired')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_review_requests_business ON review_requests(business_id, status);

-- ============================================
-- Anti-Collusion System: 교육/인증 프로그램
-- ============================================

-- 교육 커리큘럼 모듈
CREATE TABLE IF NOT EXISTS training_modules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  day_number INT NOT NULL,
  module_order INT NOT NULL,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  content_type VARCHAR(20) NOT NULL
    CHECK (content_type IN ('video', 'text', 'interactive', 'quiz')),
  content_data JSONB NOT NULL,
  passing_score INT DEFAULT 80,
  estimated_minutes INT DEFAULT 10,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_training_modules_day ON training_modules(day_number, module_order);

-- 리뷰어 인증 진행 상태
CREATE TABLE IF NOT EXISTS reviewer_certifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  status VARCHAR(20) DEFAULT 'in_progress'
    CHECK (status IN ('in_progress', 'certified', 'failed', 'suspended', 'recertifying')),
  current_day INT DEFAULT 1,
  day1_completed_at TIMESTAMPTZ,
  day2_completed_at TIMESTAMPTZ,
  day3_completed_at TIMESTAMPTZ,
  final_exam_score INT,
  certification_date TIMESTAMPTZ,
  next_recertification TIMESTAMPTZ,
  total_attempts INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);
CREATE INDEX IF NOT EXISTS idx_certifications_user ON reviewer_certifications(user_id, status);

-- 모듈별 진행 기록
CREATE TABLE IF NOT EXISTS training_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  module_id UUID REFERENCES training_modules(id) NOT NULL,
  status VARCHAR(20) DEFAULT 'not_started'
    CHECK (status IN ('not_started', 'in_progress', 'completed', 'failed')),
  score INT,
  attempts INT DEFAULT 0,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  answers JSONB,
  UNIQUE(user_id, module_id)
);
CREATE INDEX IF NOT EXISTS idx_training_progress_user ON training_progress(user_id, status);

-- 리뷰 품질 감사 기록
CREATE TABLE IF NOT EXISTS review_quality_audits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id UUID REFERENCES reviews(id) NOT NULL,
  auditor_type VARCHAR(20) NOT NULL
    CHECK (auditor_type IN ('system', 'manual')),
  quality_score INT,
  objectivity_score INT,
  detail_score INT,
  evidence_score INT,
  flags JSONB DEFAULT '[]',
  action_taken VARCHAR(50),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_quality_audits_review ON review_quality_audits(review_id);

-- users 테이블 인증 관련 컬럼 추가
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_certified BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS certification_level VARCHAR(20) DEFAULT 'none';
ALTER TABLE users ADD COLUMN IF NOT EXISTS quality_score INT DEFAULT 100;
ALTER TABLE users ADD COLUMN IF NOT EXISTS warning_count INT DEFAULT 0;

-- ============================================
-- Anti-Collusion System: 역탐지 테스트
-- ============================================

CREATE TABLE IF NOT EXISTS detection_tests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mission_id UUID REFERENCES missions(id) NOT NULL,
  business_id UUID REFERENCES businesses(id) NOT NULL,
  reviewer_id UUID REFERENCES users(id) NOT NULL,
  guessed_date DATE,
  guessed_time_slot VARCHAR(20),
  guessed_description TEXT,
  confidence_level INT,
  actual_date DATE NOT NULL,
  actual_time_slot VARCHAR(20) NOT NULL,
  date_correct BOOLEAN,
  time_correct BOOLEAN,
  detection_score INT,
  status VARCHAR(20) DEFAULT 'pending'
    CHECK (status IN ('pending', 'submitted', 'expired', 'skipped')),
  submitted_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(mission_id)
);
CREATE INDEX IF NOT EXISTS idx_detection_tests_business ON detection_tests(business_id, status);
CREATE INDEX IF NOT EXISTS idx_detection_tests_reviewer ON detection_tests(reviewer_id);

-- users 테이블 은밀성 관련 컬럼 추가
ALTER TABLE users ADD COLUMN IF NOT EXISTS stealth_score INT DEFAULT 50;
ALTER TABLE users ADD COLUMN IF NOT EXISTS detection_test_count INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS detected_count INT DEFAULT 0;

-- ============================================
-- Anti-Collusion System: 담합 방지 엔진
-- ============================================

-- 세션 핑거프린트 추적
CREATE TABLE IF NOT EXISTS session_fingerprints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  ip_address VARCHAR(45),
  device_id VARCHAR(255),
  device_model VARCHAR(100),
  os_version VARCHAR(50),
  app_version VARCHAR(20),
  session_start TIMESTAMPTZ DEFAULT NOW(),
  session_end TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_fingerprints_user ON session_fingerprints(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_fingerprints_ip ON session_fingerprints(ip_address);
CREATE INDEX IF NOT EXISTS idx_fingerprints_device ON session_fingerprints(device_id);

-- 담합 의심 플래그
CREATE TABLE IF NOT EXISTS collusion_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flag_type VARCHAR(50) NOT NULL,
  severity VARCHAR(10) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  reviewer_id UUID REFERENCES users(id),
  business_id UUID REFERENCES businesses(id),
  mission_id UUID REFERENCES missions(id),
  evidence JSONB NOT NULL,
  status VARCHAR(20) DEFAULT 'open'
    CHECK (status IN ('open', 'investigating', 'confirmed', 'dismissed', 'resolved')),
  auto_action VARCHAR(50),
  resolution_note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_collusion_flags_status ON collusion_flags(status, severity);
CREATE INDEX IF NOT EXISTS idx_collusion_flags_reviewer ON collusion_flags(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_collusion_flags_business ON collusion_flags(business_id);

-- 리뷰어-사업자 관계 추적
CREATE TABLE IF NOT EXISTS reviewer_business_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reviewer_id UUID REFERENCES users(id) NOT NULL,
  business_id UUID REFERENCES businesses(id) NOT NULL,
  mission_id UUID REFERENCES missions(id) NOT NULL,
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(reviewer_id, mission_id)
);
CREATE INDEX IF NOT EXISTS idx_rb_history_pair ON reviewer_business_history(reviewer_id, business_id);

-- ============================================
-- Anti-Collusion System: 익명성 강화
-- ============================================

-- 리뷰 익명화 메타데이터
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS anonymized_at TIMESTAMPTZ;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS display_visit_date DATE;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS display_time_slot VARCHAR(20);

-- 미션 블라인드 주소
ALTER TABLE missions ADD COLUMN IF NOT EXISTS blinded_address TEXT;
ALTER TABLE missions ADD COLUMN IF NOT EXISTS full_address_revealed_at TIMESTAMPTZ;

-- ============================================
-- Email Verification (이메일 인증)
-- ============================================
CREATE TABLE IF NOT EXISTS email_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  email VARCHAR(255) NOT NULL,
  code VARCHAR(6) NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  verified BOOLEAN DEFAULT FALSE,
  attempts INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_email_verifications_email ON email_verifications(email, code);

ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE;

-- ============================================
-- GPS 구간별 체크인 (점진적 반경 완화)
-- ============================================
ALTER TABLE missions ADD COLUMN IF NOT EXISTS gps_zone VARCHAR(10) DEFAULT 'green';
ALTER TABLE missions ADD COLUMN IF NOT EXISTS checkin_photo_url TEXT;

-- ============================================
-- Phase 1: 튜토리얼 서약 시스템 (보상 제거, 서약 중심)
-- ============================================
ALTER TABLE tutorial_sessions ADD COLUMN IF NOT EXISTS pledge_accepted BOOLEAN DEFAULT FALSE;
ALTER TABLE tutorial_sessions ADD COLUMN IF NOT EXISTS pledge_accepted_at TIMESTAMPTZ;
ALTER TABLE tutorial_sessions ADD COLUMN IF NOT EXISTS pledge_version VARCHAR(10) DEFAULT '1.0';
ALTER TABLE tutorial_sessions ALTER COLUMN total_steps SET DEFAULT 4;
-- tutorial_reward_claimed는 더 이상 사용하지 않음 (보상 시스템 제거)

-- ============================================
-- Phase 2: 미션 유형 4가지로 확장 (visit/delivery/online/phone)
-- ============================================
-- 기존 mission_type CHECK 제약 변경을 위한 마이그레이션
ALTER TABLE missions DROP CONSTRAINT IF EXISTS missions_mission_type_check;
ALTER TABLE missions ADD CONSTRAINT missions_mission_type_check
  CHECK (mission_type IN ('visit', 'delivery', 'online', 'phone', 'offline', 'ecommerce'));

-- GPS 필요 여부 컬럼 추가 (방문 미션에서만 선택적)
ALTER TABLE missions ADD COLUMN IF NOT EXISTS gps_required BOOLEAN DEFAULT FALSE;

-- 인증 방식 컬럼 추가
ALTER TABLE missions ADD COLUMN IF NOT EXISTS verification_method VARCHAR(50);

-- 기존 데이터 마이그레이션
UPDATE missions SET mission_type = 'visit' WHERE mission_type = 'offline';
UPDATE missions SET mission_type = 'online' WHERE mission_type = 'ecommerce';

-- ============================================
-- Phase 4: 업체 보호 시스템 (이의제기 워크플로우 + 증거 첨부)
-- ============================================

-- 이의제기 상세 필드 추가
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS dispute_status VARCHAR(20) DEFAULT 'pending'
  CHECK (dispute_status IN ('pending', 'investigating', 'resolved'));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS dispute_outcome VARCHAR(20)
  CHECK (dispute_outcome IN ('upheld', 'modified', 'removed'));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS dispute_resolution_deadline TIMESTAMPTZ;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS dispute_investigated_by UUID REFERENCES users(id);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS dispute_admin_notes TEXT;

-- 이의제기 증거 테이블
CREATE TABLE IF NOT EXISTS dispute_evidences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  uploaded_by UUID NOT NULL REFERENCES users(id),
  file_url TEXT NOT NULL,
  file_type VARCHAR(20) DEFAULT 'image' CHECK (file_type IN ('image', 'document', 'screenshot')),
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dispute_evidences_review ON dispute_evidences(review_id);

-- ============================================
-- Phase 5: 데이터 정합성 개선
-- ============================================
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS referral_reward_processed BOOLEAN DEFAULT FALSE;

-- ============================================
-- Phase 6: 스키마 정합성, 성능, 보안 개선
-- ============================================
-- 이 섹션은 V4, G4, I6, S9, S10, S11, S12, I9, V7/S8 이슈를 해결합니다.

-- --------------------------------------------
-- V4: Referral abuse limits (추천인 악용 방지)
-- --------------------------------------------
-- 리퍼럴 최대 횟수 제한 및 전화번호 인증 여부
ALTER TABLE users ADD COLUMN IF NOT EXISTS max_referrals INT DEFAULT 10;
ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_phone_verified BOOLEAN DEFAULT FALSE;

-- 추천인당 최대 10개의 활성 리퍼럴만 허용하는 제약 (트리거로 구현)
CREATE OR REPLACE FUNCTION check_max_referrals()
RETURNS TRIGGER AS $$
DECLARE
  active_count INT;
  max_allowed INT;
BEGIN
  SELECT COUNT(*) INTO active_count
  FROM referrals
  WHERE referrer_id = NEW.referrer_id
    AND status NOT IN ('expired');

  SELECT COALESCE(max_referrals, 10) INTO max_allowed
  FROM users
  WHERE id = NEW.referrer_id;

  IF active_count >= max_allowed THEN
    RAISE EXCEPTION 'Referrer has reached maximum active referrals (%)', max_allowed;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS enforce_max_referrals ON referrals;
CREATE TRIGGER enforce_max_referrals
  BEFORE INSERT ON referrals
  FOR EACH ROW EXECUTE FUNCTION check_max_referrals();

-- --------------------------------------------
-- G4: Business onboarding state (업체 온보딩 상태 백엔드 저장)
-- --------------------------------------------
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT FALSE;
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS onboarding_completed_at TIMESTAMPTZ;

-- --------------------------------------------
-- I6: Missing indexes (스케줄러 성능에 필수적인 누락 인덱스)
-- --------------------------------------------
-- 모집 마감일 기준 미션 조회 (스케줄러: 마감 처리)
CREATE INDEX IF NOT EXISTS idx_missions_recruitment_deadline ON missions(recruitment_deadline) WHERE status = 'recruiting';

-- 배정된 리뷰어가 있는 미션 조회
CREATE INDEX IF NOT EXISTS idx_missions_assigned_reviewer ON missions(assigned_reviewer_id) WHERE assigned_reviewer_id IS NOT NULL;

-- 자동 정산 대상 에스크로 조회 (스케줄러: 자동 지급)
CREATE INDEX IF NOT EXISTS idx_escrows_auto_release ON escrows(auto_release_at) WHERE auto_release_executed = false AND status = 'paid';

-- 제출/프리뷰 상태 리뷰 조회 (프리뷰 기간 만료 처리)
CREATE INDEX IF NOT EXISTS idx_reviews_submitted_at ON reviews(submitted_at) WHERE status IN ('submitted', 'preview');

-- 리뷰어별 리뷰 조회
CREATE INDEX IF NOT EXISTS idx_reviews_reviewer_id ON reviews(reviewer_id);

-- 만료되지 않은 이메일 인증 코드 조회 (정리 작업)
CREATE INDEX IF NOT EXISTS idx_email_verifications_expires ON email_verifications(expires_at) WHERE verified = false;

-- --------------------------------------------
-- S9: Soft delete support (논리적 삭제 지원)
-- --------------------------------------------
ALTER TABLE users ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- 삭제된 레코드 조회를 위한 인덱스
CREATE INDEX IF NOT EXISTS idx_users_deleted ON users(deleted_at) WHERE deleted_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_businesses_deleted ON businesses(deleted_at) WHERE deleted_at IS NOT NULL;

-- --------------------------------------------
-- S10: RLS policy cleanup (RLS 정책 안내)
-- --------------------------------------------
-- NOTE: 현재 RLS 정책들은 Supabase Auth (auth.uid())를 전제로 작성되어 있으나,
-- 백엔드는 JWT + Supabase service key를 사용하여 인증을 처리합니다.
-- 따라서 기존 RLS 정책들은 실제로 적용되지 않으며,
-- 향후 Supabase Auth로 마이그레이션할 경우를 대비한 플레이스홀더입니다.
--
-- 영향을 받는 기존 정책:
--   - "Users can view own data" ON users
--   - "Users can update own data" ON users
--   - "Published reviews are public" ON reviews
--   - "Users can view own social accounts" ON social_accounts
--
-- 백엔드 서비스 키는 RLS를 바이패스하므로 현재 운영에는 영향 없음.
-- Supabase Auth 마이그레이션 시 이 정책들을 실제 요구사항에 맞게 업데이트할 것.

-- --------------------------------------------
-- S11: JSONB GIN indexes (JSONB 필드 검색 성능 개선)
-- --------------------------------------------
CREATE INDEX IF NOT EXISTS idx_notifications_data ON notifications USING GIN(data);
CREATE INDEX IF NOT EXISTS idx_collusion_flags_evidence ON collusion_flags USING GIN(evidence);
CREATE INDEX IF NOT EXISTS idx_training_modules_content ON training_modules USING GIN(content_data);

-- --------------------------------------------
-- S12: Mission type migration (미션 타입 정리: offline→visit, ecommerce→online)
-- --------------------------------------------
-- 레거시 미션 타입 마이그레이션 (Phase 2에서 이미 실행되었을 수 있지만 안전하게 재실행)
UPDATE missions SET mission_type = 'visit' WHERE mission_type = 'offline';
UPDATE missions SET mission_type = 'online' WHERE mission_type = 'ecommerce';

-- CHECK 제약 업데이트: 이제 새로운 4가지 타입만 허용 (레거시 타입 제거)
ALTER TABLE missions DROP CONSTRAINT IF EXISTS missions_mission_type_check;
ALTER TABLE missions ADD CONSTRAINT missions_mission_type_check
  CHECK (mission_type IN ('visit', 'delivery', 'online', 'phone'));

-- businesses 테이블의 business_type도 일관성을 위해 확장
ALTER TABLE businesses DROP CONSTRAINT IF EXISTS businesses_business_type_check;
ALTER TABLE businesses ADD CONSTRAINT businesses_business_type_check
  CHECK (business_type IN ('offline', 'ecommerce', 'online', 'service'));

-- --------------------------------------------
-- I9: Table partitioning preparation (테이블 파티셔닝 준비)
-- --------------------------------------------
-- TODO: 데이터 볼륨이 커지면 다음 테이블들을 월별로 파티셔닝할 것:
--   - notifications: created_at 기준 월별 파티셔닝
--   - analytics_events: created_at 기준 월별 파티셔닝
--   - session_fingerprints: created_at 기준 월별 파티셔닝
-- 현재는 정리(cleanup) 쿼리 성능을 위한 인덱스만 추가

CREATE INDEX IF NOT EXISTS idx_analytics_events_created ON analytics_events(created_at);
CREATE INDEX IF NOT EXISTS idx_session_fingerprints_created ON session_fingerprints(created_at);

-- --------------------------------------------
-- V7/S8: Escrow hold timeout (에스크로 보류 타임아웃)
-- --------------------------------------------
-- 에스크로가 'hold' 상태로 들어간 시점과 에스컬레이션 여부 추적
ALTER TABLE escrows ADD COLUMN IF NOT EXISTS hold_started_at TIMESTAMPTZ;
ALTER TABLE escrows ADD COLUMN IF NOT EXISTS hold_escalated BOOLEAN DEFAULT FALSE;

-- 보류 타임아웃 모니터링을 위한 인덱스
CREATE INDEX IF NOT EXISTS idx_escrows_hold_timeout ON escrows(hold_started_at) WHERE status = 'hold' AND hold_escalated = false;

-- ============================================
-- 리뷰 투표 테이블 (Review Votes)
-- ============================================
CREATE TABLE IF NOT EXISTS review_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  vote_type VARCHAR(20) NOT NULL CHECK (vote_type IN ('helpful', 'not_helpful')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(review_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_review_votes_review ON review_votes(review_id);
CREATE INDEX IF NOT EXISTS idx_review_votes_user ON review_votes(user_id);

-- 리뷰 helpful/not_helpful 카운트 감소 RPC 함수
CREATE OR REPLACE FUNCTION decrement_helpful_count(p_review_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE reviews
  SET helpful_count = GREATEST(helpful_count - 1, 0),
      updated_at = NOW()
  WHERE id = p_review_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_not_helpful_count(p_review_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE reviews
  SET not_helpful_count = GREATEST(not_helpful_count - 1, 0),
      updated_at = NOW()
  WHERE id = p_review_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 리뷰 신고 테이블 (Review Reports)
-- ============================================
CREATE TABLE IF NOT EXISTS review_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category VARCHAR(30) NOT NULL DEFAULT 'other'
    CHECK (category IN ('spam', 'inappropriate', 'fake', 'harassment', 'other')),
  reason TEXT,
  description TEXT,
  status VARCHAR(20) DEFAULT 'pending'
    CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(review_id, reporter_id)
);
CREATE INDEX IF NOT EXISTS idx_review_reports_review ON review_reports(review_id);
CREATE INDEX IF NOT EXISTS idx_review_reports_status ON review_reports(status);

-- ============================================
-- 미션 보상 타입 (Reward Type): 현금 / 무료체험
-- --------------------------------------------
-- free_experience: 리뷰어에게 현금이 아닌 "무료 체험(가게 제공)"을 보상으로 줌.
--   → 결제/에스크로/정산을 거치지 않음. 플랫폼 현금 지출 0원. 구독 플랜에 포함.
-- cash: 기존 현금 정산 방식(reviewer_fee를 에스크로로 지급).
-- ============================================
ALTER TABLE missions ADD COLUMN IF NOT EXISTS reward_type VARCHAR(20) DEFAULT 'cash';
ALTER TABLE missions DROP CONSTRAINT IF EXISTS missions_reward_type_check;
ALTER TABLE missions ADD CONSTRAINT missions_reward_type_check
  CHECK (reward_type IN ('cash', 'free_experience'));

-- 무료체험으로 제공하는 내용과 추정 가치(표시·한도용; 실제 결제는 없음)
ALTER TABLE missions ADD COLUMN IF NOT EXISTS experience_description TEXT;
ALTER TABLE missions ADD COLUMN IF NOT EXISTS experience_value INT;

-- 업체의 월별 무료체험 미션 사용량 집계(구독 플랜 한도 체크)를 위한 인덱스
CREATE INDEX IF NOT EXISTS idx_missions_free_experience
  ON missions(business_id, created_at)
  WHERE reward_type = 'free_experience';
