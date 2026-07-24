/**
 * 정산 자동 처리 서비스
 * 스케줄러에서 호출 - auto_release_at이 지난 에스크로 자동 정산
 */

const supabase = require('../config/supabase');
const { createNotification } = require('../utils/notificationService');
const NT = require('../config/notificationTypes');
const { GRADE_BENEFITS } = require('../config/constants');
// 실제 결제사 송금. 미설정 시 가짜 성공 없이 pending 반환.
const { requestBankTransfer: simulateBankTransfer } = require('../utils/payoutService');

const MAX_RETRY_COUNT = 3;

/**
 * 자동 정산 처리
 * - escrows WHERE status='paid' AND auto_release_at <= NOW()
 * - 각 에스크로마다 은행 송금 시뮬레이션 후 상태 업데이트
 */
async function processAutoSettlement() {
  const { data: escrows, error } = await supabase
    .from('escrows')
    .select(`
      *,
      reviewer:users!escrows_reviewer_id_fkey(
        id, bank_name, bank_account_number, bank_account_holder,
        bank_verification_status, bank_verification_failed_count,
        reviewer_grade
      )
    `)
    .eq('status', 'paid')
    .lte('auto_release_at', new Date().toISOString())
    .eq('auto_release_executed', false);

  if (error) {
    console.error('[SETTLEMENT] Query error:', error.message);
    return { processed: 0, succeeded: 0, failed: 0 };
  }

  if (!escrows || escrows.length === 0) {
    return { processed: 0, succeeded: 0, failed: 0 };
  }

  let succeeded = 0;
  let failed = 0;
  let held = 0;

  for (const escrow of escrows) {
    try {
      // 멱등성: 원자적으로 releasing 상태로 변경하여 중복 처리 방지
      const { data: claimed, error: claimError } = await supabase
        .from('escrows')
        .update({ status: 'releasing' })
        .eq('id', escrow.id)
        .eq('status', 'paid')
        .eq('auto_release_executed', false)
        .select('id');

      if (claimError || !claimed || claimed.length === 0) {
        // 다른 인스턴스가 이미 처리 중
        continue;
      }

      const reviewer = escrow.reviewer;

      // 리뷰어 계좌 정보 없으면 hold 처리
      if (!reviewer?.bank_name || !reviewer?.bank_account_number) {
        await supabase
          .from('escrows')
          .update({
            status: 'hold',
            payout_error_message: '정산 계좌가 등록되지 않았습니다.',
            auto_release_executed: true,
          })
          .eq('id', escrow.id);

        const notifResult = await createNotification(
          reviewer?.id || escrow.reviewer_id,
          NT.SETTLEMENT_FAILED,
          '정산 계좌를 등록해주세요',
          '정산 계좌가 등록되지 않아 정산이 보류되었습니다.',
          { escrowId: escrow.id }
        );
        if (!notifResult.success) {
          console.error(`[SETTLEMENT] Notification failed for escrow ${escrow.id}:`, notifResult.error);
        }
        failed++;
        continue;
      }

      // 계좌 인증 실패 횟수 초과 시 hold
      if (reviewer.bank_verification_failed_count >= MAX_RETRY_COUNT) {
        await supabase
          .from('escrows')
          .update({
            status: 'hold',
            payout_error_message: '계좌 재인증이 필요합니다.',
            auto_release_executed: true,
          })
          .eq('id', escrow.id);
        failed++;
        continue;
      }

      // 등급 배율 적용
      const gradeMultiplier = GRADE_BENEFITS[reviewer.reviewer_grade]?.payMultiplier || 1.0;
      const baseAmount = escrow.reviewer_fee;
      const gradeBonus = Math.round(baseAmount * (gradeMultiplier - 1));
      const totalPayout = baseAmount + gradeBonus;

      // 실제 결제사 송금 요청
      const payoutResult = await simulateBankTransfer({
        bankName: reviewer.bank_name,
        accountNumber: reviewer.bank_account_number,
        accountHolder: reviewer.bank_account_holder,
        amount: totalPayout,
      });

      // 보류(pending): 결제사 미설정/일시오류. 리뷰어 책임이 아니므로
      // 재시도 카운트를 올리지 않고 'paid' 상태로 되돌려 다음 주기에 재처리.
      if (!payoutResult.success && payoutResult.pending) {
        await supabase
          .from('escrows')
          .update({
            status: 'paid',
            payout_error_message: payoutResult.errorMessage,
            payout_last_attempt_at: new Date().toISOString(),
          })
          .eq('id', escrow.id)
          .eq('status', 'releasing');
        console.warn(
          `[SETTLEMENT] Held (pending): escrowId=${escrow.id}, notConfigured=${!!payoutResult.notConfigured}, msg=${payoutResult.errorMessage}`
        );
        held++;
        continue;
      }

      if (payoutResult.success) {
        await supabase
          .from('escrows')
          .update({
            status: 'released',
            payout_amount: totalPayout,
            payout_bank: reviewer.bank_name,
            payout_account: maskAccountNumber(reviewer.bank_account_number),
            payout_holder: reviewer.bank_account_holder,
            payout_at: new Date().toISOString(),
            payout_transaction_id: payoutResult.transactionId,
            payout_error_message: null,
            auto_release_executed: true,
          })
          .eq('id', escrow.id);

        // Record earning history
        await supabase.from('reviewer_earnings').insert({
          reviewer_id: reviewer.id,
          mission_id: escrow.mission_id,
          escrow_id: escrow.id,
          earning_type: 'mission_pay',
          base_amount: baseAmount,
          grade_bonus: gradeBonus,
          total_amount: totalPayout,
          status: 'paid',
          paid_at: new Date().toISOString(),
        });

        // Update user total_earnings (atomic increment via RPC)
        const { error: rpcError } = await supabase.rpc('increment_user_earnings', {
          p_user_id: reviewer.id,
          p_amount: totalPayout,
        });
        if (rpcError) {
          // Fallback: direct update with atomic SQL expression
          console.warn(`[SETTLEMENT] RPC fallback for user ${reviewer.id}:`, rpcError.message);
          await supabase.from('users')
            .update({
              total_earnings: supabase.raw(`COALESCE(total_earnings, 0) + ${totalPayout}`),
              bank_verification_status: 'verified',
              bank_verification_failed_count: 0,
            })
            .eq('id', reviewer.id);
        } else {
          await supabase.from('users')
            .update({
              bank_verification_status: 'verified',
              bank_verification_failed_count: 0,
            })
            .eq('id', reviewer.id);
        }

        const bonusText = gradeBonus > 0
          ? ` (등급 보너스 +${gradeBonus.toLocaleString()}원 포함)`
          : '';
        const notifResult = await createNotification(
          reviewer.id,
          NT.SETTLEMENT_COMPLETE,
          '정산이 완료되었습니다',
          `${totalPayout.toLocaleString()}원이 정산되었습니다.${bonusText}`,
          { escrowId: escrow.id, amount: totalPayout, gradeBonus }
        );
        if (!notifResult.success) {
          console.error(`[SETTLEMENT] Notification failed for escrow ${escrow.id}:`, notifResult.error);
        }

        console.log(`[SETTLEMENT] Success: escrowId=${escrow.id}, base=${baseAmount}, bonus=${gradeBonus}, total=${totalPayout}`);
        succeeded++;
      } else {
        // 실패 - 재시도 카운트 원자적 증가
        // status를 'releasing'에서 다시 'paid'로 되돌리면서 retry_count 증가
        const { data: updatedEscrow } = await supabase
          .from('escrows')
          .update({
            status: 'paid',
            payout_error_message: payoutResult.errorMessage,
            payout_last_attempt_at: new Date().toISOString(),
          })
          .eq('id', escrow.id)
          .eq('status', 'releasing')
          .select('payout_retry_count');

        // RPC로 retry count 원자적 증가
        const { data: incrementedEscrow } = await supabase.rpc('increment_escrow_retry', {
          p_escrow_id: escrow.id,
        });

        const retryCount = incrementedEscrow?.payout_retry_count
          || (updatedEscrow?.[0]?.payout_retry_count || 0) + 1;
        const needsVerification = retryCount >= MAX_RETRY_COUNT;

        if (needsVerification) {
          await supabase
            .from('escrows')
            .update({ status: 'hold' })
            .eq('id', escrow.id);
        }

        await supabase
          .from('users')
          .update({
            bank_verification_status: needsVerification ? 'verification_required' : 'pending',
            bank_verification_failed_count: retryCount,
          })
          .eq('id', reviewer.id);

        console.log(`[SETTLEMENT] Failed: escrowId=${escrow.id}, retry=${retryCount}, error=${payoutResult.errorMessage}`);
        failed++;
      }
    } catch (err) {
      console.error(`[SETTLEMENT] Error processing escrow ${escrow.id}:`, err.message);
      failed++;
    }
  }

  return { processed: escrows.length, succeeded, failed, held };
}

function maskAccountNumber(accountNumber) {
  if (!accountNumber || accountNumber.length < 4) return '****';
  return accountNumber.slice(0, -4).replace(/./g, '*') + accountNumber.slice(-4);
}

module.exports = { processAutoSettlement };
