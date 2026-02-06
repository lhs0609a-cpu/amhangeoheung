const jwt = require('jsonwebtoken');
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

      const { data: user } = await supabase
        .from('users')
        .select('*')
        .eq('id', decoded.userId)
        .single();

      if (user) {
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
  requireVerification,
  requireReviewerGrade
};
