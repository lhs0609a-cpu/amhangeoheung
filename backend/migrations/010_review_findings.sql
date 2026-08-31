-- ============================================
-- 010: 지적사항을 추적 가능한 실체로 분리
-- --------------------------------------------
-- 지금까지 지적사항은 reviews.cons 의 TEXT[] 뿐이었다. 문자열 배열이라
-- "이 지적이 나중에 고쳐졌는지"를 물어볼 수가 없었고, 그래서 소비자 화면의
-- '개선점'은 실제 감찰관이 쓴 지적이 아니라 카테고리 점수에서 계산한
-- 추정치를 보여주고 있었다.
--
-- 이 제품의 유일한 차별점은 별점이 아니라
--   지적했다 → 업체가 약속했다 → 다시 가보니 고쳤더라
-- 는 서사다. 그걸 보여주려면 지적사항이 리뷰를 건너 살아남아야 한다.
--
-- ── 규칙 ─────────────────────────────────────
-- status 를 'fixed' 로 바꿀 수 있는 것은 **재감찰뿐이다.**
-- 업체는 promise 만 남길 수 있고 status 는 건드리지 못한다. 업체가 스스로
-- "고쳤다"고 표시할 수 있으면 "업체가 결과를 못 바꾼다"는 제품의 주장이
-- 그 자리에서 무너진다. 애플리케이션 레벨 규칙이자 아래 RLS 로도 막는다.
-- ============================================

CREATE TABLE IF NOT EXISTS review_findings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,

  -- 이 지적을 처음 남긴 감찰
  review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,

  title TEXT NOT NULL,
  detail TEXT,

  status VARCHAR(20) NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'fixed')),

  first_found_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- 같은 지적이 재감찰에서 또 나온 횟수. 1 이면 한 번만 지적된 것.
  -- 2 이상이면 "고치겠다고 하고 안 고친" 항목이라 소비자 화면에서 더 무겁게 쓴다.
  recurrence_count INT NOT NULL DEFAULT 1,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- 업체가 남긴 개선 약속. status 와 무관하다.
  promise TEXT,
  promised_at TIMESTAMPTZ,

  -- 개선을 확인한 재감찰. status='fixed' 는 반드시 이 값과 함께 채워진다.
  resolved_review_id UUID REFERENCES reviews(id) ON DELETE SET NULL,
  resolved_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 'fixed' 인데 확인한 감찰이 없는 행을 만들 수 없게 한다.
-- 업체가 임의로 status 만 바꾸는 경로를 DB 레벨에서 차단한다.
ALTER TABLE review_findings DROP CONSTRAINT IF EXISTS review_findings_fixed_needs_proof;
ALTER TABLE review_findings ADD CONSTRAINT review_findings_fixed_needs_proof
  CHECK (
    status <> 'fixed'
    OR (resolved_review_id IS NOT NULL AND resolved_at IS NOT NULL)
  );

CREATE INDEX IF NOT EXISTS idx_review_findings_business
  ON review_findings (business_id, status);
CREATE INDEX IF NOT EXISTS idx_review_findings_review
  ON review_findings (review_id);

-- 같은 감찰에서 같은 문구가 중복 저장되지 않게 한다.
CREATE UNIQUE INDEX IF NOT EXISTS idx_review_findings_unique_per_review
  ON review_findings (review_id, title);

COMMENT ON TABLE review_findings IS
  '감찰에서 지적된 항목. 리뷰를 건너 살아남아 개선 여부를 추적한다.';
COMMENT ON COLUMN review_findings.status IS
  'open|fixed. fixed 로 바꿀 수 있는 것은 재감찰뿐이며 업체는 불가.';
COMMENT ON COLUMN review_findings.promise IS
  '업체가 남긴 개선 약속. 이것만으로는 status 가 바뀌지 않는다.';
COMMENT ON COLUMN review_findings.recurrence_count IS
  '같은 지적이 반복된 횟수. 2 이상이면 약속하고 안 고친 항목.';

-- updated_at 자동 갱신
CREATE OR REPLACE FUNCTION touch_review_findings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_review_findings_updated_at ON review_findings;
CREATE TRIGGER trg_review_findings_updated_at
  BEFORE UPDATE ON review_findings
  FOR EACH ROW EXECUTE FUNCTION touch_review_findings_updated_at();

-- ── RLS ──────────────────────────────────────
-- 서비스 롤(백엔드)만 쓰기가 가능하다. 업체 계정이 직접 status 를 바꾸는
-- 경로를 아예 열지 않는다.
ALTER TABLE review_findings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS review_findings_read_published ON review_findings;
CREATE POLICY review_findings_read_published ON review_findings
  FOR SELECT USING (true);
