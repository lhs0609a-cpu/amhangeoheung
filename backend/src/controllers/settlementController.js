/**
 * 정산 컨트롤러
 * P0-3: 정산 계좌 오류 처리 로직
 */

const supabase = require('../config/supabase');
const { createErrorResponse } = require('../utils/errorMessages');

// 정산 상태 상수
const SETTLEMENT_STATUS = {
  PENDING: 'pending',
  PROCESSING: 'processing',
  COMPLETED: 'completed',
  FAILED: 'failed',
  RETRY_REQUIRED: 'retry_required',
  ACCOUNT_VERIFICATION_REQUIRED: 'account_verification_required'
};

// 최대 재시도 횟수
const MAX_RETRY_COUNT = 3;

/**
 * 내 정산 내역 조회 (리뷰어)
 */
exports.getMySettlements = async (req, res, next) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    let query = supabase
      .from('escrows')
      .select(`
        id,
        mission_id,
        reviewer_fee,
        status,
        payout_amount,
        payout_at,
        payout_bank,
        payout_account,
        payout_holder,
        payout_retry_count,
        payout_error_message,
        auto_release_at,
        created_at,
        mission:missions(id, mission_type, category, completed_at)
      `, { count: 'exact' })
      .eq('reviewer_id', req.user.id)
      .order('created_at', { ascending: false });

    if (status) {
      query = query.eq('status', status);
    }

    query = query.range(offset, offset + parseInt(limit) - 1);

    const { data: settlements, error, count } = await query;

    if (error) throw error;

    // 정산 요약 통계
    const { data: summary } = await supabase
      .from('escrows')
      .select('status, reviewer_fee')
      .eq('reviewer_id', req.user.id);

    const stats = {
      totalEarnings: summary?.filter(s => s.status === 'released').reduce((sum, s) => sum + (s.reviewer_fee || 0), 0) || 0,
      pendingAmount: summary?.filter(s => ['paid', 'hold'].includes(s.status)).reduce((sum, s) => sum + (s.reviewer_fee || 0), 0) || 0,
      processingCount: summary?.filter(s => s.status === 'releasing').length || 0,
      failedCount: summary?.filter(s => s.status === 'failed' || s.payout_retry_count > 0).length || 0
    };

    res.json({
      success: true,
      data: {
        settlements: settlements || [],
        stats,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: count || 0,
          pages: Math.ceil((count || 0) / limit)
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 정산 상세 조회
 */
exports.getSettlementDetail = async (req, res, next) => {
  try {
    const { data: settlement, error } = await supabase
      .from('escrows')
      .select(`
        *,
        mission:missions(
          id, mission_type, category, status, completed_at,
          business:businesses(id, name, category)
        ),
        review:reviews(id, status, published_at, total_score)
      `)
      .eq('id', req.params.id)
      .eq('reviewer_id', req.user.id)
      .single();

    if (error || !settlement) {
      return res.status(404).json(
        createErrorResponse('SETTLEMENT_NOT_FOUND')
      );
    }

    // 정산 타임라인 생성
    const timeline = buildSettlementTimeline(settlement);

    res.json({
      success: true,
      data: {
        settlement,
        timeline
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 정산 타임라인 생성
 */
function buildSettlementTimeline(settlement) {
  const timeline = [];

  // 1. 결제 완료
  if (settlement.paid_at) {
    timeline.push({
      status: 'completed',
      title: '업체 결제 완료',
      description: '미션 비용이 에스크로에 입금되었습니다.',
      date: settlement.paid_at
    });
  }

  // 2. 리뷰 제출
  if (settlement.review?.published_at) {
    timeline.push({
      status: 'completed',
      title: '리뷰 공개',
      description: '리뷰가 공개되었습니다.',
      date: settlement.review.published_at
    });
  }

  // 3. 정산 대기
  if (settlement.auto_release_at) {
    const isReleased = settlement.status === 'released';
    timeline.push({
      status: isReleased ? 'completed' : 'pending',
      title: '정산 처리',
      description: isReleased
        ? '정산이 완료되었습니다.'
        : `예상 정산일: ${new Date(settlement.auto_release_at).toLocaleDateString()}`,
      date: settlement.payout_at || settlement.auto_release_at
    });
  }

  // 4. 정산 실패 (있는 경우)
  if (settlement.payout_retry_count > 0) {
    timeline.push({
      status: 'error',
      title: `정산 실패 (${settlement.payout_retry_count}/${MAX_RETRY_COUNT}회)`,
      description: settlement.payout_error_message || '계좌 정보를 확인해주세요.',
      date: settlement.updated_at
    });
  }

  return timeline.sort((a, b) => new Date(a.date) - new Date(b.date));
}

/**
 * 정산 처리 (관리자 또는 자동 스케줄러용)
 */
exports.processSettlement = async (req, res, next) => {
  try {
    const { escrowId } = req.params;

    const { data: escrow, error: fetchError } = await supabase
      .from('escrows')
      .select(`
        *,
        reviewer:users!escrows_reviewer_id_fkey(
          id, bank_name, bank_account_number, bank_account_holder,
          bank_verification_status, bank_verification_failed_count
        )
      `)
      .eq('id', escrowId)
      .single();

    if (fetchError || !escrow) {
      return res.status(404).json(
        createErrorResponse('ESCROW_NOT_FOUND')
      );
    }

    // 이미 정산 완료된 경우
    if (escrow.status === 'released') {
      return res.status(400).json({
        success: false,
        error: {
          code: 'ALREADY_SETTLED',
          message: '이미 정산 완료된 건입니다.'
        }
      });
    }

    // 리뷰어 계좌 정보 확인
    const reviewer = escrow.reviewer;
    if (!reviewer?.bank_name || !reviewer?.bank_account_number) {
      // 계좌 미등록 - 재인증 필요
      await supabase
        .from('escrows')
        .update({
          status: 'hold',
          payout_error_message: '정산 계좌가 등록되지 않았습니다.'
        })
        .eq('id', escrowId);

      return res.status(400).json({
        success: false,
        error: {
          code: 'BANK_ACCOUNT_NOT_REGISTERED',
          message: '정산 계좌가 등록되지 않았습니다.',
          guidance: ['설정 > 정산 계좌에서 계좌를 등록해주세요.'],
          action: 'go_to_bank_settings'
        }
      });
    }

    // 계좌 인증 실패 횟수 확인 (3회 이상이면 재인증 필요)
    if (reviewer.bank_verification_failed_count >= MAX_RETRY_COUNT) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'BANK_VERIFICATION_REQUIRED',
          message: '정산 계좌 재인증이 필요합니다.',
          guidance: [
            '계좌 정보 오류로 정산이 실패했습니다.',
            '새 계좌를 등록하거나 기존 계좌를 재인증해주세요.'
          ],
          action: 'verify_bank_account'
        }
      });
    }

    // 정산 처리 시뮬레이션 (실제로는 은행 API 연동 필요)
    const payoutResult = await simulateBankTransfer({
      bankName: reviewer.bank_name,
      accountNumber: reviewer.bank_account_number,
      accountHolder: reviewer.bank_account_holder,
      amount: escrow.reviewer_fee
    });

    if (payoutResult.success) {
      // 정산 성공
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
          payout_error_message: null
        })
        .eq('id', escrowId);

      // 리뷰어 계좌 인증 실패 횟수 초기화
      await supabase
        .from('users')
        .update({
          bank_verification_status: 'verified',
          bank_verification_failed_count: 0
        })
        .eq('id', reviewer.id);

      // 정산 완료 알림
      const { createNotification } = require('../utils/notificationService');
      await createNotification(
        reviewer.id,
        'settlement_complete',
        '정산이 완료되었습니다',
        `${escrow.reviewer_fee.toLocaleString()}원이 정산되었습니다.`,
        { escrowId, amount: escrow.reviewer_fee }
      );
      console.log(`[SETTLEMENT] Success: escrowId=${escrowId}, amount=${escrow.reviewer_fee}`);

      res.json({
        success: true,
        message: '정산이 완료되었습니다.',
        data: {
          transactionId: payoutResult.transactionId,
          amount: escrow.reviewer_fee,
          paidAt: new Date().toISOString()
        }
      });
    } else {
      // 정산 실패 - 재시도 카운트 증가
      const retryCount = (escrow.payout_retry_count || 0) + 1;
      const needsVerification = retryCount >= MAX_RETRY_COUNT;

      await supabase
        .from('escrows')
        .update({
          status: needsVerification ? 'hold' : 'releasing',
          payout_retry_count: retryCount,
          payout_error_message: payoutResult.errorMessage
        })
        .eq('id', escrowId);

      // 리뷰어 계좌 인증 실패 횟수 증가
      await supabase
        .from('users')
        .update({
          bank_verification_status: needsVerification ? 'verification_required' : 'pending',
          bank_verification_failed_count: retryCount
        })
        .eq('id', reviewer.id);

      console.log(`[SETTLEMENT] Failed: escrowId=${escrowId}, retryCount=${retryCount}, error=${payoutResult.errorMessage}`);

      if (needsVerification) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'BANK_VERIFICATION_REQUIRED',
            message: '정산 계좌 재인증이 필요합니다.',
            guidance: [
              `정산 실패 ${retryCount}회로 계좌 재인증이 필요합니다.`,
              '계좌 정보를 확인하고 다시 등록해주세요.'
            ],
            action: 'verify_bank_account',
            retryCount,
            maxRetryCount: MAX_RETRY_COUNT
          }
        });
      }

      res.status(400).json({
        success: false,
        error: {
          code: 'SETTLEMENT_FAILED',
          message: '정산 처리에 실패했습니다.',
          guidance: [
            payoutResult.errorMessage,
            `${MAX_RETRY_COUNT - retryCount}회 재시도 가능합니다.`
          ],
          action: 'retry',
          retryCount,
          maxRetryCount: MAX_RETRY_COUNT
        }
      });
    }
  } catch (error) {
    next(error);
  }
};

