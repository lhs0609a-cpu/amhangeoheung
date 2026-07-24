const { body, param, query } = require('express-validator');

// === Auth ===
const registerValidation = [
  body('email').isEmail().withMessage('유효한 이메일을 입력하세요.'),
  body('password')
    .isLength({ min: 8 })
    .withMessage('비밀번호는 최소 8자 이상이어야 합니다.'),
  body('phone').isMobilePhone('ko-KR').withMessage('유효한 휴대폰 번호를 입력하세요.'),
  body('name').notEmpty().trim().withMessage('이름을 입력하세요.'),
  body('userType')
    .isIn(['consumer', 'reviewer', 'business'])
    .withMessage('유효한 사용자 유형을 선택하세요.')
];

const loginValidation = [
  body('email').isEmail().withMessage('유효한 이메일을 입력하세요.'),
  body('password').notEmpty().withMessage('비밀번호를 입력하세요.')
];

const forgotPasswordValidation = [
  body('email').isEmail().withMessage('유효한 이메일을 입력하세요.')
];

const resetPasswordValidation = [
  body('token').notEmpty().withMessage('토큰이 필요합니다.'),
  body('newPassword')
    .isLength({ min: 8 })
    .withMessage('비밀번호는 최소 8자 이상이어야 합니다.')
];

const socialLoginValidation = [
  body('provider')
    .isIn(['google', 'kakao', 'apple'])
    .withMessage('유효한 소셜 로그인 제공자를 선택하세요.'),
  body('accessToken').notEmpty().withMessage('액세스 토큰이 필요합니다.')
];

// === User ===
const updateProfileValidation = [
  body('name').optional().trim().isLength({ min: 1, max: 50 }).withMessage('이름은 1~50자여야 합니다.'),
  body('nickname').optional().trim().isLength({ min: 2, max: 20 }).withMessage('닉네임은 2~20자여야 합니다.')
];

const changePasswordValidation = [
  body('currentPassword').notEmpty().withMessage('현재 비밀번호를 입력하세요.'),
  body('newPassword')
    .isLength({ min: 8 })
    .withMessage('새 비밀번호는 최소 8자 이상이어야 합니다.')
];

const updateNotificationValidation = [
  body('push').optional().isBoolean().withMessage('push는 boolean이어야 합니다.'),
  body('email').optional().isBoolean().withMessage('email은 boolean이어야 합니다.'),
  body('sms').optional().isBoolean().withMessage('sms는 boolean이어야 합니다.')
];

const updateBankAccountValidation = [
  body('bank').notEmpty().withMessage('은행을 선택하세요.'),
  body('accountNumber')
    .notEmpty()
    .matches(/^[0-9-]+$/)
    .withMessage('유효한 계좌번호를 입력하세요.'),
  body('accountHolder').notEmpty().trim().withMessage('예금주를 입력하세요.')
];

const updateSpecialtiesValidation = [
  body('specialties')
    .isArray({ min: 1, max: 5 })
    .withMessage('전문 카테고리는 1~5개까지 선택할 수 있습니다.')
];

// === Mission ===
const createMissionValidation = [
  body('missionType')
    .isIn(['offline', 'online', 'ecommerce'])
    .withMessage('유효한 미션 유형을 선택하세요.'),
  body('businessId').notEmpty().isUUID().withMessage('업체 ID가 필요합니다.'),
  body('rewardType')
    .optional()
    .isIn(['cash', 'free_experience'])
    .withMessage('보상 타입은 cash 또는 free_experience 여야 합니다.'),
  // 무료체험 미션은 reviewerFee를 보내지 않거나 0이어도 됨(서버에서 0으로 강제)
  body('reviewerFee')
    .optional()
    .isInt({ min: 0 })
    .withMessage('리뷰어 보상금은 0 이상이어야 합니다.'),
  body('productCost')
    .optional()
    .isInt({ min: 0 })
    .withMessage('제품/서비스 비용은 0 이상이어야 합니다.'),
  body('experienceDescription')
    .if(body('rewardType').equals('free_experience'))
    .trim()
    .notEmpty()
    .withMessage('무료체험 미션은 제공 내용(experienceDescription)을 입력해야 합니다.'),
  body('maxApplicants')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('최대 신청자 수는 1~100명이어야 합니다.')
];

