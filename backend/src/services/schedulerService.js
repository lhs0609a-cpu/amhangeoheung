/**
 * 스케줄러 메인 서비스
 * node-cron 기반으로 정산, 리뷰 게시, 미션 만료 자동 처리
 */

const cron = require('node-cron');
const { processAutoSettlement } = require('./settlementService');
const { processAutoPublish } = require('./reviewService');
const { processMissionExpiry } = require('./missionService');
const supabase = require('../config/supabase');

const NOTIFICATION_RETENTION_DAYS = 90;

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

  // 매일 04:00 KST - 오래된 알림 정리
  const cleanupJob = cron.schedule('0 4 * * *', async () => {
    console.log('[SCHEDULER] Running: cleanupOldNotifications');
    try {
      const result = await cleanupOldNotifications();
      console.log(`[SCHEDULER] Notification cleanup done: deleted=${result.deleted}`);
    } catch (err) {
      console.error('[SCHEDULER] Notification cleanup error:', err.message);
    }
  }, {
    timezone: 'Asia/Seoul',
  });
  jobs.push(cleanupJob);

  console.log('[SCHEDULER] All cron jobs initialized');
  console.log('[SCHEDULER]   - Settlement:     every day at 02:00 KST');
  console.log('[SCHEDULER]   - Review publish:  every hour at :00');
  console.log('[SCHEDULER]   - Mission expiry:  every day at 03:00 KST');
  console.log('[SCHEDULER]   - Notification cleanup: every day at 04:00 KST');
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

/**
 * 오래된 알림 정리 (90일 이상 + 읽음 처리된 알림 삭제)
 */
async function cleanupOldNotifications() {
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - NOTIFICATION_RETENTION_DAYS);

  const { data, error } = await supabase
    .from('notifications')
    .delete()
    .eq('is_read', true)
    .lt('created_at', cutoff.toISOString())
    .select('id');

  if (error) {
    console.error('[NOTIFICATION_CLEANUP] Delete error:', error.message);
    return { deleted: 0 };
  }

  return { deleted: data?.length || 0 };
}

module.exports = { startScheduler, stopScheduler };
