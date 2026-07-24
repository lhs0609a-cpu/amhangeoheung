const express = require('express');
const router = express.Router();
const reviewRequestController = require('../controllers/reviewRequestController');
const { authenticate, optionalAuth, requireUserType } = require('../middleware/auth');

router.post('/', authenticate, reviewRequestController.createRequest);
router.get('/business/:id', authenticate, requireUserType('business'), reviewRequestController.getRequestsForBusiness);
router.get('/popular', optionalAuth, reviewRequestController.getPopularRequests);

module.exports = router;
