const supabase = require('../config/supabase');
const { confirmPayment, cancelPayment } = require('../utils/tossPayments');
const { createErrorResponse, createPaymentErrorResponse } = require('../utils/errorMessages');

const PLAN_DETAILS = {
  basic: { monthlyInspections: 2, price: 99000, name: 'Basic' },
  standard: { monthlyInspections: 4, price: 179000, name: 'Standard' },
  premium: { monthlyInspections: 8, price: 299000, name: 'Premium' }
};

// ROI 계산 상수
const ROI_CONSTANTS = {
  RATING_IMPACT_PER_POINT: 0.12, // 평점 1점당 매출 영향 12%
  REVIEW_IMPACT_PER_10: 0.05,   // 리뷰 10개당 매출 영향 5%
  TRUST_BADGE_IMPACT: 0.08,     // 신뢰 배지 매출 영향 8%
  FAKE_REVIEW_DAMAGE: 0.15      // 가짜 리뷰 적발 시 매출 손실 15%
};

// 업체 등록
exports.createBusiness = async (req, res, next) => {
  try {
    const businessData = {
      owner_id: req.user.id,
      ...req.body
    };

    const { data: business, error } = await supabase
      .from('businesses')
      .insert(businessData)
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({
      success: true,
      message: '업체가 등록되었습니다.',
      data: { business }
    });
  } catch (error) {
    next(error);
  }
};

// 업체 목록 조회
exports.getBusinesses = async (req, res, next) => {
  try {
    const {
      page = 1,
      limit = 20,
      category,
      city,
      badge
    } = req.query;

    let query = supabase
      .from('businesses')
      .select('*', { count: 'exact' })
      .eq('status', 'active');

    if (category) query = query.eq('category', category);
    if (city) query = query.eq('address_city', city);
    if (badge) query = query.eq('badge_level', badge);

    const offset = (page - 1) * limit;
    query = query.range(offset, offset + parseInt(limit) - 1)
      .order('created_at', { ascending: false });

    const { data: businesses, count, error } = await query;

    if (error) throw error;

    res.json({
      success: true,
      data: {
        businesses,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: count,
          pages: Math.ceil(count / limit)
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

// 업체 상세 조회
exports.getBusiness = async (req, res, next) => {
  try {
    const { data: business, error } = await supabase
      .from('businesses')
      .select('*')
      .eq('id', req.params.id)
      .single();

    if (error || !business) {
      return res.status(404).json(
        createErrorResponse('MISSION_NOT_FOUND')
      );
    }

    res.json({
      success: true,
      data: { business }
    });
  } catch (error) {
    next(error);
  }
};

// 내 업체 목록
exports.getMyBusinesses = async (req, res, next) => {
  try {
    const { data: businesses, error } = await supabase
      .from('businesses')
      .select('*')
      .eq('owner_id', req.user.id);

    if (error) throw error;

    res.json({
      success: true,
      data: { businesses }
    });
  } catch (error) {
    next(error);
  }
};

// 업체 수정
exports.updateBusiness = async (req, res, next) => {
  try {
    const { data: existing } = await supabase
      .from('businesses')
      .select('id')
      .eq('id', req.params.id)
      .eq('owner_id', req.user.id)
      .single();

    if (!existing) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'BUSINESS_NOT_FOUND',
          message: '업체를 찾을 수 없거나 권한이 없습니다.',
          guidance: ['업체 목록에서 다시 확인해주세요.'],
          action: 'go_to_business_list'
        }
      });
    }

    const { data: business, error } = await supabase
      .from('businesses')
      .update(req.body)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;

    res.json({
      success: true,
      data: { business }
    });
  } catch (error) {
    next(error);
  }
};

// 이미지 업로드
exports.uploadImages = async (req, res, next) => {
  try {
    // 업체 소유권 확인
    const { data: business } = await supabase
      .from('businesses')
      .select('id, images')
      .eq('id', req.params.id)
      .eq('owner_id', req.user.id)
      .single();

    if (!business) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'BUSINESS_NOT_FOUND',
          message: '업체를 찾을 수 없거나 권한이 없습니다.',
          guidance: ['업체 목록에서 다시 확인해주세요.'],
          action: 'go_to_business_list'
        }
      });
    }

    const { images } = req.body; // [{base64, caption}]

    if (!images || !Array.isArray(images) || images.length === 0) {
      return res.status(400).json(
        createErrorResponse('UPLOAD_FAILED', { reason: '업로드할 이미지가 필요합니다.' })
      );
    }

    const uploadedUrls = [];

    for (let i = 0; i < images.length; i++) {
      const image = images[i];
      if (!image.base64) continue;

      const fileName = `businesses/${req.params.id}/${Date.now()}_${i}.jpg`;
      const buffer = Buffer.from(image.base64, 'base64');

      const { error: uploadError } = await supabase.storage
        .from('business-images')
        .upload(fileName, buffer, {
          contentType: 'image/jpeg',
          upsert: true
        });

      if (uploadError) {
        console.error('Image upload error:', uploadError);
        continue;
      }

      const { data: urlData } = supabase.storage
        .from('business-images')
        .getPublicUrl(fileName);

      uploadedUrls.push({
        url: urlData.publicUrl,
        caption: image.caption || ''
      });
    }

    // 기존 이미지와 병합
    const existingImages = business.images || [];
    const allImages = [...existingImages, ...uploadedUrls.map(img => img.url)];

    await supabase
      .from('businesses')
      .update({ images: allImages })
      .eq('id', req.params.id);

    res.json({
      success: true,
      message: `${uploadedUrls.length}장의 이미지가 업로드되었습니다.`,
      data: { images: uploadedUrls }
    });
  } catch (error) {
    next(error);
  }
};

