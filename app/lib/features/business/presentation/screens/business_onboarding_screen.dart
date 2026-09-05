import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';

/// 업체가 처음 들어왔을 때 보는 다섯 장.
///
/// 파는 것은 "리뷰를 좋게 만들어주는 서비스"가 아니라 **결과를 못 바꾸는
/// 감찰**이다. 그래서 여기서 약속하는 것도 좋은 평점이 아니라 시간(72시간
/// 선공개)과 진짜 리뷰다. 이 순서를 흐리면 나중에 환불 분쟁이 된다.
class BusinessOnboardingScreen extends StatefulWidget {
  const BusinessOnboardingScreen({super.key});

  @override
  State<BusinessOnboardingScreen> createState() =>
      _BusinessOnboardingScreenState();
}

class _Slide {
  const _Slide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color color;
}

const _slides = <_Slide>[
  _Slide(
    icon: Icons.verified_user_rounded,
    title: '왜 찐 후기가 중요한가',
    subtitle: '진짜 후기는 진짜 고객을 부릅니다',
    description: '가짜 리뷰를 본 고객은 한 번 오고 끝이지만,\n'
        '찐 리뷰를 보고 온 고객은 신뢰하고 재방문합니다.',
    color: HwahaeColors.primary,
  ),
  _Slide(
    icon: Icons.trending_up_rounded,
    title: '나쁜 후기도 기회입니다',
    subtitle: '고치면 그 사실까지 함께 남습니다',
    description: '지적을 받으면 그 지적이 사라지지 않고 추적됩니다.\n'
        '대신 고쳤다는 것이 확인되면 그 사실도 같이 남습니다.\n'
        '지운 리뷰보다 고친 기록이 더 설득력이 있습니다.',
    color: HwahaeColors.accent,
  ),
  _Slide(
    icon: Icons.schedule_rounded,
    title: '72시간 선공개',
    subtitle: '답변할 시간을 먼저 드립니다',
    description: '모든 리뷰는 공개 전 72시간 동안 업체에 먼저 보입니다.\n'
        '답변을 남기거나 개선 약속을 쓸 시간이 있습니다.\n'
        '다만 내용을 바꾸거나 내릴 수는 없습니다.',
    color: HwahaeColors.primaryDark,
  ),
  _Slide(
    icon: Icons.security_rounded,
    title: '담합 없는 진짜 리뷰',
    subtitle: '감찰관도 검증합니다',
    description: '3일 교육 인증, 담합 감지 엔진, 익명화로\n'
        '실제로 다녀온 사람의 리뷰만 남습니다.\n'
        '업체가 감찰관을 고를 수 없고, 감찰관도 업체를 못 고릅니다.',
    color: HwahaeColors.info,
  ),
  _Slide(
    icon: Icons.rocket_launch_rounded,
    title: '지금 시작하세요',
    subtitle: '14일 무료 체험',
    description: '14일 무료 체험으로 부담 없이 시작하세요.\n'
        '진짜 고객의 솔직한 피드백을 받아보세요.',
    color: HwahaeColors.primary,
  ),
];

class _BusinessOnboardingScreenState extends State<BusinessOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
        duration: AppMotion.slow,
        curve: AppMotion.decelerate,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: AppMotion.slow,
        curve: AppMotion.decelerate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: HwahaeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 터치 영역이 아이콘 크기(20px)밖에 안 됐다. 손가락이
                  // 닿는 크기는 48pt 다.
                  SizedBox(
                    width: AppLayout.iconButtonSize,
                    child: _currentPage > 0
                        ? AppIconButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: '이전',
                            onPressed: _previousPage,
                          )
                        : null,
                  ),
                  Text(
                    '${_currentPage + 1} / ${_slides.length}',
                    style: HwahaeTypography.labelMedium.copyWith(
                      color: HwahaeColors.textSecondary,
                    ),
                  ),
                  AppButton.ghost(
                    label: '건너뛰기',
                    size: AppButtonSize.small,
                    onPressed: _completeOnboarding,
                  ),
                ],
              ),
            ),
            _DotIndicators(
              count: _slides.length,
              current: _currentPage,
              color: _slides[_currentPage].color,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                itemBuilder: (context, index) =>
                    _SlideView(slide: _slides[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: AppButton(
                label: isLast ? '구독 플랜 보기' : '다음',
                icon: Icons.arrow_forward_rounded,
                trailingIcon: true,
                size: AppButtonSize.large,
                onPressed: _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotIndicators extends StatelessWidget {
  const _DotIndicators({
    required this.count,
    required this.current,
    required this.color,
  });

  final int count;
  final int current;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: AppMotion.slow,
            curve: AppMotion.decelerate,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: index == current ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: index == current ? color : HwahaeColors.surfaceContainer,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: slide.color,
              borderRadius: BorderRadius.circular(30),
              boxShadow: AppElevation.sticker(4, color: slide.color),
            ),
            child: Icon(
              slide.icon,
              size: 52,
              // 슬라이드마다 배경 밝기가 다르다. 흰색을 고정하면 골드
              // 슬라이드에서 아이콘이 1.86:1 로 사라진다.
              color: HwahaeColors.onColor(slide.color),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            slide.title,
            style: HwahaeTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          AppBadge(label: slide.subtitle, color: slide.color),
          const SizedBox(height: 22),
          Text(
            slide.description,
            style: HwahaeTypography.bodyLarge.copyWith(
              color: HwahaeColors.textSecondary,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
