/**
 * 스케줄러 메인 서비스
 * node-cron 기반으로 정산, 리뷰 게시, 미션 만료 자동 처리
 */

const cron = require('node-cron');
const { processAutoSettlement } = require('./settlementService');
const { processAutoPublish } = require('./reviewService');
const { processMissionExpiry } = require('./missionService');
const supabase = require('../config/supabase');
const { createNotification } = require('../utils/notificationService');
const NOTIFICATION_TYPES = require('../config/notificationTypes');
const { withLock, LOCK_IDS } = require('../utils/distributedLock');
const { sendPushNotification } = require('./fcmService');

const { expireDetectionTests } = require('../controllers/detectionTestController');
const { runDailyCollusionScan } = require('../controllers/collusionController');

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
// ── 작업 실행기(runner) 정의 ────────────────────────────────────────────────
// 각 작업의 "실제 로직"을 이름 붙은 함수로 정의한다.
// node-cron(상시구동) 과 외부 cron HTTP 트리거(/api/cron/:job) 양쪽에서 동일하게 호출된다.

const TASKS = {
  // 정산 자동 처리 (분산 잠금)
  settlement: withLock(LOCK_IDS.SETTLEMENT, async () => {
    console.log('[SCHEDULER] Running: processAutoSettlement');
    const result = await processAutoSettlement();
    console.log(`[SCHEDULER] Settlement done: processed=${result.processed}, succeeded=${result.succeeded}, failed=${result.failed}, held=${result.held || 0}`);
    return result;
  }),

  // 리뷰 자동 게시 + G5: 분쟁 자동 해결 (분산 잠금)
  autopublish: withLock(LOCK_IDS.AUTO_PUBLISH, async () => {
    console.log('[SCHEDULER] Running: processAutoPublish');
    const result = await processAutoPublish();
    console.log(`[SCHEDULER] Review publish done: processed=${result.processed}, published=${result.published}, failed=${result.failed}`);

    try {
      const { data: expiredDisputes } = await supabase
        .from('reviews')
        .select('id, mission_id, reviewer_id, business_id')
        .eq('is_disputed', true)
        .eq('dispute_status', 'pending')
        .lt('dispute_resolution_deadline', new Date().toISOString());

      for (const review of (expiredDisputes || [])) {
        await supabase.from('reviews')
          .update({
            dispute_status: 'resolved',
            dispute_outcome: 'upheld',
            status: 'published',
            published_at: new Date().toISOString()
          })
          .eq('id', review.id);

        await supabase.from('escrows')
          .update({ is_disputed: false })
          .eq('mission_id', review.mission_id);

        console.log(`[Scheduler] Auto-resolved expired dispute for review ${review.id} (upheld)`);
      }
      if (expiredDisputes?.length) {
        console.log(`[Scheduler] Auto-resolved ${expiredDisputes.length} expired disputes`);
      }
    } catch (disputeErr) {
      console.error('[Scheduler] Dispute auto-resolve error:', disputeErr.message);
    }

    return result;
  }),

  // 미션 만료 처리 (분산 잠금)
  missionExpiry: withLock(LOCK_IDS.MISSION_EXPIRY, async () => {
    console.log('[SCHEDULER] Running: processMissionExpiry');
    const result = await processMissionExpiry();
    console.log(`[SCHEDULER] Mission expiry done: processed=${result.processed}, cancelled=${result.cancelled}, failed=${result.failed}`);

    const threeDaysAgo = new Date();
    threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);

    const { data: expiredAssigned } = await supabase
      .from('missions')
      .select('id, assigned_reviewer_id')
      .in('status', ['assigned', 'in_progress'])
      .lt('assigned_at', threeDaysAgo.toISOString());

    for (const mission of (expiredAssigned || [])) {
      await supabase
        .from('missions')
        .update({ status: 'cancelled', cancelled_reason: 'visit_deadline_expired' })
        .eq('id', mission.id);
      console.log(`[SCHEDULER] Expired assigned mission ${mission.id}`);
    }

    return result;
  }),

  // 30일 이상 보류된 에스크로 에스컬레이션
  escrowEscalation: async () => {
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
    const { data: staleEscrows } = await supabase
      .from('escrows')
      .select('id, mission_id, reviewer_id, total_amount')
      .eq('status', 'hold')
      .eq('hold_escalated', false)
      .lt('hold_started_at', thirtyDaysAgo);

    for (const escrow of (staleEscrows || [])) {
      await supabase.from('escrows')
        .update({ hold_escalated: true })
        .eq('id', escrow.id);

      console.error(`[ESCROW ESCALATION] Escrow ${escrow.id} held for 30+ days. Amount: ${escrow.total_amount}. Requires manual intervention.`);

      await createNotification(
        escrow.reviewer_id,
        'SETTLEMENT_FAILED',
        '정산 보류 안내',
        '정산이 30일 이상 보류 중입니다. 계좌 정보를 확인해주세요.',
        { escrowId: escrow.id }
      );
    }
    if (staleEscrows?.length) {
      console.log(`[Scheduler] Escalated ${staleEscrows.length} stale escrows`);
    }
  },

  // 오래된 알림/토큰/블랙리스트 정리 (분산 잠금)
  cleanup: withLock(LOCK_IDS.NOTIFICATION_CLEANUP, async () => {
    console.log('[SCHEDULER] Running: cleanupOldNotifications');
    const result = await cleanupOldNotifications();
    console.log(`[SCHEDULER] Notification cleanup done: deleted=${result.deleted}`);

    try {
      const ninetyDaysAgo = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString();
      const { data: deletedTokens } = await supabase
        .from('device_tokens')
        .delete()
        .eq('is_active', false)
        .lt('last_used_at', ninetyDaysAgo)
        .select('id');
      if (deletedTokens?.length) {
        console.log(`[Scheduler] Cleaned up ${deletedTokens.length} inactive device tokens`);
      }
    } catch (tokenErr) {
      console.error('[Scheduler] Device token cleanup error:', tokenErr.message);
    }

    try {
      const { data: deletedBlacklist } = await supabase
        .from('token_blacklist')
        .delete()
        .lt('expires_at', new Date().toISOString())
        .select('id');
      if (deletedBlacklist?.length) {
        console.log(`[Scheduler] Cleaned up ${deletedBlacklist.length} expired blacklist entries`);
      }
    } catch (blacklistErr) {
      console.error('[Scheduler] Token blacklist cleanup error:', blacklistErr.message);
    }

    return result;
  }),

  // 지역 랭킹 캐시 재구축 (분산 잠금)
  ranking: withLock(LOCK_IDS.RANKING_REBUILD, async () => {
    console.log('[SCHEDULER] Running: rebuildRegionalRankings');
    const result = await rebuildRegionalRankings();
    console.log(`[SCHEDULER] Rankings rebuilt: ${result.count} entries`);
    return result;
  }),

  // 지역 수요 집계 + 추천 만료
  demand: async () => {
    console.log('[SCHEDULER] Running: processRegionalDemand + expireReferrals');
    await processRegionalDemand();
    await expireReferrals();
    console.log('[SCHEDULER] Regional demand + referral expiry done');
  },

  // 히든 미션/시즌 알림 + G9: 시즌 자동 종료
  missionAlerts: async () => {
    console.log('[SCHEDULER] Running: sendHiddenMissionAlerts + sendSeasonAlerts + seasonAutoEnd');
    await sendHiddenMissionAlerts();
    await sendSeasonAlerts();

    try {
      const { data: expiredSeasons } = await supabase
        .from('seasons')
        .select('id, name')
        .eq('is_active', true)
        .lt('end_at', new Date().toISOString());

      for (const season of (expiredSeasons || [])) {
        await supabase.from('seasons')
          .update({ is_active: false })
          .eq('id', season.id);
        console.log(`[Scheduler] Season "${season.name}" auto-deactivated`);
      }
    } catch (seasonErr) {
      console.error('[Scheduler] Season auto-end error:', seasonErr.message);
    }

    console.log('[SCHEDULER] Mission alerts + season auto-end done');
  },

  // 구독 일시정지 자동 재개 + G8: 구독 갱신 안내 (분산 잠금)
  subscription: withLock(LOCK_IDS.SUBSCRIPTION_RENEWAL, async () => {
    console.log('[SCHEDULER] Running: resumePausedSubscriptions + subscriptionRenewal');
    const result = await resumePausedSubscriptions();
    console.log(`[SCHEDULER] Paused subscriptions resumed: ${result.count}`);

    try {
      const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
      const { data: expiring } = await supabase
        .from('businesses')
        .select('id, owner_id, subscription_plan, subscription_end')
        .eq('auto_renew', true)
        .eq('subscription_paused', false)
        .lt('subscription_end', tomorrow)
        .neq('subscription_plan', 'none');

      for (const biz of (expiring || [])) {
        await createNotification(
          biz.owner_id,
          'SYSTEM',
          '구독 갱신 안내',
          `${biz.subscription_plan} 구독이 곧 만료됩니다. 자동 갱신이 진행됩니다.`,
          { businessId: biz.id, plan: biz.subscription_plan }
        );
        console.log(`[Scheduler] Subscription renewal notice sent to business ${biz.id}`);
      }
    } catch (renewErr) {
      console.error('[Scheduler] Subscription renewal error:', renewErr.message);
    }

    return result;
  }),

  // 리뷰 요청 임계치 알림 (주간)
  reviewRequest: async () => {
    console.log('[SCHEDULER] Running: notifyReviewRequestThreshold');
    await notifyReviewRequestThreshold();
    console.log('[SCHEDULER] Review request threshold notifications done');
  },

  // 재인증 기한 알림 + 인증 정지 안내
  recertification: async () => {
    console.log('[SCHEDULER] Running: recertificationAlerts');
    await sendRecertificationAlerts();
    console.log('[SCHEDULER] Recertification alerts done');
  },

  // 만료 detection_test 처리
  detectionExpiry: async () => {
    console.log('[SCHEDULER] Running: expireDetectionTests');
    const result = await expireDetectionTests();
    console.log(`[SCHEDULER] Detection tests expired: ${result.expired}`);
    return result;
  },

  // 일괄 담합 스캔 (분산 잠금)
  collusionScan: withLock(LOCK_IDS.COLLUSION_SCAN, async () => {
    console.log('[SCHEDULER] Running: runDailyCollusionScan');
    const result = await runDailyCollusionScan();
    console.log(`[SCHEDULER] Collusion scan done: newFlags=${result.totalFlags}`);
    return result;
  }),

  // 실패한 푸시 알림 재시도
  pushRetry: async () => {
    const fiveMinAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();
    const { data: failedNotifs } = await supabase
      .from('notifications')
      .select('id, user_id, type, title, message, data, push_retry_count')
      .eq('push_status', 'failed')
      .lt('push_retry_count', 3)
      .gt('created_at', fiveMinAgo)
      .limit(50);

    for (const notif of (failedNotifs || [])) {
      try {
        await sendPushNotification(notif.user_id, notif.title, notif.message, notif.data);
        await supabase.from('notifications')
          .update({ push_status: 'sent' })
          .eq('id', notif.id);
      } catch (pushErr) {
        await supabase.from('notifications')
          .update({
            push_retry_count: (notif.push_retry_count || 0) + 1,
            push_status: 'failed'
          })
          .eq('id', notif.id);
      }
    }
    if (failedNotifs?.length) {
      console.log(`[Scheduler] Push retry processed ${failedNotifs.length} notifications`);
    }
  },
};

