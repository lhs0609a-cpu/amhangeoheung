const supabase = require('../config/supabase');
const { sendPushNotification, sendMulticastNotification } = require('../services/fcmService');

/**
 * 알림 생성 + FCM 푸시 발송
 */
async function createNotification(userId, type, title, message, data = {}) {
  try {
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

    // FCM 푸시 발송 (비동기 — DB 알림 저장과 독립적으로 실행)
    setImmediate(() => {
      sendPushNotification(userId, title, message, { type, ...data }).catch(err => {
        console.error('[NOTIFICATION] FCM push failed:', err.message);
      });
    });

    return { success: true };
  } catch (error) {
    console.error('[NOTIFICATION] Error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * 다수에게 알림 발송 + FCM 푸시
 */
async function createBulkNotifications(userIds, type, title, message, data = {}) {
  try {
    const notifications = userIds.map(userId => ({
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

    console.log(`[NOTIFICATION] Bulk created: type=${type}, count=${userIds.length}`);

    // FCM 푸시 발송 (비동기)
    setImmediate(() => {
      sendMulticastNotification(userIds, title, message, { type, ...data }).catch(err => {
        console.error('[NOTIFICATION] Bulk FCM push failed:', err.message);
      });
    });

    return { success: true };
  } catch (error) {
    console.error('[NOTIFICATION] Bulk error:', error);
    return { success: false, error: error.message };
  }
}

module.exports = { createNotification, createBulkNotifications };
