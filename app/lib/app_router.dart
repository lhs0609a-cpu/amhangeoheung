import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/email_verification_screen.dart';
import 'features/onboarding/presentation/screens/free_trial_screen.dart';
import 'features/onboarding/presentation/screens/user_type_selection_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/mission/presentation/screens/mission_list_screen.dart';
import 'features/mission/presentation/screens/mission_detail_screen.dart';
import 'features/mission/presentation/screens/tutorial_mission_screen.dart';
import 'features/review/presentation/screens/review_list_screen.dart';
import 'features/review/presentation/screens/review_detail_screen.dart';
import 'features/review/presentation/screens/write_review_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/profile/presentation/screens/edit_profile_screen.dart';
import 'features/profile/presentation/screens/my_reviews_screen.dart';
import 'features/profile/presentation/screens/settlements_screen.dart';
import 'features/profile/presentation/screens/specialties_screen.dart';
import 'features/profile/presentation/screens/bank_account_screen.dart';
import 'features/profile/presentation/screens/support_screen.dart';
import 'features/profile/presentation/screens/notifications_settings_screen.dart';
import 'features/profile/presentation/screens/about_screen.dart';
import 'features/ranking/presentation/screens/ranking_screen.dart';
import 'features/trust/presentation/screens/trust_analysis_screen.dart';
import 'features/pricing/presentation/screens/pricing_screen.dart';
import 'features/pricing/presentation/screens/business_pricing_screen.dart';
import 'features/search/presentation/screens/search_screen.dart';
import 'features/legal/presentation/screens/legal_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/notification/presentation/screens/notification_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/portfolio/presentation/screens/portfolio_screen.dart';
import 'features/accessibility/presentation/screens/accessibility_screen.dart';
import 'features/business/presentation/screens/preview_reviews_screen.dart';
import 'features/business/presentation/screens/cancel_subscription_screen.dart';
import 'features/business/presentation/screens/business_onboarding_screen.dart';
import 'features/mission/presentation/screens/season_detail_screen.dart';
import 'features/referral/presentation/screens/invite_screen.dart';
import 'features/ranking/presentation/screens/regional_ranking_screen.dart';
import 'features/review_request/presentation/screens/request_review_screen.dart';
import 'features/certification/presentation/screens/certification_home_screen.dart';
import 'features/certification/presentation/screens/training_module_screen.dart';
import 'features/certification/presentation/screens/final_exam_screen.dart';
import 'features/detection_test/presentation/screens/detection_test_screen.dart';
import 'features/detection_test/presentation/screens/stealth_stats_screen.dart';
import 'shared/widgets/main_scaffold.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return EmailVerificationScreen(email: email);
        },
      ),

      // User Type Selection (회원가입 후 유형 선택)
      GoRoute(
        path: '/select-user-type',
        builder: (context, state) => const UserTypeSelectionScreen(),
      ),

      // Free Trial (Value-First Onboarding)
      GoRoute(
        path: '/try-free',
        builder: (context, state) => const FreeTrialScreen(),
      ),

      // Tutorial Mission (리뷰어 튜토리얼)
      GoRoute(
        path: '/tutorial-mission',
        builder: (context, state) => const TutorialMissionScreen(),
      ),

      // Main Shell (Bottom Navigation) - 모든 유형의 탭 라우트 통합
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          // 공통 라우트
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/missions',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MissionListScreen(),
            ),
          ),
          GoRoute(
            path: '/ranking',
            pageBuilder: (context, state) {
              final tab = state.uri.queryParameters['tab'];
              return NoTransitionPage(
                child: RankingScreen(initialTab: tab),
              );
            },
          ),
          GoRoute(
            path: '/reviews',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReviewListScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
          // 업체 유형: 대시보드 (ShellRoute 내부)
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          // 소비자 유형: 검색 (ShellRoute 내부)
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchScreen(),
            ),
          ),
          // 리뷰어 유형: 내 활동 (미션 진행 + 완료 목록)
          GoRoute(
            path: '/my-activity',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MyReviewsScreen(),
            ),
          ),
          // 업체 유형: 분석 (센터 FAB)
          GoRoute(
            path: '/trust-overview',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
        ],
      ),

      // Detail Routes (Outside Shell)
      GoRoute(
        path: '/missions/:id',
        builder: (context, state) => MissionDetailScreen(
          missionId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/reviews/:id',
        builder: (context, state) => ReviewDetailScreen(
          reviewId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/write-review/:missionId',
        builder: (context, state) => WriteReviewScreen(
          missionId: state.pathParameters['missionId']!,
        ),
      ),

      // Trust Analysis Route
      GoRoute(
        path: '/trust/:businessId',
        builder: (context, state) => TrustAnalysisScreen(
          businessId: state.pathParameters['businessId']!,
        ),
      ),

      // Pricing Route
      GoRoute(
        path: '/pricing',
        builder: (context, state) => const PricingScreen(),
      ),

      // Business Onboarding Slides
      GoRoute(
        path: '/business-onboarding',
        builder: (context, state) => const BusinessOnboardingScreen(),
      ),

      // Business Pricing Route
      GoRoute(
        path: '/business-pricing',
        builder: (context, state) => const BusinessPricingScreen(),
      ),

      // Notifications Route
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),

      // Preview Reviews (업체용 선공개 리뷰)
      GoRoute(
        path: '/preview-reviews',
        builder: (context, state) => const PreviewReviewsScreen(),
      ),

      // Settings Route
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Portfolio Route
      GoRoute(
        path: '/portfolio/:userId',
        builder: (context, state) => PortfolioScreen(
          userId: state.pathParameters['userId']!,
        ),
      ),

      // Accessibility Route
      GoRoute(
        path: '/accessibility',
        builder: (context, state) => const AccessibilityScreen(),
      ),

      // Legal Routes
      GoRoute(
        path: '/terms',
        builder: (context, state) => const LegalScreen(type: LegalType.terms),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const LegalScreen(type: LegalType.privacy),
      ),
      GoRoute(
        path: '/location-privacy',
        builder: (context, state) => const LegalScreen(type: LegalType.locationPrivacy),
      ),
      GoRoute(
        path: '/marketing',
        builder: (context, state) => const LegalScreen(type: LegalType.marketing),
      ),

      // Season Detail Route
      GoRoute(
        path: '/seasons/:id',
        builder: (context, state) => SeasonDetailScreen(
          seasonId: state.pathParameters['id']!,
        ),
      ),

      // Invite Route (추천인 시스템)
      GoRoute(
        path: '/invite',
        builder: (context, state) => const InviteScreen(),
      ),

      // Cancel Subscription Route (구독 해지 리텐션)
      GoRoute(
        path: '/business/:id/cancel',
        builder: (context, state) => CancelSubscriptionScreen(
          businessId: state.pathParameters['id']!,
        ),
      ),

      // Regional Ranking Route
      GoRoute(
        path: '/ranking/regional',
        builder: (context, state) {
          final region = state.uri.queryParameters['region'];
          final category = state.uri.queryParameters['category'];
          return RegionalRankingScreen(
            initialRegion: region,
            initialCategory: category,
          );
        },
      ),

      // Review Request Route
      GoRoute(
        path: '/request-review/:businessId',
        builder: (context, state) => RequestReviewScreen(
          businessId: state.pathParameters['businessId']!,
        ),
      ),

      // Certification Routes (리뷰어 교육/인증)
      GoRoute(
        path: '/certification',
        builder: (context, state) => const CertificationHomeScreen(),
      ),
      GoRoute(
        path: '/certification/training/:day',
        builder: (context, state) => TrainingModuleScreen(
          day: int.parse(state.pathParameters['day']!),
        ),
      ),
      GoRoute(
        path: '/certification/exam',
        builder: (context, state) => const FinalExamScreen(),
      ),

      // Detection Test Routes (역탐지 테스트)
      GoRoute(
        path: '/detection-test/:id',
        builder: (context, state) => DetectionTestScreen(
          testId: state.pathParameters['id']!,
        ),
      ),

      // Stealth Stats Route (은밀성 통계)
      GoRoute(
        path: '/stealth-stats',
        builder: (context, state) => const StealthStatsScreen(),
      ),

      // Profile Sub-Routes
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/my-reviews',
        builder: (context, state) => const MyReviewsScreen(),
      ),
      GoRoute(
        path: '/settlements',
        builder: (context, state) => const SettlementsScreen(),
      ),
      GoRoute(
        path: '/specialties',
        builder: (context, state) => const SpecialtiesScreen(),
      ),
      GoRoute(
        path: '/bank-account',
        builder: (context, state) => const BankAccountScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/notifications-settings',
        builder: (context, state) => const NotificationsSettingsScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
}