// 구독 신청 (P0: 트랜잭션 롤백 적용)
exports.subscribe = async (req, res, next) => {
  let paymentKey = null;

  try {
    const { plan } = req.body;
    paymentKey = req.body.paymentKey;

    const { data: business } = await supabase
      .from('businesses')
      .select('id, name')
      .eq('id', req.params.id)
      .eq('owner_id', req.user.id)
      .single();

    if (!business) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'BUSINESS_NOT_FOUND',
          message: '업체를 찾을 수 없습니다.',
          guidance: ['업체 목록에서 다시 확인해주세요.'],
          action: 'go_to_business_list'
        }
      });
    }

    const planDetails = PLAN_DETAILS[plan];
    if (!planDetails) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'INVALID_PLAN',
          message: '유효하지 않은 플랜입니다.',
          guidance: ['basic, standard, premium 중 선택해주세요.'],
          action: 'select_plan'
        }
      });
    }

    if (!paymentKey) {
      return res.status(400).json(
        createErrorResponse('PAYMENT_FAILED', { reason: '결제 정보가 필요합니다.' })
      );
    }

    // Step 1: 토스페이먼츠 결제 승인
    const orderId = `subscription_${req.params.id}_${plan}_${Date.now()}`;
    const paymentResult = await confirmPayment(
      paymentKey,
      orderId,
      planDetails.price
    );

    if (paymentResult.status !== 'DONE') {
      return res.status(400).json(
        createPaymentErrorResponse('결제 승인에 실패했습니다.', false)
      );
    }

    // Step 2: 구독 정보 업데이트
    const startDate = new Date();
    const endDate = new Date();
    endDate.setMonth(endDate.getMonth() + 1);

    const { data: updated, error } = await supabase
      .from('businesses')
      .update({
        subscription_plan: plan,
        subscription_start_date: startDate.toISOString(),
        subscription_end_date: endDate.toISOString(),
        subscription_auto_renew: true,
        subscription_payment_key: paymentKey,
        subscription_order_id: orderId,
        monthly_inspections: planDetails.monthlyInspections,
        used_inspections: 0
      })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) {
      // DB 업데이트 실패 → 결제 취소
      console.error('Subscription DB update failed, cancelling payment:', error);
      await cancelPayment(paymentKey, '시스템 오류로 인한 자동 취소');
      return res.status(500).json(
        createPaymentErrorResponse('처리 중 오류가 발생했습니다.', true)
      );
    }

    res.json({
      success: true,
      message: '구독이 시작되었습니다.',
      data: {
        subscription: {
          plan,
          planName: planDetails.name,
          startDate,
          endDate,
          monthlyInspections: planDetails.monthlyInspections
        }
      }
    });
  } catch (error) {
    // 예외 발생 시 결제 취소 시도
    if (paymentKey) {
      try {
        await cancelPayment(paymentKey, '시스템 오류로 인한 자동 취소');
        return res.status(500).json(
          createPaymentErrorResponse('처리 중 오류가 발생했습니다.', true)
        );
      } catch (cancelError) {
        console.error('Payment cancellation failed:', cancelError);
      }
    }
    next(error);
  }
};

