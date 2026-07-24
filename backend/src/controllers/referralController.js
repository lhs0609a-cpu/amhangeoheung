const supabase = require('../config/supabase');
const { REFERRAL_REWARD_AMOUNT } = require('../config/constants');
const { createNotification } = require('../utils/notificationService');
const NOTIFICATION_TYPES = require('../config/notificationTypes');

// 6자 영숫자 코드 생성
function generateReferralCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

// 내 추천 코드 조회/생성
exports.getMyReferralCode = async (req, res) => {
  try {
    const userId = req.user.id;

    // 기존 코드 확인
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('referral_code')
      .eq('id', userId)
      .single();

    if (!userError && user?.referral_code) {
      return res.json({ success: true, data: { code: user.referral_code } });
    }

    // 새 코드 생성 (중복 방지 루프)
    let code;
    let exists = true;
    while (exists) {
      code = generateReferralCode();
      const { data, error: codeCheckError } = await supabase
        .from('users')
        .select('id')
        .eq('referral_code', code)
        .single();
      exists = !codeCheckError && !!data;
    }

    await supabase
      .from('users')
      .update({ referral_code: code })
      .eq('id', userId);

    res.json({ success: true, data: { code } });
  } catch (error) {
    console.error('getMyReferralCode error:', error);
    res.status(500).json({ success: false, message: '추천 코드 생성에 실패했습니다.' });
  }
};

// 추천 통계 조회
exports.getReferralStats = async (req, res) => {
  try {
    const userId = req.user.id;

    const { data: referrals, error } = await supabase
      .from('referrals')
      .select('*')
      .eq('referrer_id', userId);

    if (error) throw error;

    const stats = {
      total: referrals?.length || 0,
      pending: referrals?.filter(r => r.status === 'pending').length || 0,
      registered: referrals?.filter(r => r.status === 'registered').length || 0,
      completed: referrals?.filter(r => r.status === 'mission_completed').length || 0,
      rewarded: referrals?.filter(r => r.status === 'rewarded').length || 0,
      totalEarnings: referrals?.filter(r => r.status === 'rewarded')
        .reduce((sum, r) => sum + (r.reward_amount || 0), 0) || 0,
    };

    res.json({ success: true, data: stats });
  } catch (error) {
    console.error('getReferralStats error:', error);
    res.status(500).json({ success: false, message: '추천 통계 조회에 실패했습니다.' });
  }
};

// 지역 수요 조회
exports.getRegionalDemand = async (req, res) => {
  try {
    const { data: demand, error } = await supabase
      .from('regional_demand')
      .select('*')
      .gt('demand_score', 0)
      .order('demand_score', { ascending: false })
      .limit(20);

    if (error) throw error;

    res.json({ success: true, data: demand || [] });
  } catch (error) {
    console.error('getRegionalDemand error:', error);
    res.status(500).json({ success: false, message: '지역 수요 조회에 실패했습니다.' });
  }
};

// 추천 코드 적용 (새 사용자)
exports.applyReferralCode = async (req, res) => {
  try {
    const userId = req.user.id;
    const { code } = req.body;

    if (!code) {
      return res.status(400).json({ success: false, message: '추천 코드를 입력해주세요.' });
    }

    // 추천인 찾기
    const { data: referrer, error: referrerError } = await supabase
      .from('users')
      .select('id, nickname')
      .eq('referral_code', code.toUpperCase())
      .single();

    if (referrerError || !referrer) {
      return res.status(404).json({ success: false, message: '유효하지 않은 추천 코드입니다.' });
    }

    if (referrer.id === userId) {
      return res.status(400).json({ success: false, message: '자신의 추천 코드는 사용할 수 없습니다.' });
    }

    // Check max referral limit (10 per user)
    const { data: existingReferrals } = await supabase
      .from('referrals')
      .select('id')
      .eq('referrer_id', referrer.id)
      .in('status', ['registered', 'rewarded', 'mission_completed']);

    if (existingReferrals && existingReferrals.length >= 10) {
      return res.status(400).json({
        success: false,
        message: '추천 한도(10명)를 초과했습니다.'
      });
    }

    // 이미 추천 받은 적 있는지 확인
    const { data: existing, error: existingError } = await supabase
      .from('referrals')
      .select('id')
      .eq('referred_id', userId)
      .single();

    if (existing && !existingError) {
      return res.status(400).json({ success: false, message: '이미 추천 코드를 사용했습니다.' });
    }

    // 추천 레코드 생성
    const { data: referral, error } = await supabase
      .from('referrals')
      .insert({
        referrer_id: referrer.id,
        referred_id: userId,
        referral_code: code.toUpperCase(),
        status: 'registered',
        reward_amount: REFERRAL_REWARD_AMOUNT,
        expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
      })
      .select()
      .single();

    if (error) throw error;

    // 추천인에게 알림
    await createNotification(
      referrer.id,
      NOTIFICATION_TYPES.REFERRAL_REGISTERED,
      '새로운 친구가 가입했어요!',
      '추천한 친구가 가입을 완료했습니다. 첫 미션 완료 시 보상이 지급됩니다.',
      { referralId: referral.id }
    );

    res.json({
      success: true,
      message: `${referrer.nickname || '추천인'}님의 추천으로 등록되었습니다!`,
      data: referral,
    });
  } catch (error) {
    console.error('applyReferralCode error:', error);
    res.status(500).json({ success: false, message: '추천 코드 적용에 실패했습니다.' });
  }
};

// 내부: 추천 보상 처리 (첫 미션 완료 시)
exports.processReferralReward = async (referredUserId) => {
  try {
    const { data: referral, error: referralError } = await supabase
      .from('referrals')
      .select('*')
      .eq('referred_id', referredUserId)
      .eq('status', 'registered')
      .single();

    if (referralError || !referral) return;

    const now = new Date().toISOString();

    // 추천 상태 업데이트
    await supabase
      .from('referrals')
      .update({
        status: 'rewarded',
        referrer_rewarded_at: now,
        referred_rewarded_at: now,
      })
      .eq('id', referral.id);

    // 추천인 보상 카운트 업데이트
    await supabase.rpc('increment_referral_stats', {
      user_id: referral.referrer_id,
      earnings: referral.reward_amount,
    });

    // 양측 알림
    await createNotification(
      referral.referrer_id,
      NOTIFICATION_TYPES.REFERRAL_REWARDED,
      '추천 보상 지급!',
      `추천한 친구가 첫 미션을 완료했습니다. ${referral.reward_amount.toLocaleString()}원이 지급됩니다.`,
      { referralId: referral.id, amount: referral.reward_amount }
    );

    await createNotification(
      referredUserId,
      NOTIFICATION_TYPES.REFERRAL_REWARDED,
      '추천인 보상 지급!',
      `첫 미션 완료 축하합니다! ${referral.reward_amount.toLocaleString()}원이 지급됩니다.`,
      { referralId: referral.id, amount: referral.reward_amount }
    );
  } catch (error) {
    console.error('processReferralReward error:', error);
  }
};
