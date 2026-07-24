/**
 * 정산 송금 서비스 (실제 결제사/오픈뱅킹 연동)
 *
 * 안전 원칙:
 * - 결제사 자격증명(PAYOUT_*)이 설정되지 않으면 절대 "성공"을 반환하지 않는다.
 *   대신 notConfigured=true 로 보류(hold) 처리하여 사람이 수동 정산하도록 한다.
 * - Math.random 같은 가짜 성공 시뮬레이션은 사용하지 않는다.
 *
 * 환경변수:
 * - PAYOUT_PROVIDER      : 'openbanking' | 'toss' 등 (미설정 시 비활성)
 * - PAYOUT_API_BASE_URL  : 결제사 송금 API 베이스 URL
 * - PAYOUT_API_KEY       : 결제사 API 시크릿/토큰
 */

const axios = require('axios');

const PAYOUT_PROVIDER = process.env.PAYOUT_PROVIDER || '';
const PAYOUT_API_BASE_URL = process.env.PAYOUT_API_BASE_URL || '';
const PAYOUT_API_KEY = process.env.PAYOUT_API_KEY || '';

/**
 * 결제사 연동이 설정되어 있는지 여부
 */
function isPayoutConfigured() {
  return Boolean(PAYOUT_PROVIDER && PAYOUT_API_BASE_URL && PAYOUT_API_KEY);
}

function notConfiguredResult() {
  return {
    success: false,
    pending: true,
    notConfigured: true,
    errorMessage:
      '정산 결제사 연동이 아직 설정되지 않았습니다. 관리자 수동 정산이 필요합니다.'
  };
}

function buildClient() {
  return axios.create({
    baseURL: PAYOUT_API_BASE_URL,
    timeout: 15000,
    headers: {
      Authorization: `Bearer ${PAYOUT_API_KEY}`,
      'Content-Type': 'application/json'
    }
  });
}

/**
 * 실제 계좌로 송금 요청.
 * @returns {Promise<{success:boolean, transactionId?:string, pending?:boolean, notConfigured?:boolean, errorMessage?:string}>}
 */
async function requestBankTransfer({ bankName, accountNumber, accountHolder, amount }) {
  if (!isPayoutConfigured()) {
    return notConfiguredResult();
  }

  try {
    const client = buildClient();
    // NOTE: 실제 엔드포인트/요청 스펙은 선택한 결제사 문서에 맞춰 조정한다.
    const { data } = await client.post('/transfers', {
      bank_name: bankName,
      account_number: accountNumber,
      account_holder: accountHolder,
      amount
    });

    if (data && (data.status === 'completed' || data.success === true)) {
      return {
        success: true,
        transactionId: data.transaction_id || data.transactionId || data.id
      };
    }

    return {
      success: false,
      errorMessage: data?.message || '송금이 거절되었습니다.'
    };
  } catch (error) {
    // 네트워크/일시 오류는 실패가 아닌 보류로 처리하여 재시도 카운트가
    // 사용자 책임으로 누적되지 않도록 한다.
    const status = error.response?.status;
    const message = error.response?.data?.message || error.message;
    console.error('[PAYOUT] transfer error:', status, message);

    if (status === 400 || status === 422) {
      // 계좌 정보 오류 등 명확한 거절 → 실패
      return { success: false, errorMessage: message };
    }
    // 그 외(타임아웃/5xx) → 보류 후 재시도
    return { success: false, pending: true, errorMessage: message };
  }
}

/**
 * 예금주 실명/계좌 유효성 검증.
 */
async function requestAccountVerification({ bankName, accountNumber, accountHolder }) {
  if (!isPayoutConfigured()) {
    return notConfiguredResult();
  }

  try {
    const client = buildClient();
    const { data } = await client.post('/accounts/verify', {
      bank_name: bankName,
      account_number: accountNumber,
      account_holder: accountHolder
    });

    if (data && (data.verified === true || data.success === true)) {
      return { success: true };
    }

    return {
      success: false,
      errorMessage: data?.message || '예금주명이 일치하지 않습니다.'
    };
  } catch (error) {
    const status = error.response?.status;
    const message = error.response?.data?.message || error.message;
    console.error('[PAYOUT] verify error:', status, message);

    if (status === 400 || status === 422) {
      return { success: false, errorMessage: message };
    }
    return { success: false, pending: true, errorMessage: message };
  }
}

module.exports = {
  isPayoutConfigured,
  requestBankTransfer,
  requestAccountVerification
};
