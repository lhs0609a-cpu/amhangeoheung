/**
 * 리뷰 품질 감사 컨트롤러
 * 리뷰 제출 시 자동으로 품질을 분석하고 플래그를 생성
 */

const supabase = require('../config/supabase');
const { QUALITY_WARNING_THRESHOLD, QUALITY_BONUSES } = require('../config/constants');

/**
 * 리뷰 자동 품질 감사 (리뷰 제출 시 호출)
 */
async function auditReview(reviewId) {
  try {
    const { data: review, error: reviewError } = await supabase
      .from('reviews')
      .select(`
        *,
        mission:missions(check_in_time, check_out_time, assigned_reviewer_id)
      `)
      .eq('id', reviewId)
      .single();

    if (reviewError || !review) return null;

    const flags = [];
    let qualityScore = 100;

    // 1. 텍스트 길이 검사
    const textLength = (review.content_pros?.join(' ') || '').length +
                       (review.content_cons?.join(' ') || '').length +
                       (review.content_summary || '').length;
    if (textLength < 200) {
      flags.push('too_short');
      qualityScore -= 15;
    }

    // 2. 긍정 편향 검사 (pros >> cons)
    const prosLength = (review.content_pros?.join(' ') || '').length;
    const consLength = (review.content_cons?.join(' ') || '').length;
    const totalTextLen = prosLength + consLength;
    if (totalTextLen > 0 && (prosLength / totalTextLen) > 0.85) {
      flags.push('too_positive');
      qualityScore -= 10;
    }

    // 3. 체류시간 검사
    if (review.mission?.check_in_time && review.mission?.check_out_time) {
      const stayMs = new Date(review.mission.check_out_time) - new Date(review.mission.check_in_time);
      const stayMinutes = stayMs / 60000;
      if (stayMinutes < 45) {
        flags.push('suspiciously_fast');
        qualityScore -= 10;
      }
    }

    // 4. cons 항목 품질 검사
    if (!review.content_cons || review.content_cons.length === 0) {
      flags.push('weak_cons');
      qualityScore -= 20;
    } else {
      const shortCons = review.content_cons.filter(c => c.length < 10);
      if (shortCons.length === review.content_cons.length) {
        flags.push('weak_cons');
        qualityScore -= 15;
      }
    }

    // 5. 최근 리뷰 평균 점수 편향 검사
    const reviewerId = review.reviewer_id;
    const { data: recentReviews } = await supabase
      .from('reviews')
      .select('total_score')
      .eq('reviewer_id', reviewerId)
      .neq('id', reviewId)
      .order('created_at', { ascending: false })
      .limit(5);

    if (recentReviews && recentReviews.length >= 3) {
      const avgScore = recentReviews.reduce((sum, r) => sum + (r.total_score || 0), 0) / recentReviews.length;
      if (avgScore > 4.5) {
        flags.push('consistently_high');
        qualityScore -= 10;
      }
    }

    // 품질 보너스 감지
    const bonuses = [];
    if (textLength >= (QUALITY_BONUSES.DETAILED_REVIEW?.threshold || 500)) {
      bonuses.push({ type: 'detailed_review', bonus: QUALITY_BONUSES.DETAILED_REVIEW.bonus, label: QUALITY_BONUSES.DETAILED_REVIEW.label });
    }
    if (prosLength > 0 && consLength > 0 && totalTextLen > 0 && (consLength / totalTextLen) >= 0.15) {
      bonuses.push({ type: 'balanced_review', bonus: QUALITY_BONUSES.BALANCED_REVIEW.bonus, label: QUALITY_BONUSES.BALANCED_REVIEW.label });
    }

    // 점수 범위 보정
    qualityScore = Math.max(0, Math.min(100, qualityScore));

    // 세부 점수 계산
    const objectivityScore = flags.includes('too_positive') || flags.includes('consistently_high') ? 50 : 85;
    const detailScore = flags.includes('too_short') ? 40 : 80;
    const evidenceScore = review.receipt_verified ? 90 : 60;

    // 감사 기록 저장
    const { data: audit } = await supabase
      .from('review_quality_audits')
      .insert({
        review_id: reviewId,
        auditor_type: 'system',
        quality_score: qualityScore,
        objectivity_score: objectivityScore,
        detail_score: detailScore,
        evidence_score: evidenceScore,
        flags: JSON.stringify(flags),
        action_taken: qualityScore < 70 ? 'warning' : 'none',
      })
      .select()
      .single();

    // 품질 점수가 낮으면 경고 처리
    if (qualityScore < 70) {
      const { data: user, error: userError } = await supabase
        .from('users')
        .select('warning_count')
        .eq('id', reviewerId)
        .single();

      const newWarningCount = ((!userError && user) ? user.warning_count : 0) + 1;

      const updates = {
        warning_count: newWarningCount,
        quality_score: qualityScore,
      };

      // 3회 누적 시 인증 정지
      if (newWarningCount >= (QUALITY_WARNING_THRESHOLD || 3)) {
        updates.is_certified = false;

        // Suspend certification
        await supabase.from('reviewer_certifications')
          .update({ status: 'suspended' })
          .eq('user_id', reviewerId);

        await supabase.from('users')
          .update({ is_certified: false })
          .eq('id', reviewerId);

        // Send notification IMMEDIATELY (not deferred)
        const { createNotification } = require('../utils/notificationService');
        await createNotification(
          reviewerId,
          'CERTIFICATION_SUSPENDED',
          '인증이 정지되었습니다',
          `품질 경고 ${newWarningCount}회 누적으로 인증이 정지되었습니다. 재교육을 완료해야 활동을 재개할 수 있습니다.`,
          { warningCount: newWarningCount, action: 'recertification_required' }
        );
      } else if (newWarningCount >= 2) {
        // S4: Recertification notice at 2 warnings
        const { createNotification } = require('../utils/notificationService');
        await createNotification(
          reviewerId,
          'RECERTIFICATION_DUE',
          '재교육 권고',
          `품질 경고 ${newWarningCount}회 누적되었습니다. 추가 경고 시 인증이 정지됩니다. 재교육을 권장합니다.`,
          { warningCount: newWarningCount, action: 'recertification_recommended' }
        );
      } else {
        // 일반 경고 알림
        const { createNotification } = require('../utils/notificationService');
        await createNotification(
          reviewerId,
          'quality_warning',
          '리뷰 품질 경고',
          `최근 리뷰의 품질 점수가 ${qualityScore}점입니다. 더 구체적이고 객관적인 리뷰를 작성해주세요.`,
          { auditId: audit?.id, qualityScore, warningCount: newWarningCount }
        );
      }

      await supabase
        .from('users')
        .update(updates)
        .eq('id', reviewerId);
    }

    // 품질 보너스 지급 (점수가 양호한 경우에만)
    if (bonuses.length > 0 && qualityScore >= 70) {
      for (const bonus of bonuses) {
        await supabase.from('reviewer_earnings').insert({
          reviewer_id: reviewerId,
          earning_type: 'quality_bonus',
          base_amount: 0,
          quality_bonus: bonus.bonus,
          total_amount: bonus.bonus,
          status: 'paid',
          paid_at: new Date().toISOString(),
        });
      }

      const totalBonus = bonuses.reduce((s, b) => s + b.bonus, 0);
      const { data: currentUser, error: currentUserError } = await supabase
        .from('users')
        .select('total_earnings, quality_bonus_count')
        .eq('id', reviewerId)
        .single();

      await supabase.from('users')
        .update({
          total_earnings: ((!currentUserError && currentUser) ? currentUser.total_earnings : 0) + totalBonus,
          quality_bonus_count: ((!currentUserError && currentUser) ? currentUser.quality_bonus_count : 0) + bonuses.length,
        })
        .eq('id', reviewerId);

      const { createNotification } = require('../utils/notificationService');
      const bonusLabels = bonuses.map(b => b.label).join(', ');
      await createNotification(
        reviewerId,
        'quality_bonus',
        '품질 보너스 지급!',
        `${bonusLabels} 보너스 ${totalBonus.toLocaleString()}원이 지급되었습니다.`,
        { bonuses, totalBonus }
      );
    }

    console.log(`[QUALITY_AUDIT] Review ${reviewId}: score=${qualityScore}, flags=${flags.join(',')}, bonuses=${bonuses.length}`);
    return { qualityScore, flags, bonuses, audit };
  } catch (err) {
    console.error('[QUALITY_AUDIT] Error:', err.message);
    return null;
  }
}

/**
 * 리뷰어 본인 감사 이력 조회
 */
async function getAuditHistory(req, res, next) {
  try {
    const { data: reviews } = await supabase
      .from('reviews')
      .select('id')
      .eq('reviewer_id', req.user.id);

    if (!reviews || reviews.length === 0) {
      return res.json({ success: true, data: { audits: [] } });
    }

    const reviewIds = reviews.map(r => r.id);

    const { data: audits, error } = await supabase
      .from('review_quality_audits')
      .select('*')
      .in('review_id', reviewIds)
      .order('created_at', { ascending: false })
      .limit(20);

    if (error) throw error;

    res.json({
      success: true,
      data: { audits: audits || [] },
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  auditReview,
  getAuditHistory,
};
