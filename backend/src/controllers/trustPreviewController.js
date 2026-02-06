const supabase = require('../config/supabase');

/**
 * 비인증 신뢰도 분석 API (무료 체험용)
 */
exports.getTrustPreview = async (req, res, next) => {
  try {
    const { query } = req.query;

    if (!query || query.trim().length < 2) {
      return res.status(400).json({
        success: false,
        message: '검색어를 2자 이상 입력해주세요.',
      });
    }

    // 업체명 검색 (ILIKE로 부분 일치)
    const { data: businesses, error: bizError } = await supabase
      .from('businesses')
      .select('id, name, category, total_reviews, average_rating, badge_level')
      .ilike('name', `%${query.trim()}%`)
      .eq('status', 'active')
      .limit(1);

    if (bizError) throw bizError;

    if (!businesses || businesses.length === 0) {
      return res.json({
        success: true,
        data: { found: false },
      });
    }

    const business = businesses[0];

    // 리뷰 집계
    const { data: reviews, error: reviewError } = await supabase
      .from('reviews')
      .select('total_score, receipt_verified, status')
      .eq('business_id', business.id)
      .eq('status', 'published');

    if (reviewError) throw reviewError;

    const reviewCount = reviews ? reviews.length : 0;
    const avgRating = reviewCount > 0
      ? reviews.reduce((sum, r) => sum + (r.total_score || 0), 0) / reviewCount
      : 0;
    const verifiedCount = reviews ? reviews.filter(r => r.receipt_verified).length : 0;
    const verifiedRatio = reviewCount > 0 ? verifiedCount / reviewCount : 0;

    // 같은 카테고리 업체 수 (순위 계산용)
    const { count: categoryTotal } = await supabase
      .from('businesses')
      .select('*', { count: 'exact', head: true })
      .eq('category', business.category)
      .eq('status', 'active');

    // 같은 카테고리에서 평점이 더 높은 업체 수
    const { count: higherRanked } = await supabase
      .from('businesses')
      .select('*', { count: 'exact', head: true })
      .eq('category', business.category)
      .eq('status', 'active')
      .gt('average_rating', business.average_rating || 0);

    const categoryRank = (higherRanked || 0) + 1;

    // 신뢰도 점수 계산 (간단 버전)
    // verifiedRatio * 40 + avgRating/5 * 30 + min(reviewCount/50, 1) * 30
    const trustScore = Math.round(
      verifiedRatio * 40 +
      (avgRating / 5) * 30 +
      Math.min(reviewCount / 50, 1) * 30
    );

    // 강점/개선점 생성
    const strengths = [];
    const improvements = [];

    if (verifiedRatio >= 0.7) {
      strengths.push(`실제 방문 인증 리뷰 비율이 높습니다 (${Math.round(verifiedRatio * 100)}%)`);
    } else {
      improvements.push('영수증 인증 리뷰가 부족합니다');
    }

    if (avgRating >= 4.0) {
      strengths.push('평균 평점이 우수합니다');
    }

    if (reviewCount >= 20) {
      strengths.push('충분한 수의 리뷰가 있습니다');
    } else {
      improvements.push('리뷰 수를 늘리면 신뢰도가 올라갑니다');
    }

    if (strengths.length === 0) {
      strengths.push('암행어흥에 등록되어 리뷰 검증이 가능합니다');
    }

    res.json({
      success: true,
      data: {
        found: true,
        businessName: business.name,
        trustScore,
        reviewCount,
        avgRating: Math.round(avgRating * 10) / 10,
        categoryRank,
        totalInCategory: categoryTotal || 0,
        strengths,
        improvements,
      },
    });
  } catch (error) {
    next(error);
  }
};
