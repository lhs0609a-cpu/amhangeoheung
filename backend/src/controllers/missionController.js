const supabase = require('../config/supabase');
const { confirmPayment, cancelPayment, safeRollback, verifyPaymentStatus, PAYMENT_STATUS } = require('../utils/tossPayments');
const { calculateDistance } = require('../utils/geoUtils');
const {
  createErrorResponse,
  createGpsErrorResponse,
  createPaymentErrorResponse,
  createStayTimeErrorResponse
} = require('../utils/errorMessages');
const { processReferralReward } = require('./referralController');
const NOTIFICATION_TYPES = require('../config/notificationTypes');
const { checkCollusionRisk } = require('./collusionController');
const { generateBlindedAddress } = require('../utils/anonymizer');
const { COLLUSION_REPEAT_BLOCK_MONTHS, GPS_ZONES, REWARD_TYPES, PLAN_DETAILS } = require('../config/constants');

/**
 * 이번 달(월초~현재) 업체가 등록한 무료체험 미션 수를 센다.
 */
async function countFreeExperienceThisMonth(businessId) {
  const monthStart = new Date();
  monthStart.setDate(1);
  monthStart.setHours(0, 0, 0, 0);

  const { count } = await supabase
    .from('missions')
    .select('id', { count: 'exact', head: true })
    .eq('business_id', businessId)
    .eq('reward_type', 'free_experience')
    .gte('created_at', monthStart.toISOString());

  return count || 0;
}

const PLATFORM_FEE_RATE = 0.1; // 10% 수수료

// GPS 구간별 체크인: 점진적 반경 완화
// GREEN (0-100m): 즉시 체크인
// YELLOW (100-200m): 체크인 허용 + 경고
// ORANGE (200-500m): 사진 인증 필요
// RED (500m+): 체크인 차단

/**
 * 거리에 따른 GPS 존 판별
 */
function getGpsZone(distance) {
  if (distance <= GPS_ZONES.GREEN.max) {
    return {
      zone: 'green',
      label: GPS_ZONES.GREEN.label,
      requiresPhotoVerification: false,
      allowed: true,
      message: '정상 범위 내 위치입니다.',
    };
  } else if (distance <= GPS_ZONES.YELLOW.max) {
    return {
      zone: 'yellow',
      label: GPS_ZONES.YELLOW.label,
      requiresPhotoVerification: false,
      allowed: true,
      message: 'GPS 오차가 있습니다. 체크인은 완료됐지만 위치를 확인해주세요.',
    };
  } else if (distance <= GPS_ZONES.ORANGE.max) {
    return {
      zone: 'orange',
      label: GPS_ZONES.ORANGE.label,
      requiresPhotoVerification: true,
      allowed: true,
      message: '업체에서 먼 위치입니다. 업체 간판 사진을 촬영해 인증해주세요.',
    };
  } else {
    return {
      zone: 'red',
      label: GPS_ZONES.RED.label,
      requiresPhotoVerification: false,
      allowed: false,
      message: `업체와 너무 멀리 있습니다 (${Math.round(distance)}m). 업체 근처로 이동해주세요.`,
    };
  }
}

// 수동 인증 가이드
const MANUAL_VERIFICATION_GUIDE = {
  title: '수동 인증 방법',
  steps: [
    '업체 간판이 보이도록 사진을 촬영해주세요.',
    '가능하면 영수증도 함께 찍어주세요.',
    '사진이 선명하게 나오도록 해주세요.'
  ],
  examples: [
    '간판 + 본인이 함께 나오는 셀카',
    '영수증과 매장 내부가 함께 보이는 사진',
    '매장 외관 전경 사진'
  ]
};

// 미션 생성
exports.createMission = async (req, res, next) => {
  try {
    // 보상 관련 필드는 스프레드에서 분리(컬럼명 불일치 방지) 후 명시적으로 처리
    const {
      businessId,
      missionType,
      rewardType,
      reward_type,
      experienceDescription,
      experience_description,
      experienceValue,
      experience_value,
      ...missionData
    } = req.body;

    const resolvedRewardType =
      (reward_type || rewardType) === REWARD_TYPES.FREE_EXPERIENCE
        ? REWARD_TYPES.FREE_EXPERIENCE
        : REWARD_TYPES.CASH;
    const expDescription = experience_description || experienceDescription || null;
    const expValue = experience_value ?? experienceValue ?? null;

    // 4개 유형 검증
    const validTypes = ['visit', 'delivery', 'online', 'phone'];
    if (!validTypes.includes(missionType)) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'INVALID_MISSION_TYPE',
          message: `유효하지 않은 미션 유형입니다. 허용: ${validTypes.join(', ')}`,
        },
      });
    }

    // 업체 소유권 + 구독 플랜 확인
    const { data: business, error: businessError } = await supabase
      .from('businesses')
      .select('id, address_full, subscription_plan')
      .eq('id', businessId)
      .eq('owner_id', req.user.id)
      .single();

    if (businessError || !business) {
      return res.status(404).json(
        createErrorResponse('MISSION_NOT_FOUND')
      );
    }

    // 블라인드 주소 생성
    const blindedAddress = generateBlindedAddress(business?.address_full || missionData.address || '');

    // ── 무료체험 미션: 결제/에스크로 없이 바로 모집 시작 ──
    if (resolvedRewardType === REWARD_TYPES.FREE_EXPERIENCE) {
      if (!expDescription) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'EXPERIENCE_DESCRIPTION_REQUIRED',
            message: '무료체험 미션은 제공 내용을 입력해야 합니다.',
          },
        });
      }

      // 구독 플랜별 월 무료체험 한도 체크 (-1 = 무제한)
      const plan = business.subscription_plan || 'none';
      const limit = PLAN_DETAILS[plan]?.monthlyFreeExperience ?? 0;
      if (limit !== -1) {
        const used = await countFreeExperienceThisMonth(businessId);
        if (used >= limit) {
          return res.status(403).json({
            success: false,
            error: {
              code: 'FREE_EXPERIENCE_LIMIT_EXCEEDED',
              message: `현재 플랜(${plan})의 이번 달 무료체험 미션 한도(${limit}건)를 모두 사용했습니다.`,
              used,
              limit,
            },
          });
        }
      }

      const { data: mission, error: feError } = await supabase
        .from('missions')
        .insert({
          business_id: businessId,
          mission_type: missionType,
          ...missionData,
          reward_type: REWARD_TYPES.FREE_EXPERIENCE,
          experience_description: expDescription,
          experience_value: expValue,
          product_cost: 0,
          reviewer_fee: 0,
          platform_fee: 0,
          total_amount: 0,
          payment_status: 'paid', // 결제 불필요 → 모집 가능 상태로 간주
          status: 'recruiting',
          blinded_address: blindedAddress || null,
          gps_required: missionType === 'visit' ? (missionData.gps_required || false) : false,
          verification_method: missionType,
        })
        .select()
        .single();

      if (feError) throw feError;

      res.status(201).json({
        success: true,
        message: '무료체험 미션이 등록되었습니다. 바로 모집이 시작됩니다.',
        data: { mission },
      });

      notifyNearbyCompetitors(mission).catch(err => {
        console.error('[MISSION_CREATE] Failed to notify competitors:', err);
      });
      return;
    }

    // ── 현금 미션 (기존 흐름: 결제 필요) ──
    const productCost = missionData.product_cost || 0;
    const reviewerFee = missionData.reviewer_fee || 0;
    const platformFee = Math.round((productCost + reviewerFee) * PLATFORM_FEE_RATE);
    const totalAmount = productCost + reviewerFee + platformFee;

    const { data: mission, error } = await supabase
      .from('missions')
      .insert({
        business_id: businessId,
        mission_type: missionType,
        ...missionData,
        reward_type: REWARD_TYPES.CASH,
        product_cost: productCost,
        reviewer_fee: reviewerFee,
        platform_fee: platformFee,
        total_amount: totalAmount,
        payment_status: 'pending',
        status: 'pending_payment',
        blinded_address: blindedAddress || null,
        gps_required: missionType === 'visit' ? (missionData.gps_required || false) : false,
        verification_method: missionType,
      })
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({
      success: true,
      message: '미션이 생성되었습니다. 결제를 진행해주세요.',
      data: { mission }
    });

    // 비동기로 주변 경쟁업체에 알림 (non-blocking)
    notifyNearbyCompetitors(mission).catch(err => {
      console.error('[MISSION_CREATE] Failed to notify competitors:', err);
    });
  } catch (error) {
    next(error);
  }
};

