const supabase = require('../config/supabase');

/**
 * GET /api/review-topics/:category
 * 카테고리별 토픽 정의 목록
 */
exports.getTopicsByCategory = async (req, res, next) => {
  try {
    const { category } = req.params;

    const { data: topics, error } = await supabase
      .from('review_topic_definitions')
      .select('*')
      .eq('category', category)
      .order('sort_order', { ascending: true });

    if (error) throw error;

    // 긍정/부정/중립 그룹핑
    const grouped = {
      positive: (topics || []).filter(t => t.topic_type === 'positive'),
      negative: (topics || []).filter(t => t.topic_type === 'negative'),
      neutral: (topics || []).filter(t => t.topic_type === 'neutral'),
    };

    res.json({
      success: true,
      data: {
        category,
        topics: topics || [],
        grouped,
      },
    });
  } catch (error) {
    next(error);
  }
};
