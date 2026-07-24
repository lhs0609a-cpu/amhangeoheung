const rateLimit = require('express-rate-limit');

// 로그인: 15분 내 5회
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: {
    success: false,
    message: '로그인 시도가 너무 많습니다. 15분 후 다시 시도해주세요.',
    code: 'RATE_LIMIT_LOGIN',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// 회원가입: 1시간 내 3회
const registerLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 3,
  message: {
    success: false,
    message: '회원가입 시도가 너무 많습니다. 1시간 후 다시 시도해주세요.',
    code: 'RATE_LIMIT_REGISTER',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// 비밀번호 재설정: 1시간 내 3회
const forgotPasswordLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 3,
  message: {
    success: false,
    message: '비밀번호 재설정 요청이 너무 많습니다. 1시간 후 다시 시도해주세요.',
    code: 'RATE_LIMIT_FORGOT_PASSWORD',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// 이메일/전화번호 중복 확인: 1분 내 10회
const checkDuplicateLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  message: {
    success: false,
    message: '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
    code: 'RATE_LIMIT_CHECK',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// 일반 API: 1분 내 60회
const generalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 60,
  message: {
    success: false,
    message: '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
    code: 'RATE_LIMIT_GENERAL',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

module.exports = {
  loginLimiter,
  registerLimiter,
  forgotPasswordLimiter,
  checkDuplicateLimiter,
  generalLimiter,
};
