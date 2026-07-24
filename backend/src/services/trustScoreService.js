const supabase = require('../config/supabase');
const { GRADE_PROMOTION, GRADE_BENEFITS, TRUST_WEIGHT } = require('../config/constants');

/**
 * Calculate reviewer trust score (0-5.0)
 * Weighted average of: quality (40%), stealth (20%), completion rate (20%), consistency (20%)
 */
async function calculateTrustScore(userId) {
  // 1. Quality score (from audit averages)
  const { data: audits } = await supabase
    .from('review_quality_audits')
    .select('quality_score')
    .eq('reviewer_id', userId)
    .order('created_at', { ascending: false })
    .limit(20);

  const avgQuality = audits?.length
    ? audits.reduce((sum, a) => sum + a.quality_score, 0) / audits.length
    : 70; // default
  const qualityScore = Math.min(5, (avgQuality / 100) * 5);

  // 2. Stealth score
  const { data: user, error: userError } = await supabase
    .from('users')
    .select('stealth_score, completed_missions, detection_test_count')
    .eq('id', userId)
    .single();

  const stealthScore = Math.min(5, (((!userError && user) ? user.stealth_score : 50) || 50) / 100 * 5);

  // 3. Completion rate (completed / assigned)
  const { data: assignedMissions } = await supabase
    .from('missions')
    .select('id')
    .eq('assigned_reviewer_id', userId);

  const { data: completedReviews } = await supabase
    .from('reviews')
    .select('id')
    .eq('reviewer_id', userId)
    .eq('status', 'published');

  const assignedCount = assignedMissions?.length || 0;
  const completedCount = completedReviews?.length || 0;
  const completionRate = assignedCount > 0 ? completedCount / assignedCount : 1;
  const completionScore = Math.min(5, completionRate * 5);

  // 4. Consistency (low variance in scores = good)
  const { data: scores } = await supabase
    .from('reviews')
    .select('total_score')
    .eq('reviewer_id', userId)
    .eq('status', 'published')
    .order('created_at', { ascending: false })
    .limit(20);

  let consistencyScore = 3.5; // default
  if (scores?.length >= 5) {
    const mean = scores.reduce((s, r) => s + r.total_score, 0) / scores.length;
    const variance = scores.reduce((s, r) => s + Math.pow(r.total_score - mean, 2), 0) / scores.length;
    // Lower variance = higher consistency score
    consistencyScore = Math.min(5, Math.max(1, 5 - variance));
  }

  // Weighted average
  const trustScore = (
    qualityScore * 0.4 +
    stealthScore * 0.2 +
    completionScore * 0.2 +
    consistencyScore * 0.2
  );

  const finalScore = Math.round(trustScore * 100) / 100;

  // Update user
  await supabase.from('users')
    .update({ trust_score: finalScore })
    .eq('id', userId);

  // Check grade promotion after trust score update
  await checkAndPromoteGrade(userId);

  return finalScore;
}

/**
 * Check and auto-promote reviewer grade based on missions and trust score
 */
