/**
 * 사업자 역탐지 테스트 컨트롤러
 * 리뷰어의 익명성 검증 - 사업자가 리뷰어의 방문 시점을 맞출 수 있는지 테스트
 */

const supabase = require('../config/supabase');
const { getTimeSlot } = require('../utils/anonymizer');

/**
 * 역탐지 테스트 생성 (내부 함수, 리뷰 프리뷰 시작 시 호출)
 */
async function createDetectionTest(missionId) {
  try {
    const { data: mission, error: missionError } = await supabase
      .from('missions')
      .select(`
        id, business_id, assigned_reviewer_id, check_in_time,
        business:businesses(id, owner_id)
      `)
      .eq('id', missionId)
      .single();

    if (missionError || !mission || !mission.check_in_time) return null;

    // 이미 테스트가 존재하는지 확인
    const { data: existing, error: existingError } = await supabase
      .from('detection_tests')
      .select('id')
      .eq('mission_id', missionId)
      .single();

    if (existing && !existingError) return existing;

    const checkInDate = new Date(mission.check_in_time);
    const actualDate = checkInDate.toISOString().split('T')[0];
    const actualTimeSlot = getTimeSlot(checkInDate.getHours());

    // 72시간 후 만료 (프리뷰 기간과 동일)
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 72);

    const { data: test, error } = await supabase
      .from('detection_tests')
      .insert({
        mission_id: missionId,
        business_id: mission.business_id,
        reviewer_id: mission.assigned_reviewer_id,
        actual_date: actualDate,
        actual_time_slot: actualTimeSlot,
        expires_at: expiresAt.toISOString(),
        status: 'pending',
      })
      .select()
      .single();

    if (error) throw error;

    // 사업자에게 알림
    if (mission.business?.owner_id) {
      const { createNotification } = require('../utils/notificationService');
      await createNotification(
        mission.business.owner_id,
        'detection_test_available',
        '역탐지 테스트가 도착했습니다',
        '리뷰어가 언제 방문했는지 추측해보세요. 72시간 내에 응답해주세요.',
        { testId: test.id, missionId }
      );
    }

    console.log(`[DETECTION_TEST] Created for mission ${missionId}`);
    return test;
  } catch (err) {
    console.error('[DETECTION_TEST] Create error:', err.message);
    return null;
  }
}

/**
 * 사업자용: 응답 대기 테스트 목록
 */