// 작업별 cron 표현식 (node-cron 사용 시 + 외부 cron 설정 참고용)
const SCHEDULES = {
  ranking: '0 1 * * *',
  settlement: '0 */2 * * *',
  autopublish: '0 * * * *',
  missionExpiry: '0 3 * * *',
  escrowEscalation: '30 3 * * *',
  cleanup: '0 4 * * *',
  demand: '0 5 * * *',
  missionAlerts: '0 6 * * *',
  subscription: '0 7 * * *',
  reviewRequest: '0 8 * * 1',
  recertification: '0 9 * * *',
  detectionExpiry: '0 10 * * *',
  collusionScan: '0 23 * * *',
  pushRetry: '*/5 * * * *',
};

const JOB_NAMES = Object.keys(TASKS);

/**
 * 외부 cron(HTTP 트리거) 또는 수동 실행용 단일 작업 디스패처
 * @param {string} name TASKS 키
 */
async function runJob(name) {
  const task = TASKS[name];
  if (!task) {
    const err = new Error(`Unknown job: ${name}`);
    err.code = 'UNKNOWN_JOB';
    throw err;
  }
  return task();
}

/**
 * 스케줄러 시작
 * 상시구동 환경(Fly/Railway/Render 등)에서만 node-cron을 켠다.
 * Vercel 등 서버리스에서는 ENABLE_CRON을 켜지 말고 외부 cron이
 * /api/cron/:job 을 호출하도록 한다.
 */
