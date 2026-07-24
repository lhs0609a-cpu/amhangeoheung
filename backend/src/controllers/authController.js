const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const axios = require('axios');
const { validationResult } = require('express-validator');
const supabase = require('../config/supabase');
const { sendPasswordResetEmail, sendWelcomeEmail } = require('../utils/emailService');

// JWT 토큰 생성
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d'
  });
};

// 회원가입
exports.register = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array()
      });
    }

    const { email, password, phone, name, userType, deviceId } = req.body;

    // 이메일 중복 확인
    const { data: existingEmail, error: existingEmailError } = await supabase
      .from('users')
      .select('id')
      .eq('email', email)
      .single();

    if (existingEmail && !existingEmailError) {
      return res.status(400).json({
        success: false,
        message: '이미 사용 중인 이메일입니다.'
      });
    }

    // 휴대폰 번호 중복 확인
    const { data: existingPhone, error: existingPhoneError } = await supabase
      .from('users')
      .select('id')
      .eq('phone', phone)
      .single();

    if (existingPhone && !existingPhoneError) {
      return res.status(400).json({
        success: false,
        message: '이미 사용 중인 휴대폰 번호입니다.'
      });
    }

    // 비밀번호 해싱
    const hashedPassword = await bcrypt.hash(password, 12);

    // 사용자 생성
    const { data: user, error } = await supabase
      .from('users')
      .insert({
        email,
        password: hashedPassword,
        phone,
        name,
        user_type: userType || 'consumer'
      })
      .select()
      .single();

    if (error) {
      console.error('Supabase error:', error);
      return res.status(500).json({
        success: false,
        message: '회원가입 처리 중 오류가 발생했습니다.'
      });
    }

    const token = generateToken(user.id);

    // 환영 이메일 발송 (실패해도 가입은 완료)
    sendWelcomeEmail(user.email, user.name).catch(err => {
      console.error('Welcome email failed:', err.message);
    });

    res.status(201).json({
      success: true,
      message: '회원가입이 완료되었습니다.',
      data: {
        token,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          userType: user.user_type,
          isVerified: user.is_verified || false
        }
      }
    });
  } catch (error) {
    console.error('Register error:', error);
    next(error);
  }
};

// 로그인
exports.login = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array()
      });
    }

    const { email, password } = req.body;

    // 사용자 찾기
    const { data: user, error } = await supabase
      .from('users')
      .select('*')
      .eq('email', email)
      .single();

    if (error || !user) {
      return res.status(401).json({
        success: false,
        message: '이메일 또는 비밀번호가 올바르지 않습니다.'
      });
    }

    // 비밀번호 확인
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: '이메일 또는 비밀번호가 올바르지 않습니다.'
      });
    }

    // 계정 상태 확인
    if (user.status !== 'active') {
      return res.status(403).json({
        success: false,
        message: '정지된 계정입니다.',
        reason: user.ban_reason
      });
    }

    // 마지막 로그인 시간 업데이트
    await supabase
      .from('users')
      .update({ last_login_at: new Date().toISOString() })
      .eq('id', user.id);

    const token = generateToken(user.id);

    res.json({
      success: true,
      message: '로그인 성공',
      data: {
        token,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          nickname: user.nickname,
          userType: user.user_type,
          profileImage: user.profile_image,
          isVerified: user.is_verified || false,
          reviewer: user.user_type === 'reviewer' ? {
            grade: user.reviewer_grade,
            completedMissions: user.completed_missions,
            trustScore: user.trust_score,
            specialties: user.specialties
          } : undefined,
          premium: {
            isActive: user.premium_active,
            expiresAt: user.premium_expires_at
          }
        }
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    next(error);
  }
};

