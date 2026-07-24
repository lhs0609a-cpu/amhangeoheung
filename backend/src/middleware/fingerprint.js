/**
 * 세션 핑거프린트 미들웨어
 * 인증된 요청에서 IP, User-Agent, device_id 추출 → session_fingerprints 저장
 * 사용자당 1시간 1회 throttled
 */

const { recordFingerprint } = require('../controllers/collusionController');
const { FINGERPRINT_THROTTLE_MINUTES } = require('../config/constants');

// 메모리 기반 throttle 캐시 (사용자당 마지막 기록 시간)
const throttleCache = new Map();
const THROTTLE_MS = (FINGERPRINT_THROTTLE_MINUTES || 60) * 60 * 1000;

// 캐시 정리 (1시간마다)
setInterval(() => {
  const now = Date.now();
  for (const [key, timestamp] of throttleCache.entries()) {
    if (now - timestamp > THROTTLE_MS * 2) {
      throttleCache.delete(key);
    }
  }
}, THROTTLE_MS);

function fingerprintMiddleware(req, res, next) {
  // 인증된 사용자만
  if (!req.user?.id) {
    return next();
  }

  const userId = req.user.id;
  const lastRecorded = throttleCache.get(userId);
  const now = Date.now();

  // throttle: 1시간 내 이미 기록했으면 스킵
  if (lastRecorded && (now - lastRecorded) < THROTTLE_MS) {
    return next();
  }

  // 비동기로 기록 (요청 흐름 차단하지 않음)
  throttleCache.set(userId, now);
  recordFingerprint(userId, req).catch(err => {
    console.error('[FINGERPRINT_MW] Error:', err.message);
  });

  next();
}

module.exports = { fingerprintMiddleware };
