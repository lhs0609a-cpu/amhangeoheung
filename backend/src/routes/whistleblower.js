const express = require('express');
const router = express.Router();
const whistleblowerController = require('../controllers/whistleblowerController');
const { authenticate, requireUserType } = require('../middleware/auth');

// 리뷰어: 담합 시도 신고
router.post('/report', authenticate, requireUserType('reviewer'), whistleblowerController.createReport);

// 관리자: 신고 목록
router.get('/', authenticate, requireUserType('admin'), whistleblowerController.getReports);

// 관리자: 신고 처리
router.put('/:id', authenticate, requireUserType('admin'), whistleblowerController.resolveReport);

module.exports = router;
