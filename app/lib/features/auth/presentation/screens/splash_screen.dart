import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isCheckingOnboarding = true;
  bool _onboardingCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingAndAuth();
  }

  Future<void> _checkOnboardingAndAuth() async {
    // 온보딩 완료 여부 확인
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool(AppConstants.onboardingKey) ?? false;

    if (mounted) {
      setState(() {
        _onboardingCompleted = onboardingCompleted;
        _isCheckingOnboarding = false;
      });

      if (!onboardingCompleted) {
        // 온보딩 미완료 -> 온보딩 화면으로
        context.go('/onboarding');
      } else {
        // 온보딩 완료 -> 인증 상태 확인
        ref.read(authProvider.notifier).checkAuthStatus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      // 온보딩이 완료되지 않았으면 인증 상태 변경 무시
      if (_isCheckingOnboarding || !_onboardingCompleted) return;

      if (!next.isLoading) {
        if (next.isAuthenticated) {
          context.go('/home');
        } else {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              context.go('/login');
            }
          });
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 아이콘
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified_user,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            // 앱 이름
            const Text(
              '암행어흥',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '리뷰 신뢰 플랫폼',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 48),
            if (_isCheckingOnboarding || authState.isLoading)
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
          ],
        ),
      ),
    );
  }
}
