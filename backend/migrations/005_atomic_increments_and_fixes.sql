-- Migration 005: Atomic increment functions + schema fixes
-- 정산 Race Condition 방지를 위한 원자적 증가 함수 + 스키마 정합성

-- ========================================
-- 1. 원자적 사용자 수익 증가 함수
-- ========================================
CREATE OR REPLACE FUNCTION increment_user_earnings(p_user_id UUID, p_amount INT)
RETURNS VOID AS $$
BEGIN
  UPDATE users
  SET total_earnings = COALESCE(total_earnings, 0) + p_amount
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 2. 원자적 에스크로 재시도 횟수 증가 함수
-- ========================================
CREATE OR REPLACE FUNCTION increment_escrow_retry(p_escrow_id UUID)
RETURNS TABLE(payout_retry_count INT) AS $$
BEGIN
  RETURN QUERY
  UPDATE escrows
  SET payout_retry_count = COALESCE(escrows.payout_retry_count, 0) + 1
  WHERE id = p_escrow_id
  RETURNING escrows.payout_retry_count;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 3. 원자적 completed_missions 증가 함수
-- ========================================
CREATE OR REPLACE FUNCTION increment_completed_missions(p_user_id UUID)
RETURNS TABLE(completed_missions INT) AS $$
BEGIN
  RETURN QUERY
  UPDATE users
  SET completed_missions = COALESCE(users.completed_missions, 0) + 1
  WHERE id = p_user_id
  RETURNING users.completed_missions;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 4. 추천 보상 원자적 처리 함수
-- ========================================
CREATE OR REPLACE FUNCTION mark_referral_reward_processed(p_review_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  was_updated BOOLEAN;
BEGIN
  UPDATE reviews
  SET referral_reward_processed = TRUE
  WHERE id = p_review_id
    AND (referral_reward_processed IS NULL OR referral_reward_processed = FALSE);

  GET DIAGNOSTICS was_updated = ROW_COUNT > 0;
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 5. 금액 필드 CHECK 제약 (P1이지만 함께 처리)
-- ========================================
DO $$
BEGIN
  -- missions 금액 필드
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_missions_product_price') THEN
    ALTER TABLE missions ADD CONSTRAINT chk_missions_product_price CHECK (product_price >= 0);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_missions_reviewer_fee') THEN
    ALTER TABLE missions ADD CONSTRAINT chk_missions_reviewer_fee CHECK (reviewer_fee >= 0);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_missions_platform_fee') THEN
    ALTER TABLE missions ADD CONSTRAINT chk_missions_platform_fee CHECK (platform_fee >= 0);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_missions_total_amount') THEN
    ALTER TABLE missions ADD CONSTRAINT chk_missions_total_amount CHECK (total_amount >= 0);
  END IF;
  -- escrows 금액 필드
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_escrows_total_amount') THEN
    ALTER TABLE escrows ADD CONSTRAINT chk_escrows_total_amount CHECK (total_amount >= 0);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_escrows_product_cost') THEN
    ALTER TABLE escrows ADD CONSTRAINT chk_escrows_product_cost CHECK (product_cost >= 0);
  END IF;
END $$;

-- ========================================
-- 6. 스키마 컬럼 타입 불일치 해소 (P0-11)
-- stealth_score: INT DEFAULT 50 (migration 004 기준 통일)
-- quality_score: INT DEFAULT 100 (migration 004 기준 통일)
-- ========================================
-- schema.sql에서 DECIMAL로 정의했을 수 있으므로 INT로 변경
DO $$
BEGIN
  -- stealth_score를 INT로 통일 (기본값 50)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'stealth_score'
    AND data_type != 'integer'
  ) THEN
    ALTER TABLE users ALTER COLUMN stealth_score TYPE INT USING stealth_score::INT;
    ALTER TABLE users ALTER COLUMN stealth_score SET DEFAULT 50;
  END IF;

  -- quality_score를 INT로 통일 (기본값 100)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'quality_score'
    AND data_type != 'integer'
  ) THEN
    ALTER TABLE users ALTER COLUMN quality_score TYPE INT USING quality_score::INT;
    ALTER TABLE users ALTER COLUMN quality_score SET DEFAULT 100;
  END IF;
END $$;

-- ========================================
-- 7. 누락된 인덱스 추가 (성능)
-- ========================================
CREATE INDEX IF NOT EXISTS idx_reviews_mission_id ON reviews(mission_id);
CREATE INDEX IF NOT EXISTS idx_review_photos_review_id ON review_photos(review_id);
CREATE INDEX IF NOT EXISTS idx_reviews_business_status ON reviews(business_id, status);