// 구독 해지
exports.unsubscribe = async (req, res, next) => {
  try {
    const { data: business } = await supabase
      .from('businesses')
      .select('id, subscription_end_date')
      .eq('id', req.params.id)
      .eq('owner_id', req.user.id)
      .single();

    if (!business) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'BUSINESS_NOT_FOUND',
          message: '업체를 찾을 수 없습니다.',
          guidance: ['업체 목록에서 다시 확인해주세요.'],
          action: 'go_to_business_list'
        }
      });
    }

    const { error } = await supabase
      .from('businesses')
      .update({ subscription_auto_renew: false })
      .eq('id', req.params.id);

    if (error) throw error;

    res.json({
      success: true,
      message: '구독 자동 갱신이 해지되었습니다.',
      data: {
        subscriptionEndDate: business.subscription_end_date,
        note: '현재 구독 기간이 끝날 때까지 서비스를 이용하실 수 있습니다.'
      }
    });
  } catch (error) {
    next(error);
  }
};

// P1: 대시보드 (ROI 시각화 강화)
exports.getDashboard = async (req, res, next) => {
  try {
    const { data: business } = await supabase
      .from('businesses')
      .select('*')
      .eq('id', req.params.id)
      .eq('owner_id', req.user.id)
      .single();

    if (!business) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'BUSINESS_NOT_FOUND',
          message: '업체를 찾을 수 없습니다.',
          guidance: ['업체 목록에서 다시 확인해주세요.'],
          action: 'go_to_business_list'
        }
      });
    }

    // 최근 리뷰 조회
    const { data: recentReviews } = await supabase
      .from('reviews')
      .select('id, total_score, created_at, helpful_count')
      .eq('business_id', req.params.id)
      .eq('status', 'published')
      .order('created_at', { ascending: false })
      .limit(5);

    // 진행 중인 미션 수
    const { count: pendingMissions } = await supabase
      .from('missions')
      .select('*', { count: 'exact', head: true })
      .eq('business_id', req.params.id)
      .in('status', ['recruiting', 'assigned', 'in_progress']);

    // 완료된 미션 수
    const { count: completedMissions } = await supabase
      .from('missions')
      .select('*', { count: 'exact', head: true })
      .eq('business_id', req.params.id)
      .eq('status', 'completed');

    // P1: 월별 평점 추이 (최근 6개월)
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

    const { data: monthlyReviews } = await supabase
      .from('reviews')
      .select('total_score, created_at')
      .eq('business_id', req.params.id)
      .eq('status', 'published')
      .gte('created_at', sixMonthsAgo.toISOString())
      .order('created_at', { ascending: true });

    // 월별 평균 계산
    const monthlyTrend = calculateMonthlyTrend(monthlyReviews || []);

    // P1: 카테고리 내 경쟁사 비교
    const { data: competitors } = await supabase
      .from('businesses')
      .select('average_rating, total_reviews')
      .eq('category', business.category)
      .eq('status', 'active')
      .neq('id', business.id);

    const categoryStats = calculateCategoryStats(competitors || [], business);

    // P1: ROI 계산
    const roiAnalysis = calculateROI(business, categoryStats);

    // P1: 누적 데이터 가치
    const dataValue = calculateDataValue(business, completedMissions || 0);

    res.json({
      success: true,
      data: {
        business: {
          id: business.id,
          name: business.name,
          category: business.category
        },
        stats: {
          totalReviews: business.total_reviews || 0,
          averageRating: business.average_rating || 0,
          helpfulCount: business.helpful_count || 0,
          pendingMissions: pendingMissions || 0,
          completedMissions: completedMissions || 0
        },
        badge: {
          level: business.badge_level,
          achievedAt: business.badge_achieved_at,
          nextLevel: getNextBadgeLevel(business.badge_level),
          progress: getBadgeProgress(business)
        },
        subscription: {
          plan: business.subscription_plan,
          planName: PLAN_DETAILS[business.subscription_plan]?.name || '없음',
          endDate: business.subscription_end_date,
          autoRenew: business.subscription_auto_renew,
          monthlyInspections: business.monthly_inspections || 0,
          usedInspections: business.used_inspections || 0,
          remainingInspections: (business.monthly_inspections || 0) - (business.used_inspections || 0)
        },

        // P1: ROI 시각화
        roi: roiAnalysis,

        // P1: 월별 추이
        trend: {
          monthly: monthlyTrend,
          direction: getTrendDirection(monthlyTrend)
        },

        // P1: 카테고리 내 위치
        categoryComparison: categoryStats,

        // P1: 누적 데이터 가치
        dataValue,

        recentReviews: (recentReviews || []).map(r => ({
          id: r.id,
          score: r.total_score,
          date: r.created_at,
          helpfulCount: r.helpful_count
        }))
      }
    });
  } catch (error) {
    next(error);
  }
};