exports.getPendingTests = async (req, res, next) => {
  try {
    // 사업자가 소유한 업체 ID 조회
    const { data: businesses } = await supabase
      .from('businesses')
      .select('id')
      .eq('owner_id', req.user.id);

    if (!businesses || businesses.length === 0) {
      return res.json({ success: true, data: { tests: [] } });
    }

    const businessIds = businesses.map(b => b.id);

    const { data: tests, error } = await supabase
      .from('detection_tests')
      .select('id, mission_id, business_id, status, expires_at, created_at')
      .in('business_id', businessIds)
      .eq('status', 'pending')
      .gt('expires_at', new Date().toISOString())
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json({
      success: true,
      data: { tests: tests || [] },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 사업자: 추측 제출
 */
exports.submitTest = async (req, res, next) => {
  try {
    const testId = req.params.id;
    const { guessedDate, guessedTimeSlot, guessedDescription, confidenceLevel } = req.body;

    // 테스트 조회 및 소유권 확인
    const { data: test, error: testError } = await supabase
      .from('detection_tests')
      .select(`
        *,
        business:businesses(owner_id)
      `)
      .eq('id', testId)
      .single();

    if (testError || !test || test.business?.owner_id !== req.user.id) {
      return res.status(404).json({ success: false, message: '테스트를 찾을 수 없습니다.' });
    }

    if (test.status !== 'pending') {
      return res.status(400).json({ success: false, message: '이미 응답한 테스트입니다.' });
    }

    if (new Date(test.expires_at) < new Date()) {
      return res.status(400).json({ success: false, message: '테스트 기한이 만료되었습니다.' });
    }

    // 날짜/시간대 일치 여부 계산
    const dateCorrect = guessedDate === test.actual_date;
    const timeCorrect = guessedTimeSlot === test.actual_time_slot;
    const confidence = Math.min(5, Math.max(1, confidenceLevel || 3));

    // detection_score 계산
    let detectionScore = 0;
    if (dateCorrect && timeCorrect) {
      detectionScore = confidence >= 4 ? 90 : 70;
    } else if (dateCorrect) {
      detectionScore = confidence >= 4 ? 55 : 40;
    } else if (timeCorrect) {
      detectionScore = confidence >= 4 ? 35 : 25;
    } else {
      detectionScore = confidence >= 4 ? 15 : 5;
    }

    // 테스트 결과 저장
    const { error: updateError } = await supabase
      .from('detection_tests')
      .update({
        guessed_date: guessedDate,
        guessed_time_slot: guessedTimeSlot,
        guessed_description: guessedDescription || null,
        confidence_level: confidence,
        date_correct: dateCorrect,
        time_correct: timeCorrect,
        detection_score: detectionScore,
        status: 'submitted',
        submitted_at: new Date().toISOString(),
      })
      .eq('id', testId);

    if (updateError) throw updateError;

    // 리뷰어 stealth_score 업데이트 (가중 이동 평균)
    await updateStealthScore(test.reviewer_id, detectionScore);

    // 감지도가 높으면 리뷰어에게 경고
    if (detectionScore >= 70) {
      const { createNotification } = require('../utils/notificationService');
      await createNotification(
        test.reviewer_id,
        'stealth_warning',
        '은밀성 경고',
        '최근 방문에서 사업자에게 감지되었을 수 있습니다. 방문 패턴을 다양하게 해보세요.',
        { testId, detectionScore }
      );
    }

    res.json({
      success: true,
      message: '추측이 제출되었습니다.',
      data: {
        dateCorrect,
        timeCorrect,
        detectionScore,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 리뷰어용: 은밀성 통계
 */
exports.getDetectionStats = async (req, res, next) => {
  try {
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('stealth_score, detection_test_count, detected_count')
      .eq('id', req.user.id)
      .single();

    const { data: tests } = await supabase
      .from('detection_tests')
      .select('detection_score, date_correct, time_correct, status, created_at')
      .eq('reviewer_id', req.user.id)
      .in('status', ['submitted', 'expired'])
      .order('created_at', { ascending: false })
      .limit(10);

    const totalTests = (!userError && user) ? (user.detection_test_count || 0) : 0;
    const detectedCount = (!userError && user) ? (user.detected_count || 0) : 0;
    const detectionRate = totalTests > 0 ? Math.round((detectedCount / totalTests) * 100) : 0;

    // 조언 생성
    let advice = '잘 하고 있습니다! 현재 은밀성이 높습니다.';
    if (detectionRate > 50) {
      advice = '감지율이 높습니다. 방문 시간대를 더 다양하게 해보세요.';
    } else if (detectionRate > 30) {
      advice = '방문 시 자연스럽게 행동하고, 사진 촬영에 주의하세요.';
    }

    res.json({
      success: true,
      data: {
        stealthScore: user?.stealth_score || 100,
        totalTests,
        detectedCount,
        detectionRate,
        advice,
        recentTests: tests || [],
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 리뷰어 stealth_score 업데이트 (가중 이동 평균)
 */
async function updateStealthScore(reviewerId, detectionScore) {
  try {
    const { data: user, error: userFetchError } = await supabase
      .from('users')
      .select('stealth_score, detection_test_count, detected_count')
      .eq('id', reviewerId)
      .single();

    if (userFetchError || !user) return;

    const currentScore = user.stealth_score || 100;
    const testCount = (user.detection_test_count || 0) + 1;
    const isDetected = detectionScore >= 70;
    const detectedCount = (user.detected_count || 0) + (isDetected ? 1 : 0);

    // 가중 이동 평균: 새 값의 가중치 30%
    const invertedDetection = 100 - detectionScore; // 낮은 감지 = 높은 stealth
    const newStealthScore = Math.round(currentScore * 0.7 + invertedDetection * 0.3);

    await supabase
      .from('users')
      .update({
        stealth_score: Math.max(0, Math.min(100, newStealthScore)),
        detection_test_count: testCount,
        detected_count: detectedCount,
      })
      .eq('id', reviewerId);
  } catch (err) {
    console.error('[STEALTH_SCORE] Update error:', err.message);
  }
}

/**
 * 만료 테스트 처리 (스케줄러에서 호출)
 * 기한 만료 = 사업자가 모름 = 성공 (stealth 보너스)
 */
async function expireDetectionTests() {
  try {
    const now = new Date().toISOString();

    const { data: expiredTests } = await supabase
      .from('detection_tests')
      .select('id, reviewer_id')
      .eq('status', 'pending')
      .lt('expires_at', now);

    if (!expiredTests || expiredTests.length === 0) return { expired: 0 };

    // 만료 처리
    const ids = expiredTests.map(t => t.id);
    await supabase
      .from('detection_tests')
      .update({
        status: 'expired',
        detection_score: 0, // 미감지 = 0점 (최고)
      })
      .in('id', ids);

    // 각 리뷰어에게 stealth 보너스
    for (const test of expiredTests) {
      await updateStealthScore(test.reviewer_id, 0); // 0 = 완벽한 은밀성
    }

    console.log(`[DETECTION_TEST] Expired ${expiredTests.length} tests`);
    return { expired: expiredTests.length };
  } catch (err) {
    console.error('[DETECTION_TEST] Expire error:', err.message);
    return { expired: 0 };
  }
}

module.exports = {
  createDetectionTest,
  getPendingTests: exports.getPendingTests,
  submitTest: exports.submitTest,
  getDetectionStats: exports.getDetectionStats,
  expireDetectionTests,
};
