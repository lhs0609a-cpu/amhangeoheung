const bcrypt = require('bcryptjs');
const supabase = require('../config/supabase');
const { confirmPayment, cancelPayment, safeRollback, PAYMENT_STATUS } = require('../utils/tossPayments');
const { createErrorResponse, createPaymentErrorResponse } = require('../utils/errorMessages');

// 내 프로필 조회
exports.getMyProfile = async (req, res, next) => {
  try {
    res.json({
      success: true,
      data: {
        user: req.user
      }
    });
  } catch (error) {
    next(error);
  }
};

// 프로필 수정
exports.updateMyProfile = async (req, res, next) => {
  try {
    const allowedFields = ['name', 'nickname', 'profile_image'];
    const updates = {};

    allowedFields.forEach(field => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field];
      }
    });

    const { data: user, error } = await supabase
      .from('users')
      .update(updates)
      .eq('id', req.user.id)
      .select()
      .single();

    if (error) throw error;

    delete user.password;

    res.json({
      success: true,
      data: { user }
    });
  } catch (error) {
    next(error);
  }
};

// 프로필 이미지 업로드
exports.uploadAvatar = async (req, res, next) => {
  try {
    const { base64 } = req.body;

    if (!base64) {
      return res.status(400).json(
        createErrorResponse('UPLOAD_FAILED', { reason: '이미지가 필요합니다.' })
      );
    }

    const fileName = `avatars/${req.user.id}/${Date.now()}.jpg`;
    const buffer = Buffer.from(base64, 'base64');

    const { error: uploadError } = await supabase.storage
      .from('avatars')
      .upload(fileName, buffer, {
        contentType: 'image/jpeg',
        upsert: true
      });

    if (uploadError) {
      return res.status(500).json(
        createErrorResponse('UPLOAD_FAILED')
      );
    }

    const { data: urlData } = supabase.storage
      .from('avatars')
      .getPublicUrl(fileName);

    await supabase
      .from('users')
      .update({ profile_image: urlData.publicUrl })
      .eq('id', req.user.id);

    res.json({
      success: true,
      message: '프로필 이미지가 업로드되었습니다.',
      data: { imageUrl: urlData.publicUrl }
    });
  } catch (error) {
    next(error);
  }
};

// 비밀번호 변경
exports.changePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;

    const { data: user, error } = await supabase
      .from('users')
      .select('password')
      .eq('id', req.user.id)
      .single();

    if (error) throw error;

    const isMatch = await bcrypt.compare(currentPassword, user.password);

    if (!isMatch) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'INVALID_PASSWORD',
          message: '현재 비밀번호가 올바르지 않습니다.',
          guidance: ['비밀번호를 다시 확인해주세요.'],
          action: 'retry'
        }
      });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 12);

    const { error: updateError } = await supabase
      .from('users')
      .update({ password: hashedPassword })
      .eq('id', req.user.id);

    if (updateError) throw updateError;

    res.json({
      success: true,
      message: '비밀번호가 변경되었습니다.'
    });
  } catch (error) {
    next(error);
  }
};

// 알림 설정 변경
exports.updateNotificationSettings = async (req, res, next) => {
  try {
    const { push, email, sms } = req.body;

    const notifications = {
      push: push ?? req.user.notification_push ?? true,
      email: email ?? req.user.notification_email ?? true,
      sms: sms ?? req.user.notification_sms ?? true
    };

    const { error } = await supabase
      .from('users')
      .update({
        notification_push: notifications.push,
        notification_email: notifications.email,
        notification_sms: notifications.sms
      })
      .eq('id', req.user.id);

    if (error) throw error;

    res.json({
      success: true,
      data: { notifications }
    });
  } catch (error) {
    next(error);
  }
};