// 월별 추이 계산
function calculateMonthlyTrend(reviews) {
  const monthlyData = {};

  reviews.forEach(review => {
    const date = new Date(review.created_at);
    const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;

    if (!monthlyData[monthKey]) {
      monthlyData[monthKey] = { total: 0, count: 0 };
    }
    monthlyData[monthKey].total += review.total_score || 0;
    monthlyData[monthKey].count += 1;
  });

  return Object.entries(monthlyData)
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([month, data]) => ({
      month,
      averageRating: Math.round((data.total / data.count) * 10) / 10,
      reviewCount: data.count
    }));
}

// 추이 방향 계산
function getTrendDirection(trend) {
  if (trend.length < 2) return 'neutral';

  const recent = trend.slice(-2);
  const diff = recent[1]?.averageRating - recent[0]?.averageRating;

  if (diff > 0.2) return 'up';
  if (diff < -0.2) return 'down';
  return 'stable';
}

// 카테고리 통계 계산
function calculateCategoryStats(competitors, business) {
  if (competitors.length === 0) {
    return {
      ranking: 1,
      totalBusinesses: 1,
      percentile: 100,
      avgRating: business.average_rating || 0,
      avgReviews: business.total_reviews || 0
    };
  }

  const allRatings = [...competitors.map(c => c.average_rating || 0), business.average_rating || 0]
    .sort((a, b) => b - a);

  const myRank = allRatings.indexOf(business.average_rating || 0) + 1;
  const total = allRatings.length;

  const avgRating = competitors.reduce((sum, c) => sum + (c.average_rating || 0), 0) / competitors.length;
  const avgReviews = competitors.reduce((sum, c) => sum + (c.total_reviews || 0), 0) / competitors.length;

  return {
    ranking: myRank,
    totalBusinesses: total,
    percentile: Math.round(((total - myRank + 1) / total) * 100),
    categoryAvgRating: Math.round(avgRating * 10) / 10,
    categoryAvgReviews: Math.round(avgReviews),
    ratingDiff: Math.round(((business.average_rating || 0) - avgRating) * 10) / 10,
    reviewsDiff: (business.total_reviews || 0) - Math.round(avgReviews)
  };
}