function startScheduler() {
  if (String(process.env.ENABLE_CRON).toLowerCase() !== 'true') {
    console.log('[SCHEDULER] node-cron 비활성화됨 (ENABLE_CRON !== "true").');
    console.log('[SCHEDULER] 외부 cron이 POST /api/cron/:job 을 호출하도록 설정하세요.');
    console.log('[SCHEDULER] 사용 가능한 job:', JOB_NAMES.join(', '));
    return;
  }

  for (const [name, expr] of Object.entries(SCHEDULES)) {
    const job = cron.schedule(expr, async () => {
      try {
        await TASKS[name]();
      } catch (err) {
        console.error(`[SCHEDULER] ${name} error:`, err.message);
      }
    }, { timezone: 'Asia/Seoul' });
    jobs.push(job);
  }

  console.log('[SCHEDULER] node-cron jobs initialized:', Object.keys(SCHEDULES).join(', '));
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

/**
 * 지역 랭킹 캐시 재구축
 */
async function rebuildRegionalRankings() {
  const { data: businesses } = await supabase
    .from('businesses')
    .select('id, name, address, category, badge_level, total_reviews, average_rating')
    .eq('subscription_plan', 'starter')
    .or('subscription_plan.eq.growth,subscription_plan.eq.pro')
    .gt('total_reviews', 0);

  if (!businesses || businesses.length === 0) return { count: 0 };

  // 지역별 그룹핑 및 랭킹
  const regionMap = {};
  businesses.forEach(b => {
    const region = b.address?.split(' ').slice(0, 2).join(' ') || '기타';
    const cat = b.category || '기타';
    const key = `${region}__${cat}`;
    if (!regionMap[key]) regionMap[key] = [];
    regionMap[key].push(b);
  });

  const records = [];
  Object.entries(regionMap).forEach(([key, list]) => {
    const [region, category] = key.split('__');
    list.sort((a, b) => (b.average_rating || 0) - (a.average_rating || 0));
    list.slice(0, 20).forEach((b, i) => {
      records.push({
        region, category,
        business_id: b.id,
        business_name: b.name,
        rank: i + 1,
        trust_score: b.average_rating,
        review_count: b.total_reviews,
        avg_rating: b.average_rating,
        badge_level: b.badge_level,
        period: 'monthly',
      });
    });
  });

  // I8: Use upsert instead of truncate+insert to avoid downtime
  if (records.length > 0) {
    for (const ranking of records) {
      await supabase.from('regional_rankings_cache')
        .upsert(ranking, { onConflict: 'region,category,business_id,period' });
    }
  }

  return { count: records.length };
}

/**
 * 지역 수요 집계
 */
async function processRegionalDemand() {
  const { data: missions } = await supabase
    .from('missions')
    .select('region, category')
    .eq('status', 'recruiting');

  const { data: reviewers } = await supabase
    .from('users')
    .select('specialties')
    .eq('user_type', 'reviewer')
    .eq('status', 'active');

  // 간단 집계
  const demandMap = {};
  (missions || []).forEach(m => {
    const region = m.region || '기타';
    if (!demandMap[region]) demandMap[region] = { pending: 0, reviewers: 0 };
    demandMap[region].pending++;
  });

  // 기존 데이터 삭제 후 새로 삽입
  await supabase.from('regional_demand').delete().neq('id', '00000000-0000-0000-0000-000000000000');

  const records = Object.entries(demandMap).map(([region, data]) => ({
    region,
    pending_missions: data.pending,
    active_reviewers: data.reviewers,
    demand_score: Math.max(0, data.pending * 10 - data.reviewers * 5),
  }));

  if (records.length > 0) {
    await supabase.from('regional_demand').insert(records);
  }
}

/**
 * 만료 추천 처리
 */
async function expireReferrals() {
  const now = new Date().toISOString();
  await supabase
    .from('referrals')
    .update({ status: 'expired' })
    .eq('status', 'pending')
    .lt('expires_at', now);
}

/**
 * 히든 미션 알림
 */
async function sendHiddenMissionAlerts() {
  const { data: hiddenMissions } = await supabase
    .from('missions')
    .select('id, category, region, min_reviewer_grade')
    .eq('visibility', 'hidden')
    .eq('status', 'recruiting');

  if (!hiddenMissions || hiddenMissions.length === 0) return;

  const gradeOrder = ['rookie', 'regular', 'senior', 'master'];

  for (const mission of hiddenMissions) {
    const minIdx = gradeOrder.indexOf(mission.min_reviewer_grade || 'rookie');
    const eligibleGrades = gradeOrder.slice(minIdx);

    const { data: reviewers } = await supabase
      .from('users')
      .select('id')
      .eq('user_type', 'reviewer')
      .eq('status', 'active')
      .in('reviewer_grade', eligibleGrades)
      .limit(100);

    for (const reviewer of (reviewers || [])) {
      await createNotification(
        reviewer.id,
        NOTIFICATION_TYPES.HIDDEN_MISSION_AVAILABLE,
        '히든 미션이 있어요!',
        `등급 혜택으로 공개된 히든 미션을 확인해보세요.`,
        { missionId: mission.id }
      );
    }
  }
}

/**
 * 시즌 시작/종료 알림
 */
async function sendSeasonAlerts() {
  const now = new Date();
  const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);

  // 오늘 시작하는 시즌
  const { data: startingSeasons } = await supabase
    .from('seasons')
    .select('id, name, theme')
    .eq('is_active', true)
    .gte('start_at', now.toISOString())
    .lt('start_at', tomorrow.toISOString());

  if (startingSeasons && startingSeasons.length > 0) {
    const { data: reviewers } = await supabase
      .from('users')
      .select('id')
      .eq('user_type', 'reviewer')
      .eq('status', 'active')
      .limit(500);

    for (const season of startingSeasons) {
      for (const reviewer of (reviewers || [])) {
        await createNotification(
          reviewer.id,
          NOTIFICATION_TYPES.SEASON_STARTED,
          `새 시즌: ${season.name}`,
          `${season.theme} 시즌이 시작됩니다! 특별 미션과 보너스를 확인하세요.`,
          { seasonId: season.id }
        );
      }
    }
  }
}

