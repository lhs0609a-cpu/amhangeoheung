/**
 * FCM 푸시 알림 서비스
 * Firebase Cloud Messaging을 통한 알림 발송
 */

const supabase = require('../config/supabase');
const { getMessaging, isFirebaseInitialized } = require('../config/firebase');

/**
 * 단일 사용자에게 푸시 알림 발송
 * @param {string} userId - 수신 사용자 ID
 * @param {string} title - 알림 제목
 * @param {string} body - 알림 본문
 * @param {Object} data - 추가 데이터 (화면 이동 등)
 */
async function sendPushNotification(userId, title, body, data = {}) {
  if (!isFirebaseInitialized()) return;

  try {
    // 사용자의 푸시 알림 설정 확인
    const { data: user } = await supabase
      .from('users')
      .select('notify_push')
      .eq('id', userId)
      .single();

    if (!user?.notify_push) return;

    // 활성 토큰 조회
    const { data: tokens } = await supabase
      .from('device_tokens')
      .select('token')
      .eq('user_id', userId)
      .eq('is_active', true);

    if (!tokens || tokens.length === 0) return;

    const messaging = getMessaging();
    if (!messaging) return;

    const tokenList = tokens.map(t => t.token);

    const message = {
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      tokens: tokenList,
    };

    const response = await messaging.sendEachForMulticast(message);

    // 실패한 토큰 비활성화
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errorCode = resp.error?.code;
          // 토큰이 만료/등록 해제된 경우 비활성화
          if (
            errorCode === 'messaging/invalid-registration-token' ||
            errorCode === 'messaging/registration-token-not-registered'
          ) {
            failedTokens.push(tokenList[idx]);
          }
        }
      });

      if (failedTokens.length > 0) {
        await supabase
          .from('device_tokens')
          .update({ is_active: false })
          .in('token', failedTokens);
        console.log(`[FCM] Deactivated ${failedTokens.length} invalid tokens for user ${userId}`);
      }
    }

    console.log(`[FCM] Sent to user ${userId}: success=${response.successCount}, fail=${response.failureCount}`);
  } catch (err) {
    console.error(`[FCM] Error sending to user ${userId}:`, err.message);
  }
}

/**
 * 여러 사용자에게 푸시 알림 발송
 * @param {string[]} userIds - 수신 사용자 ID 배열
 * @param {string} title - 알림 제목
 * @param {string} body - 알림 본문
 * @param {Object} data - 추가 데이터
 */
async function sendMulticastNotification(userIds, title, body, data = {}) {
  if (!isFirebaseInitialized()) return;

  for (const userId of userIds) {
    await sendPushNotification(userId, title, body, data);
  }
}

module.exports = { sendPushNotification, sendMulticastNotification };
