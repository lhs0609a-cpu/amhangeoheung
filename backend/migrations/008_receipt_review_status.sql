-- ============================================
-- 008: 영수증 검토 상태 및 OCR 데이터 컬럼 추가
-- --------------------------------------------
-- 기존 코드가 참조하던 receipt_ocr_data, receipt_uploaded_at 를 실제 컬럼으로
-- 추가하고, 영수증 검증 흐름을 명시적 상태로 관리하기 위한
-- receipt_review_status 를 추가한다.
--
-- 정책(fail-closed): OCR 이 성공적으로 실행되고 신뢰도가 임계값(0.6) 이상일 때만
-- 'auto_verified'. OCR 미설정/실패/낮은 신뢰도는 'manual_review_required' 로
-- 남겨 사람이 검토한다. 자동 승인은 절대 이 관문을 우회하지 않는다.
-- ============================================

ALTER TABLE reviews ADD COLUMN IF NOT EXISTS receipt_ocr_data JSONB;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS receipt_uploaded_at TIMESTAMPTZ;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS receipt_review_status VARCHAR(30) DEFAULT 'pending';

ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_receipt_review_status_check;
ALTER TABLE reviews ADD CONSTRAINT reviews_receipt_review_status_check
  CHECK (receipt_review_status IN (
    'pending',                 -- 영수증 미업로드
    'auto_verified',           -- OCR 자동 검증 통과
    'manual_review_required',  -- 사람이 검토해야 함
    'approved',                -- 관리자 수동 승인
    'rejected'                 -- 관리자 반려
  ));

-- 관리자 수동 검토 감사 컬럼
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS receipt_review_reason TEXT;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS receipt_reviewed_by UUID REFERENCES users(id);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS receipt_reviewed_at TIMESTAMPTZ;

-- 관리자 수동 검토 큐를 빠르게 조회하기 위한 인덱스
CREATE INDEX IF NOT EXISTS idx_reviews_receipt_review_status
  ON reviews(receipt_review_status)
  WHERE receipt_review_status = 'manual_review_required';
