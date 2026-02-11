/**
 * 미션 만료 처리 서비스
 * 스케줄러에서 호출 - 모집 마감일이 지난 미완료 미션 자동 취소 및 환불
 */

const supabase = require('../config/supabase');
const { cancelPayment } = require('../utils/tossPayments');
const { createNotification } = require('../utils/notificationService');

/**
 * 미션 만료 처리
 * - missions WHERE status='recruiting' AND recruitment_deadline <= NOW()
 * - 결제 환불 처리 후 에스크로 → refunded, 미션 → cancelled
 */
async function processMissionExpiry() {
  const { data: missions, error } = await supabase
    .from('missions')
    .select(`
      id,
      business_id,
      transaction_id,
      total_amount,
      status,
      recruitment_deadline
    `)
    .eq('status', 'recruiting')
    .lte('recruitment_deadline', new Date().toISOString());

  if (error) {
    console.error('[MISSION_EXPIRY] Query error:', error.message);
    return { processed: 0, cancelled: 0, failed: 0 };
  }

  if (!missions || missions.length === 0) {
    return { processed: 0, cancelled: 0, failed: 0 };
  }

  let cancelled = 0;
  let failed = 0;

  for (const mission of missions) {
    try {
      // 결제 환불 처리 (transaction_id가 있는 경우)
      if (mission.transaction_id) {
        try {
          await cancelPayment(
            mission.transaction_id,
            '모집 기간 만료로 인한 자동 취소'
          );
          console.log(`[MISSION_EXPIRY] Payment cancelled: missionId=${mission.id}`);
        } catch (paymentError) {
          console.error(`[MISSION_EXPIRY] Payment cancel failed for mission ${mission.id}:`, paymentError.message);
          // 결제 환불 실패해도 미션은 취소 처리 진행 (수동 처리 필요 플래그)
        }
      }

      // 에스크로 → refunded
      await supabase
        .from('escrows')
        .update({
          status: 'refunded',
          refund_amount: mission.total_amount,
          refund_reason: '모집 기간 만료로 인한 자동 환불',
          refund_processed_at: new Date().toISOString(),
        })
        .eq('mission_id', mission.id)
        .in('status', ['pending', 'paid']);

      // 미션 → cancelled
      await supabase
        .from('missions')
        .update({
          status: 'cancelled',
        })
        .eq('id', mission.id);

      // 업체에 알림
      const { data: business } = await supabase
        .from('businesses')
        .select('owner_id')
        .eq('id', mission.business_id)
        .single();

      if (business?.owner_id) {
        await createNotification(
          business.owner_id,
          'mission_expired',
          '미션 모집이 만료되었습니다',
          '모집 기간이 종료되어 미션이 자동 취소되었습니다. 결제 금액은 환불됩니다.',
          { missionId: mission.id }
        );
      }

      console.log(`[MISSION_EXPIRY] Cancelled: missionId=${mission.id}`);
      cancelled++;
    } catch (err) {
      console.error(`[MISSION_EXPIRY] Error processing mission ${mission.id}:`, err.message);
      failed++;
    }
  }

  return { processed: missions.length, cancelled, failed };
}

module.exports = { processMissionExpiry };
