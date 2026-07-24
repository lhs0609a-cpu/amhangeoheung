require('dotenv').config();

// Validate critical environment variables before starting
const requiredEnvVars = ['JWT_SECRET', 'SUPABASE_URL', 'SUPABASE_SERVICE_KEY'];
const missingVars = requiredEnvVars.filter(v => !process.env[v]);
if (missingVars.length > 0) {
  console.error(`[FATAL] Missing required environment variables: ${missingVars.join(', ')}`);
  console.error('Copy .env.example to .env and fill in the values.');
  process.exit(1);
}

if (process.env.JWT_SECRET.length < 64) {
  console.error('[FATAL] JWT_SECRET is too short. Generate a secure key:');
  console.error('  node -e "console.log(require(\'crypto\').randomBytes(64).toString(\'hex\'))"');
  process.exit(1);
}

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');

// Routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/user');
const businessRoutes = require('./routes/business');
const missionRoutes = require('./routes/mission');
const reviewRoutes = require('./routes/review');
const settlementRoutes = require('./routes/settlement');
const notificationRoutes = require('./routes/notifications'); // FCM 디바이스 토큰 포함 버전
const rankingRoutes = require('./routes/ranking');
const seasonRoutes = require('./routes/season');
const tutorialRoutes = require('./routes/tutorial');
const referralRoutes = require('./routes/referral');
const analyticsRoutes = require('./routes/analytics');
const certificationRoutes = require('./routes/certification');
const reviewRequestRoutes = require('./routes/reviewRequest');
const detectionTestRoutes = require('./routes/detectionTest');
const collusionRoutes = require('./routes/collusion');
const whistleblowerRoutes = require('./routes/whistleblower');
const trustPreviewRoutes = require('./routes/trustPreview');
const cronRoutes = require('./routes/cron');

const { startScheduler, stopScheduler } = require('./services/schedulerService');

const app = express();

// 미들웨어
app.use(helmet());

// CORS: 허용된 출처만 접근 가능
const allowedOrigins = [
  'http://localhost:3000',
  'http://localhost:8080',
  'https://amhangeoheung.com',
  'https://app.amhangeoheung.com',
  'https://amhangeoheung-backend.fly.dev',
  'https://amhangeoheung-backend-staging.fly.dev',
];
app.use(cors({
  origin: function (origin, callback) {
    // 모바일 앱 등 origin이 없는 요청 허용
    if (!origin) return callback(null, true);
    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    return callback(new Error('CORS policy: Origin not allowed'), false);
  },
  credentials: true,
}));

app.use(morgan('dev'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// 정적 파일 서빙
app.use('/uploads', express.static('uploads'));

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/businesses', businessRoutes);
app.use('/api/missions', missionRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/settlements', settlementRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/rankings', rankingRoutes);
app.use('/api/seasons', seasonRoutes);
app.use('/api/tutorials', tutorialRoutes);
app.use('/api/referrals', referralRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/certification', certificationRoutes);
app.use('/api/review-requests', reviewRequestRoutes);
app.use('/api/detection-tests', detectionTestRoutes);
app.use('/api/admin/collusion', collusionRoutes);
app.use('/api/whistleblower', whistleblowerRoutes);
app.use('/api/trust-preview', trustPreviewRoutes);
app.use('/api/cron', cronRoutes);

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
      notifications: '/api/notifications',
      rankings: '/api/rankings',
      seasons: '/api/seasons',
      tutorials: '/api/tutorials',
      referrals: '/api/referrals',
      analytics: '/api/analytics',
      certification: '/api/certification',
      reviewRequests: '/api/review-requests',
      detectionTests: '/api/detection-tests',
      collusion: '/api/admin/collusion',
      whistleblower: '/api/whistleblower',
      trustPreview: '/api/trust-preview'
    }
  });
});

// 404 핸들러
app.use(notFoundHandler);

// 에러 핸들러
app.use(errorHandler);

const PORT = process.env.PORT || 3000;

// Vercel 등 서버리스 환경에서는 app 핸들러만 export하고 listen하지 않는다.
const isServerless = Boolean(process.env.VERCEL);

const server = isServerless ? null : app.listen(PORT, () => {
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

  // 스케줄러 시작 (정산, 리뷰 자동게시, 미션 만료 등)
  try {
    startScheduler();
    console.log('[SERVER] Scheduler started successfully');
  } catch (err) {
    console.error('[SERVER] Failed to start scheduler:', err.message);
  }
});

// 처리되지 않은 Promise 거부 처리
process.on('unhandledRejection', (err) => {
  console.error('UNHANDLED REJECTION:', err);
});

// Graceful Shutdown
const gracefulShutdown = (signal) => {
  console.log(`[SERVER] ${signal} received. Shutting down gracefully...`);

  // 스케줄러 정지
  try {
    stopScheduler();
    console.log('[SERVER] Scheduler stopped');
  } catch (err) {
    console.error('[SERVER] Error stopping scheduler:', err.message);
  }

  // HTTP 서버 종료 (in-flight 요청 drain 후)
  if (!server) {
    process.exit(0);
    return;
  }
  server.close(() => {
    console.log('[SERVER] HTTP server closed');
    process.exit(0);
  });

  // 30초 후 강제 종료
  setTimeout(() => {
    console.error('[SERVER] Forced shutdown after timeout');
    process.exit(1);
  }, 30000);
};

if (!isServerless) {
  process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
  process.on('SIGINT', () => gracefulShutdown('SIGINT'));
}

module.exports = app;