// 토큰 검증 (인증 상태 확인)
exports.verifyToken = async (req, res, next) => {
  try {
    // authenticate 미들웨어가 이미 토큰을 검증했으므로
    // req.user가 있으면 유효한 토큰
    res.json({
      success: true,
      data: {
        user: {
          id: req.user.id,
          email: req.user.email,
          name: req.user.name,
          nickname: req.user.nickname,
          userType: req.user.user_type,
          profileImage: req.user.profile_image,
          isVerified: req.user.is_verified || false,
          reviewer: req.user.user_type === 'reviewer' ? {
            grade: req.user.reviewer_grade,
            completedMissions: req.user.completed_missions,
            trustScore: req.user.trust_score,
            specialties: req.user.specialties
          } : undefined,
          premium: {
            isActive: req.user.premium_active,
            expiresAt: req.user.premium_expires_at
          }
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

// 토큰 갱신 (만료 후 최대 7일 이내만 허용)
const REFRESH_GRACE_PERIOD_SECONDS = 7 * 24 * 60 * 60; // 7일

exports.refreshToken = async (req, res, next) => {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({
        success: false,
        message: '토큰이 필요합니다.'
      });
    }

    let decoded;
    try {
      // 먼저 유효한 토큰인지 확인
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        // 만료된 토큰: grace period 내인지 확인
        const expiredAt = err.expiredAt;
        const now = new Date();
        const secondsSinceExpiry = Math.floor((now - expiredAt) / 1000);

        if (secondsSinceExpiry > REFRESH_GRACE_PERIOD_SECONDS) {
          return res.status(401).json({
            success: false,
            message: '토큰이 만료되었습니다. 다시 로그인해주세요.'
          });
        }

        // Grace period 내: 페이로드 디코드 (서명은 이미 검증됨)
        decoded = jwt.decode(token);
      } else {
        return res.status(401).json({
          success: false,
          message: '유효하지 않은 토큰입니다.'
        });
      }
    }

    if (!decoded?.userId) {
      return res.status(401).json({
        success: false,
        message: '유효하지 않은 토큰입니다.'
      });
    }

    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id, status')
      .eq('id', decoded.userId)
      .single();

    if (userError || !user || user.status !== 'active') {
      return res.status(401).json({
        success: false,
        message: '유효하지 않은 토큰입니다.'
      });
    }

    const newToken = generateToken(user.id);

    res.json({
      success: true,
      data: { token: newToken }
    });
  } catch (error) {
    next(error);
  }
};

// 로그아웃
exports.logout = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

      // Decode token to get expiry time
      const decoded = jwt.decode(token);
      const expiresAt = decoded?.exp
        ? new Date(decoded.exp * 1000).toISOString()
        : new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(); // fallback: 7 days

      // Insert into blacklist
      const { error: blacklistError } = await supabase
        .from('token_blacklist')
        .insert({
          token_hash: tokenHash,
          user_id: req.user.id,
          expires_at: expiresAt
        });

      if (blacklistError) {
        console.error('Token blacklist insert error:', blacklistError.message);
        // Don't fail the logout even if blacklisting fails
      }
    }

    res.json({
      success: true,
      message: '로그아웃되었습니다.'
    });
  } catch (error) {
    next(error);
  }
};

// 비밀번호 찾기
exports.forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;

    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id, email, name')
      .eq('email', email)
      .single();

    if (user && !userError) {
      // 비밀번호 재설정 토큰 생성 (6시간 유효)
      const resetToken = jwt.sign(
        { userId: user.id, type: 'password_reset' },
        process.env.JWT_SECRET,
        { expiresIn: '6h' }
      );

      // 토큰 저장
      await supabase
        .from('users')
        .update({
          reset_token: resetToken,
          reset_token_expires: new Date(Date.now() + 6 * 60 * 60 * 1000).toISOString()
        })
        .eq('id', user.id);

      // 비밀번호 재설정 이메일 발송
      await sendPasswordResetEmail(user.email, user.name, resetToken);
    }

    // 보안을 위해 존재 여부와 관계없이 동일한 응답
    res.json({
      success: true,
      message: '이메일이 존재하면 비밀번호 재설정 링크가 발송됩니다.'
    });
  } catch (error) {
    next(error);
  }
};

