const express = require('express');
const router = express.Router();
const rankingController = require('../controllers/rankingController');
const { optionalAuth } = require('../middleware/auth');

router.get('/regional', optionalAuth, rankingController.getRegionalRanking);
router.get('/reviewers', optionalAuth, rankingController.getReviewerRanking);
router.get('/regions', optionalAuth, rankingController.getAvailableRegions);

module.exports = router;