// P1: ROI 계산
function calculateROI(business, categoryStats) {
  // 가상의 월 매출 (실제로는 연동 필요)
  const estimatedMonthlyRevenue = 10000000; // 1천만원 가정

  // 평점 향상에 따른 매출 영향
  const ratingImpact = (categoryStats.ratingDiff || 0) * ROI_CONSTANTS.RATING_IMPACT_PER_POINT;

  // 리뷰 수에 따른 매출 영향
  const reviewImpact = Math.floor((business.total_reviews || 0) / 10) * ROI_CONSTANTS.REVIEW_IMPACT_PER_10;

  // 신뢰 배지에 따른 매출 영향
  const badgeImpact = business.badge_level && business.badge_level !== 'none'
    ? ROI_CONSTANTS.TRUST_BADGE_IMPACT
    : 0;

  // 가짜 리뷰 방어 가치
  const fakeReviewProtection = ROI_CONSTANTS.FAKE_REVIEW_DAMAGE;

  const totalImpact = ratingImpact + reviewImpact + badgeImpact + fakeReviewProtection;
  const estimatedValue = Math.round(estimatedMonthlyRevenue * Math.max(0, totalImpact));

  // 구독료 대비 ROI
  const subscriptionCost = PLAN_DETAILS[business.subscription_plan]?.price || 0;
  const roiPercentage = subscriptionCost > 0
    ? Math.round(((estimatedValue - subscriptionCost) / subscriptionCost) * 100)
    : 0;

  return {
    estimatedMonthlyValue: estimatedValue,
    breakdown: {
      ratingImpact: {
        factor: '평점 경쟁력',
        value: Math.round(estimatedMonthlyRevenue * ratingImpact),
        description: categoryStats.ratingDiff > 0
          ? `카테고리 평균보다 ${categoryStats.ratingDiff}점 높음`
          : `카테고리 평균보다 ${Math.abs(categoryStats.ratingDiff || 0)}점 낮음`
      },
      reviewImpact: {
        factor: '리뷰 양',
        value: Math.round(estimatedMonthlyRevenue * reviewImpact),
        description: `${business.total_reviews || 0}개의 검증된 리뷰 보유`
      },
      badgeImpact: {
        factor: '신뢰 배지',
        value: Math.round(estimatedMonthlyRevenue * badgeImpact),
        description: business.badge_level && business.badge_level !== 'none'
          ? `${business.badge_level} 배지 획득`
          : '배지 획득 시 +8% 기대'
      },
      protectionValue: {
        factor: '가짜 리뷰 방어',
        value: Math.round(estimatedMonthlyRevenue * fakeReviewProtection),
        description: '검증된 리뷰로 신뢰도 보호'
      }
    },
    subscriptionCost,
    roiPercentage,
    verdict: roiPercentage > 100
      ? '투자 대비 높은 효과'
      : roiPercentage > 0
        ? '투자 효과 있음'
        : '장기적 효과 기대'
  };
}

// 누적 데이터 가치 계산
function calculateDataValue(business, completedMissions) {
  const monthsSinceCreation = business.created_at
    ? Math.max(1, Math.floor((Date.now() - new Date(business.created_at).getTime()) / (30 * 24 * 60 * 60 * 1000)))
    : 1;

  return {
    dataAccumulatedMonths: monthsSinceCreation,
    totalVerifiedReviews: business.total_reviews || 0,
    completedMissions: completedMissions,
    uniqueInsights: Math.floor((business.total_reviews || 0) * 3), // 리뷰당 약 3개의 인사이트
    warning: monthsSinceCreation >= 3
      ? '해지 시 누적된 데이터 접근이 제한됩니다.'
      : null
  };
}

// 다음 배지 레벨
function getNextBadgeLevel(currentLevel) {
  const levels = ['none', 'bronze', 'silver', 'gold', 'platinum'];
  const currentIndex = levels.indexOf(currentLevel || 'none');
  return currentIndex < levels.length - 1 ? levels[currentIndex + 1] : null;
}

// 배지 진행률
function getBadgeProgress(business) {
  const currentLevel = business.badge_level || 'none';
  const reviews = business.total_reviews || 0;
  const rating = business.average_rating || 0;

  const requirements = {
    bronze: { reviews: 10, rating: 3.5 },
    silver: { reviews: 30, rating: 4.0 },
    gold: { reviews: 50, rating: 4.3 },
    platinum: { reviews: 100, rating: 4.5 }
  };

  const nextLevel = getNextBadgeLevel(currentLevel);
  if (!nextLevel) return { complete: true };

  const req = requirements[nextLevel];
  return {
    nextLevel,
    reviewsRequired: req.reviews,
    reviewsCurrent: reviews,
    reviewsProgress: Math.min(100, Math.round((reviews / req.reviews) * 100)),
    ratingRequired: req.rating,
    ratingCurrent: rating,
    ratingProgress: Math.min(100, Math.round((rating / req.rating) * 100))
  };
}

