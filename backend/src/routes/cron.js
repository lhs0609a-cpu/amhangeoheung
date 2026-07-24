/**
 * 외부 cron 트리거 라우트
 *
 * Vercel 등 서버리스 환경에서는 node-cron이 동작하지 않으므로,
 * cron-job.org / GitHub Actions / Vercel Cron 같은 외부 스케줄러가
 * 아래 엔드포인트를 주기적으로 호출하여 작업을 실행한다.
 *
 *   POST /api/cron/:job
 *   Header: X-Cron-Secret: <CRON_SECRET>
 *
 * 보안: CRON_SECRET 환경변수가 설정되어 있어야 하며, 헤더와 일치해야 한다.
 */

const express = require('express');
const crypto = require('crypto');
const router = express.Router();
const { runJob, JOB_NAMES } = require('../services/schedulerService');

// 타이밍 공격 방지를 위한 상수 시간 비교
function safeEqual(a, b) {
  const bufA = Buffer.from(String(a));
  const bufB = Buffer.from(String(b));
  if (bufA.length !== bufB.length) return false;
  return crypto.timingSafeEqual(bufA, bufB);
}

function requireCronSecret(req, res, next) {
  const secret = process.env.CRON_SECRET;
  if (!secret) {
    return res.status(503).json({
      success: false,
      message: 'CRON_SECRET이 설정되지 않아 cron 트리거가 비활성화되어 있습니다.'
    });
  }
  const provided = req.get('X-Cron-Secret') || '';
  if (!safeEqual(provided, secret)) {
    return res.status(401).json({ success: false, message: '유효하지 않은 cron 시크릿입니다.' });
  }
  next();
}

// 사용 가능한 job 목록 조회
router.get('/', requireCronSecret, (req, res) => {
  res.json({ success: true, data: { jobs: JOB_NAMES } });
});

// 단일 job 실행
router.post('/:job', requireCronSecret, async (req, res) => {
  const { job } = req.params;
  if (!JOB_NAMES.includes(job)) {
    return res.status(404).json({
      success: false,
      message: `알 수 없는 job: ${job}`,
      data: { available: JOB_NAMES }
    });
  }

  try {
    const result = await runJob(job);
    console.log(`[CRON] job '${job}' executed via HTTP trigger`);
    res.json({ success: true, job, result: result ?? null });
  } catch (err) {
    console.error(`[CRON] job '${job}' failed:`, err.message);
    res.status(500).json({ success: false, job, message: err.message });
  }
});

module.exports = router;
