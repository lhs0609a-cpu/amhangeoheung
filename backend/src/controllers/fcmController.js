/**
 * FCM 디바이스 토큰 컨트롤러
 * 디바이스 토큰 등록/삭제 API
 */

const supabase = require('../config/supabase');

// FCM 토큰 형식 검증 (영숫자 + 특수문자, 50~300자)
const FCM_TOKEN_REGEX = /^[a-zA-Z0-9_:=-]+$/;
const FCM_TOKEN_MIN_LENGTH = 50;
const FCM_TOKEN_MAX_LENGTH = 300;

function isValidFcmToken(token) {
  if (typeof token !== 'string') return false;
  if (token.length < FCM_TOKEN_MIN_LENGTH || token.length > FCM_TOKEN_MAX_LENGTH) return false;
  return FCM_TOKEN_REGEX.test(token);
}

/**
 * 디바이스 토큰 등록
 * POST /api/notifications/device-token
 * Body: { token: string, platform: 'android'|'ios'|'web' }
 */
exports.registerDeviceToken = async (req, res, next) => {
  try {
    const { token, platform } = req.body;
    const userId = req.user.id;

    if (!token || !platform) {
      return res.status(400).json({
        success: false,
        message: 'token과 platform은 필수 입력값입니다.',
      });
    }

    if (!isValidFcmToken(token)) {
      return res.status(400).json({
        success: false,
        message: '유효하지 않은 토큰 형식입니다.',
      });
    }

    if (!['android', 'ios', 'web'].includes(platform)) {
      return res.status(400).json({
        success: false,
        message: 'platform은 android, ios, web 중 하나여야 합니다.',
      });
    }

    // 같은 토큰이 이미 존재하는지 확인
    const { data: existing } = await supabase
      .from('device_tokens')
      .select('id, user_id, is_active')
      .eq('token', token)
      .single();

    if (existing) {
      if (existing.user_id === userId) {
        // 같은 사용자의 같은 토큰 → last_used_at 갱신
        await supabase
          .from('device_tokens')
          .update({
            is_active: true,
            last_used_at: new Date().toISOString(),
            platform,
          })
          .eq('id', existing.id);
      } else {
        // 다른 사용자의 토큰 → 기존 비활성화 후 새로 생성
        await supabase
          .from('device_tokens')
          .update({ is_active: false })
          .eq('id', existing.id);

        await supabase
          .from('device_tokens')
          .insert({
            user_id: userId,
            token,
            platform,
          });
      }
    } else {
      // 새 토큰 등록
      await supabase
        .from('device_tokens')
        .insert({
          user_id: userId,
          token,
          platform,
        });
    }

    res.json({
      success: true,
      message: '디바이스 토큰이 등록되었습니다.',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 디바이스 토큰 삭제 (비활성화)
 * DELETE /api/notifications/device-token
 * Body: { token: string }
 */
exports.removeDeviceToken = async (req, res, next) => {
  try {
    const { token } = req.body;
    const userId = req.user.id;

    if (!token) {
      return res.status(400).json({
        success: false,
        message: 'token은 필수 입력값입니다.',
      });
    }

    await supabase
      .from('device_tokens')
      .update({ is_active: false })
      .eq('token', token)
      .eq('user_id', userId);

    res.json({
      success: true,
      message: '디바이스 토큰이 삭제되었습니다.',
    });
  } catch (error) {
    next(error);
  }
};
