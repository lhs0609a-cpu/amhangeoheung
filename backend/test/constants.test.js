const { test } = require('node:test');
const assert = require('node:assert');
const C = require('../src/config/constants');

test('플랫폼 수수료율은 10%', () => {
  assert.strictEqual(C.PLATFORM_FEE_RATE, 0.10);
});

test('보상 타입은 cash / free_experience', () => {
  assert.deepStrictEqual(
    Object.values(C.REWARD_TYPES).sort(),
    ['cash', 'free_experience']
  );
});

test('구독 플랜 가격 단조 증가 (starter < growth < pro)', () => {
  const { starter, growth, pro } = C.PLAN_DETAILS;
  assert.ok(starter.price < growth.price);
  assert.ok(growth.price < pro.price);
});

test('pro 플랜 무료체험 한도는 무제한(-1)', () => {
  assert.strictEqual(C.PLAN_DETAILS.pro.monthlyFreeExperience, -1);
});

test('등급 배율은 rookie<regular<senior<master 로 증가', () => {
  const g = C.GRADE_BENEFITS;
  assert.ok(g.rookie.payMultiplier < g.regular.payMultiplier);
  assert.ok(g.regular.payMultiplier < g.senior.payMultiplier);
  assert.ok(g.senior.payMultiplier < g.master.payMultiplier);
});

test('GPS 존 경계는 GREEN<YELLOW<ORANGE 순으로 증가', () => {
  const z = C.GPS_ZONES;
  assert.ok(z.GREEN.max < z.YELLOW.max);
  assert.ok(z.YELLOW.max < z.ORANGE.max);
  assert.strictEqual(z.RED.max, Infinity);
});

test('미션 유형은 visit/delivery/online/phone 4종', () => {
  assert.deepStrictEqual(
    Object.values(C.MISSION_TYPES).sort(),
    ['delivery', 'online', 'phone', 'visit']
  );
});