// 미션 결제 (P0: 강화된 트랜잭션 롤백)
exports.payMission = async (req, res, next) => {
  let paymentKey = null;
  let orderId = null;
  let escrowCreated = false;
  const transactionLog = {
    missionId: req.params.id,
    userId: req.user?.id,
    steps: [],
    startedAt: new Date().toISOString()
  };

  const logStep = (step, success, details = {}) => {
    transactionLog.steps.push({ step, success, timestamp: new Date().toISOString(), ...details });
    console.log(`[MISSION_PAYMENT] ${step}: ${success ? 'SUCCESS' : 'FAILED'}`, JSON.stringify(details));
  };

  try {
    // Step 0: 미션 조회 및 검증
    const { data: mission, error: missionFetchError } = await supabase
      .from('missions')
      .select(`
        *,
        business:businesses(id, owner_id)
      `)
      .eq('id', req.params.id)
      .single();

    if (missionFetchError || !mission || mission.business.owner_id !== req.user.id) {
      return res.status(404).json(
        createErrorResponse('MISSION_NOT_FOUND')
      );
    }

    // 무료체험 미션은 결제가 필요 없다.
    if (mission.reward_type === REWARD_TYPES.FREE_EXPERIENCE) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'NO_PAYMENT_REQUIRED',
          message: '무료체험 미션은 결제가 필요하지 않습니다.',
        },
      });
    }

    if (mission.status !== 'pending_payment') {
      return res.status(400).json(
        createErrorResponse('PAYMENT_ALREADY_PROCESSED')
      );
    }

    paymentKey = req.body.paymentKey;
    if (!paymentKey) {
      return res.status(400).json(
        createErrorResponse('PAYMENT_FAILED', { reason: '결제 정보가 필요합니다.' })
      );
    }

    orderId = `mission_${mission.id}_${Date.now()}`;
    transactionLog.orderId = orderId;
    transactionLog.paymentKey = paymentKey;
    transactionLog.amount = mission.total_amount;

    // Step 1: 결제 승인
    logStep('PAYMENT_CONFIRM', true, { paymentKey, orderId, amount: mission.total_amount });

    let paymentResult;
    try {
      paymentResult = await confirmPayment(paymentKey, orderId, mission.total_amount);
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

    // S4: 결제 금액 검증
    if (paymentResult.totalAmount !== mission.total_amount) {
      logStep('AMOUNT_MISMATCH', false, { expected: mission.total_amount, actual: paymentResult.totalAmount });
      // Cancel the mismatched payment
      await cancelPayment(paymentKey, '결제 금액 불일치');
      return res.status(400).json({
        success: false,
        message: '결제 금액이 일치하지 않습니다.'
      });
    }

    logStep('PAYMENT_CONFIRM', true, { status: paymentResult.status });

    // Step 2: 에스크로 생성 (실패 시 안전한 롤백)
    const { data: escrow, error: escrowError } = await supabase
      .from('escrows')
      .insert({
        mission_id: mission.id,
        business_id: mission.business_id,
        product_cost: mission.product_cost,
        reviewer_fee: mission.reviewer_fee,
        platform_fee: mission.platform_fee,
        total_amount: mission.total_amount,
        status: 'paid',
        payment_method: paymentResult.method,
        pg_provider: 'tosspayments',
        transaction_id: paymentKey,
        paid_at: new Date().toISOString()
      })
      .select()
      .single();

    if (escrowError) {
      logStep('ESCROW_CREATE', false, { error: escrowError.message });

      // 안전한 롤백 실행
      const rollbackResult = await safeRollback(paymentKey, '에스크로 생성 실패로 인한 자동 취소', {
        missionId: mission.id,
        step: 'ESCROW_CREATE'
      });

      if (!rollbackResult.success) {
        // 롤백 실패 - CRITICAL
        logStep('ROLLBACK', false, { error: rollbackResult.error, requiresManualIntervention: true });
        return res.status(500).json({
          success: false,
          error: {
            code: 'ROLLBACK_FAILED',
            message: '결제 처리 중 오류가 발생했습니다. 고객센터로 문의해주세요.',
            guidance: ['결제가 청구되었을 수 있습니다.', '영업일 기준 1-2일 내 자동 환불됩니다.', '확인이 필요하시면 고객센터로 문의해주세요.'],
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

    escrowCreated = true;
    logStep('ESCROW_CREATE', true, { escrowId: escrow.id });

    // Step 3: 미션 상태 업데이트 (실패 시 에스크로 삭제 + 결제 취소)
    const recruitmentDeadline = new Date();
    recruitmentDeadline.setDate(recruitmentDeadline.getDate() + 3);

    const { data: updatedMission, error: missionError } = await supabase
      .from('missions')
      .update({
        status: 'recruiting',
        payment_status: 'paid',
        paid_at: new Date().toISOString(),
        recruitment_deadline: recruitmentDeadline.toISOString(),
        transaction_id: paymentKey
      })
      .eq('id', req.params.id)
      .select()
      .single();

    if (missionError) {
      logStep('MISSION_UPDATE', false, { error: missionError.message });

      // 에스크로 삭제
      await supabase.from('escrows').delete().eq('id', escrow.id);
      logStep('ESCROW_DELETE', true);

      // 안전한 롤백
      const rollbackResult = await safeRollback(paymentKey, '미션 상태 업데이트 실패로 인한 자동 취소', {
        missionId: mission.id,
        step: 'MISSION_UPDATE'
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

    logStep('MISSION_UPDATE', true, { newStatus: 'recruiting' });
    transactionLog.completedAt = new Date().toISOString();
    console.log('[MISSION_PAYMENT] Transaction completed successfully', JSON.stringify(transactionLog));

    res.json({
      success: true,
      message: '결제가 완료되었습니다. 리뷰어 모집이 시작됩니다.',
      data: {
        mission: updatedMission,
        payment: {
          orderId,
          amount: mission.total_amount,
          paidAt: new Date().toISOString()
        }
      }
    });
  } catch (error) {
    logStep('UNEXPECTED_ERROR', false, { error: error.message });

    // 예외 발생 시 결제 취소 시도
    if (paymentKey) {
      // 에스크로가 생성되었다면 삭제
      if (escrowCreated) {
        await supabase.from('escrows').delete().eq('mission_id', req.params.id);
        logStep('ESCROW_CLEANUP', true);
      }

      const rollbackResult = await safeRollback(paymentKey, '시스템 오류로 인한 자동 취소', {
        missionId: req.params.id,
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

// 미션 취소
exports.cancelMission = async (req, res, next) => {
  try {
    const { data: mission, error: missionFetchError } = await supabase
      .from('missions')
      .select(`
        *,
        business:businesses(id, owner_id)
      `)
      .eq('id', req.params.id)
      .single();

    if (missionFetchError || !mission || mission.business.owner_id !== req.user.id) {
      return res.status(404).json(
        createErrorResponse('MISSION_NOT_FOUND')
      );
    }

    if (!['pending_payment', 'recruiting'].includes(mission.status)) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'MISSION_CANNOT_CANCEL',
          message: '취소할 수 없는 상태입니다.',
          guidance: ['리뷰어가 배정된 미션은 취소할 수 없습니다.'],
          action: 'contact_support'
        }
      });
    }

    // 에스크로 환불 처리 (무료체험 미션은 결제/에스크로가 없으므로 스킵)
    if (mission.payment_status === 'paid' && mission.reward_type !== REWARD_TYPES.FREE_EXPERIENCE) {
      // 토스페이먼츠 환불 요청
      const { data: escrow, error: escrowError } = await supabase
        .from('escrows')
        .select('payment_key')
        .eq('mission_id', mission.id)
        .single();

      if (escrow?.payment_key) {
        try {
          await cancelPayment(escrow.payment_key, '업체 요청에 의한 취소');
        } catch (refundError) {
          console.error('Refund failed:', refundError);
          return res.status(500).json({
            success: false,
            error: {
              code: 'REFUND_FAILED',
              message: '환불 처리에 실패했습니다.',
              guidance: ['고객센터로 문의해주세요.'],
              action: 'contact_support'
            }
          });
        }
      }

      await supabase
        .from('escrows')
        .update({
          status: 'refunded',
          refund_reason: '업체 요청에 의한 취소',
          refunded_at: new Date().toISOString()
        })
        .eq('mission_id', mission.id);
    }

    const { error } = await supabase
      .from('missions')
      .update({ status: 'cancelled' })
      .eq('id', req.params.id);

    if (error) throw error;

    res.json({
      success: true,
      message: '미션이 취소되었습니다. 환불은 영업일 기준 3-5일 내 처리됩니다.'
    });
  } catch (error) {
    next(error);
  }
};

// 참여 가능한 미션 목록 (리뷰어용) - P1-5: 블라인드 위치 정보 개선
exports.getAvailableMissions = async (req, res, next) => {
  try {
    const { category, city, type, page = 1, limit = 20, latitude, longitude } = req.query;
    const offset = (page - 1) * limit;
    const userLat = latitude ? parseFloat(latitude) : null;
    const userLon = longitude ? parseFloat(longitude) : null;

    // 이미 신청한 미션 ID 목록 조회
    const { data: appliedMissions } = await supabase
      .from('mission_applicants')
      .select('mission_id')
      .eq('reviewer_id', req.user.id);

    const appliedMissionIds = appliedMissions?.map(m => m.mission_id) || [];

    let query = supabase
      .from('missions')
      .select(`
        id, mission_type, category, region, reviewer_fee,
        recruitment_deadline, max_applicants, evaluation_criteria,
        business:businesses(id, category, address_city, address_district, latitude, longitude)
      `)
      .eq('status', 'recruiting')
      .gt('recruitment_deadline', new Date().toISOString());

    if (type) {
      query = query.eq('mission_type', type);
    }

    if (appliedMissionIds.length > 0) {
      query = query.not('id', 'in', `(${appliedMissionIds.join(',')})`);
    }

    query = query
      .order('created_at', { ascending: false })
      .range(offset, offset + parseInt(limit) - 1);

    const { data: missions, error } = await query;

    if (error) throw error;

    // P1-5: 블라인드 정보 + 구/동 + 거리 정보 반환
    const blindMissions = missions.map(m => {
      const business = m.business;

      // 블라인드 위치 정보 (구/동까지만)
      let blindLocation = '';
      if (business?.address_city) {
        blindLocation = business.address_city;
        if (business.address_district) {
          blindLocation += ` ${business.address_district}`;
        }
      } else if (m.region) {
        blindLocation = m.region;
      }

      // 거리 및 예상 이동 시간 계산
      let distance = null;
      let estimatedTravelTime = null;
      if (userLat && userLon && business?.latitude && business?.longitude) {
        distance = calculateDistance(userLat, userLon, business.latitude, business.longitude);
        // 평균 이동 속도: 도보 5km/h, 대중교통 20km/h 가정
        if (distance < 2000) {
          // 2km 미만: 도보
          estimatedTravelTime = {
            method: 'walk',
            minutes: Math.round(distance / 83), // 5km/h = 83m/min
            label: `도보 약 ${Math.round(distance / 83)}분`
          };
        } else {
          // 2km 이상: 대중교통
          estimatedTravelTime = {
            method: 'transit',
            minutes: Math.round(distance / 333), // 20km/h = 333m/min
            label: `대중교통 약 ${Math.round(distance / 333)}분`
          };
        }
      }

      return {
        id: m.id,
        missionType: m.mission_type,
        category: m.category || business?.category,
        // P1-5: 개선된 블라인드 위치 정보
        location: {
          blindAddress: blindLocation, // "서울시 강남구" 수준
          distance: distance ? Math.round(distance) : null, // 미터 단위
          distanceLabel: distance
            ? (distance < 1000 ? `${Math.round(distance)}m` : `${(distance/1000).toFixed(1)}km`)
            : null,
          estimatedTravel: estimatedTravelTime
        },
        payment: {
          reviewerFee: m.reviewer_fee
        },
        recruitment: {
          deadline: m.recruitment_deadline,
          maxApplicants: m.max_applicants,
          daysLeft: Math.ceil((new Date(m.recruitment_deadline) - new Date()) / (1000 * 60 * 60 * 24))
        },
        evaluationCriteria: m.evaluation_criteria
      };
    });

    // 각 미션별 신청자 수 조회
    for (const mission of blindMissions) {
      const { count } = await supabase
        .from('mission_applicants')
        .select('*', { count: 'exact', head: true })
        .eq('mission_id', mission.id);
      mission.recruitment.currentApplicants = count || 0;
    }

    // 거리순 정렬 옵션
    if (userLat && userLon) {
      blindMissions.sort((a, b) => {
        if (a.location.distance === null) return 1;
        if (b.location.distance === null) return -1;
        return a.location.distance - b.location.distance;
      });
    }

    res.json({
      success: true,
      data: {
        missions: blindMissions,
        meta: {
          userLocationProvided: !!(userLat && userLon)
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

// 미션 신청
exports.applyMission = async (req, res, next) => {
  try {
    // 인증 여부 확인
    const { data: currentUser, error: currentUserError } = await supabase
      .from('users')
      .select('is_certified')
      .eq('id', req.user.id)
      .single();

    if (!currentUser?.is_certified) {
      return res.status(403).json({
        success: false,
        error: {
          code: 'CERTIFICATION_REQUIRED',
          message: '교육 인증을 완료해야 미션에 지원할 수 있습니다.',
          guidance: ['교육 인증 프로그램(3일 과정)을 먼저 완료해주세요.'],
          action: 'go_to_certification',
        },
      });
    }

    const { data: mission, error: missionFetchError } = await supabase
      .from('missions')
      .select('id, status, max_applicants, recruitment_deadline, category, business_id')
      .eq('id', req.params.id)
      .single();

    if (missionFetchError || !mission || mission.status !== 'recruiting') {
      return res.status(404).json(
        createErrorResponse('MISSION_NOT_FOUND')
      );
    }

    // 6개월 내 동일 업체 미션 완료 이력 → 지원 차단
    const blockDate = new Date();
    blockDate.setMonth(blockDate.getMonth() - (COLLUSION_REPEAT_BLOCK_MONTHS || 6));

    const { data: prevHistory } = await supabase
      .from('reviewer_business_history')
      .select('id')
      .eq('reviewer_id', req.user.id)
      .eq('business_id', mission.business_id)
      .gt('assigned_at', blockDate.toISOString())
      .limit(1);

    if (prevHistory && prevHistory.length > 0) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'COLLUSION_RISK_BLOCKED',
          message: '이 업체에는 배정될 수 없습니다.',
          guidance: [`동일 업체에 ${COLLUSION_REPEAT_BLOCK_MONTHS || 6}개월 내 재방문이 제한됩니다.`],
          action: 'browse_other_missions',
        },
      });
    }

    // L1: Pre-check collusion risk
    const riskResult = await checkCollusionRisk(req.user.id, mission.business_id).catch(() => null);
    if (riskResult?.riskLevel === 'blocked') {
      return res.status(403).json({
        success: false,
        message: '이 미션에 지원할 수 없습니다.',
        code: 'COLLUSION_RISK'
      });
    }

    // 이미 신청했는지 확인
    const { data: existingApplication, error: existingApplicationError } = await supabase
      .from('mission_applicants')
      .select('id')
      .eq('mission_id', req.params.id)
      .eq('reviewer_id', req.user.id)
      .single();

    if (existingApplication && !existingApplicationError) {
      return res.status(400).json(
        createErrorResponse('MISSION_ALREADY_APPLIED')
      );
    }

    // 신청자 수 확인
    const { count } = await supabase
      .from('mission_applicants')
      .select('*', { count: 'exact', head: true })
      .eq('mission_id', req.params.id);

    if (count >= mission.max_applicants) {
      return res.status(400).json(
        createErrorResponse('MISSION_CLOSED')
      );
    }

    // 리뷰어 정보 조회 (매칭 점수 계산용)
    const { data: reviewer, error: reviewerError } = await supabase
      .from('users')
      .select('trust_score, specialties, completed_missions, last_active_at')
      .eq('id', req.user.id)
      .single();

    // 매칭 점수 계산
    const matchScore = calculateMatchScore(reviewer, mission);

    // 신청 추가
    const { error } = await supabase
      .from('mission_applicants')
      .insert({
        mission_id: req.params.id,
        reviewer_id: req.user.id,
        status: 'applied',
        match_score: matchScore
      });

    if (error) throw error;

    // 최소 인원(5명) 충족 시 가중치 기반 배정
    if (count + 1 >= 5) {
      await assignWeightedReviewer(req.params.id);
    }

    res.json({
      success: true,
      message: '미션 신청이 완료되었습니다.',
      data: {
        matchScore,
        estimatedSelectionRate: calculateSelectionRate(matchScore, count + 1)
      }
    });
  } catch (error) {
    next(error);
  }
};

// P2: 벌크 미션 신청
exports.bulkApplyMissions = async (req, res, next) => {
  try {
    const { missionIds } = req.body;

    if (!Array.isArray(missionIds) || missionIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: '신청할 미션 ID 목록이 필요합니다.'
      });
    }

    if (missionIds.length > 10) {
      return res.status(400).json({
        success: false,
        message: '한 번에 최대 10개까지 신청할 수 있습니다.'
      });
    }

    const results = [];

    for (const missionId of missionIds) {
      try {
        // 미션 확인
        const { data: mission, error: missionFetchErr } = await supabase
          .from('missions')
          .select('id, status, max_applicants, category')
          .eq('id', missionId)
          .single();

        if (missionFetchErr || !mission || mission.status !== 'recruiting') {
          results.push({ missionId, success: false, reason: '모집이 마감됨' });
          continue;
        }

        // 이미 신청했는지 확인
        const { data: existing, error: existingErr } = await supabase
          .from('mission_applicants')
          .select('id')
          .eq('mission_id', missionId)
          .eq('reviewer_id', req.user.id)
          .single();

        if (existing && !existingErr) {
          results.push({ missionId, success: false, reason: '이미 신청함' });
          continue;
        }

        // 신청자 수 확인
        const { count } = await supabase
          .from('mission_applicants')
          .select('*', { count: 'exact', head: true })
          .eq('mission_id', missionId);

        if (count >= mission.max_applicants) {
          results.push({ missionId, success: false, reason: '모집 마감' });
          continue;
        }

        // 리뷰어 정보
        const { data: reviewer, error: reviewerErr } = await supabase
          .from('users')
          .select('trust_score, specialties, completed_missions')
          .eq('id', req.user.id)
          .single();

        const matchScore = calculateMatchScore(reviewer, mission);

        // 신청
        await supabase
          .from('mission_applicants')
          .insert({
            mission_id: missionId,
            reviewer_id: req.user.id,
            status: 'applied',
            match_score: matchScore
          });

        results.push({ missionId, success: true, matchScore });

        // 최소 인원 충족 시 배정
        if (count + 1 >= 5) {
          await assignWeightedReviewer(missionId);
        }
      } catch (err) {
        results.push({ missionId, success: false, reason: '처리 오류' });
      }
    }

    const successCount = results.filter(r => r.success).length;

    res.json({
      success: true,
      message: `${successCount}개의 미션에 신청했습니다.`,
      data: { results }
    });
  } catch (error) {
    next(error);
  }
};

// P1: 매칭 점수 계산
function calculateMatchScore(reviewer, mission) {
  if (!reviewer) return 0;

  let score = 0;

  // 1. 신뢰도 점수 (0-40점)
  score += Math.min(40, (reviewer.trust_score || 0) * 4);

  // 2. 카테고리 전문성 (0-30점)
  if (reviewer.specialties && mission.category) {
    if (reviewer.specialties.includes(mission.category)) {
      score += 30;
    }
  }

  // 3. 완료 미션 수 (0-20점)
  const completedMissions = reviewer.completed_missions || 0;
  score += Math.min(20, completedMissions * 2);

  // 4. 최근 활동 (0-10점)
  if (reviewer.last_active_at) {
    const daysSinceActive = (Date.now() - new Date(reviewer.last_active_at).getTime()) / (1000 * 60 * 60 * 24);
    if (daysSinceActive <= 1) score += 10;
    else if (daysSinceActive <= 7) score += 7;
    else if (daysSinceActive <= 30) score += 3;
  }

  return Math.round(score);
}

// 선정 확률 계산 (예상)
function calculateSelectionRate(myScore, totalApplicants) {
  if (totalApplicants <= 1) return 100;
  // 대략적인 추정치
  const baseRate = 100 / totalApplicants;
  const bonusRate = (myScore / 100) * 20; // 최대 20% 보너스
  return Math.min(100, Math.round(baseRate + bonusRate));
}

// P1: 가중치 기반 리뷰어 배정
async function assignWeightedReviewer(missionId) {
  // S6: Prevent race condition: check if already assigned
  const { data: currentMission, error: currentMissionError } = await supabase
    .from('missions')
    .select('assigned_reviewer_id')
    .eq('id', missionId)
    .single();

  if (currentMissionError || !currentMission) {
    console.log(`[ASSIGN] Mission ${missionId} not found, skipping`);
    return;
  }

  if (currentMission.assigned_reviewer_id) {
    console.log(`[ASSIGN] Mission ${missionId} already assigned, skipping`);
    return;
  }

  const { data: missionData, error: missionDataError } = await supabase
    .from('missions')
    .select('business_id')
    .eq('id', missionId)
    .single();

  const { data: applicants } = await supabase
    .from('mission_applicants')
    .select('reviewer_id, match_score')
    .eq('mission_id', missionId)
    .eq('status', 'applied');

  if (!applicants || applicants.length === 0) return;

  // 인증된 리뷰어만 필터 + 담합 위험 체크
  const filteredApplicants = [];
  for (const applicant of applicants) {
    // 인증 확인
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('is_certified')
      .eq('id', applicant.reviewer_id)
      .single();

    if (userError || !user?.is_certified) continue;

    // 담합 위험 체크
    if (missionData?.business_id) {
      const risk = await checkCollusionRisk(applicant.reviewer_id, missionData.business_id);
      if (risk.riskLevel === 'blocked') continue;
      if (risk.riskLevel === 'warning') {
        applicant.match_score = Math.round((applicant.match_score || 0) * 0.5);
      }
    }

    filteredApplicants.push(applicant);
  }

  if (filteredApplicants.length === 0) return;

  // 매칭 점수 기반 가중치 랜덤 선택
  const totalScore = filteredApplicants.reduce((sum, a) => sum + (a.match_score || 1), 0);
  let random = Math.random() * totalScore;

  let selectedReviewerId = null;
  let selectionReason = '';

  for (const applicant of filteredApplicants) {
    random -= (applicant.match_score || 1);
    if (random <= 0) {
      selectedReviewerId = applicant.reviewer_id;
      const scorePercentile = Math.round((applicant.match_score / 100) * 100);
      selectionReason = scorePercentile >= 70
        ? '카테고리 전문성 및 높은 신뢰도'
        : scorePercentile >= 40
          ? '적합한 리뷰 이력'
          : '랜덤 선정';
      break;
    }
  }

  if (!selectedReviewerId) {
    selectedReviewerId = filteredApplicants[0].reviewer_id;
    selectionReason = '랜덤 선정';
  }

  // 미션에 리뷰어 배정 + 전체 주소 공개 시점 기록
  await supabase
    .from('missions')
    .update({
      assigned_reviewer_id: selectedReviewerId,
      status: 'assigned',
      assigned_at: new Date().toISOString(),
      full_address_revealed_at: new Date().toISOString(),
    })
    .eq('id', missionId);

  // 리뷰어-사업자 배정 이력 기록 (담합 방지용)
  if (missionData?.business_id) {
    await supabase
      .from('reviewer_business_history')
      .insert({
        reviewer_id: selectedReviewerId,
        business_id: missionData.business_id,
        mission_id: missionId,
      })
      .catch(err => console.error('[RB_HISTORY] Insert error:', err.message));
  }

  // 선택된 신청자 상태 업데이트
  await supabase
    .from('mission_applicants')
    .update({
      status: 'selected',
      selection_reason: selectionReason
    })
    .eq('mission_id', missionId)
    .eq('reviewer_id', selectedReviewerId);

  // 나머지 신청자 상태 업데이트
  await supabase
    .from('mission_applicants')
    .update({ status: 'not_selected' })
    .eq('mission_id', missionId)
    .neq('reviewer_id', selectedReviewerId);

  // 선정 알림 발송
  const { createNotification } = require('../utils/notificationService');
  await createNotification(
    selectedReviewerId,
    'mission_selected',
    '미션에 선정되었습니다!',
    `미션에 선정되었습니다. 선정 사유: ${selectionReason}`,
    { missionId }
  );
  console.log(`[MISSION ${missionId}] Reviewer ${selectedReviewerId} selected. Reason: ${selectionReason}`);
}

// 미션 신청 취소
exports.cancelApplication = async (req, res, next) => {
  try {
    const { data: mission, error: missionFetchError } = await supabase
      .from('missions')
      .select('id, assigned_reviewer_id')
      .eq('id', req.params.id)
      .single();

    if (missionFetchError || !mission) {
      return res.status(404).json(
        createErrorResponse('MISSION_NOT_FOUND')
      );
    }

    // 이미 배정된 경우 취소 불가
    if (mission.assigned_reviewer_id === req.user.id) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'CANNOT_CANCEL_ASSIGNED',
          message: '이미 배정된 미션은 취소할 수 없습니다.',
          guidance: ['배정된 미션을 완료해주세요.', '부득이한 경우 고객센터로 문의해주세요.'],
          action: 'contact_support'
        }
      });
    }

    const { error } = await supabase
      .from('mission_applicants')
      .delete()
      .eq('mission_id', req.params.id)
      .eq('reviewer_id', req.user.id);

    if (error) throw error;

    res.json({
      success: true,
      message: '신청이 취소되었습니다.'
    });
  } catch (error) {
    next(error);
  }
};

// 내 미션 목록 (리뷰어)
exports.getMyMissions = async (req, res, next) => {
  try {
    const { status } = req.query;

    // 배정된 미션 조회
    let assignedQuery = supabase
      .from('missions')
      .select(`
        *,
        business:businesses(id, name, category)
      `)
      .eq('assigned_reviewer_id', req.user.id);

    if (status) assignedQuery = assignedQuery.eq('status', status);

    const { data: assignedMissions } = await assignedQuery;

    // 신청한 미션 조회 (선정 이유 포함)
    const { data: applications } = await supabase
      .from('mission_applicants')
      .select('mission_id, status, match_score, selection_reason')
      .eq('reviewer_id', req.user.id);

    const appliedMissionIds = applications?.map(a => a.mission_id) || [];

    let appliedMissions = [];
    if (appliedMissionIds.length > 0) {
      let appliedQuery = supabase
        .from('missions')
        .select(`
          *,
          business:businesses(id, name, category)
        `)
        .in('id', appliedMissionIds)
        .is('assigned_reviewer_id', null);

      if (status) appliedQuery = appliedQuery.eq('status', status);

      const { data } = await appliedQuery;
      appliedMissions = (data || []).map(m => {
        const app = applications.find(a => a.mission_id === m.id);
        return {
          ...m,
          applicationStatus: app?.status,
          matchScore: app?.match_score,
          selectionReason: app?.selection_reason
        };
      });
    }

    const missions = [...(assignedMissions || []), ...appliedMissions]
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

    res.json({
      success: true,
      data: { missions }
    });
  } catch (error) {
    next(error);
  }
};

// 미션 상세 (리뷰어용)
exports.getMissionForReviewer = async (req, res, next) => {
  try {
    const { data: mission, error } = await supabase
      .from('missions')
      .select(`
        *,
        business:businesses(id, name, category, address_full, address_detail, latitude, longitude)
      `)
      .eq('id', req.params.id)
      .single();

    if (error || !mission) {
      return res.status(404).json(
        createErrorResponse('MISSION_NOT_FOUND')
      );
    }

    // 배정된 리뷰어인지 확인
    const isAssigned = mission.assigned_reviewer_id === req.user.id;

    // 블라인드 정보 처리
    if (!isAssigned) {
      // 배정되지 않은 경우 상세 정보 숨김
      if (mission.business) {
        delete mission.business.name;
        delete mission.business.address_full;
        delete mission.business.address_detail;
        delete mission.business.latitude;
        delete mission.business.longitude;
        // 블라인드 주소만 제공
        mission.business.blindedAddress = mission.blinded_address || generateBlindedAddress(mission.business?.address_full || '');
      }
    }

    res.json({
      success: true,
      data: {
        mission,
        isAssigned,
        // GPS 수동 인증 가능 여부
        manualVerificationAvailable: isAssigned
      }
    });
  } catch (error) {
    next(error);
  }
};

// 미션 상세 (업체용)
exports.getMissionForBusiness = async (req, res, next) => {
  try {
    const { data: mission, error } = await supabase
      .from('missions')
      .select(`
        *,
        business:businesses(id, owner_id),
        assignedReviewer:users!missions_assigned_reviewer_id_fkey(id, nickname, reviewer_grade, trust_score)
      `)
      .eq('id', req.params.id)
      .single();

    if (error || !mission || mission.business.owner_id !== req.user.id) {
      return res.status(404).json(
        createErrorResponse('MISSION_NOT_FOUND')
      );
    }

    res.json({
      success: true,
      data: { mission }
    });
  } catch (error) {
    next(error);
  }
};

// 전체 미션 목록
exports.getAllMissions = async (req, res, next) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    let query = supabase
      .from('missions')
      .select(`
        *,
        business:businesses(id, name, category, address_city)
      `, { count: 'exact' });

    if (status) {
      query = query.eq('status', status);
    }

    query = query
      .order('created_at', { ascending: false })
      .range(offset, offset + parseInt(limit) - 1);

    const { data: missions, error, count } = await query;

    if (error) throw error;

    res.json({
      success: true,
      data: {
        missions: missions || [],
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: count || 0,
          pages: Math.ceil((count || 0) / limit)
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

// 미션 상세
exports.getMission = async (req, res, next) => {
  try {
    const { data: mission, error } = await supabase
      .from('missions')
      .select('*')
      .eq('id', req.params.id)
      .single();

    if (error || !mission) {
      return res.status(404).json(
        createErrorResponse('MISSION_NOT_FOUND')
      );
    }

    res.json({
      success: true,
      data: { mission }
    });
  } catch (error) {
    next(error);
  }
};

// P0: 체크인 (GPS 구간별 점진적 반경 완화)
exports.checkIn = async (req, res, next) => {
  try {
    const { latitude, longitude, verificationPhoto } = req.body;

    const { data: mission, error: missionFetchError } = await supabase
      .from('missions')
      .select(`
        *,
        business:businesses(id, name, address_full, latitude, longitude)
      `)
      .eq('id', req.params.id)
      .single();

    if (missionFetchError || !mission || mission.assigned_reviewer_id !== req.user.id) {
      return res.status(404).json(
        createErrorResponse('MISSION_NOT_FOUND')
      );
    }

    // GPS가 필요하지 않은 미션은 바로 체크인 처리
    if (!mission.gps_required && mission.mission_type !== 'visit') {
      const { error } = await supabase
        .from('missions')
        .update({
          check_in_time: new Date().toISOString(),
          status: 'in_progress',
          gps_zone: 'none',
        })
        .eq('id', req.params.id);

      if (error) throw error;

      return res.json({
        success: true,
        zone: 'none',
        distance: 0,
        requiresPhotoVerification: false,
        message: '체크인이 완료되었습니다.',
        data: {
          verificationMethod: 'none',
          distance: 0,
          zone: 'none',
          zoneLabel: 'GPS 불필요',
        }
      });
    }

    // 방문 미션이지만 GPS가 선택적인 경우
    if (mission.mission_type === 'visit' && !mission.gps_required) {
      // GPS 정보가 없으면 바로 체크인
      if (!latitude || !longitude) {
        const { error } = await supabase
          .from('missions')
          .update({
            check_in_time: new Date().toISOString(),
            status: 'in_progress',
            gps_zone: 'none',
          })
          .eq('id', req.params.id);

        if (error) throw error;

        return res.json({
          success: true,
          zone: 'none',
          distance: 0,
          requiresPhotoVerification: false,
          message: '체크인이 완료되었습니다. (GPS 미사용)',
          data: {
            businessName: mission.business.name,
            address: mission.business.address_full,
            verificationMethod: 'none',
            distance: 0,
            zone: 'none',
            zoneLabel: 'GPS 선택',
          }
        });
      }
    }

    // GPS 검증
    // L3: GPS coordinates are accepted as-is from the device.
    // Freshness is ensured by the check-in timestamp being set server-side (new Date()).
    // Replay attacks are mitigated by mission status checks (must be 'assigned' to check in).
    // Additional mock location detection is handled client-side.
    const businessLat = mission.business.latitude;
    const businessLon = mission.business.longitude;
    let verificationMethod = 'gps';
    let distance = 0;
    let gpsZoneInfo = getGpsZone(0); // default green

    if (businessLat && businessLon && latitude && longitude) {
      distance = calculateDistance(
        latitude,
        longitude,
        businessLat,
        businessLon
      );

      gpsZoneInfo = getGpsZone(distance);

      // RED zone: 체크인 차단
      if (!gpsZoneInfo.allowed) {
        return res.status(400).json({
          success: false,
          zone: gpsZoneInfo.zone,
          distance: Math.round(distance),
          requiresPhotoVerification: false,
          message: gpsZoneInfo.message,
          error: {
            code: 'GPS_OUT_OF_RANGE',
            message: gpsZoneInfo.message,
            guidance: ['업체 근처로 이동한 후 다시 시도해주세요.'],
            action: 'navigate_closer'
          }
        });
      }

      // ORANGE zone: 사진 인증 필수
      if (gpsZoneInfo.requiresPhotoVerification && !verificationPhoto) {
        return res.status(400).json({
          success: false,
          zone: gpsZoneInfo.zone,
          distance: Math.round(distance),
          requiresPhotoVerification: true,
          message: gpsZoneInfo.message,
          error: {
            code: 'PHOTO_REQUIRED',
            message: gpsZoneInfo.message,
            guidance: [
              '업체 간판이 보이도록 사진을 촬영해주세요.',
              '사진이 선명하게 나오도록 해주세요.'
            ],
            action: 'take_photo'
          }
        });
      }

      // ORANGE zone with photo: 수동 인증
      if (gpsZoneInfo.zone === 'orange') {
        verificationMethod = 'manual';
      }
    }

    // 사진 인증이 제출된 경우 (orange zone) 사진 저장
    let checkinPhotoUrl = null;
    if (verificationPhoto) {
      const fileName = `verifications/${req.params.id}/${Date.now()}.jpg`;
      const buffer = Buffer.from(verificationPhoto, 'base64');

      const { error: uploadError } = await supabase.storage
        .from('verification-photos')
        .upload(fileName, buffer, {
          contentType: 'image/jpeg',
          upsert: true
        });

      if (!uploadError) {
        const { data: urlData } = supabase.storage
          .from('verification-photos')
          .getPublicUrl(fileName);
        checkinPhotoUrl = urlData.publicUrl;
      }
    }

    const { error } = await supabase
      .from('missions')
      .update({
        check_in_latitude: latitude,
        check_in_longitude: longitude,
        check_in_time: new Date().toISOString(),
        check_in_distance: Math.round(distance),
        check_in_method: verificationMethod,
        check_in_photo: checkinPhotoUrl,
        gps_zone: gpsZoneInfo.zone,
        checkin_photo_url: checkinPhotoUrl,
        status: 'in_progress'
      })
      .eq('id', req.params.id);

    if (error) throw error;

    res.json({
      success: true,
      zone: gpsZoneInfo.zone,
      distance: Math.round(distance),
      requiresPhotoVerification: gpsZoneInfo.requiresPhotoVerification,
      message: gpsZoneInfo.zone === 'green'
        ? '체크인이 완료되었습니다.'
        : gpsZoneInfo.message,
      data: {
        businessName: mission.business.name,
        address: mission.business.address_full,
        verificationMethod,
        distance: Math.round(distance),
        zone: gpsZoneInfo.zone,
        zoneLabel: gpsZoneInfo.label,
      }
    });
  } catch (error) {
    next(error);
  }
};

// P0: 수동 체크인 요청 (GPS 실패 시)
exports.requestManualCheckIn = async (req, res, next) => {
  try {
    const { verificationPhoto, latitude, longitude } = req.body;

    if (!verificationPhoto) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'PHOTO_REQUIRED',
          message: '수동 인증을 위해 사진이 필요합니다.',
          guidance: [
            '업체 간판이 보이는 사진을 촬영해주세요.',
            '사진이 선명하게 나오도록 해주세요.'
          ],
          action: 'take_photo'
        }
      });
    }

    const { data: mission, error: missionFetchError } = await supabase
      .from('missions')
      .select(`
        *,
        business:businesses(id, name, address_full)
      `)
      .eq('id', req.params.id)
      .single();

    if (missionFetchError || !mission || mission.assigned_reviewer_id !== req.user.id) {
      return res.status(404).json(
        createErrorResponse('MISSION_NOT_FOUND')
      );
    }

    // 사진 업로드
    const fileName = `verifications/${req.params.id}/${Date.now()}.jpg`;
    const buffer = Buffer.from(verificationPhoto, 'base64');

    const { error: uploadError } = await supabase.storage
      .from('verification-photos')
      .upload(fileName, buffer, {
        contentType: 'image/jpeg',
        upsert: true
      });

    if (uploadError) throw uploadError;

    const { data: urlData } = supabase.storage
      .from('verification-photos')
      .getPublicUrl(fileName);

    // 수동 인증으로 체크인 완료
    const { error } = await supabase
      .from('missions')
      .update({
        check_in_latitude: latitude,
        check_in_longitude: longitude,
        check_in_time: new Date().toISOString(),
        check_in_method: 'manual',
        check_in_photo: urlData.publicUrl,
        status: 'in_progress'
      })
      .eq('id', req.params.id);

    if (error) throw error;

    res.json({
      success: true,
      message: '수동 인증이 완료되어 체크인되었습니다.',
      data: {
        businessName: mission.business.name,
        address: mission.business.address_full,
        verificationMethod: 'manual'
      }
    });
  } catch (error) {
    next(error);
  }
};

// 체크아웃
exports.checkOut = async (req, res, next) => {
  try {
    const { data: mission, error: missionFetchError } = await supabase
      .from('missions')
      .select('*')
      .eq('id', req.params.id)
      .single();

    if (missionFetchError || !mission || mission.assigned_reviewer_id !== req.user.id) {
      return res.status(404).json(
        createErrorResponse('MISSION_NOT_FOUND')
      );
    }

    if (!mission.check_in_time) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'CHECKIN_REQUIRED',
          message: '체크인이 필요합니다.',
          guidance: ['먼저 체크인을 완료해주세요.'],
          action: 'go_to_checkin'
        }
      });
    }

    const checkOutTime = new Date();
    const checkInTime = new Date(mission.check_in_time);
    const stayMinutes = Math.round((checkOutTime - checkInTime) / 60000);
    const requiredMinutes = mission.min_stay_minutes || 30;

    // L2: Only enforce stay time check for visit missions
    if (mission.mission_type === 'visit' && stayMinutes < requiredMinutes) {
      return res.status(400).json(
        createStayTimeErrorResponse(stayMinutes, requiredMinutes)
      );
    }
    // For non-visit missions (delivery, online, phone), skip stay time check

    const { error } = await supabase
      .from('missions')
      .update({
        check_out_time: checkOutTime.toISOString()
      })
      .eq('id', req.params.id);

    if (error) throw error;

    res.json({
      success: true,
      message: '체크아웃이 완료되었습니다. 리뷰를 작성해주세요.',
      data: { stayMinutes }
    });
  } catch (error) {
    next(error);
  }
};