async function checkAndPromoteGrade(userId) {
  try {
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('reviewer_grade, completed_missions, trust_score')
      .eq('id', userId)
      .single();

    if (userError || !user) return null;

    const currentGrade = user.reviewer_grade || 'rookie';
    const gradeOrder = ['rookie', 'regular', 'senior', 'master'];
    const currentIdx = gradeOrder.indexOf(currentGrade);

    // Check each higher grade
    for (let i = currentIdx + 1; i < gradeOrder.length; i++) {
      const targetGrade = gradeOrder[i];
      const requirements = GRADE_PROMOTION[targetGrade];
      if (!requirements) continue;

      if ((user.completed_missions || 0) >= requirements.minMissions &&
          (user.trust_score || 0) >= requirements.minTrustScore) {
        // Promote to this grade (continue checking higher grades)
        continue;
      } else {
        // Can't reach this grade, promote to previous eligible
        const newGrade = gradeOrder[i - 1];
        if (newGrade !== currentGrade) {
          await supabase.from('users')
            .update({ reviewer_grade: newGrade })
            .eq('id', userId);

          // Send promotion notification
          const { createNotification } = require('../utils/notificationService');
          const label = GRADE_BENEFITS[newGrade]?.label || newGrade;
          await createNotification(
            userId,
            'grade_promotion',
            `${label} 등급으로 승급되었습니다!`,
            `축하합니다! ${label} 등급으로 승급되었습니다. 보수 배율 ${GRADE_BENEFITS[newGrade]?.payMultiplier}x가 적용됩니다.`,
            { newGrade, payMultiplier: GRADE_BENEFITS[newGrade]?.payMultiplier }
          );
          return newGrade;
        }
        return currentGrade;
      }
    }

    // If we got through all grades, promote to highest eligible
    const highestGrade = gradeOrder[gradeOrder.length - 1];
    if (highestGrade !== currentGrade) {
      const requirements = GRADE_PROMOTION[highestGrade];
      if (requirements &&
          (user.completed_missions || 0) >= requirements.minMissions &&
          (user.trust_score || 0) >= requirements.minTrustScore) {
        await supabase.from('users')
          .update({ reviewer_grade: highestGrade })
          .eq('id', userId);

        const { createNotification } = require('../utils/notificationService');
        const label = GRADE_BENEFITS[highestGrade]?.label || highestGrade;
        await createNotification(
          userId,
          'grade_promotion',
          `${label} 등급으로 승급되었습니다!`,
          `축하합니다! 최고 등급인 ${label}로 승급되었습니다!`,
          { newGrade: highestGrade, payMultiplier: GRADE_BENEFITS[highestGrade]?.payMultiplier }
        );
        return highestGrade;
      }
    }

    return currentGrade;
  } catch (err) {
    console.error('[GRADE_PROMOTION] Error:', err.message);
    return null;
  }
}

/**
 * Calculate trust weight for a reviewer based on trust score
 * Maps 0-5 trust score to MIN_WEIGHT-MAX_WEIGHT linearly
 */
function calculateTrustWeight(trustScore) {
  const minW = TRUST_WEIGHT.MIN_WEIGHT;
  const maxW = TRUST_WEIGHT.MAX_WEIGHT;
  const score = Math.max(0, Math.min(5, trustScore || 0));
  return minW + (score / 5) * (maxW - minW);
}

/**
 * Update trust-weighted rating for a business
 * Called when a review is published or reviewer trust changes
 */
async function updateTrustWeightedRating(businessId) {
  try {
    const { data: reviews } = await supabase
      .from('reviews')
      .select(`
        total_score, trust_weight,
        reviewer:users!reviews_reviewer_id_fkey(trust_score)
      `)
      .eq('business_id', businessId)
      .eq('status', 'published');

    if (!reviews || reviews.length < TRUST_WEIGHT.MIN_REVIEWS_FOR_WEIGHTED) {
      // Not enough reviews, use simple average
      const avg = reviews && reviews.length > 0
        ? reviews.reduce((s, r) => s + (r.total_score || 0), 0) / reviews.length
        : 0;
      await supabase.from('businesses')
        .update({ trust_weighted_rating: Math.round(avg * 100) / 100 })
        .eq('id', businessId);
      return avg;
    }

    let weightedSum = 0;
    let totalWeight = 0;

    for (const review of reviews) {
      const trustScore = review.reviewer?.trust_score || 2.5;
      const weight = calculateTrustWeight(trustScore);

      // Also update the review's stored trust_weight
      if (review.trust_weight !== weight) {
        await supabase.from('reviews')
          .update({ trust_weight: weight })
          .eq('business_id', businessId)
          .eq('status', 'published');
      }

      weightedSum += (review.total_score || 0) * weight;
      totalWeight += weight;
    }

    const weightedRating = totalWeight > 0
      ? Math.round((weightedSum / totalWeight) * 100) / 100
      : 0;

    await supabase.from('businesses')
      .update({ trust_weighted_rating: weightedRating })
      .eq('id', businessId);

    return weightedRating;
  } catch (err) {
    console.error('[TRUST_WEIGHTED_RATING] Error:', err.message);
    return null;
  }
}

module.exports = {
  calculateTrustScore,
  checkAndPromoteGrade,
  calculateTrustWeight,
  updateTrustWeightedRating,
};
