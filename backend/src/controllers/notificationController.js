const supabase = require('../config/supabase');

const MAX_LIMIT = 100;

/**
 * GET /api/notifications — 내 알림 목록
 */
exports.getNotifications = async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(Math.max(1, parseInt(req.query.limit) || 20), MAX_LIMIT);
    const offset = (page - 1) * limit;

    const { data: notifications, error, count } = await supabase
      .from('notifications')
      .select('*', { count: 'exact' })
      .eq('user_id', req.user.id)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    res.json({
      success: true,
      data: {
        notifications: notifications || [],
        pagination: {
          page,
          limit,
          total: count || 0,
          pages: Math.ceil((count || 0) / limit),
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/notifications/:id/read — 읽음 처리
 */
exports.markAsRead = async (req, res, next) => {
  try {
    const { error } = await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('id', req.params.id)
      .eq('user_id', req.user.id);

    if (error) throw error;

    res.json({ success: true, message: '읽음 처리되었습니다.' });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/notifications/read-all — 전체 읽음 처리
 */
exports.markAllAsRead = async (req, res, next) => {
  try {
    const { error } = await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('user_id', req.user.id)
      .eq('is_read', false);

    if (error) throw error;

    res.json({ success: true, message: '모든 알림을 읽음 처리했습니다.' });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/notifications/unread-count — 읽지 않은 알림 수
 */
exports.getUnreadCount = async (req, res, next) => {
  try {
    const { count, error } = await supabase
      .from('notifications')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', req.user.id)
      .eq('is_read', false);

    if (error) throw error;

    res.json({
      success: true,
      data: { unreadCount: count || 0 },
    });
  } catch (error) {
    next(error);
  }
};