/**
 * 구독 일시정지 자동 재개
 */
async function resumePausedSubscriptions() {
  const now = new Date().toISOString();

  const { data, error } = await supabase
    .from('businesses')
    .update({
      subscription_paused: false,
      subscription_pause_until: null,
    })
    .eq('subscription_paused', true)
    .lt('subscription_pause_until', now)
    .select('id');

  return { count: data?.length || 0 };
}

/**
 * 리뷰 요청 임계치 알림 (주간)
 */
async function notifyReviewRequestThreshold() {
  const { data: requests } = await supabase
    .from('review_requests')
    .select('business_id, business_name')
    .eq('status', 'pending');

  if (!requests) return;

  const counts = {};
  requests.forEach(r => {
    counts[r.business_id] = (counts[r.business_id] || { count: 0, name: r.business_name });
    counts[r.business_id].count++;
  });

  for (const [businessId, info] of Object.entries(counts)) {
    if (info.count >= 5) {
      const { data: business, error: businessError } = await supabase
        .from('businesses')
        .select('owner_id')
        .eq('id', businessId)
        .single();

      if (!businessError && business?.owner_id) {
        await createNotification(
          business.owner_id,
          NOTIFICATION_TYPES.REVIEW_REQUEST_THRESHOLD,
          '리뷰 요청이 쌓이고 있어요!',
          `${info.count}명이 ${info.name}의 리뷰를 원합니다. 미션을 등록하면 고객을 확보할 수 있어요!`,
          { businessId, requestCount: info.count }
        );
      }
    }
  }
}

