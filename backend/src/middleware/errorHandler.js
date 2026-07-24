// 에러 핸들링 미들웨어

class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

const errorHandler = (err, req, res, next) => {
  err.statusCode = err.statusCode || 500;
  err.status = err.status || 'error';

  // CORS 에러
  if (err.message && err.message.includes('CORS policy')) {
    return res.status(403).json({
      success: false,
      message: '허용되지 않은 출처입니다.'
    });
  }

  // Supabase/PostgreSQL 에러
  if (err.code && typeof err.code === 'string' && err.code.length === 5) {
    const pgError = handlePostgresError(err);
    return res.status(pgError.statusCode).json({
      success: false,
      message: pgError.message
    });
  }

  // Axios 에러 (TossPayments 등 외부 API)
  if (err.isAxiosError) {
    const axiosError = handleAxiosError(err);
    return res.status(axiosError.statusCode).json({
      success: false,
      message: axiosError.message
    });
  }

  // JWT 에러
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({
      success: false,
      message: '유효하지 않은 토큰입니다.'
    });
  }

  if (err.name === 'TokenExpiredError') {
    return res.status(401).json({
      success: false,
      message: '토큰이 만료되었습니다.'
    });
  }

  // express-validator 에러
  if (err.array && typeof err.array === 'function') {
    return res.status(400).json({
      success: false,
      message: '입력 값이 올바르지 않습니다.',
      errors: err.array()
    });
  }

  // Multer 파일 업로드 에러
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({
      success: false,
      message: '파일 크기가 제한을 초과했습니다.'
    });
  }

  if (err.code === 'LIMIT_UNEXPECTED_FILE') {
    return res.status(400).json({
      success: false,
      message: '허용되지 않은 파일 형식입니다.'
    });
  }

  if (process.env.NODE_ENV === 'development') {
    return res.status(err.statusCode).json({
      success: false,
      status: err.status,
      message: err.message,
      stack: err.stack,
      error: err
    });
  }

  // Production 환경
  if (err.isOperational) {
    return res.status(err.statusCode).json({
      success: false,
      status: err.status,
      message: err.message
    });
  }

  // 프로그래밍 또는 알 수 없는 에러
  console.error('ERROR:', err);

  return res.status(500).json({
    success: false,
    status: 'error',
    message: '서버 오류가 발생했습니다.'
  });
};

// PostgreSQL 에러 처리
const handlePostgresError = (err) => {
  switch (err.code) {
    case '23505': // unique_violation
      return { statusCode: 400, message: '이미 존재하는 데이터입니다.' };
    case '23503': // foreign_key_violation
      return { statusCode: 400, message: '참조하는 데이터가 존재하지 않습니다.' };
    case '23502': // not_null_violation
      return { statusCode: 400, message: '필수 항목이 누락되었습니다.' };
    case '22P02': // invalid_text_representation
      return { statusCode: 400, message: '잘못된 데이터 형식입니다.' };
    case '42501': // insufficient_privilege
      return { statusCode: 403, message: '권한이 없습니다.' };
    default:
      console.error('Postgres error:', err.code, err.message);
      return { statusCode: 500, message: '데이터베이스 오류가 발생했습니다.' };
  }
};

// Axios 에러 처리
const handleAxiosError = (err) => {
  if (err.response) {
    const status = err.response.status;
    if (status >= 400 && status < 500) {
      return {
        statusCode: status,
        message: err.response.data?.message || '외부 서비스 요청이 실패했습니다.'
      };
    }
    return { statusCode: 502, message: '외부 서비스에 오류가 발생했습니다.' };
  }
  if (err.code === 'ECONNABORTED') {
    return { statusCode: 504, message: '외부 서비스 응답 시간이 초과되었습니다.' };
  }
  return { statusCode: 503, message: '외부 서비스에 연결할 수 없습니다.' };
};

// 404 핸들러
const notFoundHandler = (req, res, next) => {
  res.status(404).json({
    success: false,
    message: `${req.originalUrl} 경로를 찾을 수 없습니다.`
  });
};

module.exports = {
  AppError,
  errorHandler,
  notFoundHandler
};
