const express = require('express');
const router = express.Router();
const tutorialController = require('../controllers/tutorialController');
const { optionalAuth } = require('../middleware/auth');

// 튜토리얼 세션 시작 (인증 불필요)
router.post('/start', optionalAuth, tutorialController.startTutorial);

// 진행 업데이트 (인증 불필요)
router.put('/:sessionId/progress', optionalAuth, tutorialController.updateProgress);

// 서약 동의 (인증 불필요)
router.post('/:sessionId/pledge', optionalAuth, tutorialController.acceptPledge);

// 튜토리얼 완료 (인증 불필요)
router.post('/:sessionId/complete', optionalAuth, tutorialController.completeTutorial);

module.exports = router;
