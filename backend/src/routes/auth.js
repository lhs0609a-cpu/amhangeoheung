const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');
const {
  loginLimiter,
  registerLimiter,
  forgotPasswordLimiter,
  checkDuplicateLimiter,
  emailVerificationLimiter,
} = require('../middleware/rateLimiter');
const {
  registerValidation,
  loginValidation,
  forgotPasswordValidation,
  resetPasswordValidation,
  socialLoginValidation,
} = require('../middleware/validators');

// 회원가입
router.post('/register', registerLimiter, registerValidation, authController.register);

// 로그인
router.post('/login', loginLimiter, loginValidation, authController.login);

// 토큰 갱신
router.post('/refresh', authController.refreshToken);

// 토큰 검증 (인증 상태 확인)
router.get('/verify', authenticate, authController.verifyToken);

// 로그아웃
router.post('/logout', authenticate, authController.logout);

// 비밀번호 재설정 요청
router.post('/forgot-password', forgotPasswordLimiter, forgotPasswordValidation, authController.forgotPassword);

// 비밀번호 재설정
router.post('/reset-password', resetPasswordValidation, authController.resetPassword);

// 이메일 중복 확인
router.get('/check-email', checkDuplicateLimiter, authController.checkEmail);

// 휴대폰 번호 중복 확인
router.get('/check-phone', checkDuplicateLimiter, authController.checkPhone);

// 이메일 인증 코드 검증
router.post('/verify-email', authController.verifyEmail);

// 이메일 인증 코드 재전송
router.post('/resend-verification', emailVerificationLimiter, authController.resendEmailVerification);

// 본인 인증 (PASS 등)
router.post('/verify-identity', authenticate, authController.verifyIdentity);

// 소셜 로그인
router.post('/social-login', loginLimiter, socialLoginValidation, authController.socialLogin);

module.exports = router;
