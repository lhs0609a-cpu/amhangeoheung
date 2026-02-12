/**
 * 정산 자동 처리 서비스
 * 스케줄러에서 호출 - auto_release_at이 지난 에스크로 자동 정산
 */

const supabase = require('../config/supabase');
const { createNotification } = require('../utils/notificationService');
const NT = require('../config/notificationTypes');

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
        bank_verification_status, bank_verification_failed_count
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

      // 은행 송금 시뮬레이션
      const payoutResult = await simulateBankTransfer({
        bankName: reviewer.bank_name,
        accountNumber: reviewer.bank_account_number,
        accountHolder: reviewer.bank_account_holder,
        amount: escrow.reviewer_fee,
      });

      if (payoutResult.success) {
        await supabase
          .from('escrows')
          .update({
            status: 'released',
            payout_amount: escrow.reviewer_fee,
            payout_bank: reviewer.bank_name,
            payout_account: maskAccountNumber(reviewer.bank_account_number),
            payout_holder: reviewer.bank_account_holder,
            payout_at: new Date().toISOString(),
            payout_transaction_id: payoutResult.transactionId,
            payout_error_message: null,
            auto_release_executed: true,
          })
          .eq('id', escrow.id);

        // 인증 실패 횟수 초기화
        await supabase
          .from('users')
          .update({
            bank_verification_status: 'verified',
            bank_verification_failed_count: 0,
          })
          .eq('id', reviewer.id);

        const notifResult = await createNotification(
          reviewer.id,
          NT.SETTLEMENT_COMPLETE,
          '정산이 완료되었습니다',
          `${escrow.reviewer_fee.toLocaleString()}원이 정산되었습니다.`,
          { escrowId: escrow.id, amount: escrow.reviewer_fee }
        );
        if (!notifResult.success) {
          console.error(`[SETTLEMENT] Notification failed for escrow ${escrow.id}:`, notifResult.error);
        }

        console.log(`[SETTLEMENT] Success: escrowId=${escrow.id}, amount=${escrow.reviewer_fee}`);
        succeeded++;
      } else {
        // 실패 - 재시도 카운트 증가
        const retryCount = (escrow.payout_retry_count || 0) + 1;
        const needsVerification = retryCount >= MAX_RETRY_COUNT;

        await supabase
          .from('escrows')
          .update({
            status: needsVerification ? 'hold' : 'paid',
            payout_retry_count: retryCount,
            payout_error_message: payoutResult.errorMessage,
            payout_last_attempt_at: new Date().toISOString(),
          })
          .eq('id', escrow.id);

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

  return { processed: escrows.length, succeeded, failed };
}

/**
 * 은행 송금 시뮬레이션 (실제로는 은행 API 연동)
 */
async function simulateBankTransfer({ bankName, accountNumber, accountHolder, amount }) {
  const success = Math.random() > 0.1;
  if (success) {
    return {
      success: true,
      transactionId: `TXN_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    };
  }
  const errors = [
    '예금주명이 일치하지 않습니다.',
    '해당 계좌를 찾을 수 없습니다.',
    '은행 점검 시간입니다. 잠시 후 다시 시도해주세요.',
    '계좌가 해지되었거나 거래정지 상태입니다.',
  ];
  return {
    success: false,
    errorMessage: errors[Math.floor(Math.random() * errors.length)],
  };
}

function maskAccountNumber(accountNumber) {
  if (!accountNumber || accountNumber.length < 4) return '****';
  return accountNumber.slice(0, -4).replace(/./g, '*') + accountNumber.slice(-4);
}

module.exports = { processAutoSettlement };
