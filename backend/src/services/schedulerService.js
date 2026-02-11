/**
 * 스케줄러 메인 서비스
 * node-cron 기반으로 정산, 리뷰 게시, 미션 만료 자동 처리
 */

const cron = require('node-cron');
const { processAutoSettlement } = require('./settlementService');
const { processAutoPublish } = require('./reviewService');
const { processMissionExpiry } = require('./missionService');

const jobs = [];

/**
 * 스케줄러 시작
 * - 매일 02:00 KST: 정산 자동 처리
 * - 매시 정각: 리뷰 자동 게시
 * - 매일 03:00 KST: 미션 만료 처리
 *
 * node-cron은 서버 시간대 기준. KST 적용을 위해 timezone 옵션 사용.
 */
function startScheduler() {
  // 매일 02:00 KST - 정산 자동 처리
  const settlementJob = cron.schedule('0 2 * * *', async () => {
    console.log('[SCHEDULER] Running: processAutoSettlement');
    try {
      const result = await processAutoSettlement();
      console.log(`[SCHEDULER] Settlement done: processed=${result.processed}, succeeded=${result.succeeded}, failed=${result.failed}`);
    } catch (err) {
      console.error('[SCHEDULER] Settlement error:', err.message);
    }
  }, {
    timezone: 'Asia/Seoul',
  });
  jobs.push(settlementJob);

  // 매시 정각 - 리뷰 자동 게시
  const reviewJob = cron.schedule('0 * * * *', async () => {
    console.log('[SCHEDULER] Running: processAutoPublish');
    try {
      const result = await processAutoPublish();
      console.log(`[SCHEDULER] Review publish done: processed=${result.processed}, published=${result.published}, failed=${result.failed}`);
    } catch (err) {
      console.error('[SCHEDULER] Review publish error:', err.message);
    }
  }, {
    timezone: 'Asia/Seoul',
  });
  jobs.push(reviewJob);

  // 매일 03:00 KST - 미션 만료 처리
  const expiryJob = cron.schedule('0 3 * * *', async () => {
    console.log('[SCHEDULER] Running: processMissionExpiry');
    try {
      const result = await processMissionExpiry();
      console.log(`[SCHEDULER] Mission expiry done: processed=${result.processed}, cancelled=${result.cancelled}, failed=${result.failed}`);
    } catch (err) {
      console.error('[SCHEDULER] Mission expiry error:', err.message);
    }
  }, {
    timezone: 'Asia/Seoul',
  });
  jobs.push(expiryJob);

  console.log('[SCHEDULER] All cron jobs initialized');
  console.log('[SCHEDULER]   - Settlement:     every day at 02:00 KST');
  console.log('[SCHEDULER]   - Review publish:  every hour at :00');
  console.log('[SCHEDULER]   - Mission expiry:  every day at 03:00 KST');
}

/**
 * 스케줄러 정지 (graceful shutdown)
 */
function stopScheduler() {
  for (const job of jobs) {
    job.stop();
  }
  jobs.length = 0;
  console.log('[SCHEDULER] All cron jobs stopped');
}

module.exports = { startScheduler, stopScheduler };
