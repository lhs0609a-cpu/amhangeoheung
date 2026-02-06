const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { validationResult } = require('express-validator');
const supabase = require('../config/supabase');

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
    const { data: existingEmail } = await supabase
      .from('users')
      .select('id')
      .eq('email', email)
      .single();

    if (existingEmail) {
      return res.status(400).json({
        success: false,
        message: '이미 사용 중인 이메일입니다.'
      });
    }

    // 휴대폰 번호 중복 확인
    const { data: existingPhone } = await supabase
      .from('users')
      .select('id')
      .eq('phone', phone)
      .single();

    if (existingPhone) {
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

// 토큰 갱신
exports.refreshToken = async (req, res, next) => {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({
        success: false,
        message: '토큰이 필요합니다.'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET, { ignoreExpiration: true });

    const { data: user } = await supabase
      .from('users')
      .select('id, status')
      .eq('id', decoded.userId)
      .single();

    if (!user || user.status !== 'active') {
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

    const { data: user } = await supabase
      .from('users')
      .select('id, email, name')
      .eq('email', email)
      .single();

    if (user) {
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

      // 이메일 발송
      const { sendPasswordResetEmail } = require('../utils/emailService');
      await sendPasswordResetEmail(user.email, resetToken, user.name);
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

    const { data: exists } = await supabase
      .from('users')
      .select('id')
      .eq('email', email)
      .single();

    res.json({
      success: true,
      available: !exists
    });
  } catch (error) {
    next(error);
  }
};

// 휴대폰 번호 중복 확인
exports.checkPhone = async (req, res, next) => {
  try {
    const { phone } = req.query;

    const { data: exists } = await supabase
      .from('users')
      .select('id')
      .eq('phone', phone)
      .single();

    res.json({
      success: true,
      available: !exists
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
    const { data: existingCI } = await supabase
      .from('users')
      .select('id')
      .eq('ci', ci)
      .neq('id', req.user.id)
      .single();

    if (existingCI) {
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
    const { provider, providerId, email, name, profileImage, idToken, accessToken } = req.body;

    // 유효성 검사
    if (!provider || !providerId) {
      return res.status(400).json({
        success: false,
        message: '소셜 로그인 정보가 부족합니다.'
      });
    }

    // 유효한 프로바이더인지 확인
    const validProviders = ['google', 'apple', 'kakao'];
    if (!validProviders.includes(provider)) {
      return res.status(400).json({
        success: false,
        message: '지원하지 않는 소셜 로그인입니다.'
      });
    }

    // 1. 기존 소셜 계정 연결 확인
    const { data: existingSocialAccount } = await supabase
      .from('social_accounts')
      .select('user_id')
      .eq('provider', provider)
      .eq('provider_id', providerId)
      .single();

    let userId;

    if (existingSocialAccount) {
      // 기존 소셜 계정이 있으면 해당 사용자로 로그인
      userId = existingSocialAccount.user_id;

      // 소셜 계정 정보 업데이트
      await supabase
        .from('social_accounts')
        .update({
          access_token: accessToken,
          id_token: idToken,
          updated_at: new Date().toISOString()
        })
        .eq('provider', provider)
        .eq('provider_id', providerId);
    } else {
      // 2. 이메일로 기존 사용자 확인 (이메일이 있는 경우)
      let existingUser = null;
      if (email) {
        const { data: userByEmail } = await supabase
          .from('users')
          .select('id')
          .eq('email', email)
          .single();
        existingUser = userByEmail;
      }

      if (existingUser) {
        // 기존 사용자에 소셜 계정 연결
        userId = existingUser.id;

        await supabase
          .from('social_accounts')
          .insert({
            user_id: userId,
            provider,
            provider_id: providerId,
            email,
            name,
            profile_image: profileImage,
            access_token: accessToken,
            id_token: idToken
          });
      } else {
        // 3. 새 사용자 생성
        const { data: newUser, error: createError } = await supabase
          .from('users')
          .insert({
            email: email || `${provider}_${providerId}@social.amhangeoheung.com`,
            name: name || `${provider} 사용자`,
            profile_image: profileImage,
            user_type: 'consumer',
            auth_provider: provider,
            is_social_only: true
          })
          .select()
          .single();

        if (createError) {
          console.error('Create user error:', createError);
          return res.status(500).json({
            success: false,
            message: '사용자 생성 중 오류가 발생했습니다.'
          });
        }

        userId = newUser.id;

        // 소셜 계정 연결
        await supabase
          .from('social_accounts')
          .insert({
            user_id: userId,
            provider,
            provider_id: providerId,
            email,
            name,
            profile_image: profileImage,
            access_token: accessToken,
            id_token: idToken
          });
      }
    }

    // 사용자 정보 조회
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('*')
      .eq('id', userId)
      .single();

    if (userError || !user) {
      return res.status(500).json({
        success: false,
        message: '사용자 정보 조회 중 오류가 발생했습니다.'
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
      message: '소셜 로그인 성공',
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
          authProvider: user.auth_provider,
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
    console.error('Social login error:', error);
    next(error);
  }
};
