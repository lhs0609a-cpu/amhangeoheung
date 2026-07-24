const { test } = require('node:test');
const assert = require('node:assert');
const { calculateDistance, isWithinRadius, EARTH_RADIUS } = require('../src/utils/geoUtils');

test('calculateDistance: 같은 좌표는 0m', () => {
  assert.strictEqual(calculateDistance(37.5, 127.0, 37.5, 127.0), 0);
});

test('calculateDistance: 위도 1도 차이는 약 111km (±1km)', () => {
  const d = calculateDistance(37.0, 127.0, 38.0, 127.0);
  assert.ok(Math.abs(d - 111000) < 1000, `expected ~111000, got ${d}`);
});

test('calculateDistance: 서울시청→강남역 대략 8~9km 범위', () => {
  // 서울시청(37.5663, 126.9779) → 강남역(37.4979, 127.0276)
  const d = calculateDistance(37.5663, 126.9779, 37.4979, 127.0276);
  assert.ok(d > 7000 && d < 10000, `expected 7~10km, got ${d}`);
});

test('isWithinRadius: 100m GPS GREEN 존 판정', () => {
  // 약 50m 떨어진 지점 (위도 0.00045도 ≈ 50m)
  const near = calculateDistance(37.5, 127.0, 37.50045, 127.0);
  assert.ok(near < 100);
  assert.strictEqual(isWithinRadius(37.5, 127.0, 37.50045, 127.0, 100), true);
});

test('isWithinRadius: 반경 밖은 false', () => {
  assert.strictEqual(isWithinRadius(37.0, 127.0, 38.0, 127.0, 100), false);
});

test('EARTH_RADIUS 상수는 6371000m', () => {
  assert.strictEqual(EARTH_RADIUS, 6371000);
});
