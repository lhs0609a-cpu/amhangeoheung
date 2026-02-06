const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');
const { authenticate, requireUserType, optionalAuth } = require('../middleware/auth');

// === 리뷰어용 ===
// 리뷰 작성/수정
router.post('/', authenticate, requireUserType('reviewer'), reviewController.createReview);
router.put('/:id', authenticate, requireUserType('reviewer'), reviewController.updateReview);

// 리뷰 제출
router.post('/:id/submit', authenticate, requireUserType('reviewer'), reviewController.submitReview);

// 증거 자료 업로드
router.post('/:id/evidence/photos', authenticate, requireUserType('reviewer'), reviewController.uploadPhotos);
router.post('/:id/evidence/receipt', authenticate, requireUserType('reviewer'), reviewController.uploadReceipt);
router.post('/:id/evidence/video', authenticate, requireUserType('reviewer'), reviewController.uploadVideo);

// 7일 후 추가 리뷰 (이커머스)
router.post('/:id/follow-up', authenticate, requireUserType('reviewer'), reviewController.submitFollowUpReview);

// 내 리뷰 목록
router.get('/my', authenticate, requireUserType('reviewer'), reviewController.getMyReviews);

// === 소비자용 ===
// 리뷰 목록 (공개)
router.get('/', optionalAuth, reviewController.getReviews);

// 리뷰 상세 (공개)
router.get('/:id', optionalAuth, reviewController.getReview);

// 리뷰 유용성 투표
router.post('/:id/helpful', authenticate, reviewController.markHelpful);
router.post('/:id/not-helpful', authenticate, reviewController.markNotHelpful);

// 리뷰 신고
router.post('/:id/report', authenticate, reviewController.reportReview);

// 리뷰 요청 (이 업체 검증해주세요)
router.post('/request', authenticate, reviewController.requestReview);

// === 업체용 ===
// 선공개 리뷰 목록 (내 업체에 대한 선공개 리뷰 전체)
router.get('/preview', authenticate, requireUserType('business'), reviewController.getPreviewReviews);

// 선공개 리뷰 상세 조회
router.get('/preview/:id', authenticate, requireUserType('business'), reviewController.getPreviewReview);

// 리뷰에 반박/개선 약속 작성
router.post('/:id/business-response', authenticate, requireUserType('business'), reviewController.submitBusinessResponse);

// 리뷰 이의 제기
router.post('/:id/dispute', authenticate, requireUserType('business'), reviewController.disputeReview);

// === 검색/필터 ===
// 카테고리별 리뷰
router.get('/category/:category', optionalAuth, reviewController.getReviewsByCategory);

// 트렌딩 리뷰
router.get('/trending', optionalAuth, reviewController.getTrendingReviews);

// 최근 리뷰
router.get('/recent', optionalAuth, reviewController.getRecentReviews);

module.exports = router;
