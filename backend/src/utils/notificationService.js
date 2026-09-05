const supabase = require('../config/supabase');
const { sendPushNotification, sendMulticastNotification } = require('../services/fcmService');
const { loadPreferences, decide } = require('./notificationPreferences');

/**
 * 알림 생성 + FCM 푸시 발송
 * DB 알림 저장 후 FCM 발송까지 await하여 결과 확인
 * FCM 실패해도 DB 알림은 이미 저장된 상태이므로 success: true 반환
 *
 * 사용자의 수신 설정을 여기서 한 번만 본다. 모든 알림이 이 함수를 지나가므로
 * 발송하는 쪽마다 설정을 확인할 필요가 없다 — 확인을 빠뜨린 경로가 생기면
 * 그 순간 설정이 거짓말이 된다.
 */
async function createNotification(userId, type, title, message, data = {}) {
  try {
    const prefs = await loadPreferences([userId]);
    const { store, push } = decide(type, prefs.get(userId));

    if (!store) {
      console.log(`[NOTIFICATION] Skipped by user setting: type=${type}, userId=${userId}`);
      return { success: true, skipped: true };
    }

    const { error } = await supabase
      .from('notifications')
      .insert({
        user_id: userId,
        type,
        title,
        message,
        data,
      });

    if (error) {
      console.error('[NOTIFICATION] Failed to create notification:', error);
      return { success: false, error: error.message };
    }
    console.log(`[NOTIFICATION] Created: type=${type}, userId=${userId}`);

    // FCM 푸시 발송 (await하여 결과 확인, 실패해도 DB 알림은 이미 저장됨)
    if (push) {
      try {
        await sendPushNotification(userId, title, message, { type, ...data });
      } catch (pushErr) {
        console.error(`[NOTIFICATION] FCM push failed for userId=${userId}:`, pushErr.message);
      }
    }

    return { success: true };
  } catch (error) {
    console.error('[NOTIFICATION] Error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * 다수에게 알림 발송 + FCM 푸시
 *
 * 설정은 한 번의 조회로 모아 읽는다. 사람 수만큼 조회하면 시즌 미션
 * 공지처럼 수천 명에게 보내는 경로에서 그대로 터진다.
 */
async function createBulkNotifications(userIds, type, title, message, data = {}) {
  try {
    const prefs = await loadPreferences(userIds);

    const recipients = [];
    const pushTargets = [];
    for (const userId of userIds) {
      const { store, push } = decide(type, prefs.get(userId));
      if (store) recipients.push(userId);
      if (store && push) pushTargets.push(userId);
    }

    if (recipients.length === 0) {
      console.log(`[NOTIFICATION] Bulk skipped by user settings: type=${type}`);
      return { success: true, skipped: true };
    }

    const notifications = recipients.map(userId => ({
      user_id: userId,
      type,
      title,
      message,
      data,
    }));

    const { error } = await supabase
      .from('notifications')
      .insert(notifications);

    if (error) {
      console.error('[NOTIFICATION] Failed to create bulk notifications:', error);
      return { success: false, error: error.message };
    }

    console.log(
      `[NOTIFICATION] Bulk created: type=${type}, stored=${recipients.length}, pushed=${pushTargets.length}`
    );

    // FCM 푸시 발송 (await)
    if (pushTargets.length > 0) {
      try {
        await sendMulticastNotification(pushTargets, title, message, { type, ...data });
      } catch (pushErr) {
        console.error('[NOTIFICATION] Bulk FCM push failed:', pushErr.message);
      }
    }

    return { success: true };
  } catch (error) {
    console.error('[NOTIFICATION] Bulk error:', error);
    return { success: false, error: error.message };
  }
}

module.exports = { createNotification, createBulkNotifications };
