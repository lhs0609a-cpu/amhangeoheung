import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';

class BusinessOnboardingScreen extends StatefulWidget {
  const BusinessOnboardingScreen({super.key});

  @override
  State<BusinessOnboardingScreen> createState() => _BusinessOnboardingScreenState();
}

class _BusinessOnboardingScreenState extends State<BusinessOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_SlideData> _slides = [
    _SlideData(
      icon: Icons.verified_user,
      title: '왜 찐 후기가 중요한가',
      subtitle: '진짜 후기는 진짜 고객을 부릅니다',
      description: '가짜 리뷰를 본 고객은 한 번 오고 끝이지만,\n찐 리뷰를 보고 온 고객은 신뢰하고 재방문합니다.',
      gradient: HwahaeColors.gradientPrimary,
    ),
    _SlideData(
      icon: Icons.trending_up,
      title: '나쁜 후기도 기회입니다',
      subtitle: '개선하면 오히려 신뢰도가 상승합니다',
      description: '부정적 리뷰를 받아도 어떻게 개선하느냐에 따라\n고객 반응이 달라집니다.\n개선 약속을 남기고 실천하면 오히려 신뢰도가 상승합니다.',
      gradient: HwahaeColors.gradientAccent,
    ),
    _SlideData(
      icon: Icons.schedule,
      title: '72시간 선공개로 안심',
      subtitle: '답변할 시간이 충분합니다',
      description: '모든 리뷰는 공개 전 72시간 동안\n업체에 먼저 보여집니다.\n답변을 남기거나 개선 약속을 작성할 시간이 충분합니다.',
      gradient: HwahaeColors.gradientCool,
    ),
    _SlideData(
      icon: Icons.security,
      title: '담합 없는 진짜 리뷰',
      subtitle: '100% 진짜 리뷰만 게재',
      description: '3일 교육 인증, AI 담합 감지, 익명화 시스템으로\n100% 진짜 리뷰만 게재됩니다.\n가짜 리뷰 걱정 없이 신뢰할 수 있는 리뷰를 받습니다.',
      gradient: HwahaeColors.gradientWarm,
    ),
    _SlideData(
      icon: Icons.rocket_launch,
      title: '지금 시작하세요',
      subtitle: '14일 무료 체험으로 부담 없이',
      description: '14일 무료 체험으로 부담 없이 시작하세요.\n진짜 고객의 솔직한 피드백을 받아보세요.',
      gradient: HwahaeColors.gradientPrimary,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('business_onboarding_completed', true);

    // Sync onboarding completion to backend
    try {
      final apiClient = ApiClient();
      await apiClient.post('/businesses/my/onboarding-complete');
    } catch (e) {
      // Non-blocking - SharedPreferences already saved locally
      debugPrint('Onboarding sync failed: $e');
    }

    if (mounted) {
      context.go('/business-pricing');
    }
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: HwahaeColors.background,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with skip button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      GestureDetector(
                        onTap: _previousPage,
                        child: const Icon(Icons.arrow_back_ios, size: 20, color: HwahaeColors.textSecondary),
                      )
                    else
                      const SizedBox(width: 20),
                    Text(
                      '${_currentPage + 1} / ${_slides.length}',
                      style: HwahaeTypography.labelMedium.copyWith(
                        color: HwahaeColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: HwahaeColors.textSecondary,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(60, 36),
                      ),
                      child: const Text('건너뛰기'),
                    ),
                  ],
                ),
              ),

              // Dot indicators
              _buildDotIndicators(),
              const SizedBox(height: 16),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildSlide(_slides[index]);
                  },
                ),
              ),

              // Bottom button
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDotIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(colors: _slides[_currentPage].gradient)
                : null,
            color: isActive ? null : HwahaeColors.surfaceContainer,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildSlide(_SlideData slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: slide.gradient,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: slide.gradient[0].withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(slide.icon, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            slide.title,
            style: HwahaeTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Subtitle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: slide.gradient[0].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              slide.subtitle,
              style: HwahaeTypography.labelMedium.copyWith(
                color: slide.gradient[0],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Description
          Text(
            slide.description,
            style: HwahaeTypography.bodyLarge.copyWith(
              color: HwahaeColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final isLastSlide = _currentPage == _slides.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLastSlide
                    ? HwahaeColors.gradientWarm
                    : HwahaeColors.gradientPrimary,
              ),
              borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
              boxShadow: [
                BoxShadow(
                  color: (isLastSlide ? HwahaeColors.warning : HwahaeColors.primary)
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _nextPage,
                borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastSlide ? '구독 플랜 보기' : '다음',
                      style: HwahaeTypography.button.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLastSlide ? Icons.arrow_forward : Icons.arrow_forward_ios,
                      size: 18,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final List<Color> gradient;

  _SlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gradient,
  });
}
