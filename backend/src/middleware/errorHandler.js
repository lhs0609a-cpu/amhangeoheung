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

// 404 핸들러
const notFoundHandler = (req, res, next) => {
  res.status(404).json({
    success: false,
    message: `${req.originalUrl} 경로를 찾을 수 없습니다.`
  });
};

// Mongoose 에러 변환
const handleMongooseError = (err) => {
  if (err.name === 'CastError') {
    return new AppError(`잘못된 ${err.path}: ${err.value}`, 400);
  }

  if (err.code === 11000) {
    const field = Object.keys(err.keyValue)[0];
    return new AppError(`이미 사용 중인 ${field}입니다.`, 400);
  }

  if (err.name === 'ValidationError') {
    const errors = Object.values(err.errors).map(el => el.message);
    return new AppError(`유효하지 않은 입력: ${errors.join('. ')}`, 400);
  }

  return err;
};

module.exports = {
  AppError,
  errorHandler,
  notFoundHandler,
  handleMongooseError
};