/**
 * 정산 재시도 요청 (리뷰어)
 */
exports.retrySettlement = async (req, res, next) => {
  try {
    const { data: escrow, error: fetchError } = await supabase
      .from('escrows')
      .select('id, status, payout_retry_count, reviewer_id')
      .eq('id', req.params.id)
      .eq('reviewer_id', req.user.id)
      .single();

    if (fetchError || !escrow) {
      return res.status(404).json(
        createErrorResponse('SETTLEMENT_NOT_FOUND')
      );
    }

    // 재시도 가능 상태 확인
    if (escrow.status === 'released') {
      return res.status(400).json({
        success: false,
        error: {
          code: 'ALREADY_SETTLED',
          message: '이미 정산 완료된 건입니다.'
        }
      });
    }

    if (escrow.payout_retry_count >= MAX_RETRY_COUNT) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'BANK_VERIFICATION_REQUIRED',
          message: '계좌 재인증이 필요합니다.',
          guidance: ['설정 > 정산 계좌에서 계좌를 재인증해주세요.'],
          action: 'verify_bank_account'
        }
      });
    }

    // 정산 재시도 대기열에 추가
    await supabase
      .from('escrows')
      .update({
        status: 'releasing',
        payout_error_message: null
      })
      .eq('id', req.params.id);

    res.json({
      success: true,
      message: '정산 재시도가 요청되었습니다. 영업일 기준 1-2일 내 처리됩니다.'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 정산 계좌 재인증 (리뷰어)
 */
exports.verifyBankAccount = async (req, res, next) => {
  try {
    const { bankName, accountNumber, accountHolder } = req.body;

    if (!bankName || !accountNumber || !accountHolder) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'INVALID_BANK_INFO',
          message: '계좌 정보를 모두 입력해주세요.'
        }
      });
    }

    // 계좌 유효성 검증 시뮬레이션 (실제로는 은행 API 연동)
    const verificationResult = await simulateAccountVerification({
      bankName,
      accountNumber,
      accountHolder
    });

    if (!verificationResult.success) {
      // 인증 실패
      await supabase
        .from('users')
        .update({
          bank_verification_status: 'failed',
          bank_verification_failed_count: supabase.sql`bank_verification_failed_count + 1`
        })
        .eq('id', req.user.id);

      return res.status(400).json({
        success: false,
        error: {
          code: 'BANK_VERIFICATION_FAILED',
          message: '계좌 인증에 실패했습니다.',
          guidance: [
            verificationResult.errorMessage,
            '계좌 정보를 다시 확인해주세요.'
          ],
          action: 'retry'
        }
      });
    }

    // 인증 성공 - 계좌 정보 업데이트
    await supabase
      .from('users')
      .update({
        bank_name: bankName,
        bank_account_number: accountNumber,
        bank_account_holder: accountHolder,
        bank_verification_status: 'verified',
        bank_verification_failed_count: 0,
        bank_verified_at: new Date().toISOString()
      })
      .eq('id', req.user.id);

    // 보류 중인 정산 건 재처리 대기열에 추가
    await supabase
      .from('escrows')
      .update({
        status: 'releasing',
        payout_retry_count: 0,
        payout_error_message: null
      })
      .eq('reviewer_id', req.user.id)
      .eq('status', 'hold');

    res.json({
      success: true,
      message: '계좌 인증이 완료되었습니다. 보류 중인 정산이 재처리됩니다.',
      data: {
        bankName,
        accountNumber: maskAccountNumber(accountNumber),
        accountHolder
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 계좌번호 마스킹
 */
function maskAccountNumber(accountNumber) {
  if (!accountNumber || accountNumber.length < 4) return '****';
  return accountNumber.slice(0, -4).replace(/./g, '*') + accountNumber.slice(-4);
}

/**
 * 은행 송금 시뮬레이션 (실제로는 은행 API 연동 필요)
 */
async function simulateBankTransfer({ bankName, accountNumber, accountHolder, amount }) {
  // TODO: 실제 은행 API 연동
  // 개발 환경에서는 90% 확률로 성공 시뮬레이션
  const success = Math.random() > 0.1;

  if (success) {
    return {
      success: true,
      transactionId: `TXN_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
    };
  } else {
    const errors = [
      '예금주명이 일치하지 않습니다.',
      '해당 계좌를 찾을 수 없습니다.',
      '은행 점검 시간입니다. 잠시 후 다시 시도해주세요.',
      '계좌가 해지되었거나 거래정지 상태입니다.'
    ];
    return {
      success: false,
      errorMessage: errors[Math.floor(Math.random() * errors.length)]
    };
  }
}

/**
 * 계좌 유효성 검증 시뮬레이션
 */
async function simulateAccountVerification({ bankName, accountNumber, accountHolder }) {
  // TODO: 실제 은행 API 연동 (오픈뱅킹 등)
  // 개발 환경에서는 95% 확률로 성공 시뮬레이션
  const success = Math.random() > 0.05;

  if (success) {
    return { success: true };
  } else {
    return {
      success: false,
      errorMessage: '예금주명이 일치하지 않습니다.'
    };
  }
}

module.exports = {
  SETTLEMENT_STATUS,
  MAX_RETRY_COUNT
};
