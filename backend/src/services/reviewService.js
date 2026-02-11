/**
 * 리뷰 자동 게시 서비스
 * 스케줄러에서 호출 - 제출 후 72시간 경과한 리뷰 자동 게시
 */

const supabase = require('../config/supabase');
const { createNotification } = require('../utils/notificationService');
const { PREVIEW_PERIOD_HOURS, AUTO_RELEASE_DAYS } = require('../config/constants');

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
      // 리뷰 상태 → published
      const { error: reviewError } = await supabase
        .from('reviews')
        .update({
          status: 'published',
          published_at: now,
        })
        .eq('id', review.id);

      if (reviewError) {
        console.error(`[REVIEW_PUBLISH] Failed to publish review ${review.id}:`, reviewError.message);
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

      // 에스크로 auto_release_at 설정 (아직 paid 상태인 경우)
      await supabase
        .from('escrows')
        .update({
          auto_release_at: autoReleaseAt.toISOString(),
        })
        .eq('mission_id', review.mission_id)
        .in('status', ['paid', 'hold']);

      // 리뷰어에게 알림
      await createNotification(
        review.reviewer_id,
        'review_published',
        '리뷰가 공개되었습니다',
        '작성하신 리뷰가 자동 공개되었습니다.',
        { reviewId: review.id, missionId: review.mission_id }
      );

      // 업체에게 알림 (business_id로 owner_id 조회)
      const { data: business } = await supabase
        .from('businesses')
        .select('owner_id')
        .eq('id', review.business_id)
        .single();

      if (business?.owner_id) {
        await createNotification(
          business.owner_id,
          'review_published',
          '새 리뷰가 공개되었습니다',
          '미션 리뷰가 공개되었습니다. 확인해보세요.',
          { reviewId: review.id, missionId: review.mission_id }
        );
      }

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
