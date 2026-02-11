const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const fcmController = require('../controllers/fcmController');
const { authenticate } = require('../middleware/auth');

// 모든 알림 라우트는 인증 필요
router.use(authenticate);

// 디바이스 토큰 관리 (FCM)
router.post('/device-token', fcmController.registerDeviceToken);
router.delete('/device-token', fcmController.removeDeviceToken);

// 알림 조회/관리
router.get('/', notificationController.getNotifications);
router.get('/unread-count', notificationController.getUnreadCount);
router.put('/read-all', notificationController.markAllAsRead);
router.put('/:id/read', notificationController.markAsRead);

module.exports = router;
