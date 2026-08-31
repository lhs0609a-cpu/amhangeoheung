const { test } = require('node:test');
const assert = require('node:assert');
const {
  normalizeTitle,
  improvementRate,
  buildTimeline,
} = require('../src/services/findingService');

// ── 같은 지적인지 판정 ───────────────────────────────────────────────────────
// 감찰관마다 문장부호와 띄어쓰기가 다르다. 같은 지적을 다른 지적으로 세면
// "고치겠다고 하고 안 고친" 항목이 재발로 잡히지 않는다.

test('normalizeTitle: 문장부호와 공백 차이를 흡수한다', () => {
  assert.strictEqual(
    normalizeTitle('  점심  응대 · 지연!! '),
    normalizeTitle('점심 응대 지연')
  );
});

test('normalizeTitle: 가운뎃점을 지우고 공백이 두 칸 남지 않는다', () => {
  assert.strictEqual(normalizeTitle('응대 · 지연'), '응대 지연');
});

test('normalizeTitle: 대소문자를 무시한다', () => {
  assert.strictEqual(normalizeTitle('Wifi 불안정'), normalizeTitle('wifi 불안정'));
});

test('normalizeTitle: 빈 값도 안전하다', () => {
  assert.strictEqual(normalizeTitle(null), '');
  assert.strictEqual(normalizeTitle(undefined), '');
  assert.strictEqual(normalizeTitle('   '), '');
});

test('normalizeTitle: 서로 다른 지적은 합쳐지지 않는다', () => {
  assert.notStrictEqual(normalizeTitle('응대 지연'), normalizeTitle('화장실 청결'));
});

// ── 개선율 ──────────────────────────────────────────────────────────────────
// 업체 대시보드의 주인공 숫자다. 리뷰 수가 아니라 이 값이 성적표다.

test('improvementRate: 고친 비율을 센다', () => {
  const r = improvementRate([
    { status: 'fixed' },
    { status: 'fixed' },
    { status: 'open' },
  ]);
  assert.strictEqual(r.fixed, 2);
  assert.strictEqual(r.total, 3);
  assert.ok(Math.abs(r.rate - 2 / 3) < 1e-9);
});

test('improvementRate: 지적이 없으면 비율이 존재하지 않는다(0% 아님)', () => {
  // 0% 로 표시하면 감찰을 잘 받은 업체가 최악으로 보인다.
  assert.strictEqual(improvementRate([]), null);
  assert.strictEqual(improvementRate(null), null);
});

test('improvementRate: 전부 고쳤으면 1', () => {
  const r = improvementRate([{ status: 'fixed' }, { status: 'fixed' }]);
  assert.strictEqual(r.rate, 1);
});

// ── 타임라인 ────────────────────────────────────────────────────────────────
// 지적 → 약속 → 재감찰. 이 서사가 이 제품의 유일한 차별점이다.

test('buildTimeline: 지적·약속·확인을 시간순으로 늘어놓는다', () => {
  const steps = buildTimeline([
    {
      title: '웨이팅 안내 없음',
      status: 'fixed',
      first_found_at: '2026-03-12T00:00:00Z',
      promised_at: '2026-03-15T00:00:00Z',
      promise: '대기 알림 도입',
      resolved_at: '2026-06-20T00:00:00Z',
    },
  ]);

  assert.deepStrictEqual(
    steps.map((s) => s.kind),
    ['finding', 'promise', 'verified']
  );
});

test('buildTimeline: 약속이 없으면 약속 단계가 없다', () => {
  const steps = buildTimeline([
    { title: '응대 지연', status: 'open', first_found_at: '2026-03-12T00:00:00Z' },
  ]);
  assert.deepStrictEqual(steps.map((s) => s.kind), ['finding']);
});

test('buildTimeline: 약속만 있고 확인이 없으면 verified 가 생기지 않는다', () => {
  // 업체가 약속했다는 사실만으로 고쳐진 것이 되면 안 된다.
  const steps = buildTimeline([
    {
      title: '응대 지연',
      status: 'open',
      first_found_at: '2026-03-12T00:00:00Z',
      promised_at: '2026-03-15T00:00:00Z',
      promise: '인력 충원',
    },
  ]);
  assert.deepStrictEqual(steps.map((s) => s.kind), ['finding', 'promise']);
  assert.ok(!steps.some((s) => s.kind === 'verified'));
});

test('buildTimeline: status 가 fixed 여도 확인 시각이 없으면 verified 를 만들지 않는다', () => {
  const steps = buildTimeline([
    { title: 'x', status: 'fixed', first_found_at: '2026-01-01T00:00:00Z' },
  ]);
  assert.ok(!steps.some((s) => s.kind === 'verified'));
});

test('buildTimeline: 여러 지적을 섞어도 시간순을 지킨다', () => {
  const steps = buildTimeline([
    { title: 'B', status: 'open', first_found_at: '2026-06-01T00:00:00Z' },
    { title: 'A', status: 'open', first_found_at: '2026-03-01T00:00:00Z' },
  ]);
  assert.deepStrictEqual(steps.map((s) => s.title), ['A', 'B']);
});

test('buildTimeline: 빈 입력도 안전하다', () => {
  assert.deepStrictEqual(buildTimeline([]), []);
  assert.deepStrictEqual(buildTimeline(null), []);
});
