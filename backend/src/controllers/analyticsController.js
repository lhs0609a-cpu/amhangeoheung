const supabase = require('../config/supabase');

// 단일 이벤트 추적
exports.trackEvent = async (req, res) => {
  try {
    const { eventName, eventCategory, eventData, sessionId, deviceId, platform, appVersion } = req.body;

    if (!eventName || !eventCategory) {
      return res.status(400).json({ success: false, message: 'eventName, eventCategory가 필요합니다.' });
    }

    const { error } = await supabase
      .from('analytics_events')
      .insert({
        user_id: req.user?.id || null,
        event_name: eventName,
        event_category: eventCategory,
        event_data: eventData || {},
        session_id: sessionId,
        device_id: deviceId,
        platform,
        app_version: appVersion,
      });

    if (error) throw error;

    res.status(201).json({ success: true });
  } catch (error) {
    console.error('trackEvent error:', error);
    res.status(500).json({ success: false, message: '이벤트 저장에 실패했습니다.' });
  }
};

// 배치 이벤트 추적
exports.trackBatch = async (req, res) => {
  try {
    const { events } = req.body;

    if (!Array.isArray(events) || events.length === 0) {
      return res.status(400).json({ success: false, message: 'events 배열이 필요합니다.' });
    }

    if (events.length > 100) {
      return res.status(400).json({ success: false, message: '한 번에 최대 100개까지 전송 가능합니다.' });
    }

    const records = events.map(e => ({
      user_id: req.user?.id || null,
      event_name: e.eventName,
      event_category: e.eventCategory,
      event_data: e.eventData || {},
      session_id: e.sessionId,
      device_id: e.deviceId,
      platform: e.platform,
      app_version: e.appVersion,
    }));

    const { error } = await supabase
      .from('analytics_events')
      .insert(records);

    if (error) throw error;

    res.status(201).json({ success: true, count: records.length });
  } catch (error) {
    console.error('trackBatch error:', error);
    res.status(500).json({ success: false, message: '배치 이벤트 저장에 실패했습니다.' });
  }
};