// 비밀번호 재설정
exports.resetPassword = async (req, res, next) => {
  try {
    const { token, newPassword } = req.body;

    if (!token || !newPassword) {
      return res.status(400).json({
        success: false,
        message: '토큰과 새 비밀번호가 필요합니다.'
      });
    }

    // 비밀번호 강도 검증
    if (newPassword.length < 8) {
      return res.status(400).json({
        success: false,
        message: '비밀번호는 8자 이상이어야 합니다.'
      });
    }

    // 토큰 검증
    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (err) {
      return res.status(400).json({
        success: false,
        message: '유효하지 않거나 만료된 토큰입니다.'
      });
    }

    if (decoded.type !== 'password_reset') {
      return res.status(400).json({
        success: false,
        message: '유효하지 않은 토큰입니다.'
      });
    }

    // 사용자 확인 및 토큰 일치 여부 확인
    const { data: user, error } = await supabase
      .from('users')
      .select('id, reset_token, reset_token_expires')
      .eq('id', decoded.userId)
      .single();

    if (error || !user) {
      return res.status(400).json({
        success: false,
        message: '사용자를 찾을 수 없습니다.'
      });
    }

    if (user.reset_token !== token) {
      return res.status(400).json({
        success: false,
        message: '유효하지 않은 토큰입니다.'
      });
    }

    if (new Date(user.reset_token_expires) < new Date()) {
      return res.status(400).json({
        success: false,
        message: '토큰이 만료되었습니다. 다시 요청해주세요.'
      });
    }

    // 비밀번호 해싱 및 업데이트
    const hashedPassword = await bcrypt.hash(newPassword, 12);

    await supabase
      .from('users')
      .update({
        password: hashedPassword,
        reset_token: null,
        reset_token_expires: null,
        updated_at: new Date().toISOString()
      })
      .eq('id', user.id);

    res.json({
      success: true,
      message: '비밀번호가 재설정되었습니다.'
    });
  } catch (error) {
    next(error);
  }
};

// 이메일 중복 확인
exports.checkEmail = async (req, res, next) => {
  try {
    const { email } = req.query;

    const { data: exists, error: existsError } = await supabase
      .from('users')
      .select('id')
      .eq('email', email)
      .single();

    res.json({
      success: true,
      available: !exists || !!existsError
    });
  } catch (error) {
    next(error);
  }
};

// 휴대폰 번호 중복 확인
exports.checkPhone = async (req, res, next) => {
  try {
    const { phone } = req.query;

    const { data: exists, error: existsError } = await supabase
      .from('users')
      .select('id')
      .eq('phone', phone)
      .single();

    res.json({
      success: true,
      available: !exists || !!existsError
    });
  } catch (error) {
    next(error);
  }
};

// 본인 인증
exports.verifyIdentity = async (req, res, next) => {
  try {
    const { ci, di, verificationMethod } = req.body;

    // CI 중복 확인
    const { data: existingCI, error: existingCIError } = await supabase
      .from('users')
      .select('id')
      .eq('ci', ci)
      .neq('id', req.user.id)
      .single();

    if (existingCI && !existingCIError) {
      return res.status(400).json({
        success: false,
        message: '이미 다른 계정으로 인증된 정보입니다.'
      });
    }

    // 인증 정보 저장
    const { error } = await supabase
      .from('users')
      .update({
        is_verified: true,
        ci,
        di,
        verified_at: new Date().toISOString(),
        verification_method: verificationMethod
      })
      .eq('id', req.user.id);

    if (error) {
      throw error;
    }

    res.json({
      success: true,
      message: '본인 인증이 완료되었습니다.'
    });
  } catch (error) {
    next(error);
  }
};

