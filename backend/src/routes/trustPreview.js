const express = require('express');
const router = express.Router();
const trustPreviewController = require('../controllers/trustPreviewController');

// 비인증 엔드포인트
router.get('/', trustPreviewController.getTrustPreview);

module.exports = router;
