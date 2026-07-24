const { test } = require('node:test');
const assert = require('node:assert');
const {
  isIdentityVerificationConfigured,
  verifyIdentity,
  normalize,
} = require('../src/utils/identityVerificationService');

// 이 테스트 환경에는 IDENTITY_PROVIDER 등 환경변수가 없다 → 미설정 상태.

test('미설정 시 isIdentityVerificationConfigured 는 false (fail-closed)', () => {
  assert.strictEqual(isIdentityVerificationConfigured(), false);
});

test('미설정 시 verifyIdentity 는 notConfigured, verified=false', async () => {
  const result = await verifyIdentity({ receiptId: 'imp_123456' });
  assert.strictEqual(result.notConfigured, true);
  assert.strictEqual(result.verified, false);
  assert.strictEqual(result.success, false);
});

test('미설정 시에는 receiptId 유무와 무관하게 절대 verified=true 를 반환하지 않음', async () => {
  const a = await verifyIdentity({ receiptId: '' });
  const b = await verifyIdentity({});
  assert.notStrictEqual(a.verified, true);
  assert.notStrictEqual(b.verified, true);
});

test('normalize: CI 없으면 실패', () => {
  const r = normalize({ name: '홍길동' }, 'portone');
  assert.strictEqual(r.success, false);
});

test('normalize: CI/DI/전화 정규화 (하이픈 제거)', () => {
  const r = normalize(
    { ci: 'CI_ABC', di: 'DI_XYZ', name: '홍길동', phone: '010-1234-5678' },
    'portone'
  );
  assert.strictEqual(r.verified, true);
  assert.strictEqual(r.ci, 'CI_ABC');
  assert.strictEqual(r.di, 'DI_XYZ');
  assert.strictEqual(r.phone, '01012345678');
  assert.strictEqual(r.provider, 'portone');
});

test('normalize: unique_key/unique_in_site 별칭도 CI/DI 로 매핑', () => {
  const r = normalize({ unique_key: 'K', unique_in_site: 'S' }, 'nice');
  assert.strictEqual(r.ci, 'K');
  assert.strictEqual(r.di, 'S');
});
