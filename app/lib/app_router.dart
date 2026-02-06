import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/onboarding/presentation/screens/free_trial_screen.dart';
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

      // Main Shell (Bottom Navigation)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
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

      // Business Pricing Route
      GoRoute(
        path: '/business-pricing',
        builder: (context, state) => const BusinessPricingScreen(),
      ),

      // Search Route
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),

      // Notifications Route
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),

      // Dashboard Route
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
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
