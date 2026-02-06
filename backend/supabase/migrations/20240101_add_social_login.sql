-- 소셜 로그인 지원을 위한 마이그레이션
-- 기존 데이터베이스에 실행하세요

-- 1. users 테이블에 소셜 로그인 관련 컬럼 추가
ALTER TABLE users
  ALTER COLUMN password DROP NOT NULL,
  ALTER COLUMN phone DROP NOT NULL;

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(20) DEFAULT 'email' CHECK (auth_provider IN ('email', 'google', 'apple', 'kakao')),
  ADD COLUMN IF NOT EXISTS is_social_only BOOLEAN DEFAULT FALSE;

-- 2. 소셜 계정 연결 테이블 생성
CREATE TABLE IF NOT EXISTS social_accounts (
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

-- 3. 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_social_accounts_user ON social_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_social_accounts_provider ON social_accounts(provider, provider_id);

-- 4. RLS 정책
ALTER TABLE social_accounts ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'social_accounts' AND policyname = 'Users can view own social accounts'
  ) THEN
    CREATE POLICY "Users can view own social accounts" ON social_accounts FOR SELECT USING (auth.uid()::text = user_id::text);
  END IF;
END
$$;

-- 5. 업데이트 트리거
DROP TRIGGER IF EXISTS social_accounts_updated_at ON social_accounts;
CREATE TRIGGER social_accounts_updated_at BEFORE UPDATE ON social_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at();
