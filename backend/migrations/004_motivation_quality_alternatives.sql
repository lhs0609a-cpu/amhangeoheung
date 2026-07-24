-- Migration 004: Reviewer Motivation + Review Quality + Alternatives + Anti-Collusion
-- 리뷰어 동기부여 + 리뷰 품질 + 대안 추천 + 담합 방지 강화

-- ========================================
-- 1. 리뷰 토픽 정의 (카테고리별 태그)
-- ========================================
CREATE TABLE IF NOT EXISTS review_topic_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category VARCHAR(50) NOT NULL,
  topic_key VARCHAR(50) NOT NULL,
  topic_label VARCHAR(100) NOT NULL,
  topic_type VARCHAR(20) DEFAULT 'positive' CHECK (topic_type IN ('positive', 'negative', 'neutral')),
  icon VARCHAR(10),
  sort_order INT DEFAULT 0,
  UNIQUE(category, topic_key)
);

-- ========================================
-- 2. 리뷰에 선택된 토픽들
-- ========================================
CREATE TABLE IF NOT EXISTS review_topics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  topic_key VARCHAR(50) NOT NULL,
  topic_label VARCHAR(100) NOT NULL,
  topic_type VARCHAR(20) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(review_id, topic_key)
);

-- ========================================
-- 3. 내부 고발 (리뷰어가 업체의 뒷돈 제안 신고)
-- ========================================
CREATE TABLE IF NOT EXISTS whistleblower_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES users(id),
  reported_business_id UUID NOT NULL REFERENCES businesses(id),
  reported_mission_id UUID REFERENCES missions(id),
  report_type VARCHAR(30) NOT NULL CHECK (report_type IN ('kickback_offer', 'bribe_attempt', 'review_manipulation', 'threat')),
  description TEXT NOT NULL,
  evidence_urls TEXT[],
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'investigating', 'confirmed', 'dismissed')),
  admin_notes TEXT,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================================
-- 4. 리뷰어 수익 이력
-- ========================================
CREATE TABLE IF NOT EXISTS reviewer_earnings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reviewer_id UUID NOT NULL REFERENCES users(id),
  mission_id UUID REFERENCES missions(id),
  escrow_id UUID REFERENCES escrows(id),
  earning_type VARCHAR(30) DEFAULT 'mission_pay' CHECK (earning_type IN ('mission_pay', 'grade_bonus', 'quality_bonus', 'whistleblower_reward')),
  base_amount INT NOT NULL,
  grade_bonus INT DEFAULT 0,
  quality_bonus INT DEFAULT 0,
  total_amount INT NOT NULL,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'forfeited')),
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================================
-- 5. 기존 테이블 컬럼 추가
-- ========================================

-- reviews 테이블
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS content_tips TEXT;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS trust_weight DECIMAL(3,2) DEFAULT 1.0;

-- businesses 테이블
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS trust_weighted_rating DECIMAL(3,2) DEFAULT 0;

-- users 테이블
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_earnings INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS quality_bonus_count INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_permanently_banned BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS stealth_score INT DEFAULT 50;
ALTER TABLE users ADD COLUMN IF NOT EXISTS warning_count INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS quality_score INT DEFAULT 100;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_certified BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS detection_test_count INT DEFAULT 0;

-- ========================================
-- 6. 초기 토픽 데이터 삽입
-- ========================================

-- 음식점 토픽
INSERT INTO review_topic_definitions (category, topic_key, topic_label, topic_type, icon, sort_order) VALUES
  ('restaurant', 'taste_good', '맛있어요', 'positive', '😋', 1),
  ('restaurant', 'service_good', '친절해요', 'positive', '😊', 2),
  ('restaurant', 'clean', '깨끗해요', 'positive', '✨', 3),
  ('restaurant', 'value_good', '가성비 좋아요', 'positive', '💰', 4),
  ('restaurant', 'atmosphere', '분위기 좋아요', 'positive', '🎵', 5),
  ('restaurant', 'portion_big', '양이 많아요', 'positive', '🍽️', 6),
  ('restaurant', 'taste_bad', '맛이 아쉬워요', 'negative', '😕', 7),
  ('restaurant', 'service_bad', '불친절해요', 'negative', '😤', 8),
  ('restaurant', 'dirty', '위생이 아쉬워요', 'negative', '🚫', 9),
  ('restaurant', 'expensive', '비싸요', 'negative', '💸', 10),
  ('restaurant', 'noisy', '시끄러워요', 'negative', '🔊', 11),
  ('restaurant', 'wait_long', '대기가 길어요', 'negative', '⏳', 12)