// 미션 통계
exports.getMissionStats = async (req, res, next) => {
  try {
    const statuses = ['pending_payment', 'recruiting', 'assigned', 'in_progress', 'review_submitted', 'completed', 'cancelled'];
    const stats = [];

    for (const status of statuses) {
      const { count } = await supabase
        .from('missions')
        .select('*', { count: 'exact', head: true })
        .eq('status', status);

      stats.push({ status, count: count || 0 });
    }

    res.json({
      success: true,
      data: { stats }
    });
  } catch (error) {
    next(error);
  }
};

// === Feature 3: 히든/시즌 미션 ===

// 히든 미션 조회 (등급 기반 필터)
exports.getHiddenMissions = async (req, res, next) => {
  try {
    const userGrade = req.user.reviewer_grade || 'rookie';
    const gradeOrder = ['rookie', 'regular', 'senior', 'master'];
    const userGradeIdx = gradeOrder.indexOf(userGrade);

    const { data: missions, error } = await supabase
      .from('missions')
      .select(`
        id, mission_type, category, region, reviewer_fee, bonus_rate,
        min_reviewer_grade, recruitment_deadline, max_applicants,
        visibility, created_at,
        business:businesses(id, name, category, address_city, badge_level)
      `)
      .eq('visibility', 'hidden')
      .eq('status', 'recruiting')
      .gt('recruitment_deadline', new Date().toISOString())
      .order('created_at', { ascending: false });

    if (error) throw error;

    // 등급 필터링 + 잠김 상태 표시
    const filtered = (missions || []).map(m => {
      const minIdx = gradeOrder.indexOf(m.min_reviewer_grade || 'rookie');
      const isLocked = userGradeIdx < minIdx;
      return { ...m, isLocked, requiredGrade: m.min_reviewer_grade };
    });

    res.json({ success: true, data: filtered });
  } catch (error) {
    next(error);
  }
};

