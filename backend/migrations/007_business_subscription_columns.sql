-- ============================================
-- 007: 업체 구독 결제 추적 컬럼 추가
-- --------------------------------------------
-- 기존 코드가 참조하던 subscription_payment_key, subscription_order_id를
-- 실제 컬럼으로 추가한다. 결제 환불/감사 추적에 필요.
-- 기존 컬럼명(subscription_start, subscription_end, auto_renew)은 유지.
-- ============================================

ALTER TABLE businesses ADD COLUMN IF NOT EXISTS subscription_payment_key VARCHAR(200);
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS subscription_order_id VARCHAR(200);

-- 결제 키로 빠르게 환불·조회할 수 있도록 인덱스
CREATE INDEX IF NOT EXISTS idx_businesses_subscription_payment_key
  ON businesses(subscription_payment_key)
  WHERE subscription_payment_key IS NOT NULL;
