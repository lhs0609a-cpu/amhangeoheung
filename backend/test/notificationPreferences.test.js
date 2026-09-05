const { test } = require('node:test');
const assert = require('node:assert');
const {
  decide,
  isNightNow,
  CATEGORY_COLUMN,
  DEFAULTS,
} = require('../src/utils/notificationPreferences');
const NT = require('../src/config/notificationTypes');
const { NOTIFICATION_CATEGORY, ALWAYS_SEND } = require('../src/config/notificationCategories');

/** UTC 시각으로 KST 몇 시인지 만들기 쉽게. */
const atKst = (hour) => new Date(Date.UTC(2026, 0, 15, (hour - 9 + 24) % 24, 0));

// ── 종류별 스위치 ────────────────────────────────────────────────────────────
// 껐으면 알림 자체를 만들지 않는다. 안 받겠다고 한 것을 목록에 쌓아두면
// 스위치가 무의미해진다.

test('종류를 끄면 저장도 푸시도 하지 않는다', () => {
  assert.deepStrictEqual(
    decide(NT.MISSION_NEW, { notify_mission: false }),
    { store: false, push: false }
  );
});

test('끈 종류와 무관한 알림은 그대로 간다', () => {
  assert.deepStrictEqual(
    decide(NT.SETTLEMENT_COMPLETE, { notify_mission: false }),
    { store: true, push: true }
  );
});

test('분류되지 않은 타입은 막지 않는다', () => {
  // 새 타입을 추가하고 매핑을 빠뜨렸을 때 조용히 사라지면 안 된다.
  const unmapped = 'brand_new_type_nobody_mapped';
  assert.strictEqual(NOTIFICATION_CATEGORY[unmapped], undefined);
  assert.deepStrictEqual(decide(unmapped, {}), { store: true, push: true });
});

// ── 마스터 스위치 ────────────────────────────────────────────────────────────

test('푸시를 끄면 목록에는 남기고 푸시만 건너뛴다', () => {
  assert.deepStrictEqual(
    decide(NT.MISSION_NEW, { notification_push: false }),
    { store: true, push: false }
  );
});

// ── 야간 ─────────────────────────────────────────────────────────────────────
// 야간은 "안 보겠다"가 아니라 "지금 깨우지 마라"다. 아침에 목록에서 볼 수
// 있어야 하므로 저장은 한다.

test('야간에 야간알림이 꺼져 있으면 푸시만 건너뛴다', () => {
  assert.deepStrictEqual(
    decide(NT.MISSION_NEW, { notify_night: false }, atKst(23)),
    { store: true, push: false }
  );
});

test('낮에는 야간 설정이 꺼져 있어도 푸시가 나간다', () => {
  assert.deepStrictEqual(
    decide(NT.MISSION_NEW, { notify_night: false }, atKst(12)),
    { store: true, push: true }
  );
});

test('야간알림을 켜두면 새벽에도 푸시가 나간다', () => {
  assert.deepStrictEqual(
    decide(NT.MISSION_NEW, { notify_night: true }, atKst(3)),
    { store: true, push: true }
  );
});

test('야간 경계: 21시는 야간, 20시는 아니다', () => {
  assert.strictEqual(isNightNow(atKst(21)), true);
  assert.strictEqual(isNightNow(atKst(20)), false);
});

test('야간 경계: 7시는 야간, 8시는 아니다', () => {
  assert.strictEqual(isNightNow(atKst(7)), true);
  assert.strictEqual(isNightNow(atKst(8)), false);
});

test('야간 판정은 서버 타임존이 아니라 KST 를 쓴다', () => {
  // UTC 14시 = KST 23시. 서버가 UTC 여도 야간이어야 한다.
  assert.strictEqual(isNightNow(new Date(Date.UTC(2026, 0, 15, 14, 0))), true);
  // UTC 23시 = KST 익일 08시. 야간이 아니다.
  assert.strictEqual(isNightNow(new Date(Date.UTC(2026, 0, 15, 23, 0))), false);
});

// ── 끌 수 없는 알림 ──────────────────────────────────────────────────────────
// 계정 상태와 돈에 관한 통지는 사용자가 껐다고 안 보낼 수 없다. 못 받았다는
// 이유로 자격이 정지되거나 정산이 막히면 "알림을 껐으니까"로 정당화되지 않는다.

test('자격·품질 경고는 모든 스위치를 꺼도 나간다', () => {
  const allOff = {
    notification_push: false,
    notify_mission: false,
    notify_review: false,
    notify_settlement: false,
    notify_marketing: false,
    notify_night: false,
  };

  for (const type of ALWAYS_SEND) {
    assert.deepStrictEqual(
      decide(type, allOff, atKst(3)),
      { store: true, push: true },
      `${type} 은 설정과 무관하게 발송돼야 한다`
    );
  }
});

test('끌 수 없는 알림은 카테고리에도 들어 있지 않다', () => {
  // 둘 다 걸려 있으면 어느 쪽이 이기는지 헷갈린다. 애초에 겹치지 않게 둔다.
  for (const type of ALWAYS_SEND) {
    assert.strictEqual(
      NOTIFICATION_CATEGORY[type],
      undefined,
      `${type} 이 ALWAYS_SEND 와 카테고리에 동시에 있다`
    );
  }
});

// ── 기본값 ───────────────────────────────────────────────────────────────────

test('설정을 못 읽어도 알림은 막히지 않는다', () => {
  assert.deepStrictEqual(
    decide(NT.MISSION_NEW, undefined, atKst(12)),
    { store: true, push: true }
  );
});

test('마케팅은 기본값이 꺼짐이다', () => {
  // 광고성 정보는 수신 동의를 받은 사람에게만 (정보통신망법 제50조).
  assert.strictEqual(DEFAULTS.notify_marketing, false);
  assert.deepStrictEqual(
    decide(NT.COMPETITION_ALERT, {}, atKst(12)),
    { store: false, push: false }
  );
});

test('모든 카테고리에 대응하는 컬럼이 있다', () => {
  for (const [type, category] of Object.entries(NOTIFICATION_CATEGORY)) {
    assert.ok(
      CATEGORY_COLUMN[category],
      `${type} 의 카테고리 ${category} 에 대응하는 컬럼이 없다`
    );
  }
});
