const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticate, requireVerification, requireUserType } = require('../middleware/auth');

// 내 정보 조회
router.get('/me', authenticate, userController.getMyProfile);

// 내 정보 수정
router.put('/me', authenticate, userController.updateMyProfile);

// 프로필 이미지 업로드
router.post('/me/avatar', authenticate, userController.uploadAvatar);

// 비밀번호 변경
router.put('/me/password', authenticate, userController.changePassword);

// 알림 설정 변경
router.put('/me/notifications', authenticate, userController.updateNotificationSettings);

// 리뷰어 전환 신청
router.post('/become-reviewer', authenticate, requireVerification, userController.becomeReviewer);

// 리뷰어 정보 조회
router.get('/reviewer-profile', authenticate, requireUserType('reviewer'), userController.getReviewerProfile);

// 리뷰어 정산 계좌 등록
router.put('/reviewer/bank-account', authenticate, requireUserType('reviewer'), userController.updateBankAccount);

// 리뷰어 전문 카테고리 설정
router.put('/reviewer/specialties', authenticate, requireUserType('reviewer'), userController.updateSpecialties);

// 프리미엄 구독 (소비자용)
router.post('/premium/subscribe', authenticate, requireUserType('consumer'), userController.subscribePremium);

// 프리미엄 해지
router.post('/premium/cancel', authenticate, userController.cancelPremium);

// 계정 삭제 요청
router.delete('/me', authenticate, userController.deleteAccount);

module.exports = router;
