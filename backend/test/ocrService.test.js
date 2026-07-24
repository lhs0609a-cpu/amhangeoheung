const { test } = require('node:test');
const assert = require('node:assert');
const { parseReceiptText, isOcrConfigured } = require('../src/utils/ocrService');

test('parseReceiptText: 업체명/금액/날짜 추출', () => {
  const text = [
    '스타벅스 강남점',
    '사업자번호 123-45-67890',
    '2026-07-20',
    '아메리카노 4,500',
    '합계 4,500원',
  ].join('\n');

  const parsed = parseReceiptText(text);
  assert.strictEqual(parsed.storeName, '스타벅스 강남점');
  assert.strictEqual(parsed.amount, 4500);
  assert.strictEqual(parsed.date, '2026-07-20');
  assert.ok(parsed.confidence > 0.5, `confidence too low: ${parsed.confidence}`);
});

test('parseReceiptText: 사업자번호는 업체명으로 오인하지 않음', () => {
  const text = '123-45-67890\n김밥천국\n합계 8,000원';
  const parsed = parseReceiptText(text);
  assert.strictEqual(parsed.storeName, '김밥천국');
});

test('parseReceiptText: 빈 텍스트는 confidence 0', () => {
  const parsed = parseReceiptText('');
  assert.strictEqual(parsed.confidence, 0);
  assert.strictEqual(parsed.amount, null);
});

test('parseReceiptText: confidence 는 0~1 범위', () => {
  const parsed = parseReceiptText('가게\n합계 1,000원\n2026-01-01');
  assert.ok(parsed.confidence >= 0 && parsed.confidence <= 1);
});

test('isOcrConfigured: 키 미설정 시 false (fail-closed)', () => {
  // 이 테스트 환경에는 GOOGLE_VISION_API_KEY 가 없다.
  assert.strictEqual(isOcrConfigured(), false);
});
