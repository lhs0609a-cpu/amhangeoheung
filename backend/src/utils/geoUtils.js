/**
 * GPS 거리 계산 유틸리티
 * Haversine 공식을 사용한 두 좌표 간 거리 계산
 */

const EARTH_RADIUS = 6371000; // 지구 반지름 (미터)

/**
 * 각도를 라디안으로 변환
 * @param {number} deg - 각도
 * @returns {number} 라디안
 */
function toRad(deg) {
  return deg * Math.PI / 180;
}

/**
 * 두 좌표 간 거리 계산 (Haversine 공식)
 * @param {number} lat1 - 첫 번째 지점의 위도
 * @param {number} lon1 - 첫 번째 지점의 경도
 * @param {number} lat2 - 두 번째 지점의 위도
 * @param {number} lon2 - 두 번째 지점의 경도
 * @returns {number} 두 지점 간 거리 (미터)
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a = Math.sin(dLat / 2) ** 2 +
            Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return EARTH_RADIUS * c;
}

/**
 * 특정 반경 내에 있는지 확인
 * @param {number} lat1 - 첫 번째 지점의 위도
 * @param {number} lon1 - 첫 번째 지점의 경도
 * @param {number} lat2 - 두 번째 지점의 위도
 * @param {number} lon2 - 두 번째 지점의 경도
 * @param {number} radiusMeters - 반경 (미터)
 * @returns {boolean} 반경 내 여부
 */
function isWithinRadius(lat1, lon1, lat2, lon2, radiusMeters) {
  const distance = calculateDistance(lat1, lon1, lat2, lon2);
  return distance <= radiusMeters;
}

module.exports = {
  calculateDistance,
  isWithinRadius,
  EARTH_RADIUS
};