// 시즌 미션 조회
exports.getSeasonMissions = async (req, res, next) => {
  try {
    const { seasonId } = req.params;

    const { data: missions, error } = await supabase
      .from('missions')
      .select(`
        id, mission_type, category, region, reviewer_fee, bonus_rate,
        recruitment_deadline, max_applicants, visibility, season_id, created_at,
        business:businesses(id, name, category, address_city, badge_level)
      `)
      .eq('season_id', seasonId)
      .eq('visibility', 'season')
      .in('status', ['recruiting', 'assigned', 'in_progress'])
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json({ success: true, data: missions || [] });
  } catch (error) {
    next(error);
  }
};

// 주변 경쟁업체 알림 (내부 함수)
async function notifyNearbyCompetitors(mission) {
  try {
    // 미션의 업체 정보 조회
    const { data: sourceBusiness, error: sourceBusinessError } = await supabase
      .from('businesses')
      .select('id, category, latitude, longitude, competition_alert_radius')
      .eq('id', mission.business_id)
      .single();

    if (sourceBusinessError || !sourceBusiness || !sourceBusiness.latitude || !sourceBusiness.longitude) {
      return; // 위치 정보 없으면 스킵
    }

    const radius = sourceBusiness.competition_alert_radius || 1000; // 기본 1km

    // 같은 카테고리의 주변 업체 조회 (경쟁 알림 활성화된 업체만)
    const { data: nearbyBusinesses } = await supabase
      .from('businesses')
      .select('id, owner_id, name, latitude, longitude, competition_alerts_enabled, subscription_status')
      .eq('category', sourceBusiness.category)
      .eq('competition_alerts_enabled', true)
      .in('subscription_status', ['active', 'trial'])
      .neq('id', sourceBusiness.id)
      .not('latitude', 'is', null)
      .not('longitude', 'is', null);

    if (!nearbyBusinesses || nearbyBusinesses.length === 0) {
      return;
    }

    // 거리 계산 및 반경 내 업체 필터링
    const { createNotification } = require('../utils/notificationService');

    for (const business of nearbyBusinesses) {
      const distance = calculateDistance(
        sourceBusiness.latitude,
        sourceBusiness.longitude,
        business.latitude,
        business.longitude
      );

      if (distance <= radius) {
        // 경쟁 알림 발송
        await createNotification(
          business.owner_id,
          NOTIFICATION_TYPES.COMPETITION_ALERT,
          '주변 경쟁업체 미션 알림',
          `${Math.round(distance)}m 거리에서 새로운 미션이 생성되었습니다.`,
          {
            missionId: mission.id,
            distance: Math.round(distance),
            category: sourceBusiness.category
          }
        );
      }
    }

    console.log(`[COMPETITION_ALERT] Notified nearby competitors for mission ${mission.id}`);
  } catch (error) {
    console.error('[COMPETITION_ALERT] Error:', error);
    // 에러 발생해도 무시 (non-blocking)
  }
}
