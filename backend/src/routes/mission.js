const express = require('express');
const router = express.Router();
const missionController = require('../controllers/missionController');
const { authenticate, requireUserType, requireVerification, requireReviewerGrade } = require('../middleware/auth');

// === 파라미터 없는 라우트 먼저 ===
// 전체 미션 목록
router.get('/', authenticate, missionController.getAllMissions);
router.get('/list', authenticate, missionController.getAllMissions);

// 미션 통계
router.get('/stats/summary', authenticate, missionController.getMissionStats);

// 참여 가능한 미션 목록 (리뷰어용)
router.get('/available', authenticate, requireUserType('reviewer'), requireVerification, missionController.getAvailableMissions);

// 내 미션 목록 (리뷰어)
router.get('/my', authenticate, requireUserType('reviewer'), missionController.getMyMissions);

// === 업체용 ===
// 미션 생성 (미스터리 쇼핑 요청)
router.post('/', authenticate, requireUserType('business'), missionController.createMission);

// === 파라미터 있는 라우트 ===
// 미션 상세 (업체용)
router.get('/:id/business-view', authenticate, requireUserType('business'), missionController.getMissionForBusiness);

// 미션 상세 (리뷰어용 - 블라인드 정보)
router.get('/:id/reviewer-view', authenticate, requireUserType('reviewer'), missionController.getMissionForReviewer);

// 미션 상세
router.get('/:id', authenticate, missionController.getMission);

// 미션 결제
router.post('/:id/pay', authenticate, requireUserType('business'), missionController.payMission);

// 미션 취소
router.post('/:id/cancel', authenticate, requireUserType('business'), missionController.cancelMission);

// 미션 신청
router.post('/:id/apply', authenticate, requireUserType('reviewer'), requireVerification, missionController.applyMission);

// 미션 신청 취소
router.post('/:id/cancel-application', authenticate, requireUserType('reviewer'), missionController.cancelApplication);

// 체크인 (오프라인 미션)
router.post('/:id/check-in', authenticate, requireUserType('reviewer'), missionController.checkIn);

// 체크아웃 (오프라인 미션)
router.post('/:id/check-out', authenticate, requireUserType('reviewer'), missionController.checkOut);

module.exports = router;
