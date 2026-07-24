const express = require('express');
const router = express.Router();
const { authenticate, requireUserType } = require('../middleware/auth');
const detectionTestController = require('../controllers/detectionTestController');

// 사업자용: 응답 대기 테스트 목록
router.get('/pending', authenticate, requireUserType('business'), detectionTestController.getPendingTests);

// 사업자용: 추측 제출
router.post('/:id/submit', authenticate, requireUserType('business'), detectionTestController.submitTest);

// 리뷰어용: 은밀성 통계
router.get('/my-stats', authenticate, requireUserType('reviewer'), detectionTestController.getDetectionStats);

module.exports = router;