// 리뷰어 전환 신청
exports.becomeReviewer = async (req, res, next) => {
  try {
    if (req.user.user_type === 'reviewer') {
      return res.status(400).json({
        success: false,
        error: {
          code: 'ALREADY_REVIEWER',
          message: '이미 리뷰어입니다.',
          guidance: ['리뷰어 프로필에서 활동 현황을 확인해보세요.'],
          action: 'go_to_reviewer_profile'
        }
      });
    }

    if (req.user.user_type === 'business') {
      return res.status(400).json({
        success: false,
        error: {
          code: 'BUSINESS_CANNOT_BE_REVIEWER',
          message: '업체 계정은 리뷰어가 될 수 없습니다.',
          guidance: ['일반 계정으로 가입 후 리뷰어로 전환해주세요.'],
          action: 'go_back'
        }
      });
    }

    const { data: user, error } = await supabase
      .from('users')
      .update({
        user_type: 'reviewer',
        reviewer_grade: 'rookie',
        completed_missions: 0,
        trust_score: 0,
        specialties: []
      })
      .eq('id', req.user.id)
      .select()
      .single();

    if (error) throw error;

    res.json({
      success: true,
      message: '리뷰어로 전환되었습니다.',
      data: {
        reviewer: {
          grade: user.reviewer_grade,
          completedMissions: user.completed_missions,
          trustScore: user.trust_score,
          specialties: user.specialties
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

// 리뷰어 프로필 조회
exports.getReviewerProfile = async (req, res, next) => {
  try {
    res.json({
      success: true,
      data: {
        reviewer: {
          grade: req.user.reviewer_grade,
          completedMissions: req.user.completed_missions,
          trustScore: req.user.trust_score,
          specialties: req.user.specialties
        },
        isVerified: req.user.is_verified
      }
    });
  } catch (error) {
    next(error);
  }
};

// 정산 계좌 등록
exports.updateBankAccount = async (req, res, next) => {
  try {
    const { bank, accountNumber, accountHolder } = req.body;

    const { error } = await supabase
      .from('users')
      .update({
        bank_name: bank,
        bank_account_number: accountNumber,
        bank_account_holder: accountHolder
      })
      .eq('id', req.user.id);

    if (error) throw error;

    res.json({
      success: true,
      message: '정산 계좌가 등록되었습니다.'
    });
  } catch (error) {
    next(error);
  }
};

// 전문 카테고리 설정
exports.updateSpecialties = async (req, res, next) => {
  try {
    const { specialties } = req.body;

    if (!Array.isArray(specialties) || specialties.length > 5) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'INVALID_SPECIALTIES',
          message: '전문 카테고리는 최대 5개까지 선택할 수 있습니다.',
          guidance: ['5개 이하로 선택해주세요.'],
          action: 'retry'
        }
      });
    }

    const { error } = await supabase
      .from('users')
      .update({ specialties })
      .eq('id', req.user.id);

    if (error) throw error;

    res.json({
      success: true,
      data: { specialties }
    });
  } catch (error) {
    next(error);
  }
};

// 프리미엄 구독 (P0: 강화된 트랜잭션 롤백)
exports.subscribePremium = async (req, res, next) => {
  let paymentKey = null;
  let orderId = null;
  const transactionLog = {
    userId: req.user?.id,
    type: 'PREMIUM_SUBSCRIPTION',
    steps: [],
    startedAt: new Date().toISOString()
  };

  const logStep = (step, success, details = {}) => {
    transactionLog.steps.push({ step, success, timestamp: new Date().toISOString(), ...details });
    console.log(`[PREMIUM_PAYMENT] ${step}: ${success ? 'SUCCESS' : 'FAILED'}`, JSON.stringify(details));
  };

  try {
    const { plan = 'monthly' } = req.body;
    paymentKey = req.body.paymentKey;

    const prices = {
      monthly: 9900,
      yearly: 99000
    };

    if (!prices[plan]) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'INVALID_PLAN',
          message: '유효하지 않은 플랜입니다.',
          guidance: ['monthly 또는 yearly 중 선택해주세요.'],
          action: 'select_plan'
        }
      });
    }

    if (!paymentKey) {
      return res.status(400).json(
        createErrorResponse('PAYMENT_FAILED', { reason: '결제 정보가 필요합니다.' })
      );
    }

    // 이미 프리미엄인지 확인
    if (req.user.premium_active && new Date(req.user.premium_expires_at) > new Date()) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'ALREADY_PREMIUM',
          message: '이미 프리미엄 구독 중입니다.',
          guidance: [`현재 플랜: ${req.user.premium_plan}`, `만료일: ${new Date(req.user.premium_expires_at).toLocaleDateString()}`],
          action: 'go_to_settings'
        }
      });
    }

    orderId = `premium_${req.user.id}_${plan}_${Date.now()}`;
    transactionLog.orderId = orderId;
    transactionLog.paymentKey = paymentKey;
    transactionLog.plan = plan;
    transactionLog.amount = prices[plan];

    // Step 1: 토스페이먼츠 결제 승인
    let paymentResult;
    try {
      paymentResult = await confirmPayment(paymentKey, orderId, prices[plan]);
    } catch (paymentError) {
      logStep('PAYMENT_CONFIRM', false, { error: paymentError.message });
      return res.status(400).json(
        createPaymentErrorResponse(paymentError.message || '결제 승인에 실패했습니다.', false)
      );
    }

    if (paymentResult.status !== PAYMENT_STATUS.DONE) {
      logStep('PAYMENT_CONFIRM', false, { status: paymentResult.status });
      return res.status(400).json(
        createPaymentErrorResponse(`결제 상태 오류: ${paymentResult.status}`, false)
      );
    }

    logStep('PAYMENT_CONFIRM', true, { status: paymentResult.status, orderId });

    // Step 2: 사용자 프리미엄 상태 업데이트
    const expiresAt = new Date();
    if (plan === 'yearly') {
      expiresAt.setFullYear(expiresAt.getFullYear() + 1);
    } else {
      expiresAt.setMonth(expiresAt.getMonth() + 1);
    }

    const { data: updatedUser, error } = await supabase
      .from('users')
      .update({
        premium_active: true,
        premium_expires_at: expiresAt.toISOString(),
        premium_plan: plan
      })
      .eq('id', req.user.id)
      .select('id, premium_active, premium_expires_at, premium_plan')
      .single();

    if (error) {
      logStep('USER_UPDATE', false, { error: error.message });

      // 안전한 롤백 실행
      const rollbackResult = await safeRollback(paymentKey, 'DB 업데이트 실패로 인한 자동 취소', {
        userId: req.user.id,
        plan,
        step: 'USER_UPDATE'
      });

      if (!rollbackResult.success) {
        logStep('ROLLBACK', false, { error: rollbackResult.error, requiresManualIntervention: true });
        return res.status(500).json({
          success: false,
          error: {
            code: 'ROLLBACK_FAILED',
            message: '결제 처리 중 오류가 발생했습니다. 고객센터로 문의해주세요.',
            guidance: ['결제가 청구되었을 수 있습니다.', '영업일 기준 1-2일 내 자동 환불됩니다.'],
            action: 'contact_support',
            transactionId: paymentKey
          }
        });
      }

      logStep('ROLLBACK', true, { refunded: rollbackResult.refunded });
      return res.status(500).json(
        createPaymentErrorResponse('처리 중 오류가 발생했습니다. 결제가 취소되었습니다.', true)
      );
    }

    logStep('USER_UPDATE', true, { expiresAt: expiresAt.toISOString() });
    transactionLog.completedAt = new Date().toISOString();
    console.log('[PREMIUM_PAYMENT] Transaction completed successfully', JSON.stringify(transactionLog));

    res.json({
      success: true,
      message: '프리미엄 구독이 시작되었습니다.',
      data: {
        premium: {
          isActive: true,
          expiresAt,
          plan
        },
        payment: {
          orderId,
          amount: prices[plan],
          paidAt: new Date().toISOString()
        }
      }
    });
  } catch (error) {
    logStep('UNEXPECTED_ERROR', false, { error: error.message });

    // 예외 발생 시 결제 취소 시도
    if (paymentKey) {
      const rollbackResult = await safeRollback(paymentKey, '시스템 오류로 인한 자동 취소', {
        userId: req.user?.id,
        error: error.message
      });

      if (rollbackResult.success) {
        logStep('ROLLBACK', true, { refunded: rollbackResult.refunded });
        return res.status(500).json(
          createPaymentErrorResponse('처리 중 오류가 발생했습니다. 결제가 취소되었습니다.', true)
        );
      } else {
        logStep('ROLLBACK', false, { error: rollbackResult.error });
        return res.status(500).json({
          success: false,
          error: {
            code: 'ROLLBACK_FAILED',
            message: '결제 처리 중 오류가 발생했습니다. 고객센터로 문의해주세요.',
            guidance: ['결제가 청구되었을 수 있습니다.', '영업일 기준 1-2일 내 자동 환불됩니다.'],
            action: 'contact_support',
            transactionId: paymentKey
          }
        });
      }
    }
    next(error);
  }
};