const checkInValidation = [
  param('id').isUUID().withMessage('유효한 미션 ID가 필요합니다.'),
  body('latitude')
    .isFloat({ min: 33, max: 39 })
    .withMessage('유효한 위도를 입력하세요. (한국 범위: 33~39)'),
  body('longitude')
    .isFloat({ min: 124, max: 132 })
    .withMessage('유효한 경도를 입력하세요. (한국 범위: 124~132)')
];

const checkOutValidation = [
  param('id').isUUID().withMessage('유효한 미션 ID가 필요합니다.'),
  body('latitude')
    .isFloat({ min: 33, max: 39 })
    .withMessage('유효한 위도를 입력하세요.'),
  body('longitude')
    .isFloat({ min: 124, max: 132 })
    .withMessage('유효한 경도를 입력하세요.')
];

// === Review ===
const createReviewValidation = [
  body('missionId').notEmpty().isUUID().withMessage('미션 ID가 필요합니다.'),
  body('overallScore')
    .isFloat({ min: 1, max: 5 })
    .withMessage('평점은 1~5 사이여야 합니다.'),
  body('content')
    .notEmpty()
    .isLength({ min: 50, max: 5000 })
    .withMessage('리뷰 내용은 50~5000자여야 합니다.'),
  body('pros').optional().isArray().withMessage('장점은 배열이어야 합니다.'),
  body('cons').optional().isArray().withMessage('단점은 배열이어야 합니다.')
];

const reportReviewValidation = [
  param('id').isUUID().withMessage('유효한 리뷰 ID가 필요합니다.'),
  body('reason')
    .isIn(['spam', 'inappropriate', 'fake', 'personal_info', 'other'])
    .withMessage('유효한 신고 사유를 선택하세요.'),
  body('description').optional().isLength({ max: 500 }).withMessage('설명은 500자 이하여야 합니다.')
];

const businessResponseValidation = [
  param('id').isUUID().withMessage('유효한 리뷰 ID가 필요합니다.'),
  body('content')
    .notEmpty()
    .isLength({ min: 10, max: 2000 })
    .withMessage('답변은 10~2000자여야 합니다.')
];

const disputeReviewValidation = [
  param('id').isUUID().withMessage('유효한 리뷰 ID가 필요합니다.'),
  body('reason').notEmpty().isLength({ min: 10, max: 1000 }).withMessage('이의 사유를 입력하세요 (10~1000자).')
];

// === Business ===
const createBusinessValidation = [
  body('name').notEmpty().trim().isLength({ min: 2, max: 100 }).withMessage('업체명은 2~100자여야 합니다.'),
  body('category').notEmpty().withMessage('카테고리를 선택하세요.'),
  body('phone').optional().isMobilePhone('ko-KR').withMessage('유효한 전화번호를 입력하세요.')
];

const searchBusinessValidation = [
  query('q').optional().trim().isLength({ max: 100 }).withMessage('검색어는 100자 이하여야 합니다.'),
  query('category').optional().trim(),
  query('city').optional().trim()
];

// === Settlement ===
const verifyBankAccountValidation = [
  body('bank').notEmpty().withMessage('은행을 선택하세요.'),
  body('accountNumber')
    .notEmpty()
    .matches(/^[0-9-]+$/)
    .withMessage('유효한 계좌번호를 입력하세요.'),
  body('accountHolder').notEmpty().trim().withMessage('예금주를 입력하세요.')
];

// === Common ===
const uuidParam = [
  param('id').isUUID().withMessage('유효한 ID가 필요합니다.')
];

const paginationQuery = [
  query('page').optional().isInt({ min: 1 }).withMessage('페이지 번호는 1 이상이어야 합니다.'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('페이지 크기는 1~100이어야 합니다.')
];

module.exports = {
  // Auth
  registerValidation,
  loginValidation,
  forgotPasswordValidation,
  resetPasswordValidation,
  socialLoginValidation,
  // User
  updateProfileValidation,
  changePasswordValidation,
  updateNotificationValidation,
  updateBankAccountValidation,
  updateSpecialtiesValidation,
  // Mission
  createMissionValidation,
  checkInValidation,
  checkOutValidation,
  // Review
  createReviewValidation,
  reportReviewValidation,
  businessResponseValidation,
  disputeReviewValidation,
  // Business
  createBusinessValidation,
  searchBusinessValidation,
  // Settlement
  verifyBankAccountValidation,
  // Common
  uuidParam,
  paginationQuery,
};
