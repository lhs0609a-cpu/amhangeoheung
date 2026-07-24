/**
 * 리뷰어 교육/인증 프로그램 컨트롤러
 * 3일 과정 인증 + 퀴즈 + 종합 시험
 */

const supabase = require('../config/supabase');
const {
  CERTIFICATION_PASSING_SCORE,
  MAX_QUIZ_ATTEMPTS,
  RECERTIFICATION_INTERVAL_DAYS,
} = require('../config/constants');

/**
 * 특정 날짜의 교육 모듈 목록 반환
 */
exports.getTrainingModules = async (req, res, next) => {
  try {
    const day = parseInt(req.params.day);
    if (day < 1 || day > 3) {
      return res.status(400).json({ success: false, message: '유효하지 않은 교육일입니다. (1-3)' });
    }

    // 인증 상태 확인
    const { data: cert, error: certError } = await supabase
      .from('reviewer_certifications')
      .select('*')
      .eq('user_id', req.user.id)
      .single();

    // 이전 날 완료 여부 검증
    if (day > 1) {
      if (certError || !cert) {
        return res.status(400).json({ success: false, message: '먼저 Day 1 교육을 시작해주세요.' });
      }
      const prevDayField = `day${day - 1}_completed_at`;
      if (!cert[prevDayField]) {
        return res.status(400).json({
          success: false,
          message: `Day ${day - 1} 교육을 먼저 완료해주세요.`,
        });
      }
    }

    // 모듈 목록 조회
    const { data: modules, error } = await supabase
      .from('training_modules')
      .select('*')
      .eq('day_number', day)
      .eq('is_active', true)
      .order('module_order');

    if (error) throw error;

    // 진행 상태 조회
    const moduleIds = (modules || []).map(m => m.id);
    let progressMap = {};
    if (moduleIds.length > 0) {
      const { data: progress } = await supabase
        .from('training_progress')
        .select('module_id, status, score, attempts')
        .eq('user_id', req.user.id)
        .in('module_id', moduleIds);

      (progress || []).forEach(p => {
        progressMap[p.module_id] = p;
      });
    }

    const modulesWithProgress = (modules || []).map(m => {
      const moduleData = {
        ...m,
        progress: progressMap[m.id] || { status: 'not_started', score: null, attempts: 0 },
      };

      // Strip correct answers from quiz data before sending to client
      if (moduleData.content_data?.questions) {
        moduleData.content_data = {
          ...moduleData.content_data,
          questions: moduleData.content_data.questions.map(q => {
            const { correctAnswer, ...rest } = q;
            return rest;
          }),
        };
      }

      return moduleData;
    });

    res.json({
      success: true,
      data: {
        day,
        modules: modulesWithProgress,
        certification: cert || null,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 모듈 시작
 */
exports.startModule = async (req, res, next) => {
  try {
    const { moduleId } = req.params;

    // Enforce sequential day access
    const { data: module, error: moduleError } = await supabase
      .from('training_modules')
      .select('day_number')
      .eq('id', moduleId)
      .single();

    if (!moduleError && module && module.day_number > 1) {
      const prevDayField = `day${module.day_number - 1}_completed_at`;
      const { data: cert, error: certError } = await supabase
        .from('reviewer_certifications')
        .select(prevDayField)
        .eq('user_id', req.user.id)
        .single();

      if (certError || !cert || !cert[prevDayField]) {
        return res.status(400).json({
          success: false,
          message: `Day ${module.day_number - 1} 교육을 먼저 완료해주세요.`
        });
      }
    }

    // 인증 레코드 생성 (없으면)
    const { data: existingCert, error: existingCertError } = await supabase
      .from('reviewer_certifications')
      .select('id')
      .eq('user_id', req.user.id)
      .single();

    if (!existingCert || existingCertError) {
      await supabase
        .from('reviewer_certifications')
        .insert({
          user_id: req.user.id,
          status: 'in_progress',
          current_day: 1,
        });
    }

    // 진행 레코드 upsert
    const { data: existing, error: existingError } = await supabase
      .from('training_progress')
      .select('id')
      .eq('user_id', req.user.id)
      .eq('module_id', moduleId)
      .single();

    if (existing && !existingError) {
      await supabase
        .from('training_progress')
        .update({
          status: 'in_progress',
          started_at: new Date().toISOString(),
        })
        .eq('id', existing.id);
    } else {
      await supabase
        .from('training_progress')
        .insert({
          user_id: req.user.id,
          module_id: moduleId,
          status: 'in_progress',
          started_at: new Date().toISOString(),
        });
    }

    res.json({ success: true, message: '모듈을 시작합니다.' });
  } catch (error) {
    next(error);
  }
};

/**
 * 퀴즈 제출 및 채점
 */
exports.submitQuiz = async (req, res, next) => {
  try {
    const { moduleId } = req.params;
    const { answers } = req.body; // { questionIndex: selectedOption, ... }

    // 모듈 조회
    const { data: module, error: moduleError } = await supabase
      .from('training_modules')
      .select('*')
      .eq('id', moduleId)
      .single();

    if (moduleError || !module || module.content_type !== 'quiz') {
      return res.status(400).json({ success: false, message: '퀴즈 모듈이 아닙니다.' });
    }

    // Enforce sequential day access
    if (module.day_number > 1) {
      const prevDayField = `day${module.day_number - 1}_completed_at`;
      const { data: cert, error: certError } = await supabase
        .from('reviewer_certifications')
        .select(prevDayField)
        .eq('user_id', req.user.id)
        .single();

      if (certError || !cert || !cert[prevDayField]) {
        return res.status(400).json({
          success: false,
          message: `Day ${module.day_number - 1} 교육을 먼저 완료해주세요.`
        });
      }
    }

    // 시도 횟수 확인
    const { data: progress, error: progressError } = await supabase
      .from('training_progress')
      .select('*')
      .eq('user_id', req.user.id)
      .eq('module_id', moduleId)
      .single();

    if (!progressError && progress && progress.attempts >= (MAX_QUIZ_ATTEMPTS || 3) && progress.status !== 'completed') {
      return res.status(400).json({
        success: false,
        message: `최대 재시도 횟수(${MAX_QUIZ_ATTEMPTS || 3}회)를 초과했습니다.`,
      });
    }

    // 채점
    const questions = module.content_data?.questions || [];
    let correctCount = 0;
    const totalQuestions = questions.length;

    questions.forEach((q, idx) => {
      if (answers[idx] === q.correctAnswer) {
        correctCount++;
      }
    });

    const score = totalQuestions > 0 ? Math.round((correctCount / totalQuestions) * 100) : 0;
    const passed = score >= (module.passing_score || CERTIFICATION_PASSING_SCORE || 80);
    const attempts = (progress?.attempts || 0) + 1;

    // 진행 상태 업데이트
    const updateData = {
      score,
      attempts,
      answers,
      status: passed ? 'completed' : 'failed',
    };
    if (passed) {
      updateData.completed_at = new Date().toISOString();
    }

    if (progress) {
      await supabase
        .from('training_progress')
        .update(updateData)
        .eq('id', progress.id);
    } else {
      await supabase
        .from('training_progress')
        .insert({
          user_id: req.user.id,
          module_id: moduleId,
          started_at: new Date().toISOString(),
          ...updateData,
        });
    }

    res.json({
      success: true,
      data: {
        score,
        passed,
        correctCount,
        totalQuestions,
        attempts,
        maxAttempts: MAX_QUIZ_ATTEMPTS || 3,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 교육일 완료 확인
 */
exports.completeDay = async (req, res, next) => {
  try {
    const day = parseInt(req.params.day);
    if (day < 1 || day > 3) {
      return res.status(400).json({ success: false, message: '유효하지 않은 교육일입니다.' });
    }

    // 해당 일자 모듈 전부 completed 확인
    const { data: modules } = await supabase
      .from('training_modules')
      .select('id')
      .eq('day_number', day)
      .eq('is_active', true);

    if (!modules || modules.length === 0) {
      return res.status(400).json({ success: false, message: '교육 모듈이 없습니다.' });
    }

    const moduleIds = modules.map(m => m.id);

    const { data: progress } = await supabase
      .from('training_progress')
      .select('module_id, status')
      .eq('user_id', req.user.id)
      .in('module_id', moduleIds);

    const completedModules = (progress || []).filter(p => p.status === 'completed');
    if (completedModules.length < modules.length) {
      return res.status(400).json({
        success: false,
        message: `모든 모듈을 완료해야 합니다. (${completedModules.length}/${modules.length})`,
      });
    }

    // 인증 상태 업데이트
    const dayField = `day${day}_completed_at`;
    const updates = {
      [dayField]: new Date().toISOString(),
      current_day: Math.min(day + 1, 3),
    };

    await supabase
      .from('reviewer_certifications')
      .update(updates)
      .eq('user_id', req.user.id);

    // 알림
    if (day < 3) {
      const { createNotification } = require('../utils/notificationService');
      await createNotification(
        req.user.id,
        'certification_day_unlocked',
        `Day ${day + 1} 교육이 열렸습니다`,
        `Day ${day} 교육을 완료했습니다! 내일 Day ${day + 1} 교육을 진행하세요.`,
        { day: day + 1 }
      );
    }

    res.json({
      success: true,
      message: `Day ${day} 교육을 완료했습니다.`,
      data: { nextDay: day < 3 ? day + 1 : null },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 종합 시험 응시
 */
exports.takeFinalExam = async (req, res, next) => {
  try {
    const { answers } = req.body;

    // Day 3 완료 확인
    const { data: cert, error: certError } = await supabase
      .from('reviewer_certifications')
      .select('*')
      .eq('user_id', req.user.id)
      .single();

    if (certError || !cert || !cert.day3_completed_at) {
      return res.status(400).json({ success: false, message: 'Day 3 교육을 먼저 완료해주세요.' });
    }

    if (cert.status === 'certified') {
      return res.status(400).json({ success: false, message: '이미 인증을 완료했습니다.' });
    }

    // 종합 시험 모듈 조회 (day 3의 마지막 퀴즈 모듈)
    const { data: examModule, error: examModuleError } = await supabase
      .from('training_modules')
      .select('*')
      .eq('day_number', 3)
      .eq('content_type', 'quiz')
      .order('module_order', { ascending: false })
      .limit(1)
      .single();

    if (examModuleError || !examModule) {
      return res.status(400).json({ success: false, message: '시험 모듈을 찾을 수 없습니다.' });
    }

    // 채점
    const questions = examModule.content_data?.questions || [];
    let correctCount = 0;
    questions.forEach((q, idx) => {
      if (answers[idx] === q.correctAnswer) {
        correctCount++;
      }
    });

    const score = questions.length > 0 ? Math.round((correctCount / questions.length) * 100) : 0;
    const passed = score >= (CERTIFICATION_PASSING_SCORE || 80);
    const totalAttempts = (cert.total_attempts || 0) + 1;

    // 인증 상태 업데이트
    const certUpdates = {
      final_exam_score: score,
      total_attempts: totalAttempts,
    };

    if (passed) {
      const recertDate = new Date();
      recertDate.setDate(recertDate.getDate() + (RECERTIFICATION_INTERVAL_DAYS || 90));

      certUpdates.status = 'certified';
      certUpdates.certification_date = new Date().toISOString();
      certUpdates.next_recertification = recertDate.toISOString();

      // 사용자 인증 상태 업데이트
      const userUpdates = {
        is_certified: true,
        certification_level: 'basic',
      };

      // Reset warning count on recertification
      if (cert.status === 'suspended' || cert.status === 'recertifying') {
        userUpdates.warning_count = 0;
      }

      await supabase
        .from('users')
        .update(userUpdates)
        .eq('id', req.user.id);

      // 축하 알림
      const { createNotification } = require('../utils/notificationService');
      await createNotification(
        req.user.id,
        'certification_completed',
        '인증을 축하합니다!',
        '암행어흥 리뷰어 인증을 완료했습니다. 이제 미션에 지원할 수 있습니다!',
        { score, certificationLevel: 'basic' }
      );
    } else {
      certUpdates.status = totalAttempts >= 3 ? 'failed' : 'in_progress';
    }

    await supabase
      .from('reviewer_certifications')
      .update(certUpdates)
      .eq('user_id', req.user.id);

    res.json({
      success: true,
      data: {
        score,
        passed,
        correctCount,
        totalQuestions: questions.length,
        totalAttempts,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 현재 인증 상태 반환
 */
exports.getCertificationStatus = async (req, res, next) => {
  try {
    const { data: cert, error: certError } = await supabase
      .from('reviewer_certifications')
      .select('*')
      .eq('user_id', req.user.id)
      .single();

    const { data: user, error: userError } = await supabase
      .from('users')
      .select('is_certified, certification_level, quality_score, warning_count')
      .eq('id', req.user.id)
      .single();

    // 각 날짜의 진행률 계산
    const dayProgress = {};
    for (let day = 1; day <= 3; day++) {
      const { data: modules } = await supabase
        .from('training_modules')
        .select('id')
        .eq('day_number', day)
        .eq('is_active', true);

      const moduleIds = (modules || []).map(m => m.id);
      let completed = 0;

      if (moduleIds.length > 0) {
        const { data: progress } = await supabase
          .from('training_progress')
          .select('status')
          .eq('user_id', req.user.id)
          .in('module_id', moduleIds)
          .eq('status', 'completed');

        completed = progress?.length || 0;
      }

      dayProgress[day] = {
        total: moduleIds.length,
        completed,
        percentage: moduleIds.length > 0 ? Math.round((completed / moduleIds.length) * 100) : 0,
      };
    }

    res.json({
      success: true,
      data: {
        certification: (!certError && cert) ? cert : null,
        isCertified: (!userError && user) ? user.is_certified : false,
        certificationLevel: user?.certification_level || 'none',
        qualityScore: user?.quality_score || 0,
        warningCount: user?.warning_count || 0,
        dayProgress,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 분기별 재인증 필요 여부 확인
 */
exports.getRecertificationStatus = async (req, res, next) => {
  try {
    const { data: cert, error: certError } = await supabase
      .from('reviewer_certifications')
      .select('status, next_recertification, certification_date')
      .eq('user_id', req.user.id)
      .single();

    if (certError || !cert || cert.status !== 'certified') {
      return res.json({
        success: true,
        data: { needsRecertification: false, reason: 'not_certified' },
      });
    }

    const now = new Date();
    const nextRecert = cert.next_recertification ? new Date(cert.next_recertification) : null;
    const needsRecertification = nextRecert && nextRecert < now;
    const daysUntilRecert = nextRecert ? Math.ceil((nextRecert - now) / (1000 * 60 * 60 * 24)) : null;

    res.json({
      success: true,
      data: {
        needsRecertification,
        nextRecertificationDate: cert.next_recertification,
        daysUntilRecertification: daysUntilRecert,
        certificationDate: cert.certification_date,
      },
    });
  } catch (error) {
    next(error);
  }
};