// 소셜 로그인
exports.socialLogin = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array()
      });
    }

    const { provider, accessToken, name: providedName } = req.body;

    // 소셜 프로바이더에서 사용자 정보 조회
    let socialUser;
    try {
      socialUser = await getSocialUserInfo(provider, accessToken);
    } catch (err) {
      return res.status(401).json({
        success: false,
        message: '소셜 로그인 인증에 실패했습니다.'
      });
    }

    if (!socialUser || !socialUser.email) {
      return res.status(400).json({
        success: false,
        message: '소셜 계정에서 이메일 정보를 가져올 수 없습니다.'
      });
    }

    // 기존 사용자 찾기
    const { data: existingUser, error: existingUserError } = await supabase
      .from('users')
      .select('*')
      .eq('email', socialUser.email)
      .single();

    let user;

    if (existingUser && !existingUserError) {
      // 기존 사용자: 소셜 프로바이더 정보 업데이트
      if (existingUser.status !== 'active') {
        return res.status(403).json({
          success: false,
          message: '정지된 계정입니다.',
          reason: existingUser.ban_reason
        });
      }

      await supabase
        .from('users')
        .update({
          social_provider: provider,
          social_id: socialUser.id,
          last_login_at: new Date().toISOString()
        })
        .eq('id', existingUser.id);

      user = existingUser;
    } else {
      // 신규 사용자: 자동 가입
      const { data: newUser, error } = await supabase
        .from('users')
        .insert({
          email: socialUser.email,
          name: socialUser.name || providedName || socialUser.email.split('@')[0],
          password: null,
          social_provider: provider,
          social_id: socialUser.id,
          profile_image: socialUser.profileImage,
          user_type: 'consumer'
        })
        .select()
        .single();

      if (error) {
        console.error('Social register error:', error);
        return res.status(500).json({
          success: false,
          message: '소셜 로그인 처리 중 오류가 발생했습니다.'
        });
      }

      user = newUser;

      // 환영 이메일 (비동기)
      sendWelcomeEmail(user.email, user.name).catch(err => {
        console.error('Welcome email failed:', err.message);
      });
    }

    const token = generateToken(user.id);

    res.json({
      success: true,
      message: (existingUser && !existingUserError) ? '로그인 성공' : '소셜 계정으로 가입되었습니다.',
      data: {
        token,
        isNewUser: !(existingUser && !existingUserError),
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          nickname: user.nickname,
          userType: user.user_type,
          profileImage: user.profile_image,
          isVerified: user.is_verified || false
        }
      }
    });
  } catch (error) {
    console.error('Social login error:', error);
    next(error);
  }
};

// 소셜 프로바이더별 사용자 정보 조회
async function getSocialUserInfo(provider, accessToken) {
  switch (provider) {
    case 'google': {
      const { data } = await axios.get('https://www.googleapis.com/oauth2/v2/userinfo', {
        headers: { Authorization: `Bearer ${accessToken}` }
      });
      return {
        id: data.id,
        email: data.email,
        name: data.name,
        profileImage: data.picture
      };
    }

    case 'kakao': {
      const { data } = await axios.get('https://kapi.kakao.com/v2/user/me', {
        headers: { Authorization: `Bearer ${accessToken}` }
      });
      const account = data.kakao_account || {};
      return {
        id: String(data.id),
        email: account.email,
        name: account.profile?.nickname,
        profileImage: account.profile?.profile_image_url
      };
    }

    case 'apple': {
      // Apple id_token 서명 검증
      // Apple의 공개키를 가져와서 JWT 서명을 검증
      const jwksResponse = await axios.get('https://appleid.apple.com/auth/keys', { timeout: 10000 });
      const appleKeys = jwksResponse.data.keys;

      // 토큰 헤더에서 kid 추출
      const tokenHeader = jwt.decode(accessToken, { complete: true });
      if (!tokenHeader || !tokenHeader.header?.kid) {
        throw new Error('Invalid Apple token format');
      }

      const matchingKey = appleKeys.find(k => k.kid === tokenHeader.header.kid);
      if (!matchingKey) {
        throw new Error('Apple public key not found');
      }

      // JWK를 PEM으로 변환하여 검증
      const crypto = require('crypto');
      const publicKey = crypto.createPublicKey({ key: matchingKey, format: 'jwk' });

      const decoded = jwt.verify(accessToken, publicKey, {
        algorithms: ['RS256'],
        issuer: 'https://appleid.apple.com',
        audience: process.env.APPLE_CLIENT_ID || 'com.amhangeoheung.app',
      });

      if (!decoded || !decoded.sub) {
        throw new Error('Invalid Apple token');
      }
      return {
        id: decoded.sub,
        email: decoded.email,
        name: null,
        profileImage: null
      };
    }

    default:
      throw new Error(`Unsupported provider: ${provider}`);
  }
}
