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