// 경쟁력 리포트 (강화)
exports.getCompetitiveReport = async (req, res, next) => {
  try {
    const { data: business } = await supabase
      .from('businesses')
      .select('*')
      .eq('id', req.params.id)
      .eq('owner_id', req.user.id)
      .single();

    if (!business) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'BUSINESS_NOT_FOUND',
          message: '업체를 찾을 수 없습니다.',
          guidance: ['업체 목록에서 다시 확인해주세요.'],
          action: 'go_to_business_list'
        }
      });
    }

    // 같은 카테고리 업체들 조회
    const { data: competitors } = await supabase
      .from('businesses')
      .select('id, name, average_rating, total_reviews, helpful_count, badge_level')
      .eq('category', business.category)
      .eq('status', 'active')
      .neq('id', business.id)
      .order('average_rating', { ascending: false })
      .limit(50);

    const strengths = [];
    const weaknesses = [];
    const recommendations = [];

    if (competitors && competitors.length > 0) {
      // 평균 계산
      const avgRating = competitors.reduce((a, b) => a + (b.average_rating || 0), 0) / competitors.length;
      const avgReviews = competitors.reduce((a, b) => a + (b.total_reviews || 0), 0) / competitors.length;
      const avgHelpful = competitors.reduce((a, b) => a + (b.helpful_count || 0), 0) / competitors.length;

      // 순위 계산
      const allRatings = [...competitors.map(c => c.average_rating || 0), business.average_rating || 0]
        .sort((a, b) => b - a);
      const myRank = allRatings.indexOf(business.average_rating || 0) + 1;

      // 평점 비교
      if ((business.average_rating || 0) > avgRating) {
        const percentile = Math.round((1 - (myRank - 1) / allRatings.length) * 100);
        strengths.push({
          type: 'rating',
          message: '카테고리 평균보다 높은 평점',
          detail: `상위 ${percentile}%`,
          value: business.average_rating || 0,
          categoryAvg: Math.round(avgRating * 10) / 10,
          impact: '예상 매출 +12%'
        });
      } else if ((business.average_rating || 0) < avgRating) {
        weaknesses.push({
          type: 'rating',
          message: '카테고리 평균보다 낮은 평점',
          value: business.average_rating || 0,
          categoryAvg: Math.round(avgRating * 10) / 10,
          gap: Math.round((avgRating - (business.average_rating || 0)) * 10) / 10
        });
        recommendations.push({
          priority: 'high',
          action: '품질 개선 미션 진행',
          description: `평점을 ${Math.round(avgRating * 10) / 10}점까지 올리면 카테고리 평균에 도달합니다.`,
          expectedImpact: '예상 매출 증가 +12%'
        });
      }

      // 리뷰 수 비교
      if ((business.total_reviews || 0) > avgReviews * 1.5) {
        strengths.push({
          type: 'reviews',
          message: '카테고리 평균보다 많은 리뷰',
          value: business.total_reviews || 0,
          categoryAvg: Math.round(avgReviews),
          impact: '신뢰도 상승'
        });
      } else if ((business.total_reviews || 0) < avgReviews) {
        const gap = Math.round(avgReviews) - (business.total_reviews || 0);
        weaknesses.push({
          type: 'reviews',
          message: '카테고리 평균보다 적은 리뷰',
          value: business.total_reviews || 0,
          categoryAvg: Math.round(avgReviews),
          gap
        });
        recommendations.push({
          priority: 'medium',
          action: '리뷰 미션 등록',
          description: `${gap}개의 리뷰를 더 모으면 카테고리 평균에 도달합니다.`,
          suggestedMissions: Math.ceil(gap / 2)
        });
      }

      // 도움됨 수 비교
      if ((business.helpful_count || 0) > avgHelpful * 1.2) {
        strengths.push({
          type: 'helpful',
          message: '리뷰 유용성이 높음',
          value: business.helpful_count || 0,
          categoryAvg: Math.round(avgHelpful)
        });
      } else if ((business.helpful_count || 0) < avgHelpful * 0.5) {
        weaknesses.push({
          type: 'helpful',
          message: '리뷰 유용성 개선 필요',
          value: business.helpful_count || 0,
          categoryAvg: Math.round(avgHelpful)
        });
        recommendations.push({
          priority: 'low',
          action: '상세 리뷰 요청 미션',
          description: '상세한 리뷰를 요청하면 유용성 점수가 올라갑니다.'
        });
      }

      // 배지 관련 추천
      if (!business.badge_level || business.badge_level === 'none') {
        recommendations.push({
          priority: 'high',
          action: '신뢰 배지 획득',
          description: '10개 이상의 리뷰와 3.5점 이상의 평점으로 Bronze 배지를 획득하세요.',
          expectedImpact: '예상 매출 증가 +8%'
        });
      }
    } else {
      recommendations.push({
        priority: 'medium',
        action: '첫 리뷰 미션 등록',
        description: '카테고리 내 첫 번째 업체입니다. 리뷰 미션을 등록하여 경쟁 우위를 선점하세요.'
      });
    }

    res.json({
      success: true,
      data: {
        ranking: competitors ? competitors.findIndex(c => (c.average_rating || 0) < (business.average_rating || 0)) + 1 : 1,
        totalCompetitors: competitors?.length || 0,
        topCompetitors: (competitors || []).slice(0, 5).map(c => ({
          name: c.name.substring(0, 2) + '**', // 익명화
          rating: c.average_rating,
          reviews: c.total_reviews,
          badge: c.badge_level
        })),
        strengths,
        weaknesses,
        recommendations: recommendations.sort((a, b) => {
          const priority = { high: 0, medium: 1, low: 2 };
          return priority[a.priority] - priority[b.priority];
        })
      }
    });
  } catch (error) {
    next(error);
  }
};

