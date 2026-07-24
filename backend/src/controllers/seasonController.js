const supabase = require('../config/supabase');

// 활성 시즌 목록
exports.getActiveSeasons = async (req, res) => {
  try {
    const now = new Date().toISOString();

    const { data: seasons, error } = await supabase
      .from('seasons')
      .select('*')
      .eq('is_active', true)
      .lte('start_at', now)
      .gte('end_at', now)
      .order('start_at', { ascending: false });

    if (error) throw error;

    res.json({ success: true, data: seasons || [] });
  } catch (error) {
    console.error('getActiveSeasons error:', error);
    res.status(500).json({ success: false, message: '시즌 목록 조회에 실패했습니다.' });
  }
};

// 시즌 상세 + 미션 목록
exports.getSeasonDetail = async (req, res) => {
  try {
    const { id } = req.params;

    const { data: season, error: seasonError } = await supabase
      .from('seasons')
      .select('*')
      .eq('id', id)
      .single();

    if (seasonError || !season) {
      return res.status(404).json({ success: false, message: '시즌을 찾을 수 없습니다.' });
    }

    const { data: missions, error: missionError } = await supabase
      .from('missions')
      .select('*, businesses(name, badge_level, address)')
      .eq('season_id', id)
      .eq('visibility', 'season')
      .in('status', ['recruiting', 'assigned', 'in_progress'])
      .order('created_at', { ascending: false });

    if (missionError) throw missionError;

    res.json({
      success: true,
      data: {
        ...season,
        missions: missions || [],
      },
    });
  } catch (error) {
    console.error('getSeasonDetail error:', error);
    res.status(500).json({ success: false, message: '시즌 상세 조회에 실패했습니다.' });
  }
};
