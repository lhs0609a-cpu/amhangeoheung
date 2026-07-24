const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const supabase = require('../config/supabase');

// JWT 토큰 검증 미들웨어
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: '인증 토큰이 필요합니다.'
      });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Check if token has been blacklisted (logged out)
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
    const { data: blacklisted, error: blacklistError } = await supabase
      .from('token_blacklist')
      .select('id')
      .eq('token_hash', tokenHash)
      .single();

    if (blacklisted && !blacklistError) {
      return res.status(401).json({
        success: false,
        message: '로그아웃된 토큰입니다.'
      });
    }

    const { data: user, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', decoded.userId)
      .single();

    if (error || !user) {
      return res.status(401).json({
        success: false,
        message: '사용자를 찾을 수 없습니다.'
      });
    }

    if (user.status !== 'active') {
      return res.status(403).json({
        success: false,
        message: '계정이 정지되었습니다.',
        reason: user.ban_reason
      });
    }

    // 비밀번호 제외하고 req.user에 저장
    delete user.password;
    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: '토큰이 만료되었습니다.'
      });
    }

    return res.status(401).json({
      success: false,
      message: '유효하지 않은 토큰입니다.'
    });
  }
};

// 선택적 인증 (로그인 안 해도 됨)
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      const { data: user, error: userError } = await supabase
        .from('users')
        .select('*')
        .eq('id', decoded.userId)
        .single();

      if (!userError && user) {
        delete user.password;
        req.user = user;
      }
    }

    next();
  } catch (error) {
    // 토큰이 유효하지 않아도 통과
    next();
  }
};

// 사용자 유형 체크
const requireUserType = (...types) => {
  return (req, res, next) => {
    if (!types.includes(req.user.user_type)) {
      return res.status(403).json({
        success: false,
        message: '해당 기능에 접근할 권한이 없습니다.'
      });
    }
    next();
  };
};

// 관리자 권한 체크
// user_type enum에는 'admin'이 없으므로, users.is_admin 플래그 또는
// ADMIN_USER_IDS(쉼표구분 env)로 관리자를 식별한다.
const requireAdmin = (req, res, next) => {
  const adminIds = (process.env.ADMIN_USER_IDS || '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);

  const isAdmin = req.user?.is_admin === true || adminIds.includes(String(req.user?.id));

  if (!isAdmin) {
    return res.status(403).json({
      success: false,
      message: '관리자 권한이 필요합니다.'
    });
  }
  next();
};

// 본인 인증 필수
const requireVerification = (req, res, next) => {
  if (!req.user.is_verified) {
    return res.status(403).json({
      success: false,
      message: '본인 인증이 필요합니다.'
    });
  }
  next();
};

// 리뷰어 등급 체크
const requireReviewerGrade = (...grades) => {
  return (req, res, next) => {
    if (req.user.user_type !== 'reviewer') {
      return res.status(403).json({
        success: false,
        message: '리뷰어 계정이 아닙니다.'
      });
    }

    if (!grades.includes(req.user.reviewer_grade)) {
      return res.status(403).json({
        success: false,
        message: '리뷰어 등급이 부족합니다.'
      });
    }

    next();
  };
};

module.exports = {
  authenticate,
  optionalAuth,
  requireUserType,
  requireAdmin,
  requireVerification,
  requireReviewerGrade
};
