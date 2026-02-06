const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const authController = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');

// 유효성 검사 규칙
const registerValidation = [
  body('email').isEmail().withMessage('유효한 이메일을 입력하세요.'),
  body('password')
    .isLength({ min: 8 })
    .withMessage('비밀번호는 최소 8자 이상이어야 합니다.'),
  body('phone').isMobilePhone('ko-KR').withMessage('유효한 휴대폰 번호를 입력하세요.'),
  body('name').notEmpty().withMessage('이름을 입력하세요.'),
  body('userType')
    .isIn(['consumer', 'reviewer', 'business'])
    .withMessage('유효한 사용자 유형을 선택하세요.')
];

const loginValidation = [
  body('email').isEmail().withMessage('유효한 이메일을 입력하세요.'),
  body('password').notEmpty().withMessage('비밀번호를 입력하세요.')
];

// 회원가입
router.post('/register', registerValidation, authController.register);

// 로그인
router.post('/login', loginValidation, authController.login);

// 토큰 갱신
router.post('/refresh', authController.refreshToken);

// 토큰 검증 (인증 상태 확인)
router.get('/verify', authenticate, authController.verifyToken);

// 로그아웃
router.post('/logout', authenticate, authController.logout);

// 비밀번호 재설정 요청
router.post('/forgot-password', authController.forgotPassword);

// 비밀번호 재설정
router.post('/reset-password', authController.resetPassword);

// 이메일 중복 확인
router.get('/check-email', authController.checkEmail);

// 휴대폰 번호 중복 확인
router.get('/check-phone', authController.checkPhone);

// 본인 인증 (PASS 등)
router.post('/verify-identity', authenticate, authController.verifyIdentity);

// 소셜 로그인
router.post('/social-login', authController.socialLogin);

module.exports = router;
