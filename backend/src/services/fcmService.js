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
    const stringData = Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v)])
    );

    const message = {
      notification: { title, body },
      data: stringData,
      tokens: tokenList,
    };

    const response = await messaging.sendEachForMulticast(message);

    // 실패한 토큰 비활성화
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errorCode = resp.error?.code;
          if (
            errorCode === 'messaging/invalid-registration-token' ||
            errorCode === 'messaging/registration-token-not-registered'
          ) {
            failedTokens.push(tokenList[idx]);
          }
        }
      });

      if (failedTokens.length > 0) {
        try {
          await supabase
            .from('device_tokens')
            .update({ is_active: false })
            .in('token', failedTokens);
          console.log(`[FCM] Deactivated ${failedTokens.length} invalid tokens for user ${userId}`);
        } catch (deactivateErr) {
          console.error(`[FCM] Failed to deactivate tokens:`, deactivateErr.message);
        }
      }
    }

    console.log(`[FCM] Sent to user ${userId}: success=${response.successCount}, fail=${response.failureCount}`);
  } catch (err) {
    console.error(`[FCM] Error sending to user ${userId}:`, err.message);
  }
}

/**
 * 여러 사용자에게 푸시 알림 발송 (일괄 배치)
 * 모든 사용자의 토큰을 한번에 조회하여 한번의 FCM 호출로 발송
 * @param {string[]} userIds - 수신 사용자 ID 배열
 * @param {string} title - 알림 제목
 * @param {string} body - 알림 본문
 * @param {Object} data - 추가 데이터
 */
async function sendMulticastNotification(userIds, title, body, data = {}) {
  if (!isFirebaseInitialized()) return;
  if (!userIds || userIds.length === 0) return;

  try {
    // 푸시 알림이 활성화된 사용자만 필터
    const { data: pushEnabledUsers } = await supabase
      .from('users')
      .select('id')
      .in('id', userIds)
      .eq('notify_push', true);

    if (!pushEnabledUsers || pushEnabledUsers.length === 0) return;

    const enabledUserIds = pushEnabledUsers.map(u => u.id);

    // 모든 활성 토큰을 한번에 조회
    const { data: tokenRecords } = await supabase
      .from('device_tokens')
      .select('token')
      .in('user_id', enabledUserIds)
      .eq('is_active', true);

    if (!tokenRecords || tokenRecords.length === 0) return;

    const messaging = getMessaging();
    if (!messaging) return;

    const tokenList = tokenRecords.map(t => t.token);
    const stringData = Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v)])
    );

    // FCM은 한번에 최대 500개 토큰 지원 → 배치 분할
    const BATCH_SIZE = 500;
    let totalSuccess = 0;
    let totalFail = 0;

    for (let i = 0; i < tokenList.length; i += BATCH_SIZE) {
      const batch = tokenList.slice(i, i + BATCH_SIZE);

      const message = {
        notification: { title, body },
        data: stringData,
        tokens: batch,
      };

      const response = await messaging.sendEachForMulticast(message);
      totalSuccess += response.successCount;
      totalFail += response.failureCount;

      // 실패한 토큰 비활성화
      if (response.failureCount > 0) {
        const failedTokens = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const errorCode = resp.error?.code;
            if (
              errorCode === 'messaging/invalid-registration-token' ||
              errorCode === 'messaging/registration-token-not-registered'
            ) {
              failedTokens.push(batch[idx]);
            }
          }
        });

        if (failedTokens.length > 0) {
          try {
            await supabase
              .from('device_tokens')
              .update({ is_active: false })
              .in('token', failedTokens);
            console.log(`[FCM] Deactivated ${failedTokens.length} invalid tokens (multicast batch)`);
          } catch (deactivateErr) {
            console.error(`[FCM] Failed to deactivate tokens:`, deactivateErr.message);
          }
        }
      }
    }

    console.log(`[FCM] Multicast to ${userIds.length} users: success=${totalSuccess}, fail=${totalFail}`);
  } catch (err) {
    console.error(`[FCM] Multicast error:`, err.message);
  }
}

module.exports = { sendPushNotification, sendMulticastNotification };
