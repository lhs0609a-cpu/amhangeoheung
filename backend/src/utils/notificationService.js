const supabase = require('../config/supabase');

/**
 * 알림 생성
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
    return { success: true };
  } catch (error) {
    console.error('[NOTIFICATION] Error:', error);
    return { success: false, error: error.message };
  }
}
/**
 * 다수에게 알림 발송
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
    return { success: true };
  } catch (error) {
    console.error('[NOTIFICATION] Bulk error:', error);
    return { success: false, error: error.message };
  }
}

module.exports = { createNotification, createBulkNotifications };
