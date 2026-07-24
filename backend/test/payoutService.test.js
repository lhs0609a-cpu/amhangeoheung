const { test } = require('node:test');
const assert = require('node:assert');
const {
  isPayoutConfigured,
  requestBankTransfer,
  requestAccountVerification,
} = require('../src/utils/payoutService');

// 이 테스트 환경에는 PAYOUT_* 환경변수가 없다 → 미설정 상태.

test('미설정 시 isPayoutConfigured 는 false (fail-closed)', () => {
  assert.strictEqual(isPayoutConfigured(), false);
});

test('미설정 시 송금은 성공을 반환하지 않고 hold 처리', async () => {
  const r = await requestBankTransfer({
    bankName: '국민',
    accountNumber: '123456',
    accountHolder: '홍길동',
    amount: 10000,
  });
  assert.strictEqual(r.success, false);
  assert.strictEqual(r.notConfigured, true);
  assert.strictEqual(r.pending, true);
});

test('미설정 시 계좌 검증도 성공을 반환하지 않음', async () => {
  const r = await requestAccountVerification({
    bankName: '국민',
    accountNumber: '123456',
    accountHolder: '홍길동',
  });
  assert.strictEqual(r.success, false);
  assert.strictEqual(r.notConfigured, true);
});