// 프리미엄 해지
exports.cancelPremium = async (req, res, next) => {
  try {
    const { error } = await supabase
      .from('users')
      .update({ premium_active: false })
      .eq('id', req.user.id);

    if (error) throw error;

    res.json({
      success: true,
      message: '프리미엄 구독이 해지되었습니다. 남은 기간은 계속 이용 가능합니다.'
    });
  } catch (error) {
    next(error);
  }
};

// P0: 계정 삭제 (업체 소유자 체크 + 완전한 데이터 처리)
exports.deleteAccount = async (req, res, next) => {
  try {
    // 1. 리뷰어로서 진행 중인 미션 확인
    const { data: activeMissionsAsReviewer } = await supabase
      .from('missions')
      .select('id')
      .eq('assigned_reviewer_id', req.user.id)
      .in('status', ['assigned', 'in_progress']);

    if (activeMissionsAsReviewer && activeMissionsAsReviewer.length > 0) {
      return res.status(400).json(
        createErrorResponse('ACCOUNT_HAS_ACTIVE_MISSIONS', {
          activeMissionCount: activeMissionsAsReviewer.length
        })
      );
    }

    // 2. 미완료 에스크로 확인 (리뷰어)
    const { data: pendingEscrows } = await supabase
      .from('escrows')
      .select('id')
      .eq('reviewer_id', req.user.id)
      .in('status', ['paid', 'held']);

    if (pendingEscrows && pendingEscrows.length > 0) {
      return res.status(400).json(
        createErrorResponse('ACCOUNT_HAS_PENDING_PAYMENT')
      );
    }

    // P0: 3. 업체 소유자인 경우 추가 확인
    const { data: ownedBusinesses } = await supabase
      .from('businesses')
      .select('id, name')
      .eq('owner_id', req.user.id)
      .eq('status', 'active');

    if (ownedBusinesses && ownedBusinesses.length > 0) {
      // 업체에 진행 중인 미션이 있는지 확인
      const businessIds = ownedBusinesses.map(b => b.id);

      const { data: activeMissionsAsBusiness } = await supabase
        .from('missions')
        .select('id, business_id')
        .in('business_id', businessIds)
        .not('status', 'in', '("completed","cancelled")');

      if (activeMissionsAsBusiness && activeMissionsAsBusiness.length > 0) {
        return res.status(400).json(
          createErrorResponse('ACCOUNT_HAS_ACTIVE_BUSINESS', {
            businessCount: ownedBusinesses.length,
            activeMissionCount: activeMissionsAsBusiness.length,
            businesses: ownedBusinesses.map(b => b.name)
          })
        );
      }

      // 업체에 미정산 에스크로가 있는지 확인
      const { data: businessEscrows } = await supabase
        .from('escrows')
        .select('id')
        .in('business_id', businessIds)
        .in('status', ['paid', 'held']);

      if (businessEscrows && businessEscrows.length > 0) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'BUSINESS_HAS_PENDING_ESCROW',
            message: '운영 중인 업체에 처리되지 않은 결제가 있습니다.',
            guidance: [
              '모든 미션이 완료될 때까지 기다려주세요.',
              '환불이 필요한 경우 고객센터로 문의해주세요.'
            ],
            action: 'contact_support'
          }
        });
      }

      // 업체 비활성화 처리
      await supabase
        .from('businesses')
        .update({
          status: 'deleted',
          deleted_at: new Date().toISOString(),
          owner_id: null // 소유자 연결 해제
        })
        .in('id', businessIds);
    }

    // 4. 리뷰 익명화 처리
    await supabase
      .from('reviews')
      .update({
        reviewer_id: null,
        is_anonymous: true
      })
      .eq('reviewer_id', req.user.id);

    // 5. 미션 신청 내역 삭제
    await supabase
      .from('mission_applicants')
      .delete()
      .eq('reviewer_id', req.user.id);

    // 6. 투표 내역 삭제
    await supabase
      .from('review_votes')
      .delete()
      .eq('user_id', req.user.id);

    // 7. 신고 내역 삭제
    await supabase
      .from('review_reports')
      .delete()
      .eq('reporter_id', req.user.id);

    // 8. 리뷰 요청 삭제
    await supabase
      .from('review_requests')
      .delete()
      .eq('requester_id', req.user.id);

    // 9. 프로필 이미지 삭제
    if (req.user.profile_image) {
      try {
        const avatarPath = `avatars/${req.user.id}`;
        const { data: files } = await supabase.storage
          .from('avatars')
          .list(avatarPath);

        if (files && files.length > 0) {
          const filesToDelete = files.map(f => `${avatarPath}/${f.name}`);
          await supabase.storage.from('avatars').remove(filesToDelete);
        }
      } catch (storageError) {
        console.error('Avatar deletion error:', storageError);
      }
    }

    // 10. 사용자 삭제 (또는 소프트 삭제)
    const { error } = await supabase
      .from('users')
      .update({
        status: 'deleted',
        email: `deleted_${req.user.id}_${Date.now()}@deleted.local`,
        deleted_at: new Date().toISOString()
      })
      .eq('id', req.user.id);

    if (error) throw error;

    res.json({
      success: true,
      message: '계정이 삭제되었습니다. 그동안 이용해주셔서 감사합니다.'
    });
  } catch (error) {
    next(error);
  }
};

