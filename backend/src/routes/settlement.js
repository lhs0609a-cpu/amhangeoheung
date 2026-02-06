/**
 * 정산 라우트
 * P0-3: 정산 계좌 오류 처리
 */

const express = require('express');
const router = express.Router();
const settlementController = require('../controllers/settlementController');
const { authenticate, requireUserType, requireVerification } = require('../middleware/auth');

// 내 정산 내역 조회 (리뷰어)
router.get(
  '/my',
  authenticate,
  requireUserType('reviewer'),
  settlementController.getMySettlements
);

// 정산 상세 조회
router.get(
  '/:id',
  authenticate,
  requireUserType('reviewer'),
  settlementController.getSettlementDetail
);

// 정산 재시도 요청 (리뷰어)
router.post(
  '/:id/retry',
  authenticate,
  requireUserType('reviewer'),
  settlementController.retrySettlement
);

// 정산 계좌 재인증 (리뷰어)
router.post(
  '/verify-bank-account',
  authenticate,
  requireUserType('reviewer'),
  requireVerification,
  settlementController.verifyBankAccount
);

// 정산 처리 (관리자/스케줄러용 - 나중에 관리자 권한 체크 추가)
router.post(
  '/:escrowId/process',
  authenticate,
  settlementController.processSettlement
);

module.exports = router;
