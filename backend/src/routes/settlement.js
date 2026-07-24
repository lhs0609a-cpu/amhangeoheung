/**
 * 정산 라우트
 */

const express = require('express');
const router = express.Router();
const settlementController = require('../controllers/settlementController');
const { authenticate, requireUserType, requireAdmin, requireVerification } = require('../middleware/auth');
const { verifyBankAccountValidation } = require('../middleware/validators');

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
  verifyBankAccountValidation,
  settlementController.verifyBankAccount
);

// 정산 처리 (관리자 전용)
router.post(
  '/:escrowId/process',
  authenticate,
  requireAdmin,
  settlementController.processSettlement
);

module.exports = router;
