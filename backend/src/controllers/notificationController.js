const supabase = require('../config/supabase');

// 알림 목록 조회
exports.getNotifications = async (req, res, next) => {
  try {
    const { page = 1, limit = 20 } = req.query;
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
          page: parseInt(page),
          limit: parseInt(limit),
          total: count || 0,
          totalPages: Math.ceil((count || 0) / limit)
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

// 읽지 않은 알림 수 조회
exports.getUnreadCount = async (req, res, next) => {
  try {
    const { count, error } = await supabase
      .from('notifications')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', req.user.id)
      .eq('is_read', false);

    if (error) throw error;

    res.json({
      success: true,
      data: { unreadCount: count || 0 }
    });
  } catch (error) {
    next(error);
  }
};

// 알림 읽음 처리
exports.markAsRead = async (req, res, next) => {
  try {
    const { id } = req.params;

    const { error } = await supabase
      .from('notifications')
      .update({ is_read: true, read_at: new Date().toISOString() })
      .eq('id', id)
      .eq('user_id', req.user.id);

    if (error) throw error;

    res.json({
      success: true,
      message: '알림을 읽음 처리했습니다.'
    });
  } catch (error) {
    next(error);
  }
};

// 전체 읽음 처리
exports.markAllAsRead = async (req, res, next) => {
  try {
    const { error } = await supabase
      .from('notifications')
      .update({ is_read: true, read_at: new Date().toISOString() })
      .eq('user_id', req.user.id)
      .eq('is_read', false);

    if (error) throw error;

    res.json({
      success: true,
      message: '모든 알림을 읽음 처리했습니다.'
    });
  } catch (error) {
    next(error);
  }
};

// 알림 삭제
exports.deleteNotification = async (req, res, next) => {
  try {
    const { id } = req.params;

    const { error } = await supabase
      .from('notifications')
      .delete()
      .eq('id', id)
      .eq('user_id', req.user.id);

    if (error) throw error;

    res.json({
      success: true,
      message: '알림이 삭제되었습니다.'
    });
  } catch (error) {
    next(error);
  }
};

// 알림 생성 유틸리티 (내부 사용)
exports.createNotification = async ({ userId, type, title, body, data = {} }) => {
  try {
    const { error } = await supabase
      .from('notifications')
      .insert({
        user_id: userId,
        type,
        title,
        body,
        data,
        is_read: false
      });

    if (error) {
      console.error('Failed to create notification:', error);
    }
  } catch (err) {
    console.error('Notification creation error:', err);
  }
};
