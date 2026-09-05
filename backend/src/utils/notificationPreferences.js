const { NOTIFICATION_CATEGORY, ALWAYS_SEND } = require('../config/notificationCategories');

// supabase 를 최상위에서 부르면 환경변수 없이는 모듈을 import 조차 할 수 없어
// 순수 로직(decide / isNightNow)을 테스트할 수 없다. 필요한 시점에 가져온다.
let _supabase = null;
function db() {
  _supabase ??= require('../config/supabase');
  return _supabase;
}

/**
 * 알림 수신 설정 게이트.
 *
 * 두 가지를 따로 판단한다.
 *
 *   - **종류를 껐다** → 알림 자체를 만들지 않는다. 안 받겠다고 한 것을
 *     목록에 쌓아두면 설정이 무의미하다.
 *   - **야간이라 껐다** → 알림은 남기고 푸시만 건너뛴다. 안 보겠다는 게
 *     아니라 지금 깨우지 말라는 뜻이므로, 아침에 목록에서 볼 수 있어야 한다.
 *
 * 계정 상태·돈에 관한 통지는 어느 쪽으로도 막지 않는다
 * ([ALWAYS_SEND] 참고).
 */

/** 야간 시간대 (KST 기준, 21:00~08:00) */
const NIGHT_START_HOUR = 21;
const NIGHT_END_HOUR = 8;

/** 카테고리 → users 테이블 컬럼 */
const CATEGORY_COLUMN = {
  mission: 'notify_mission',
  review: 'notify_review',
  settlement: 'notify_settlement',
  marketing: 'notify_marketing',
};

/** 설정을 읽지 못했을 때 쓰는 값. 못 읽었다고 알림을 막지는 않는다. */
const DEFAULTS = {
  notification_push: true,
  notify_mission: true,
  notify_review: true,
  notify_settlement: true,
  notify_marketing: false,
  notify_night: false,
};

/** 지금이 KST 기준 야간인지. */
function isNightNow(now = new Date()) {
  // 서버 타임존에 기대지 않는다. UTC 에서 KST(+9)로 직접 옮긴다.
  const kstHour = (now.getUTCHours() + 9) % 24;
  return kstHour >= NIGHT_START_HOUR || kstHour < NIGHT_END_HOUR;
}

/** 여러 사용자의 설정을 한 번에 읽는다. id → 설정 맵. */
async function loadPreferences(userIds) {
  const ids = [...new Set(userIds)].filter(Boolean);
  if (ids.length === 0) return new Map();

  const columns = [
    'id',
    'notification_push',
    'notify_night',
    ...Object.values(CATEGORY_COLUMN),
  ].join(', ');

  const { data, error } = await db()
    .from('users')
    .select(columns)
    .in('id', ids);

  if (error) {
    // 설정을 못 읽었다고 알림을 끊으면, DB 장애가 곧 알림 장애가 된다.
    // 기본값으로 보내고 로그만 남긴다.
    console.error('[NOTIFICATION] Failed to load preferences:', error.message);
    return new Map();
  }

  return new Map((data || []).map((row) => [row.id, row]));
}

/**
 * 한 사용자에게 이 알림을 어떻게 처리할지 정한다.
 *
 * @returns {{ store: boolean, push: boolean }}
 */
function decide(type, prefs, now = new Date()) {
  if (ALWAYS_SEND.has(type)) {
    return { store: true, push: true };
  }

  const settings = { ...DEFAULTS, ...(prefs || {}) };

  const category = NOTIFICATION_CATEGORY[type];
  const column = category ? CATEGORY_COLUMN[category] : null;

  // 분류되지 않은 타입은 막지 않는다. 매핑을 빠뜨렸을 때 조용히
  // 사라지는 것보다 일단 가는 편이 낫다.
  if (column && settings[column] === false) {
    return { store: false, push: false };
  }

  if (settings.notification_push === false) {
    // 푸시만 껐다는 뜻이다. 앱 안 알림 목록에는 남긴다.
    return { store: true, push: false };
  }

  if (settings.notify_night === false && isNightNow(now)) {
    return { store: true, push: false };
  }

  return { store: true, push: true };
}

module.exports = {
  loadPreferences,
  decide,
  isNightNow,
  CATEGORY_COLUMN,
  DEFAULTS,
  NIGHT_START_HOUR,
  NIGHT_END_HOUR,
};
