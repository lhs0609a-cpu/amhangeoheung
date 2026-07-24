const supabase = require('../config/supabase');

// 지역별 업체 랭킹
exports.getRegionalRanking = async (req, res) => {
  try {
    const { region, category, period, limit: queryLimit } = req.query;
    const resultLimit = Math.min(parseInt(queryLimit) || 20, 100);

    let query = supabase
      .from('regional_rankings_cache')
      .select('*')
      .eq('period', period || 'monthly')
      .order('rank', { ascending: true })
      .limit(resultLimit);

    if (region) query = query.eq('region', region);
    if (category) query = query.eq('category', category);

    const { data: rankings, error } = await query;

    if (error) throw error;

    res.json({ success: true, data: rankings || [] });
  } catch (error) {
    console.error('getRegionalRanking error:', error);
    res.status(500).json({ success: false, message: '랭킹 조회에 실패했습니다.' });
  }
};

// 리뷰어 랭킹
exports.getReviewerRanking = async (req, res) => {
  try {
    const { limit: queryLimit } = req.query;
    const resultLimit = Math.min(parseInt(queryLimit) || 20, 100);

    const { data: reviewers, error } = await supabase
      .from('users')
      .select('id, nickname, profile_image, reviewer_grade, completed_missions, trust_score')
      .eq('user_type', 'reviewer')
      .eq('status', 'active')
      .gt('completed_missions', 0)
      .order('trust_score', { ascending: false })
      .order('completed_missions', { ascending: false })
      .limit(resultLimit);

    if (error) throw error;

    const ranked = (reviewers || []).map((r, index) => ({
      ...r,
      rank: index + 1,
    }));

    res.json({ success: true, data: ranked });
  } catch (error) {
    console.error('getReviewerRanking error:', error);
    res.status(500).json({ success: false, message: '리뷰어 랭킹 조회에 실패했습니다.' });
  }
};

// 사용 가능 지역/카테고리 목록
exports.getAvailableRegions = async (req, res) => {
  try {
    const { data: rankings, error } = await supabase
      .from('regional_rankings_cache')
      .select('region, category')
      .eq('period', 'monthly');

    if (error) throw error;

    const regions = [...new Set((rankings || []).map(r => r.region).filter(Boolean))];
    const categories = [...new Set((rankings || []).map(r => r.category).filter(Boolean))];

    res.json({
      success: true,
      data: { regions, categories },
    });
  } catch (error) {
    console.error('getAvailableRegions error:', error);
    res.status(500).json({ success: false, message: '지역 목록 조회에 실패했습니다.' });
  }
};
