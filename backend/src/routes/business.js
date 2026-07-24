const express = require('express');
const router = express.Router();
const businessController = require('../controllers/businessController');
const { authenticate, requireUserType, optionalAuth } = require('../middleware/auth');
const {
  createBusinessValidation,
  searchBusinessValidation,
} = require('../middleware/validators');
const { validateBusinessImages } = require('../middleware/uploadValidator');

// 업체 등록
router.post('/', authenticate, requireUserType('business'), createBusinessValidation, businessController.createBusiness);

// 업체 목록 조회 (공개)
router.get('/', optionalAuth, businessController.getBusinesses);

// 내 업체 목록 조회 (파라미터 라우트보다 먼저 정의)
router.get('/my/list', authenticate, requireUserType('business'), businessController.getMyBusinesses);

// 근처 업체 검색 (파라미터 라우트보다 먼저 정의)
router.get('/nearby', optionalAuth, businessController.getNearbyBusinesses);

// 업체 검색 (파라미터 라우트보다 먼저 정의)
router.get('/search', optionalAuth, searchBusinessValidation, businessController.searchBusinesses);

// 업체 상세 조회 (공개)
router.get('/:id', optionalAuth, businessController.getBusiness);

// 업체 정보 수정
router.put('/:id', authenticate, requireUserType('business'), businessController.updateBusiness);

// 업체 이미지 업로드
router.post('/:id/images', authenticate, requireUserType('business'), validateBusinessImages, businessController.uploadImages);

// 구독 신청
router.post('/:id/subscribe', authenticate, requireUserType('business'), businessController.subscribe);

// 구독 해지
router.post('/:id/unsubscribe', authenticate, requireUserType('business'), businessController.unsubscribe);

// 신뢰도 분석 (공개)
router.get('/:id/trust-analysis', optionalAuth, businessController.getTrustAnalysis);

// 업체 대시보드
router.get('/:id/dashboard', authenticate, requireUserType('business'), businessController.getDashboard);

// 경쟁력 리포트
router.get('/:id/report', authenticate, requireUserType('business'), businessController.getCompetitiveReport);

// 대안 업체 추천
router.get('/:id/alternatives', optionalAuth, businessController.getAlternatives);

// 업체 리뷰 목록
router.get('/:id/reviews', optionalAuth, businessController.getBusinessReviews);

// 업체 미션 목록
router.get('/:id/missions', authenticate, requireUserType('business'), businessController.getBusinessMissions);

// 리뷰에 답변 달기
router.post('/:id/reviews/:reviewId/response', authenticate, requireUserType('business'), businessController.respondToReview);

module.exports = router;
