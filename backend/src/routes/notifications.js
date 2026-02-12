const express = require('express');
const router = express.Router();
const rateLimit = require('express-rate-limit');
const notificationController = require('../controllers/notificationController');
const fcmController = require('../controllers/fcmController');
const { authenticate } = require('../middleware/auth');

// 모든 알림 라우트는 인증 필요
router.use(authenticate);

// 디바이스 토큰 등록 rate limiting (사용자당 분당 10회)
const tokenRegisterLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  keyGenerator: (req) => req.user?.id || req.ip,
  message: {
    success: false,
    message: '토큰 등록 요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
  },
});

// 디바이스 토큰 관리 (FCM)
router.post('/device-token', tokenRegisterLimiter, fcmController.registerDeviceToken);
router.delete('/device-token', fcmController.removeDeviceToken);

// 알림 조회/관리
router.get('/', notificationController.getNotifications);
router.get('/unread-count', notificationController.getUnreadCount);
router.put('/read-all', notificationController.markAllAsRead);
router.put('/:id/read', notificationController.markAsRead);

module.exports = router;
