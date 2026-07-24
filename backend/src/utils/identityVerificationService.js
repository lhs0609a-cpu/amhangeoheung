/**
 * 본인인증 서버측 검증 서비스 (PASS / NICE / PortOne 등)
 *
 * 안전 원칙 (payoutService 와 동일한 fail-closed 정책):
 * - 클라이언트가 보낸 CI/DI/이름 등은 절대 신뢰하지 않는다.
 *   클라이언트는 인증기관이 발급한 "영수증 식별자(receiptId)"만 전달하고,
 *   서버가 그 식별자로 인증기관 API를 호출해 CI/DI 를 직접 조회한다.
 * - 인증기관 자격증명이 설정되지 않았거나 조회에 실패하면 절대 성공(verified=true)을
 *   반환하지 않는다. 대신 notConfigured / verified=false 로 인증을 거부한다.
 * - Math.random 같은 가짜 성공 시뮬레이션은 사용하지 않는다.
 *
 * 환경변수:
 * - IDENTITY_PROVIDER        : 'portone' | 'nice' (미설정 시 비활성 → 인증 거부)
 * - PORTONE_API_KEY          : PortOne(아임포트) REST API Key
 * - PORTONE_API_SECRET       : PortOne REST API Secret
 * - NICE_VERIFY_URL          : NICE 본인인증 결과조회 엔드포인트 (self-host 어댑터)
 * - NICE_VERIFY_TOKEN        : 위 엔드포인트 인증 토큰
 */

const axios = require('axios');

const IDENTITY_PROVIDER = (process.env.IDENTITY_PROVIDER || '').toLowerCase();

const PORTONE_API_KEY = process.env.PORTONE_API_KEY || '';
const PORTONE_API_SECRET = process.env.PORTONE_API_SECRET || '';

const NICE_VERIFY_URL = process.env.NICE_VERIFY_URL || '';
const NICE_VERIFY_TOKEN = process.env.NICE_VERIFY_TOKEN || '';

/**
 * 본인인증 연동이 설정되어 있는지 여부
 */
function isIdentityVerificationConfigured() {
  if (IDENTITY_PROVIDER === 'portone') {
    return Boolean(PORTONE_API_KEY && PORTONE_API_SECRET);
  }
  if (IDENTITY_PROVIDER === 'nice') {
    return Boolean(NICE_VERIFY_URL && NICE_VERIFY_TOKEN);
  }
  return false;
}

function notConfiguredResult() {
  return {
    success: false,
    verified: false,
    notConfigured: true,
    errorMessage:
      '본인인증 연동이 아직 설정되지 않았습니다. 관리자에게 문의하세요.',
  };
}

function failure(errorMessage) {
  return { success: false, verified: false, errorMessage };
}

/**
 * 인증기관에서 조회한 신원 정보를 표준 형태로 정규화한다.
 * @returns {{success:boolean, verified:boolean, ci?:string, di?:string,
 *   name?:string, phone?:string, birthdate?:string, gender?:string,
 *   provider?:string, errorMessage?:string, notConfigured?:boolean}}
 */
function normalize(raw, provider) {
  const ci = raw.ci || raw.unique_key || raw.CI;
  const di = raw.di || raw.unique_in_site || raw.DI || null;
  if (!ci) {
    return failure('인증기관 응답에 CI 값이 없습니다.');
  }
  // 전화번호는 숫자만 남긴다 (010-1234-5678 → 01012345678)
  const phone = raw.phone ? String(raw.phone).replace(/[^0-9]/g, '') : null;
  return {
    success: true,
    verified: true,
    ci,
    di,
    name: raw.name || null,
    phone,
    birthdate: raw.birthday || raw.birth || raw.birthdate || null,
    gender: raw.gender != null ? String(raw.gender) : null,
    provider,
  };
}

/**
 * PortOne(아임포트) 본인인증 조회.
 * 1) REST API Key/Secret 으로 access token 발급
 * 2) GET /certifications/{imp_uid} 로 인증 결과(CI/DI 포함) 조회
 */
async function verifyWithPortOne(receiptId) {
  const base = 'https://api.iamport.kr';
  let token;
  try {
    const { data: tokenRes } = await axios.post(
      `${base}/users/getToken`,
      { imp_key: PORTONE_API_KEY, imp_secret: PORTONE_API_SECRET },
      { timeout: 10000 }
    );
    token = tokenRes?.response?.access_token;
    if (!token) {
      return failure('본인인증 토큰 발급에 실패했습니다.');
    }
  } catch (error) {
    console.error('[IDENTITY] portone token error:', error.message);
    return { ...failure('인증기관 연결에 실패했습니다.'), pending: true };
  }

  try {
    const { data } = await axios.get(
      `${base}/certifications/${encodeURIComponent(receiptId)}`,
      { headers: { Authorization: token }, timeout: 10000 }
    );
    const cert = data?.response;
    if (!cert) {
      return failure('본인인증 결과를 찾을 수 없습니다.');
    }
    if (cert.certified !== true) {
      return failure('완료되지 않은 본인인증입니다.');
    }
    return normalize(cert, 'portone');
  } catch (error) {
    const status = error.response?.status;
    const message = error.response?.data?.message || error.message;
    console.error('[IDENTITY] portone lookup error:', status, message);
    if (status === 404) {
      return failure('유효하지 않은 본인인증 식별자입니다.');
    }
    // 타임아웃/5xx → 보류 (사용자 책임으로 실패 누적하지 않음)
    return { ...failure(message), pending: true };
  }
}

/**
 * NICE 본인인증 조회 (자체 호스팅 결과조회 어댑터 경유).
 * 어댑터는 receiptId 를 받아 인증기관 결과를 조회하고 CI/DI 를 반환한다.
 */
async function verifyWithNice(receiptId) {
  try {
    const { data } = await axios.post(
      NICE_VERIFY_URL,
      { receiptId },
      {
        headers: { Authorization: `Bearer ${NICE_VERIFY_TOKEN}` },
        timeout: 10000,
      }
    );
    if (!data || data.success !== true || !data.result) {
      return failure(data?.message || '본인인증 결과 조회에 실패했습니다.');
    }
    return normalize(data.result, 'nice');
  } catch (error) {
    const status = error.response?.status;
    const message = error.response?.data?.message || error.message;
    console.error('[IDENTITY] nice lookup error:', status, message);
    if (status === 400 || status === 404) {
      return failure('유효하지 않은 본인인증 식별자입니다.');
    }
    return { ...failure(message), pending: true };
  }
}

/**
 * 본인인증 결과를 서버에서 직접 조회한다.
 * @param {{ receiptId:string }} params 인증기관이 발급한 영수증/인증 식별자
 * @returns 표준 신원 정보 (normalize 참조)
 */
async function verifyIdentity({ receiptId }) {
  if (!isIdentityVerificationConfigured()) {
    return notConfiguredResult();
  }
  if (!receiptId || typeof receiptId !== 'string') {
    return failure('본인인증 식별자가 필요합니다.');
  }

  if (IDENTITY_PROVIDER === 'portone') {
    return verifyWithPortOne(receiptId);
  }
  if (IDENTITY_PROVIDER === 'nice') {
    return verifyWithNice(receiptId);
  }
  return notConfiguredResult();
}

module.exports = {
  isIdentityVerificationConfigured,
  verifyIdentity,
};
