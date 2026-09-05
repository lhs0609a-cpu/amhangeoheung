const { test } = require('node:test');
const assert = require('node:assert');
const { blindRecruitingMissions } = require('../src/utils/missionBlinding');

const recruiting = () => ({
  id: 'm1',
  status: 'recruiting',
  business_id: 'b1',
  business: {
    id: 'b1',
    owner_id: 'owner-1',
    name: '비밀가게',
    category: '카페',
    address_city: '서울',
  },
});

const assigned = () => ({
  id: 'm2',
  status: 'in_progress',
  business_id: 'b1',
  business: { id: 'b1', owner_id: 'owner-1', name: '공개가게' },
});

// ── 블라인드 ────────────────────────────────────────────────────────────────
// 모집 단계에서 업체명이 보이면 감찰관이 골라 지원하게 되고, 무작위 배정과
// 담합 방지가 통째로 무의미해진다.

test('모집 중인 미션은 남에게 업체명을 보여주지 않는다', () => {
  const [m] = blindRecruitingMissions([recruiting()], 'stranger');
  assert.strictEqual(m.business.name, undefined);
});

test('가려도 지역·업종은 남는다 — 지원 판단에는 필요하다', () => {
  const [m] = blindRecruitingMissions([recruiting()], 'stranger');
  assert.strictEqual(m.business.category, '카페');
  assert.strictEqual(m.business.address_city, '서울');
});

test('자기 업체 미션이면 사장님에게는 이름이 보인다', () => {
  const [m] = blindRecruitingMissions([recruiting()], 'owner-1');
  assert.strictEqual(m.business.name, '비밀가게');
});

test('배정된 뒤에는 이름이 보인다', () => {
  const [m] = blindRecruitingMissions([assigned()], 'stranger');
  assert.strictEqual(m.business.name, '공개가게');
});

// ── owner_id 노출 ───────────────────────────────────────────────────────────
// 판정에만 쓰는 값이라 응답에 남으면 안 된다. 소유자 계정 id 가 그대로
// 흘러나가면 그 자체로 식별자가 된다.

test('owner_id 는 어떤 경우에도 응답에 남지 않는다', () => {
  for (const viewer of ['stranger', 'owner-1']) {
    for (const row of [recruiting(), assigned()]) {
      const [m] = blindRecruitingMissions([row], viewer);
      assert.strictEqual(
        m.business.owner_id,
        undefined,
        `viewer=${viewer} status=${row.status} 에서 owner_id 가 샜다`
      );
    }
  }
});

// ── 경계 ────────────────────────────────────────────────────────────────────

test('business 가 없는 행은 그대로 통과한다', () => {
  const row = { id: 'm3', status: 'recruiting', business: null };
  assert.deepStrictEqual(blindRecruitingMissions([row], 'x'), [row]);
});

test('로그인하지 않은 뷰어여도 owner 로 오인하지 않는다', () => {
  // ownerId 와 viewerId 가 둘 다 undefined 일 때 "같다"고 판정하면
  // 모든 사람이 모든 가게의 주인이 된다.
  const row = recruiting();
  row.business.owner_id = undefined;
  const [m] = blindRecruitingMissions([row], undefined);
  assert.strictEqual(m.business.name, undefined);
});

test('빈 목록도 안전하다', () => {
  assert.deepStrictEqual(blindRecruitingMissions([], 'x'), []);
});
