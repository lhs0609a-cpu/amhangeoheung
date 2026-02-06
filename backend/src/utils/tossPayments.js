/**
 * 토스페이먼츠 결제 유틸리티
 * https://docs.tosspayments.com/reference
 */

const axios = require('axios');

const TOSS_API_URL = 'https://api.tosspayments.com/v1';

// 결제 상태 상수
const PAYMENT_STATUS = {
  READY: 'READY',
  IN_PROGRESS: 'IN_PROGRESS',
  WAITING_FOR_DEPOSIT: 'WAITING_FOR_DEPOSIT',
  DONE: 'DONE',
  CANCELED: 'CANCELED',
  PARTIAL_CANCELED: 'PARTIAL_CANCELED',
  ABORTED: 'ABORTED',
  EXPIRED: 'EXPIRED'
};

// 롤백 가능한 상태
const REFUNDABLE_STATUSES = [PAYMENT_STATUS.DONE, PAYMENT_STATUS.PARTIAL_CANCELED];

/**
 * 인증 헤더 생성
 * @returns {Object} Authorization 헤더
 */
function getAuthHeader() {
  const secretKey = process.env.TOSS_SECRET_KEY;
  if (!secretKey) {
    throw new Error('TOSS_SECRET_KEY 환경변수가 설정되지 않았습니다.');
  }
  const encodedKey = Buffer.from(secretKey + ':').toString('base64');
  return {
    Authorization: `Basic ${encodedKey}`,
    'Content-Type': 'application/json'
  };
}

/**
 * 결제 승인
 * @param {string} paymentKey - 토스에서 발급한 결제 키
 * @param {string} orderId - 주문 ID
 * @param {number} amount - 결제 금액
 * @returns {Promise<Object>} 결제 승인 결과
 */
async function confirmPayment(paymentKey, orderId, amount) {
  try {
    const response = await axios.post(
      `${TOSS_API_URL}/payments/confirm`,
      { paymentKey, orderId, amount },
      { headers: getAuthHeader() }
    );
    return response.data;
  } catch (error) {
    if (error.response) {
      const { code, message } = error.response.data;
      throw new Error(`결제 승인 실패: ${message} (${code})`);
    }
    throw error;
  }
}

/**
 * 결제 취소/환불 (안전한 롤백 지원)
 * @param {string} paymentKey - 토스에서 발급한 결제 키
 * @param {string} cancelReason - 취소 사유
 * @param {number} [cancelAmount] - 부분 취소 금액 (선택, 미입력시 전액 취소)
 * @param {Object} [options] - 추가 옵션
 * @param {boolean} [options.skipStatusCheck] - 상태 확인 건너뛰기 (이미 확인된 경우)
 * @param {number} [options.retryCount] - 재시도 횟수 (기본: 3)
 * @returns {Promise<Object>} 취소 결과
 */
async function cancelPayment(paymentKey, cancelReason, cancelAmount = null, options = {}) {
  const { skipStatusCheck = false, retryCount = 3 } = options;

  // 상태 확인 (이미 취소된 결제인지 체크)
  if (!skipStatusCheck) {
    try {
      const payment = await getPayment(paymentKey);

      // 이미 취소된 경우
      if (payment.status === PAYMENT_STATUS.CANCELED) {
        console.log(`[PAYMENT] Already canceled: ${paymentKey}`);
        return {
          ...payment,
          alreadyCanceled: true,
          message: '이미 취소된 결제입니다.'
        };
      }

      // 취소 불가능한 상태
      if (!REFUNDABLE_STATUSES.includes(payment.status)) {
        console.warn(`[PAYMENT] Cannot cancel, status: ${payment.status}, paymentKey: ${paymentKey}`);
        throw new Error(`취소 불가능한 결제 상태: ${payment.status}`);
      }
    } catch (statusError) {
      // 결제 조회 실패 시에도 취소 시도 (결제가 존재하지 않을 수 있음)
      console.warn(`[PAYMENT] Status check failed, attempting cancel anyway: ${statusError.message}`);
    }
  }

  // 재시도 로직
  let lastError = null;
  for (let attempt = 1; attempt <= retryCount; attempt++) {
    try {
      const body = { cancelReason };
      if (cancelAmount !== null) {
        body.cancelAmount = cancelAmount;
      }

      const response = await axios.post(
        `${TOSS_API_URL}/payments/${paymentKey}/cancel`,
        body,
        { headers: getAuthHeader() }
      );

      console.log(`[PAYMENT] Cancel success: ${paymentKey}, reason: ${cancelReason}`);
      return response.data;
    } catch (error) {
      lastError = error;

      if (error.response) {
        const { code, message } = error.response.data;

        // 이미 취소된 경우 (ALREADY_CANCELED_PAYMENT)
        if (code === 'ALREADY_CANCELED_PAYMENT') {
          console.log(`[PAYMENT] Already canceled (from API): ${paymentKey}`);
          return {
            paymentKey,
            status: PAYMENT_STATUS.CANCELED,
            alreadyCanceled: true,
            message: '이미 취소된 결제입니다.'
          };
        }

        // 재시도 불가능한 에러
        if (['INVALID_PAYMENT_KEY', 'NOT_FOUND_PAYMENT'].includes(code)) {
          throw new Error(`결제 취소 실패: ${message} (${code})`);
        }

        console.warn(`[PAYMENT] Cancel attempt ${attempt}/${retryCount} failed: ${message} (${code})`);
      }

      // 재시도 전 대기 (exponential backoff)
      if (attempt < retryCount) {
        await new Promise(resolve => setTimeout(resolve, Math.pow(2, attempt) * 100));
      }
    }
  }

  // 모든 재시도 실패
  console.error(`[PAYMENT] Cancel failed after ${retryCount} attempts: ${paymentKey}`);
  if (lastError?.response) {
    const { code, message } = lastError.response.data;
    throw new Error(`결제 취소 실패: ${message} (${code})`);
  }
  throw lastError;
}

