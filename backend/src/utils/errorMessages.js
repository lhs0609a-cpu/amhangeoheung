/**
 * 사용자 친화적 에러 메시지 유틸리티
 * 기술적 에러를 일반 사용자가 이해할 수 있는 메시지로 변환
 */

const ERROR_CODES = {
  // GPS 관련 (P1-4: 개선된 가이드)
  GPS_TOO_FAR: {
    code: 'GPS_TOO_FAR',
    message: '현재 위치가 업체와 너무 멀어요.',
    guidance: [
      '업체 근처(100m 이내)에서 다시 시도해주세요.',
      '건물 내부나 지하에서는 GPS 오차가 발생할 수 있어요.',
      'Wi-Fi를 켜면 위치 정확도가 올라갑니다.'
    ],
    action: 'manual_verification',
    manualVerificationGuide: {
      title: '수동 인증으로 체크인하기',
      steps: [
        '업체 간판이 보이도록 사진을 촬영해주세요.',
        '가능하면 영수증도 함께 찍어주세요.',
        '사진이 선명하게 나오도록 해주세요.'
      ]
    }
  },
  GPS_UNAVAILABLE: {
    code: 'GPS_UNAVAILABLE',
    message: '위치 정보를 가져올 수 없습니다.',
    guidance: [
      '위치 서비스가 켜져 있는지 확인해주세요.',
      '앱에 위치 권한이 허용되어 있는지 확인해주세요.'
    ],
    action: 'check_settings'
  },

  // 결제 관련
  PAYMENT_FAILED: {
    code: 'PAYMENT_FAILED',
    message: '결제 처리에 실패했습니다.',
    guidance: [
      '카드 정보가 올바른지 확인해주세요.',
      '카드 한도를 확인해주세요.',
      '다른 결제 수단을 이용해보세요.'
    ],
    action: 'retry_payment'
  },
  PAYMENT_CANCELLED: {
    code: 'PAYMENT_CANCELLED',
    message: '결제가 취소되었습니다.',
    guidance: [
      '결제 과정에서 오류가 발생하여 자동으로 취소되었습니다.',
      '금액이 청구되었다면 영업일 기준 3-5일 내 환불됩니다.'
    ],
    action: 'contact_support'
  },
  PAYMENT_ALREADY_PROCESSED: {
    code: 'PAYMENT_ALREADY_PROCESSED',
    message: '이미 처리된 결제입니다.',
    guidance: [
      '페이지를 새로고침하여 최신 상태를 확인해주세요.'
    ],
    action: 'refresh'
  },
  ROLLBACK_FAILED: {
    code: 'ROLLBACK_FAILED',
    message: '결제 처리 중 오류가 발생했습니다.',
    guidance: [
      '결제가 청구되었을 수 있습니다.',
      '영업일 기준 1-2일 내 자동 환불됩니다.',
      '확인이 필요하시면 고객센터로 문의해주세요.'
    ],
    action: 'contact_support'
  },
  ALREADY_PREMIUM: {
    code: 'ALREADY_PREMIUM',
    message: '이미 프리미엄 구독 중입니다.',
    guidance: [
      '설정에서 현재 구독 상태를 확인하세요.',
      '플랜 변경을 원하시면 고객센터로 문의해주세요.'
    ],
    action: 'go_to_settings'
  },

  // 미션 관련
  MISSION_NOT_FOUND: {
    code: 'MISSION_NOT_FOUND',
    message: '미션을 찾을 수 없습니다.',
    guidance: [
      '해당 미션이 삭제되었거나 마감되었을 수 있습니다.',
      '미션 목록을 새로고침해주세요.'
    ],
    action: 'go_to_missions'
  },
  MISSION_ALREADY_APPLIED: {
    code: 'MISSION_ALREADY_APPLIED',
    message: '이미 신청한 미션입니다.',
    guidance: [
      '내 미션 목록에서 신청 현황을 확인하세요.'
    ],
    action: 'go_to_my_missions'
  },
  MISSION_CLOSED: {
    code: 'MISSION_CLOSED',
    message: '모집이 마감되었습니다.',
    guidance: [
      '다른 미션을 찾아보세요.',
      '관심 카테고리를 설정하면 새 미션 알림을 받을 수 있습니다.'
    ],
    action: 'go_to_missions'
  },
  MISSION_IN_PROGRESS: {
    code: 'MISSION_IN_PROGRESS',
    message: '진행 중인 미션이 있습니다.',
    guidance: [
      '현재 진행 중인 미션을 완료한 후 다시 시도해주세요.'
    ],
    action: 'go_to_my_missions'
  },

  // 계정 관련
  ACCOUNT_HAS_ACTIVE_MISSIONS: {
    code: 'ACCOUNT_HAS_ACTIVE_MISSIONS',
    message: '진행 중인 미션이 있어 탈퇴할 수 없습니다.',
    guidance: [
      '현재 진행 중인 미션을 완료하거나 취소해주세요.',
      '미션 완료 후 다시 탈퇴를 시도해주세요.'
    ],
    action: 'go_to_my_missions'
  },
  ACCOUNT_HAS_PENDING_PAYMENT: {
    code: 'ACCOUNT_HAS_PENDING_PAYMENT',
    message: '정산되지 않은 금액이 있어 탈퇴할 수 없습니다.',
    guidance: [
      '정산 예정 금액을 먼저 수령해주세요.',
      '정산 계좌가 등록되어 있는지 확인해주세요.'
    ],
    action: 'go_to_settings'
  },
  ACCOUNT_HAS_ACTIVE_BUSINESS: {
    code: 'ACCOUNT_HAS_ACTIVE_BUSINESS',
    message: '운영 중인 업체가 있어 탈퇴할 수 없습니다.',
    guidance: [
      '모든 진행 중인 미션을 완료해주세요.',
      '업체 소유권을 다른 사람에게 이전하거나 업체를 삭제해주세요.'
    ],
    action: 'go_to_business_settings'
  },

  // 업로드 관련
  UPLOAD_FAILED: {
    code: 'UPLOAD_FAILED',
    message: '파일 업로드에 실패했습니다.',
    guidance: [
      '파일 크기가 10MB를 초과하지 않는지 확인해주세요.',
      '네트워크 연결 상태를 확인해주세요.',
      '잠시 후 다시 시도해주세요.'
    ],
    action: 'retry'
  },
  INVALID_FILE_FORMAT: {
    code: 'INVALID_FILE_FORMAT',
    message: '지원하지 않는 파일 형식입니다.',
    guidance: [
      'JPG, PNG 형식의 이미지만 업로드 가능합니다.'
    ],
    action: 'select_different_file'
  },

  // 인증 관련
  UNAUTHORIZED: {
    code: 'UNAUTHORIZED',
    message: '로그인이 필요합니다.',
    guidance: [
      '세션이 만료되었습니다. 다시 로그인해주세요.'
    ],
    action: 'go_to_login'
  },
  FORBIDDEN: {
    code: 'FORBIDDEN',
    message: '권한이 없습니다.',
    guidance: [
      '이 작업을 수행할 권한이 없습니다.',
      '계정 유형을 확인해주세요.'
    ],
    action: 'go_back'
  },

  // 네트워크 관련
  NETWORK_ERROR: {
    code: 'NETWORK_ERROR',
    message: '네트워크 오류가 발생했습니다.',
    guidance: [
      '인터넷 연결 상태를 확인해주세요.',
      '잠시 후 다시 시도해주세요.'
    ],
    action: 'retry'
  },
  SERVER_ERROR: {
    code: 'SERVER_ERROR',
    message: '서버 오류가 발생했습니다.',
    guidance: [
      '잠시 후 다시 시도해주세요.',
      '문제가 지속되면 고객센터로 문의해주세요.'
    ],
    action: 'contact_support'
  },

  // 체류 시간 관련
  INSUFFICIENT_STAY_TIME: {
    code: 'INSUFFICIENT_STAY_TIME',
    message: '최소 체류 시간을 채우지 못했습니다.',
    guidance: [
      '미션 완료를 위해 지정된 시간 이상 체류해야 합니다.',
      '체류 시간이 충족되면 다시 시도해주세요.'
    ],
    action: 'wait'
  }
};

