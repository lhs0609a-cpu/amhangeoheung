const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analyticsController');
const { optionalAuth } = require('../middleware/auth');

router.post('/event', optionalAuth, analyticsController.trackEvent);
router.post('/batch', optionalAuth, analyticsController.trackBatch);

module.exports = router;
