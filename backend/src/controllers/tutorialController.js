const supabase = require('../config/supabase');
const { PLEDGE_VERSION } = require('../config/constants');

// 튜토리얼 세션 시작
exports.startTutorial = async (req, res) => {
  try {
    const { deviceId } = req.body;
    if (!deviceId) {
      return res.status(400).json({ success: false, message: 'deviceId가 필요합니다.' });
    }

    // 기존 세션 확인
    const { data: existing } = await supabase
      .from('tutorial_sessions')
      .select('*')
      .eq('device_id', deviceId)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    if (existing && !existing.completed) {
      return res.json({ success: true, data: existing });
    }

    // 새 세션 생성 (4단계)
    const { data: session, error } = await supabase
      .from('tutorial_sessions')
      .insert({
        device_id: deviceId,
        steps_completed: 0,
        total_steps: 4,
      })
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({ success: true, data: session });
  } catch (error) {
    console.error('startTutorial error:', error);
    res.status(500).json({ success: false, message: '튜토리얼 세션 생성에 실패했습니다.' });
  }
};

// 튜토리얼 진행 업데이트
exports.updateProgress = async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { step } = req.body;

    const { data: session, error: fetchError } = await supabase
      .from('tutorial_sessions')
      .select('*')
      .eq('id', sessionId)
      .single();

    if (fetchError || !session) {
      return res.status(404).json({ success: false, message: '세션을 찾을 수 없습니다.' });
    }

    if (session.completed) {
      return res.json({ success: true, data: session, message: '이미 완료된 튜토리얼입니다.' });
    }

    const newStep = Math.max(session.steps_completed, step || session.steps_completed + 1);

    const { data: updated, error } = await supabase
      .from('tutorial_sessions')
      .update({ steps_completed: Math.min(newStep, session.total_steps) })
      .eq('id', sessionId)
      .select()
      .single();

    if (error) throw error;

    res.json({ success: true, data: updated });
  } catch (error) {
    console.error('updateProgress error:', error);
    res.status(500).json({ success: false, message: '진행 업데이트에 실패했습니다.' });
  }
};

// 서약 동의
exports.acceptPledge = async (req, res) => {
  try {
    const { sessionId } = req.params;

    const { data: session, error: fetchError } = await supabase
      .from('tutorial_sessions')
      .select('*')
      .eq('id', sessionId)
      .single();

    if (fetchError || !session) {
      return res.status(404).json({ success: false, message: '세션을 찾을 수 없습니다.' });
    }

    if (session.pledge_accepted) {
      return res.json({ success: true, data: session, message: '이미 서약에 동의했습니다.' });
    }

    const { data: updated, error } = await supabase
      .from('tutorial_sessions')
      .update({
        pledge_accepted: true,
        pledge_accepted_at: new Date().toISOString(),
        pledge_version: PLEDGE_VERSION,
      })
      .eq('id', sessionId)
      .select()
      .single();

    if (error) throw error;

    res.json({ success: true, data: updated, message: '서약에 동의했습니다.' });
  } catch (error) {
    console.error('acceptPledge error:', error);
    res.status(500).json({ success: false, message: '서약 동의 처리에 실패했습니다.' });
  }
};

// 튜토리얼 완료
exports.completeTutorial = async (req, res) => {
  try {
    const { sessionId } = req.params;

    const { data: session, error: fetchError } = await supabase
      .from('tutorial_sessions')
      .select('*')
      .eq('id', sessionId)
      .single();

    if (fetchError || !session) {
      return res.status(404).json({ success: false, message: '세션을 찾을 수 없습니다.' });
    }

    if (!session.pledge_accepted) {
      return res.status(400).json({ success: false, message: '서약에 먼저 동의해야 합니다.' });
    }

    const { data: updated, error } = await supabase
      .from('tutorial_sessions')
      .update({
        completed: true,
        completed_at: new Date().toISOString(),
        steps_completed: 4,
      })
      .eq('id', sessionId)
      .select()
      .single();

    if (error) throw error;

    res.json({
      success: true,
      data: updated,
      message: '튜토리얼이 완료되었습니다. 회원가입 후 교육을 시작하세요.',
      nextStep: 'register',
    });
  } catch (error) {
    console.error('completeTutorial error:', error);
    res.status(500).json({ success: false, message: '튜토리얼 완료 처리에 실패했습니다.' });
  }
};