/**
 * 재인증 기한 알림 (7일 전) + 인증 정지 안내
 */
async function sendRecertificationAlerts() {
  // 7일 후 재인증 기한인 리뷰어
  const sevenDaysFromNow = new Date();
  sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7);
  const eightDaysFromNow = new Date();
  eightDaysFromNow.setDate(eightDaysFromNow.getDate() + 8);

  const { data: dueSoon } = await supabase
    .from('reviewer_certifications')
    .select('user_id, next_recertification')
    .eq('status', 'certified')
    .gte('next_recertification', sevenDaysFromNow.toISOString())
    .lt('next_recertification', eightDaysFromNow.toISOString());

  for (const cert of (dueSoon || [])) {
    await createNotification(
      cert.user_id,
      NOTIFICATION_TYPES.RECERTIFICATION_DUE,
      '재인증 기한이 임박합니다',
      '7일 후 재인증 기한입니다. 기한 내 재인증을 완료해주세요.',
      { nextRecertification: cert.next_recertification }
    );
  }

  // 기한 만료된 인증 → 정지 처리
  const now = new Date().toISOString();
  const { data: expired } = await supabase
    .from('reviewer_certifications')
    .select('user_id')
    .eq('status', 'certified')
    .lt('next_recertification', now);

  for (const cert of (expired || [])) {
    await supabase
      .from('reviewer_certifications')
      .update({ status: 'recertifying' })
      .eq('user_id', cert.user_id);

    await supabase
      .from('users')
      .update({ is_certified: false })
      .eq('id', cert.user_id);

    await createNotification(
      cert.user_id,
      NOTIFICATION_TYPES.CERTIFICATION_SUSPENDED,
      '인증이 만료되었습니다',
      '재인증 기한이 지났습니다. 재교육을 완료해야 미션에 지원할 수 있습니다.',
      {}
    );
  }

  // 인증 정지 리뷰어 재교육 안내
  const { data: suspended } = await supabase
    .from('reviewer_certifications')
    .select('user_id')
    .eq('status', 'suspended');

  for (const cert of (suspended || [])) {
    await createNotification(
      cert.user_id,
      NOTIFICATION_TYPES.CERTIFICATION_SUSPENDED,
      '재교육이 필요합니다',
      '리뷰 품질 기준 미달로 인증이 정지되었습니다. 재교육을 완료해주세요.',
      {}
    );
  }
}

module.exports = { startScheduler, stopScheduler, runJob, JOB_NAMES };