/**
 * 안전한 롤백 실행 (결제 취소 + 로깅)
 * @param {string} paymentKey - 결제 키
 * @param {string} reason - 롤백 사유
 * @param {Object} context - 컨텍스트 정보 (로깅용)
 * @returns {Promise<Object>} 롤백 결과
 */
async function safeRollback(paymentKey, reason, context = {}) {
  const rollbackLog = {
    paymentKey,
    reason,
    context,
    timestamp: new Date().toISOString(),
    success: false,
    error: null
  };

  try {
    const result = await cancelPayment(paymentKey, reason);
    rollbackLog.success = true;
    rollbackLog.result = result;

    // 롤백 성공 로그 (추후 모니터링 시스템 연동)
    console.log('[ROLLBACK SUCCESS]', JSON.stringify(rollbackLog));

    return {
      success: true,
      refunded: !result.alreadyCanceled,
      alreadyCanceled: result.alreadyCanceled || false,
      paymentKey
    };
  } catch (error) {
    rollbackLog.error = error.message;

    // 롤백 실패 로그 (CRITICAL - 추후 알림 시스템 연동 필요)
    console.error('[ROLLBACK FAILED - CRITICAL]', JSON.stringify(rollbackLog));

    return {
      success: false,
      error: error.message,
      paymentKey,
      requiresManualIntervention: true
    };
  }
}

/**
 * 결제 조회
 * @param {string} paymentKey - 토스에서 발급한 결제 키
 * @returns {Promise<Object>} 결제 정보
 */
async function getPayment(paymentKey) {
  try {
    const response = await axios.get(
      `${TOSS_API_URL}/payments/${paymentKey}`,
      { headers: getAuthHeader() }
    );
    return response.data;
  } catch (error) {
    if (error.response) {
      const { code, message } = error.response.data;
      throw new Error(`결제 조회 실패: ${message} (${code})`);
    }
    throw error;
  }
}

/**
 * 주문 ID로 결제 조회
 * @param {string} orderId - 주문 ID
 * @returns {Promise<Object>} 결제 정보
 */
async function getPaymentByOrderId(orderId) {
  try {
    const response = await axios.get(
      `${TOSS_API_URL}/payments/orders/${orderId}`,
      { headers: getAuthHeader() }
    );
    return response.data;
  } catch (error) {
    if (error.response) {
      const { code, message } = error.response.data;
      throw new Error(`결제 조회 실패: ${message} (${code})`);
    }
    throw error;
  }
}

/**
 * 빌링키 발급 (자동결제용)
 * @param {string} authKey - 카드 인증 키
 * @param {string} customerKey - 고객 고유 키
 * @returns {Promise<Object>} 빌링키 정보
 */
async function issueBillingKey(authKey, customerKey) {
  try {
    const response = await axios.post(
      `${TOSS_API_URL}/billing/authorizations/issue`,
      { authKey, customerKey },
      { headers: getAuthHeader() }
    );
    return response.data;
  } catch (error) {
    if (error.response) {
      const { code, message } = error.response.data;
      throw new Error(`빌링키 발급 실패: ${message} (${code})`);
    }
    throw error;
  }
}

/**
 * 빌링키로 자동결제
 * @param {string} billingKey - 빌링키
 * @param {string} customerKey - 고객 고유 키
 * @param {number} amount - 결제 금액
 * @param {string} orderId - 주문 ID
 * @param {string} orderName - 주문명
 * @returns {Promise<Object>} 결제 결과
 */
async function payWithBillingKey(billingKey, customerKey, amount, orderId, orderName) {
  try {
    const response = await axios.post(
      `${TOSS_API_URL}/billing/${billingKey}`,
      { customerKey, amount, orderId, orderName },
      { headers: getAuthHeader() }
    );
    return response.data;
  } catch (error) {
    if (error.response) {
      const { code, message } = error.response.data;
      throw new Error(`자동결제 실패: ${message} (${code})`);
    }
    throw error;
  }
}

/**
 * 결제 상태 검증
 * @param {string} paymentKey - 결제 키
 * @returns {Promise<Object>} 검증 결과
 */
async function verifyPaymentStatus(paymentKey) {
  try {
    const payment = await getPayment(paymentKey);
    return {
      isValid: true,
      status: payment.status,
      isDone: payment.status === PAYMENT_STATUS.DONE,
      isCanceled: [PAYMENT_STATUS.CANCELED, PAYMENT_STATUS.PARTIAL_CANCELED].includes(payment.status),
      canRefund: REFUNDABLE_STATUSES.includes(payment.status),
      payment
    };
  } catch (error) {
    return {
      isValid: false,
      error: error.message
    };
  }
}

module.exports = {
  // 상수
  PAYMENT_STATUS,
  REFUNDABLE_STATUSES,

  // 핵심 기능
  confirmPayment,
  cancelPayment,
  getPayment,
  getPaymentByOrderId,

  // 자동결제
  issueBillingKey,
  payWithBillingKey,

  // 롤백 유틸리티
  safeRollback,
  verifyPaymentStatus
};