// 업체 리뷰 목록
exports.getBusinessReviews = async (req, res, next) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const offset = (page - 1) * limit;

    const { data: reviews, error } = await supabase
      .from('reviews')
      .select(`
        *,
        reviewer:users!reviews_reviewer_id_fkey(id, nickname, reviewer_grade)
      `)
      .eq('business_id', req.params.id)
      .eq('status', 'published')
      .order('created_at', { ascending: false })
      .range(offset, offset + parseInt(limit) - 1);

    if (error) throw error;

    res.json({
      success: true,
      data: { reviews }
    });
  } catch (error) {
    next(error);
  }
};

// 업체 미션 목록
exports.getBusinessMissions = async (req, res, next) => {
  try {
    const { data: missions, error } = await supabase
      .from('missions')
      .select('*')
      .eq('business_id', req.params.id)
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json({
      success: true,
      data: { missions }
    });
  } catch (error) {
    next(error);
  }
};

// 리뷰 답변
exports.respondToReview = async (req, res, next) => {
  try {
    const { content, improvementPromise } = req.body;

    // 업체 소유권 확인
    const { data: business } = await supabase
      .from('businesses')
      .select('id')
      .eq('id', req.params.id)
      .eq('owner_id', req.user.id)
      .single();

    if (!business) {
      return res.status(403).json(
        createErrorResponse('FORBIDDEN')
      );
    }

    const { data: review, error } = await supabase
      .from('reviews')
      .select('id')
      .eq('id', req.params.reviewId)
      .eq('business_id', req.params.id)
      .single();

    if (!review) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'REVIEW_NOT_FOUND',
          message: '리뷰를 찾을 수 없습니다.',
          guidance: ['리뷰 목록에서 다시 확인해주세요.'],
          action: 'go_to_reviews'
        }
      });
    }

    const { error: updateError } = await supabase
      .from('reviews')
      .update({
        business_response: content,
        improvement_promise: improvementPromise,
        responded_at: new Date().toISOString()
      })
      .eq('id', req.params.reviewId);

    if (updateError) throw updateError;

    res.json({
      success: true,
      message: '답변이 등록되었습니다.'
    });
  } catch (error) {
    next(error);
  }
};

