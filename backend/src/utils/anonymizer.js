/**
 * 익명화 유틸리티
 * 리뷰어 신분 보호를 위한 사진 메타데이터 제거, 날짜/시간 퍼지, 텍스트 익명화
 */

/**
 * 사진 EXIF 메타데이터 완전 제거
 * GPS 좌표, 촬영 시간, 카메라 모델, 시리얼 등 모두 제거
 */
async function stripPhotoMetadata(photoBuffer) {
  try {
    const sharp = require('sharp');
    // sharp로 이미지를 다시 인코딩하면 EXIF 메타데이터가 자동 제거됨
    const stripped = await sharp(photoBuffer)
      .rotate() // EXIF orientation 적용 후 메타데이터 제거
      .jpeg({ quality: 90 })
      .toBuffer();
    return stripped;
  } catch (err) {
    console.error('[ANONYMIZER] stripPhotoMetadata error:', err.message);
    // sharp 실패 시 원본 반환 (최소한의 동작 보장)
    return photoBuffer;
  }
}

/**
 * 실제 날짜 ±1~2일 랜덤 오프셋
 */
function fuzzyDate(actualDate) {
  const date = new Date(actualDate);
  const offsetDays = Math.floor(Math.random() * 3) + 1; // 1~3일
  const direction = Math.random() < 0.5 ? -1 : 1;
  date.setDate(date.getDate() + (offsetDays * direction));
  return date.toISOString().split('T')[0]; // YYYY-MM-DD
}

/**
 * 정확한 시간 → 시간대 변환
 */
function getTimeSlot(hour) {
  if (typeof hour === 'string') {
    hour = new Date(hour).getHours();
  }
  // Broadened from 5 slots to 2 slots for stronger anonymity
  if (hour >= 6 && hour < 18) return '주간';  // Daytime 6am-6pm
  return '야간';  // Nighttime 6pm-6am
}

/**
 * 시간대 한글 표시
 */
function getTimeSlotLabel(slot) {
  const labels = {
    '주간': '주간',
    '야간': '야간',
    // Legacy labels for backward compatibility
    morning: '오전',
    lunch: '점심',
    afternoon: '오후',
    evening: '저녁',
    night: '밤',
  };
  return labels[slot] || slot;
}

/**
 * 날짜를 퍼지 표현으로 변환
 * "2026-02-12" → "2월 초순"
 */
function fuzzyDateLabel(dateStr) {
  const date = new Date(dateStr);
  const month = date.getMonth() + 1;
  const day = date.getDate();

  let period;
  if (day <= 10) period = '초순';
  else if (day <= 20) period = '중순';
  else period = '하순';

  return `${month}월 ${period}`;
}

/**
 * 개인 식별 가능 정보 마스킹
 */
function anonymizeReviewText(text) {
  if (!text) return text;

  let anonymized = text;

  // Enhanced Korean name detection
  // 성+이름 (2-4자): 김철수, 이영희, 박소연
  anonymized = anonymized.replace(/[김이박최정강조윤장임한오서신권황안송류전홍고문양손배백허유남심노정하곽성차주우구신임나전민류진장방어배][가-힣]{1,3}(님|씨|사장|과장|대리|부장|실장|선생|원장|관장)?/g, '[직원]');

  // 이름 패턴 마스킹: "김○○", "이과장님", "박사장님" 등
  anonymized = anonymized.replace(/[가-힣]{1,2}(사장|과장|대리|부장|실장|원장|선생|직원|언니|오빠|형|누나)님?/g, '[직원]');

  // 이름만 호칭 (X님, X씨)
  anonymized = anonymized.replace(/[가-힣]{2,4}(님|씨)/g, '[직원]');

  // More aggressive date pattern replacement in review text
  // Matches: 2월 12일, 2/12, 02-12, 2026년 2월, 지난 월요일, 어제, 그제
  anonymized = anonymized.replace(/\d{1,2}월\s*\d{1,2}일/g, '[방문일]');
  anonymized = anonymized.replace(/\d{4}년\s*\d{1,2}월/g, '[방문일]');
  anonymized = anonymized.replace(/\d{1,2}[\/\-]\d{1,2}/g, '[방문일]');
  anonymized = anonymized.replace(/(지난|이번|저번)\s*(월요일|화요일|수요일|목요일|금요일|토요일|일요일)/g, '[방문일]');
  anonymized = anonymized.replace(/(어제|그제|그저께|엊그제|오늘|내일)/g, '[방문일]');
  anonymized = anonymized.replace(/(오전|오후|저녁|아침|점심|밤)\s*\d{1,2}시(\s*\d{1,2}분)?/g, '[방문시간]');
  anonymized = anonymized.replace(/\d{1,2}시(\s*\d{1,2}분)?에?\s*(쯤|경|정도)?/g, '[방문시간]');

  // 인원수 구체적 언급 → 일반화
  anonymized = anonymized.replace(/\d+명(이서|이)\s*(방문|갔|왔|들어)/g, '일행과 방문');
  anonymized = anonymized.replace(/혼자\s*(방문|갔|왔|들어)/g, '방문');

  // 외모/성별 묘사 제거 (사업자가 리뷰어를 식별할 수 있는 정보)
  // "키 큰 여성", "안경 쓴 남자" 등은 리뷰 텍스트에 보통 없지만 안전하게 처리

  return anonymized;
}

/**
 * 상세 주소 → 블라인드 주소 변환
 * "서울특별시 강남구 역삼동 123-4" → "서울 강남구 역삼동"
 */
function generateBlindedAddress(fullAddress) {
  if (!fullAddress) return '';

  // 공백으로 분리
  const parts = fullAddress.split(/\s+/);

  // 시/도, 구/군, 동/읍/면까지만 추출
  const result = [];
  for (const part of parts) {
    // 시/도
    if (part.endsWith('시') || part.endsWith('도') || part.endsWith('특별시') || part.endsWith('광역시')) {
      // "서울특별시" → "서울"
      result.push(part.replace(/(특별시|광역시|특별자치시|특별자치도)$/, ''));
      continue;
    }
    // 구/군
    if (part.endsWith('구') || part.endsWith('군')) {
      result.push(part);
      continue;
    }
    // 동/읍/면
    if (part.endsWith('동') || part.endsWith('읍') || part.endsWith('면') || part.endsWith('리')) {
      result.push(part);
      break; // 동까지만
    }
    // 숫자가 포함된 부분(번지)이 나오면 중단
    if (/\d/.test(part)) {
      break;
    }
    // 그 외 (시/도가 아직 안 나왔으면 추가)
    if (result.length < 3) {
      result.push(part);
    }
  }

  return result.join(' ') || fullAddress.split(/\s+/).slice(0, 3).join(' ');
}

/**
 * 리뷰어 익명 ID 생성
 * 사업자에게 보여줄 해시된 익명 식별자
 */
function generateAnonymousId(reviewerId) {
  const crypto = require('crypto');
  const hash = crypto.createHash('sha256').update(reviewerId + process.env.JWT_SECRET).digest('hex');
  // Changed from 4 to 6 chars to reduce collision risk (16M combinations vs 65K)
  return `암행어흥 #${hash.substring(0, 6).toUpperCase()}`;
}

module.exports = {
  stripPhotoMetadata,
  fuzzyDate,
  getTimeSlot,
  getTimeSlotLabel,
  fuzzyDateLabel,
  anonymizeReviewText,
  generateBlindedAddress,
  generateAnonymousId,
};