/**
 * 에러 응답 생성
 * @param {string} errorCode - 에러 코드
 * @param {Object} [extraData] - 추가 데이터 (예: distance, requiredTime 등)
 * @returns {Object} 에러 응답 객체
 */
function createErrorResponse(errorCode, extraData = {}) {
  const errorInfo = ERROR_CODES[errorCode] || ERROR_CODES.SERVER_ERROR;

  return {
    success: false,
    error: {
      code: errorInfo.code,
      message: errorInfo.message,
      guidance: errorInfo.guidance,
      action: errorInfo.action,
      ...extraData
    }
  };
}

/**
 * GPS 거리 에러 응답 생성
 * @param {number} currentDistance - 현재 거리 (미터)
 * @param {number} allowedDistance - 허용 거리 (미터)
 * @returns {Object} 에러 응답 객체
 */
function createGpsErrorResponse(currentDistance, allowedDistance = 50) {
  return createErrorResponse('GPS_TOO_FAR', {
    currentDistance: Math.round(currentDistance),
    allowedDistance,
    manualVerificationAvailable: true
  });
}

/**
 * 결제 실패 에러 응답 생성
 * @param {string} reason - 실패 사유
 * @param {boolean} refunded - 환불 여부
 * @returns {Object} 에러 응답 객체
 */
function createPaymentErrorResponse(reason, refunded = false) {
  const errorCode = refunded ? 'PAYMENT_CANCELLED' : 'PAYMENT_FAILED';
  return createErrorResponse(errorCode, {
    reason,
    refunded,
    refundStatus: refunded ? 'completed' : 'not_applicable'
  });
}

/**
 * 체류 시간 부족 에러 응답 생성
 * @param {number} currentMinutes - 현재 체류 시간 (분)
 * @param {number} requiredMinutes - 필요 체류 시간 (분)
 * @returns {Object} 에러 응답 객체
 */
function createStayTimeErrorResponse(currentMinutes, requiredMinutes) {
  return createErrorResponse('INSUFFICIENT_STAY_TIME', {
    currentMinutes,
    requiredMinutes,
    remainingMinutes: requiredMinutes - currentMinutes
  });
}

module.exports = {
  ERROR_CODES,
  createErrorResponse,
  createGpsErrorResponse,
  createPaymentErrorResponse,
  createStayTimeErrorResponse
};
