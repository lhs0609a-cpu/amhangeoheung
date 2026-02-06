require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');

// Routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/user');
const businessRoutes = require('./routes/business');
const missionRoutes = require('./routes/mission');
const reviewRoutes = require('./routes/review');
const settlementRoutes = require('./routes/settlement');
const trustPreviewRoutes = require('./routes/trustPreview');
const notificationRoutes = require('./routes/notifications');

const app = express();

// CORS 설정 - 허용된 오리진만 허용
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',').map(o => o.trim())
  : ['http://localhost:3000'];

app.use(helmet());
app.use(cors({
  origin: (origin, callback) => {
    // 모바일 앱 등 origin이 없는 요청 허용
    if (!origin) return callback(null, true);
    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    return callback(new Error('CORS 정책에 의해 차단되었습니다.'));
  },
  credentials: true,
}));
app.use(morgan('dev'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Rate Limiting - 전역
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15분
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: '너무 많은 요청을 보냈습니다. 잠시 후 다시 시도해주세요.',
  },
});
app.use(globalLimiter);

// Rate Limiting - 인증 엔드포인트 (더 엄격)
const authLoginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15분
  max: 10,
  message: {
    success: false,
    message: '로그인 시도가 너무 많습니다. 15분 후 다시 시도해주세요.',
  },
});

const authRegisterLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1시간
  max: 5,
  message: {
    success: false,
    message: '회원가입 시도가 너무 많습니다. 1시간 후 다시 시도해주세요.',
  },
});

const paymentLimiter = rateLimit({
  windowMs: 60 * 1000, // 1분
  max: 3,
  message: {
    success: false,
    message: '결제 요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
  },
});

// 정적 파일 서빙
app.use('/uploads', express.static('uploads'));

// API Routes
app.use('/api/auth/login', authLoginLimiter);
app.use('/api/auth/register', authRegisterLimiter);
app.use('/api/payments', paymentLimiter);

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/businesses', businessRoutes);
app.use('/api/missions', missionRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/settlements', settlementRoutes);
app.use('/api/trust-preview', trustPreviewRoutes);
app.use('/api/notifications', notificationRoutes);

// Health Check
app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: '암행어흥 API 서버가 정상 작동 중입니다.',
    timestamp: new Date().toISOString(),
    database: 'Supabase (PostgreSQL)'
  });
});

// API 문서
app.get('/api', (req, res) => {
  res.json({
    success: true,
    message: '암행어흥 API v1.0',
    database: 'Supabase',
    endpoints: {
      auth: '/api/auth',
      users: '/api/users',
      businesses: '/api/businesses',
      missions: '/api/missions',
      reviews: '/api/reviews',
      settlements: '/api/settlements',
      trustPreview: '/api/trust-preview',
      notifications: '/api/notifications'
    }
  });
});

// 404 핸들러
app.use(notFoundHandler);

// 에러 핸들러
app.use(errorHandler);

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`
  ╔═══════════════════════════════════════════╗
  ║                                           ║
  ║   암행어흥 API 서버                        ║
  ║   Server running on port ${PORT}             ║
  ║   Environment: ${process.env.NODE_ENV || 'development'}           ║
  ║   Database: Supabase (PostgreSQL)         ║
  ║                                           ║
  ╚═══════════════════════════════════════════╝
  `);
});

// 처리되지 않은 Promise 거부 처리
process.on('unhandledRejection', (err) => {
  console.error('UNHANDLED REJECTION:', err);
});

module.exports = app;