// 근처 업체 검색
exports.getNearbyBusinesses = async (req, res, next) => {
  try {
    const { lng, lat, radius = 5000, category } = req.query;

    let query = supabase
      .from('businesses')
      .select('*')
      .eq('status', 'active');

    if (category) query = query.eq('category', category);

    const latDiff = radius / 111000;
    const lngDiff = radius / (111000 * Math.cos(parseFloat(lat) * Math.PI / 180));

    query = query
      .gte('latitude', parseFloat(lat) - latDiff)
      .lte('latitude', parseFloat(lat) + latDiff)
      .gte('longitude', parseFloat(lng) - lngDiff)
      .lte('longitude', parseFloat(lng) + lngDiff)
      .limit(50);

    const { data: businesses, error } = await query;

    if (error) throw error;

    res.json({
      success: true,
      data: { businesses }
    });
  } catch (error) {
    next(error);
  }
};

// 업체 검색
exports.searchBusinesses = async (req, res, next) => {
  try {
    const { q, category, city } = req.query;

    let query = supabase
      .from('businesses')
      .select('*')
      .eq('status', 'active');

    if (q) {
      query = query.or(`name.ilike.%${q}%,description.ilike.%${q}%`);
    }

    if (category) query = query.eq('category', category);
    if (city) query = query.eq('address_city', city);

    query = query.limit(50);

    const { data: businesses, error } = await query;

    if (error) throw error;

    res.json({
      success: true,
      data: { businesses }
    });
  } catch (error) {
    next(error);
  }
};

// P1: 무료 체험 (비로그인)
exports.getFreeAnalysis = async (req, res, next) => {
  try {
    const { businessName, category, city } = req.query;

    if (!businessName) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'NAME_REQUIRED',
          message: '업체명을 입력해주세요.',
          guidance: ['업체명을 입력하면 간단 분석을 제공합니다.'],
          action: 'input_name'
        }
      });
    }

    // 카테고리 평균 조회 (공개 데이터)
    let query = supabase
      .from('businesses')
      .select('average_rating, total_reviews')
      .eq('status', 'active');

    if (category) query = query.eq('category', category);
    if (city) query = query.eq('address_city', city);

    const { data: businesses } = await query.limit(100);

    if (!businesses || businesses.length === 0) {
      return res.json({
        success: true,
        data: {
          message: '해당 지역/카테고리에 등록된 업체가 없습니다.',
          recommendation: '암행어흥에 등록하여 첫 번째로 신뢰 배지를 획득하세요!'
        }
      });
    }

    const avgRating = businesses.reduce((sum, b) => sum + (b.average_rating || 0), 0) / businesses.length;
    const avgReviews = businesses.reduce((sum, b) => sum + (b.total_reviews || 0), 0) / businesses.length;

    res.json({
      success: true,
      data: {
        businessName,
        categoryStats: {
          totalBusinesses: businesses.length,
          averageRating: Math.round(avgRating * 10) / 10,
          averageReviews: Math.round(avgReviews)
        },
        freeInsights: [
          {
            title: '카테고리 평균 평점',
            value: `${Math.round(avgRating * 10) / 10}점`,
            description: '이 수치 이상을 유지하면 상위 50%에 진입합니다.'
          },
          {
            title: '평균 리뷰 수',
            value: `${Math.round(avgReviews)}개`,
            description: '리뷰가 많을수록 소비자 신뢰가 높아집니다.'
          },
          {
            title: '신뢰 배지 효과',
            value: '+8%',
            description: '신뢰 배지 획득 시 예상 매출 증가율'
          }
        ],
        cta: {
          message: '더 자세한 분석과 경쟁사 비교는 가입 후 확인하세요.',
          action: 'register'
        },
        limited: true
      }
    });
  } catch (error) {
    next(error);
  }
};
