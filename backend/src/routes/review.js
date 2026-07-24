const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');
const reviewTopicController = require('../controllers/reviewTopicController');
const { authenticate, requireUserType, optionalAuth, requireAdmin } = require('../middleware/auth');
const {
  createReviewValidation,
  reportReviewValidation,
  businessResponseValidation,
  disputeReviewValidation,
  uuidParam,
} = require('../middleware/validators');
const { validateReviewPhotos, validateReceiptUpload, validateVideoUpload } = require('../middleware/uploadValidator');
const { fingerprintMiddleware } = require('../middleware/fingerprint');

// === 파라미터 없는 라우트 먼저 ===
// 내 리뷰 목록
router.get('/my', authenticate, requireUserType('reviewer'), reviewController.getMyReviews);

// 선공개 리뷰 목록 (내 업체에 대한 선공개 리뷰 전체)
router.get('/preview', authenticate, requireUserType('business'), reviewController.getPreviewReviews);

// 리뷰 요청 (이 업체 검증해주세요)
router.post('/request', authenticate, reviewController.requestReview);

// 카테고리별 리뷰 토픽 정의
router.get('/topics/:category', optionalAuth, reviewTopicController.getTopicsByCategory);

// 카테고리별 리뷰
router.get('/category/:category', optionalAuth, reviewController.getReviewsByCategory);

// 트렌딩 리뷰
router.get('/trending', optionalAuth, reviewController.getTrendingReviews);

// 최근 리뷰
router.get('/recent', optionalAuth, reviewController.getRecentReviews);

// === 관리자용: 영수증 수동 검토 큐 ===
router.get('/admin/receipt-queue', authenticate, requireAdmin, reviewController.getReceiptReviewQueue);

// === 리뷰어용 ===
// 리뷰 작성
router.post('/', authenticate, requireUserType('reviewer'), fingerprintMiddleware, createReviewValidation, reviewController.createReview);

// 리뷰 목록 (공개)
router.get('/', optionalAuth, reviewController.getReviews);

// === 파라미터 있는 라우트 ===
// 선공개 리뷰 상세 조회
router.get('/preview/:id', authenticate, requireUserType('business'), reviewController.getPreviewReview);

// 리뷰 상세 (공개)
router.get('/:id', optionalAuth, reviewController.getReview);

// 리뷰 수정
router.put('/:id', authenticate, requireUserType('reviewer'), createReviewValidation, reviewController.updateReview);

// 리뷰 제출
router.post('/:id/submit', authenticate, requireUserType('reviewer'), fingerprintMiddleware, reviewController.submitReview);

// 증거 자료 업로드
router.post('/:id/evidence/photos', authenticate, requireUserType('reviewer'), validateReviewPhotos, reviewController.uploadPhotos);
router.post('/:id/evidence/receipt', authenticate, requireUserType('reviewer'), validateReceiptUpload, reviewController.uploadReceipt);
// 관리자: 영수증 수동 검토 결정 (승인/반려)
router.post('/:id/receipt-review', authenticate, requireAdmin, reviewController.decideReceiptReview);
router.post('/:id/evidence/video', authenticate, requireUserType('reviewer'), validateVideoUpload, reviewController.uploadVideo);

// 영수증 사용 등록 (재사용 방지 기록) - :id 는 미션 ID
router.post('/:id/receipt-usage', authenticate, requireUserType('reviewer'), reviewController.registerReceiptUsage);

// 7일 후 추가 리뷰 (이커머스)
router.post('/:id/follow-up', authenticate, requireUserType('reviewer'), reviewController.submitFollowUpReview);

// 리뷰 유용성 투표
router.post('/:id/helpful', authenticate, reviewController.markHelpful);
router.post('/:id/not-helpful', authenticate, reviewController.markNotHelpful);

// 리뷰 신고
router.post('/:id/report', authenticate, reportReviewValidation, reviewController.reportReview);

// === 업체용 ===
// 리뷰에 반박/개선 약속 작성
router.post('/:id/business-response', authenticate, requireUserType('business'), businessResponseValidation, reviewController.submitBusinessResponse);

// 리뷰 이의 제기
router.post('/:id/dispute', authenticate, requireUserType('business'), disputeReviewValidation, reviewController.disputeReview);

module.exports = router;