// 탈퇴 전 확인 (P0: 탈퇴 가능 여부 미리 체크)
exports.checkAccountDeletable = async (req, res, next) => {
  try {
    const issues = [];

    // 1. 리뷰어로서 진행 중인 미션
    const { data: activeMissions, count: missionCount } = await supabase
      .from('missions')
      .select('id', { count: 'exact' })
      .eq('assigned_reviewer_id', req.user.id)
      .in('status', ['assigned', 'in_progress']);

    if (missionCount > 0) {
      issues.push({
        type: 'active_missions',
        message: `진행 중인 미션이 ${missionCount}개 있습니다.`,
        action: '미션을 완료해주세요.'
      });
    }

    // 2. 미정산 금액
    const { data: pendingEscrows, count: escrowCount } = await supabase
      .from('escrows')
      .select('id, reviewer_fee', { count: 'exact' })
      .eq('reviewer_id', req.user.id)
      .in('status', ['paid', 'held']);

    if (escrowCount > 0) {
      const totalAmount = pendingEscrows.reduce((sum, e) => sum + (e.reviewer_fee || 0), 0);
      issues.push({
        type: 'pending_payment',
        message: `정산 대기 중인 금액이 ${totalAmount.toLocaleString()}원 있습니다.`,
        action: '정산 후 탈퇴해주세요.'
      });
    }

    // 3. 업체 소유
    const { data: businesses, count: businessCount } = await supabase
      .from('businesses')
      .select('id, name', { count: 'exact' })
      .eq('owner_id', req.user.id)
      .eq('status', 'active');

    if (businessCount > 0) {
      // 업체 미션 확인
      const businessIds = businesses.map(b => b.id);
      const { count: businessMissionCount } = await supabase
        .from('missions')
        .select('id', { count: 'exact' })
        .in('business_id', businessIds)
        .not('status', 'in', '("completed","cancelled")');

      if (businessMissionCount > 0) {
        issues.push({
          type: 'business_missions',
          message: `운영 중인 업체(${businesses.map(b => b.name).join(', ')})에 진행 중인 미션이 ${businessMissionCount}개 있습니다.`,
          action: '미션 완료 후 탈퇴해주세요.'
        });
      } else {
        issues.push({
          type: 'business_warning',
          message: `운영 중인 업체(${businesses.map(b => b.name).join(', ')})가 탈퇴 시 삭제됩니다.`,
          action: '확인',
          warning: true
        });
      }
    }

    const canDelete = issues.filter(i => !i.warning).length === 0;

    res.json({
      success: true,
      data: {
        canDelete,
        issues
      }
    });
  } catch (error) {
    next(error);
  }
};
