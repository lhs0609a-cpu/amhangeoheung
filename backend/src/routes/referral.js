const express = require('express');
const router = express.Router();
const rateLimit = require('express-rate-limit');
const referralController = require('../controllers/referralController');
const { authenticate } = require('../middleware/auth');

// Rate limit referral code validation (5 per minute per IP)
const referralApplyLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 5,
  keyGenerator: (req) => req.user?.id || req.ip,
  message: {
    success: false,
    message: '추천 코드 적용 요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
  },
});

router.get('/my-code', authenticate, referralController.getMyReferralCode);
router.get('/stats', authenticate, referralController.getReferralStats);
router.get('/regional-demand', authenticate, referralController.getRegionalDemand);
router.post('/apply', authenticate, referralApplyLimiter, referralController.applyReferralCode);

module.exports = router;
