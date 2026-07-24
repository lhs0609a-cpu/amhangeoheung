const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const collusionController = require('../controllers/collusionController');

// 관리자 권한 확인 미들웨어
const requireAdmin = (req, res, next) => {
  if (req.user.user_type !== 'admin' && !req.user.is_admin) {
    return res.status(403).json({ success: false, message: '관리자 권한이 필요합니다.' });
  }
  next();
};

// 관리자용: 미해결 플래그 목록
router.get('/flags', authenticate, requireAdmin, collusionController.getCollusionFlags);

// 관리자용: 플래그 처리
router.put('/flags/:id/resolve', authenticate, requireAdmin, collusionController.resolveFlag);

module.exports = router;
