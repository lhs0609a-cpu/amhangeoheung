/**
 * 리뷰 자동 게시 서비스
 * 스케줄러에서 호출 - 제출 후 72시간 경과한 리뷰 자동 게시
 */

const supabase = require('../config/supabase');
const { createNotification } = require('../utils/notificationService');
const { PREVIEW_PERIOD_HOURS, AUTO_RELEASE_DAYS } = require('../config/constants');
const NT = require('../config/notificationTypes');
const { processReferralReward } = require('../controllers/referralController');
const { updateTrustWeightedRating, calculateTrustScore } = require('./trustScoreService');

/**
 * 자동 리뷰 게시 처리
 * - reviews WHERE status IN ('submitted','preview') AND submitted_at + 72h <= NOW() AND is_disputed = false
 * - 리뷰 → published, 미션 → published, 에스크로 auto_release_at 설정
 */
async function processAutoPublish() {
  const cutoffTime = new Date();
  cutoffTime.setHours(cutoffTime.getHours() - PREVIEW_PERIOD_HOURS);

  const { data: reviews, error } = await supabase
    .from('reviews')
    .select(`
      id,
      mission_id,
      business_id,
      reviewer_id,
      status,
      submitted_at,
      is_disputed
    `)
    .in('status', ['submitted', 'preview'])
    .lte('submitted_at', cutoffTime.toISOString())
    .eq('is_disputed', false);

  if (error) {
    console.error('[REVIEW_PUBLISH] Query error:', error.message);
    return { processed: 0, published: 0, failed: 0 };
  }

  if (!reviews || reviews.length === 0) {
    return { processed: 0, published: 0, failed: 0 };
  }

  let published = 0;
  let failed = 0;
  const now = new Date().toISOString();
  const autoReleaseAt = new Date();
  autoReleaseAt.setDate(autoReleaseAt.getDate() + AUTO_RELEASE_DAYS);

  for (const review of reviews) {
    try {
      // 멱등성: 원자적으로 published 상태로 변경하여 중복 처리 방지
      const { data: claimed, error: reviewError } = await supabase
        .from('reviews')
        .update({
          status: 'published',
          published_at: now,
        })
        .eq('id', review.id)
        .in('status', ['submitted', 'preview'])
        .select('id');

      if (reviewError || !claimed || claimed.length === 0) {
        if (reviewError) {
          console.error(`[REVIEW_PUBLISH] Failed to publish review ${review.id}:`, reviewError.message);
        }
        failed++;
        continue;
      }

      // 미션 상태 → published
      await supabase
        .from('missions')
        .update({
          status: 'published',
          published_at: now,
        })
        .eq('id', review.mission_id);

      // D1: Increment reviewer's completed missions count (원자적 증가)
      await supabase.rpc('increment_completed_missions', {
        p_user_id: review.reviewer_id,
      });

      // S5: 에스크로 auto_release_at 설정 (아직 paid 상태이고 분쟁 없는 경우)
      await supabase
        .from('escrows')
        .update({
          auto_release_at: autoReleaseAt.toISOString(),
        })
        .eq('mission_id', review.mission_id)
        .eq('is_disputed', false)
        .in('status', ['paid', 'hold']);

      // G10: 시즌 보너스 적용 (season bonus in settlement)
      const { data: missionForBonus, error: missionBonusError } = await supabase
        .from('missions')
        .select('bonus_rate, season_id')
        .eq('id', review.mission_id)
        .single();

      if (!missionBonusError && missionForBonus?.bonus_rate && missionForBonus.bonus_rate > 0) {
        const { data: escrowForBonus, error: escrowBonusError } = await supabase
          .from('escrows')
          .select('reviewer_fee')
          .eq('mission_id', review.mission_id)
          .single();

        if (!escrowBonusError && escrowForBonus) {
          const bonusAmount = Math.round(escrowForBonus.reviewer_fee * missionForBonus.bonus_rate);
          await supabase.from('escrows')
            .update({
              reviewer_fee: escrowForBonus.reviewer_fee + bonusAmount,
              bonus_amount: bonusAmount
            })
            .eq('mission_id', review.mission_id);
          console.log(`[REVIEW_PUBLISH] Season bonus applied: reviewId=${review.id}, bonus=${bonusAmount}`);
        }
      }

      // 리뷰어의 첫 완료 미션인지 확인하고 추천 보상 처리
      const { data: reviewer, error: reviewerError } = await supabase
        .from('users')
        .select('completed_missions')
        .eq('id', review.reviewer_id)
        .single();

      if (!reviewerError && reviewer && (reviewer.completed_missions === 0 || reviewer.completed_missions === 1)) {
        // D4: 추천 보상 원자적 멱등성 체크 - CAS(Compare-And-Swap) 패턴
        const { data: wasMarked } = await supabase.rpc('mark_referral_reward_processed', {
          p_review_id: review.id,
        });

        if (wasMarked) {
          // 첫 번째 미션 완료 시 추천 보상 처리 (비동기, non-blocking)
          processReferralReward(review.reviewer_id).catch(err => {
            console.error(`[REVIEW_PUBLISH] Referral reward processing failed for reviewer ${review.reviewer_id}:`, err);
          });
        }
      }

      // 리뷰어에게 알림
      const notifResult1 = await createNotification(
        review.reviewer_id,
        NT.REVIEW_PUBLISHED,
        '리뷰가 공개되었습니다',
        '작성하신 리뷰가 자동 공개되었습니다.',
        { reviewId: review.id, missionId: review.mission_id }
      );
      if (!notifResult1.success) {
        console.error(`[REVIEW_PUBLISH] Reviewer notification failed for review ${review.id}:`, notifResult1.error);
      }

      // 업체에게 알림 (business_id로 owner_id 조회)
      const { data: business, error: businessError } = await supabase
        .from('businesses')
        .select('owner_id')
        .eq('id', review.business_id)
        .single();

      if (!businessError && business?.owner_id) {
        const notifResult2 = await createNotification(
          business.owner_id,
          NT.REVIEW_PUBLISHED,
          '새 리뷰가 공개되었습니다',
          '미션 리뷰가 공개되었습니다. 확인해보세요.',
          { reviewId: review.id, missionId: review.mission_id }
        );
        if (!notifResult2.success) {
          console.error(`[REVIEW_PUBLISH] Business notification failed for review ${review.id}:`, notifResult2.error);
        }
      }

      // 신뢰도 가중 평점 재계산 (비동기, non-blocking)
      updateTrustWeightedRating(review.business_id).catch(err => {
        console.error(`[REVIEW_PUBLISH] Trust weighted rating update failed for business ${review.business_id}:`, err.message);
      });

      // 리뷰어 신뢰도 점수 + 등급 승급 체크 (비동기, non-blocking)
      calculateTrustScore(review.reviewer_id).catch(err => {
        console.error(`[REVIEW_PUBLISH] Trust score update failed for reviewer ${review.reviewer_id}:`, err.message);
      });

      console.log(`[REVIEW_PUBLISH] Published: reviewId=${review.id}`);
      published++;
    } catch (err) {
      console.error(`[REVIEW_PUBLISH] Error processing review ${review.id}:`, err.message);
      failed++;
    }
  }

  return { processed: reviews.length, published, failed };
}

module.exports = { processAutoPublish };
