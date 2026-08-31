/**
 * 지적사항 추적 서비스.
 *
 * 이 제품의 유일한 차별점은 별점이 아니라
 *   지적했다 → 업체가 약속했다 → 다시 가보니 고쳤더라
 * 는 서사다. 이 파일이 그 서사를 만든다.
 *
 * ── 절대 규칙 ────────────────────────────────
 * status 를 'fixed' 로 바꿀 수 있는 것은 **재감찰뿐이다.**
 * 업체는 promise 만 남길 수 있다. 업체가 스스로 "고쳤다"고 표시할 수 있으면
 * "업체가 돈을 내지만 결과를 못 바꾼다"는 주장이 그 자리에서 무너진다.
 * 그래서 이 파일에는 업체 입력을 받아 status 를 쓰는 함수가 없다.
 */

// supabase 를 최상위에서 부르면 환경변수 없이는 모듈을 import 조차 할 수 없어
// 순수 로직(normalizeTitle / improvementRate / buildTimeline)을 테스트할 수
// 없다. 실제로 필요한 시점에 가져온다.
let _supabase = null;
function db() {
  _supabase ??= require('../config/supabase');
  return _supabase;
}

/** 같은 지적인지 판정할 때 쓰는 정규화. 공백/문장부호 차이를 무시한다. */
function normalizeTitle(text) {
  return String(text || '')
    .toLowerCase()
    // 문장부호를 먼저 지운다. 순서를 바꾸면 '응대 · 지연' 에서 · 만 사라져
    // '응대  지연' 처럼 공백이 두 칸 남고, 같은 지적이 다른 지적으로 갈린다.
    .replace(/[.,!?·・…]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * 감찰이 공개될 때 지적사항을 실체로 저장한다.
 *
 * 이전 감찰에서 같은 지적이 이미 열려 있으면 새로 만들지 않고 재발로 센다.
 * "고치겠다고 하고 안 고친" 항목을 소비자가 볼 수 있어야 하기 때문이다.
 *
 * @param {{id: string, business_id: string, cons: string[]}} review
 * @returns {Promise<{created: number, recurred: number}>}
 */
async function recordFindingsFromReview(review) {
  const cons = Array.isArray(review?.cons) ? review.cons : [];
  const titles = cons.map((c) => String(c || '').trim()).filter(Boolean);

  if (!review?.id || !review?.business_id || titles.length === 0) {
    return { created: 0, recurred: 0 };
  }

  const { data: existing, error: existingError } = await db()
    .from('review_findings')
    .select('id, title, recurrence_count, status')
    .eq('business_id', review.business_id)
    .eq('status', 'open');

  if (existingError) throw existingError;

  const openByTitle = new Map(
    (existing || []).map((f) => [normalizeTitle(f.title), f])
  );

  const now = new Date().toISOString();
  const toInsert = [];
  let recurred = 0;

  for (const title of titles) {
    const key = normalizeTitle(title);
    const prior = openByTitle.get(key);

    if (prior) {
      // 이미 열려 있는 지적이 또 나왔다 — 재발로 센다.
      const { error } = await db()
        .from('review_findings')
        .update({
          recurrence_count: (prior.recurrence_count || 1) + 1,
          last_seen_at: now,
        })
        .eq('id', prior.id);
      if (error) throw error;
      recurred++;
      continue;
    }

    toInsert.push({
      business_id: review.business_id,
      review_id: review.id,
      title,
      status: 'open',
      first_found_at: now,
      last_seen_at: now,
    });
  }

  if (toInsert.length > 0) {
    // 같은 리뷰에 같은 문구가 중복으로 들어오면 유니크 인덱스가 막는다.
    const { error } = await db()
      .from('review_findings')
      .upsert(toInsert, { onConflict: 'review_id,title', ignoreDuplicates: true });
    if (error) throw error;
  }

  return { created: toInsert.length, recurred };
}

/**
 * 재감찰에서 개선이 확인된 지적을 닫는다.
 *
 * 이번 감찰의 cons 에 더 이상 나오지 않는, 이전에 열려 있던 지적이 대상이다.
 * "안 적혔으니 고쳐졌다"로 단정하는 것이라 재감찰이 실제로 수행된 경우에만
 * 호출해야 한다.
 *
 * @param {{id: string, business_id: string, cons: string[]}} review
 * @returns {Promise<{resolved: number}>}
 */
async function resolveFindingsFromReview(review) {
  if (!review?.id || !review?.business_id) return { resolved: 0 };

  const stillOpen = new Set(
    (Array.isArray(review.cons) ? review.cons : [])
      .map(normalizeTitle)
      .filter(Boolean)
  );

  const { data: open, error } = await db()
    .from('review_findings')
    .select('id, title, review_id')
    .eq('business_id', review.business_id)
    .eq('status', 'open');

  if (error) throw error;

  // 이번 감찰에서 처음 생긴 지적은 대상이 아니다.
  const targets = (open || []).filter(
    (f) => f.review_id !== review.id && !stillOpen.has(normalizeTitle(f.title))
  );

  if (targets.length === 0) return { resolved: 0 };

  const now = new Date().toISOString();
  const { error: updateError } = await db()
    .from('review_findings')
    .update({
      status: 'fixed',
      resolved_review_id: review.id,
      resolved_at: now,
    })
    .in('id', targets.map((f) => f.id));

  if (updateError) throw updateError;
  return { resolved: targets.length };
}

/**
 * 업체가 개선 약속을 남긴다.
 *
 * status 는 건드리지 않는다. 약속만으로 고쳐진 것이 되면 안 된다 —
 * 확인은 다음 감찰이 한다.
 */
async function recordPromise(findingId, businessId, promise) {
  const text = String(promise || '').trim();
  if (!findingId || !businessId || !text) {
    return { updated: false, reason: 'invalid_input' };
  }

  const { data, error } = await db()
    .from('review_findings')
    .update({ promise: text, promised_at: new Date().toISOString() })
    .eq('id', findingId)
    // 남의 업체 지적에 약속을 남길 수 없다.
    .eq('business_id', businessId)
    .select('id');

  if (error) throw error;
  return { updated: (data || []).length > 0 };
}

/**
 * 소비자 화면용 지적사항 목록.
 * 안 고쳐진 것을 먼저, 재발이 잦은 것을 위로.
 */
async function listFindings(businessId) {
  const { data, error } = await db()
    .from('review_findings')
    .select(
      'id, title, detail, status, recurrence_count, promise, promised_at, first_found_at, resolved_at'
    )
    .eq('business_id', businessId);

  if (error) throw error;

  return (data || []).sort((a, b) => {
    if (a.status !== b.status) return a.status === 'open' ? -1 : 1;
    if (a.status === 'open') {
      const diff = (b.recurrence_count || 1) - (a.recurrence_count || 1);
      if (diff !== 0) return diff;
    }
    return new Date(b.first_found_at) - new Date(a.first_found_at);
  });
}

/**
 * 개선율. 소비자 화면과 업체 대시보드의 주인공 숫자다.
 * 리뷰 수가 아니라 이 값이 업체의 성적표다.
 */
function improvementRate(findings) {
  const list = Array.isArray(findings) ? findings : [];
  if (list.length === 0) return null; // 지적이 없으면 비율이 존재하지 않는다
  const fixed = list.filter((f) => f.status === 'fixed').length;
  return { fixed, total: list.length, rate: fixed / list.length };
}

/**
 * 감찰 이력 타임라인 — 지적 → 약속 → 재감찰.
 * 앱의 InspectionTimeline 이 그대로 소비한다.
 */
function buildTimeline(findings) {
  const steps = [];

  for (const f of findings || []) {
    steps.push({
      kind: 'finding',
      at: f.first_found_at,
      title: f.title,
    });
    if (f.promised_at) {
      steps.push({ kind: 'promise', at: f.promised_at, title: f.promise });
    }
    if (f.status === 'fixed' && f.resolved_at) {
      steps.push({ kind: 'verified', at: f.resolved_at, title: f.title });
    }
  }

  return steps.sort((a, b) => new Date(a.at) - new Date(b.at));
}

module.exports = {
  normalizeTitle,
  recordFindingsFromReview,
  resolveFindingsFromReview,
  recordPromise,
  listFindings,
  improvementRate,
  buildTimeline,
};
