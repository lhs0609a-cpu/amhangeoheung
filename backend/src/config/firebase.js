/**
 * Firebase Admin SDK 설정
 * FCM 푸시 알림 발송을 위한 초기화
 */

const path = require('path');
let admin = null;
let initialized = false;

/**
 * Firebase Admin SDK 초기화
 * 서비스 계정 JSON 파일이 없으면 경고만 출력하고 앱은 정상 실행
 */
function initializeFirebase() {
  try {
    admin = require('firebase-admin');

    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH
      || path.join(__dirname, '../../firebase-service-account.json');

    let serviceAccount;
    try {
      serviceAccount = require(serviceAccountPath);
    } catch (e) {
      console.warn('[FIREBASE] Service account file not found:', serviceAccountPath);
      console.warn('[FIREBASE] FCM push notifications will be disabled.');
      console.warn('[FIREBASE] To enable, place firebase-service-account.json in backend/ directory.');
      return;
    }

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });

    initialized = true;
    console.log('[FIREBASE] Admin SDK initialized successfully');
  } catch (err) {
    console.warn('[FIREBASE] Initialization failed:', err.message);
    console.warn('[FIREBASE] FCM push notifications will be disabled.');
  }
}

/**
 * Firebase Messaging 인스턴스 반환
 * @returns {import('firebase-admin').messaging.Messaging|null}
 */
function getMessaging() {
  if (!initialized || !admin) return null;
  return admin.messaging();
}

/**
 * Firebase 초기화 여부
 */
function isFirebaseInitialized() {
  return initialized;
}

module.exports = { initializeFirebase, getMessaging, isFirebaseInitialized };
