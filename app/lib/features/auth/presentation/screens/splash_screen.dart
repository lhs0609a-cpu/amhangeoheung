import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';
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
        if (!context.mounted) return;
        if (next.isAuthenticated) {
          context.go('/home');
        } else {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && context.mounted) {
              context.go('/login');
            }
          });
        }
      }
    });

    // 바탕은 크림이다. 골드로 깔면 그 위에 올릴 글자가 마땅치 않다 —
    // 흰 글자는 1.86:1 이라 안 보이고, 먹 글자는 첫인상이 탁해진다.
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppMascot.eoheung(size: 140),
            const SizedBox(height: 20),
            Text(
              '암행어흥',
              style: HwahaeTypography.displayMedium.copyWith(
                color: HwahaeColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '리뷰 신뢰 플랫폼',
              style: HwahaeTypography.bodyMedium.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
            const SizedBox(height: 44),
            // 자리를 늘 차지하게 둔다. 로딩이 끝날 때 글자가 위로 튀지 않는다.
            SizedBox(
              height: 28,
              child: (_isCheckingOnboarding || authState.isLoading)
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        color: HwahaeColors.primaryDark,
                        strokeWidth: 3,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
