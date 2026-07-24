const express = require('express');
const router = express.Router();
const { authenticate, requireUserType } = require('../middleware/auth');
const certificationController = require('../controllers/certificationController');
const { getAuditHistory } = require('../controllers/qualityAuditController');

// 교육 모듈 목록
router.get('/modules/:day', authenticate, requireUserType('reviewer'), certificationController.getTrainingModules);

// 모듈 시작
router.post('/modules/:moduleId/start', authenticate, requireUserType('reviewer'), certificationController.startModule);

// 퀴즈 제출
router.post('/modules/:moduleId/submit', authenticate, requireUserType('reviewer'), certificationController.submitQuiz);

// 교육일 완료
router.post('/day/:day/complete', authenticate, requireUserType('reviewer'), certificationController.completeDay);

// 종합 시험
router.post('/final-exam', authenticate, requireUserType('reviewer'), certificationController.takeFinalExam);

// 인증 상태
router.get('/status', authenticate, certificationController.getCertificationStatus);

// 재인증 상태
router.get('/recertification', authenticate, certificationController.getRecertificationStatus);

// 품질 감사 이력
router.get('/audit-history', authenticate, requireUserType('reviewer'), getAuditHistory);

module.exports = router;