ON CONFLICT (category, topic_key) DO NOTHING;

-- 병원 토픽
INSERT INTO review_topic_definitions (category, topic_key, topic_label, topic_type, icon, sort_order) VALUES
  ('hospital', 'explain_well', '설명을 잘해요', 'positive', '📋', 1),
  ('hospital', 'kind_doctor', '의사가 친절해요', 'positive', '👨‍⚕️', 2),
  ('hospital', 'clean', '시설이 깨끗해요', 'positive', '✨', 3),
  ('hospital', 'wait_short', '대기시간 짧아요', 'positive', '⚡', 4),
  ('hospital', 'skill_good', '실력이 좋아요', 'positive', '💪', 5),
  ('hospital', 'price_fair', '가격이 합리적이에요', 'positive', '💰', 6),
  ('hospital', 'explain_bad', '설명이 부족해요', 'negative', '❓', 7),
  ('hospital', 'unkind', '불친절해요', 'negative', '😤', 8),
  ('hospital', 'wait_long', '대기가 너무 길어요', 'negative', '⏳', 9),
  ('hospital', 'expensive', '비싸요', 'negative', '💸', 10)
ON CONFLICT (category, topic_key) DO NOTHING;

-- 미용 토픽
INSERT INTO review_topic_definitions (category, topic_key, topic_label, topic_type, icon, sort_order) VALUES
  ('beauty', 'skill_good', '실력이 좋아요', 'positive', '💇', 1),
  ('beauty', 'style_match', '원하는 스타일 나와요', 'positive', '🎨', 2),
  ('beauty', 'consult_good', '상담을 잘해줘요', 'positive', '💬', 3),
  ('beauty', 'atmosphere', '분위기 좋아요', 'positive', '🎵', 4),
  ('beauty', 'clean', '깨끗해요', 'positive', '✨', 5),
  ('beauty', 'skill_bad', '실력이 아쉬워요', 'negative', '😕', 6),
  ('beauty', 'expensive', '비싸요', 'negative', '💸', 7),
  ('beauty', 'upsell', '추가 판매를 해요', 'negative', '🚫', 8)
ON CONFLICT (category, topic_key) DO NOTHING;

-- 학원 토픽
INSERT INTO review_topic_definitions (category, topic_key, topic_label, topic_type, icon, sort_order) VALUES
  ('education', 'teach_well', '잘 가르쳐요', 'positive', '📚', 1),
  ('education', 'manage_well', '관리가 잘 돼요', 'positive', '📋', 2),
  ('education', 'result_good', '성적이 올라요', 'positive', '📈', 3),
  ('education', 'facility_good', '시설이 좋아요', 'positive', '🏫', 4),
  ('education', 'teach_bad', '수업이 아쉬워요', 'negative', '😕', 5),
  ('education', 'expensive', '비싸요', 'negative', '💸', 6)
ON CONFLICT (category, topic_key) DO NOTHING;

-- 운동/피트니스 토픽
INSERT INTO review_topic_definitions (category, topic_key, topic_label, topic_type, icon, sort_order) VALUES
  ('fitness', 'equipment_good', '기구가 좋아요', 'positive', '🏋️', 1),
  ('fitness', 'trainer_good', '트레이너가 좋아요', 'positive', '💪', 2),
  ('fitness', 'clean', '깨끗해요', 'positive', '✨', 3),
  ('fitness', 'crowded', '사람이 많아요', 'negative', '🚶', 4),
  ('fitness', 'expensive', '비싸요', 'negative', '💸', 5)
ON CONFLICT (category, topic_key) DO NOTHING;

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_review_topics_review_id ON review_topics(review_id);
CREATE INDEX IF NOT EXISTS idx_review_topic_defs_category ON review_topic_definitions(category);
CREATE INDEX IF NOT EXISTS idx_whistleblower_reports_status ON whistleblower_reports(status);
CREATE INDEX IF NOT EXISTS idx_whistleblower_reports_reporter ON whistleblower_reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reviewer_earnings_reviewer ON reviewer_earnings(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_reviewer_earnings_status ON reviewer_earnings(status);
CREATE INDEX IF NOT EXISTS idx_businesses_trust_weighted ON businesses(trust_weighted_rating DESC);
