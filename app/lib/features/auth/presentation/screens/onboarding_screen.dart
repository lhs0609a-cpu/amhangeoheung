import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../../../core/constants/app_constants.dart';

/// 사용자 타입
enum UserType { reviewer, business, consumer }

/// 온보딩 화면
/// 사용자 타입 선택 → 타입별 최적화된 온보딩 경험 제공
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  UserType? _selectedUserType;
  bool _showTypeSelection = true; // 첫 화면: 사용자 타입 선택

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // 사용자 타입별 온보딩 페이지
  List<_OnboardingPageData> get _pages {
    if (_selectedUserType == UserType.reviewer) {
      return [
        _OnboardingPageData(
          icon: Icons.workspace_premium_rounded,
          backgroundIcon: Icons.star_rounded,
          title: '리뷰어로\n보상을 받으세요',
          description: '정직한 리뷰를 작성하고\n포인트와 미션 보상을 받아가세요',
          gradient: HwahaeColors.gradientWarm,
          accentColor: HwahaeColors.warning,
          features: ['미션 페이백', '등급 시스템', '우선 배정'],
        ),
        _OnboardingPageData(
          icon: Icons.verified_user_rounded,
          backgroundIcon: Icons.shield_outlined,
          title: '첫 미션을\n체험해보세요',
          description: '튜토리얼 미션을 완료하면\n바로 리뷰어 활동을 시작할 수 있어요',
          gradient: HwahaeColors.gradientPrimary,
          accentColor: HwahaeColors.primary,
          features: ['튜토리얼 미션', 'GPS 인증 체험', '첫 보상 획득'],
        ),
      ];
    } else if (_selectedUserType == UserType.business) {
      return [
        _OnboardingPageData(
          icon: Icons.storefront_rounded,
          backgroundIcon: Icons.trending_up_rounded,
          title: '우리 가게\n신뢰도를 높여요',
          description: '리뷰 미션으로 진성 리뷰를 모으고\n경쟁업체 대비 우위를 확보하세요',
          gradient: HwahaeColors.gradientAccent,
          accentColor: HwahaeColors.accent,
          features: ['맞춤 미션 제공', '경쟁 분석', '신뢰도 리포트'],
        ),
        _OnboardingPageData(
          icon: Icons.auto_awesome,
          backgroundIcon: Icons.analytics_rounded,
          title: '무료로 시작하세요',
          description: '지금 바로 우리 가게 신뢰도를 분석하고\n개선 포인트를 확인해보세요',
          gradient: HwahaeColors.gradientPrimary,
          accentColor: HwahaeColors.primary,
          features: ['무료 신뢰도 분석', '리뷰 진단', '맞춤 추천'],
        ),
      ];
    } else {
      // Consumer
      return [
        _OnboardingPageData(
          icon: Icons.verified_user_rounded,
          backgroundIcon: Icons.shield_outlined,
          title: '진짜 리뷰만\n모았습니다',
          description: 'AI가 검증한 실제 방문자의 리뷰만 보여드려요\n가짜 리뷰 걱정 없이 신뢰할 수 있어요',
          gradient: HwahaeColors.gradientPrimary,
          accentColor: HwahaeColors.primary,
          features: ['AI 리뷰 검증', 'GPS 위치 인증', '영수증 확인'],
        ),
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingKey, true);
    if (mounted) {
      context.go('/login');
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    _fadeController.reset();
    _scaleController.reset();
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  Widget build(BuildContext context) {
    // 사용자 타입 선택 화면
    if (_showTypeSelection) {
      return _buildUserTypeSelectionScreen();
    }

    // 타입별 온보딩 화면
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              HwahaeColors.background,
              _pages[_currentPage].accentColor.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 상단 영역
              _buildHeader(),

              // 페이지 뷰
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index], index == _currentPage);
                  },
                ),
              ),

              // 인디케이터
              _buildIndicators(),

              // 하단 버튼 영역
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// 사용자 타입 선택 화면
  Widget _buildUserTypeSelectionScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              HwahaeColors.background,
              HwahaeColors.primary.withOpacity(0.03),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                // 로고 및 환영 메시지
                _buildWelcomeHeader(),
                const SizedBox(height: 48),
                // 질문
                Text(
                  '어떤 목적으로 사용하시나요?',
                  style: HwahaeTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '맞춤 경험을 위해 알려주세요',
                  style: HwahaeTypography.bodyMedium.copyWith(
                    color: HwahaeColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // 타입 선택 카드들
                Expanded(
                  child: Column(
                    children: [
                      _buildUserTypeCard(
                        type: UserType.reviewer,
                        icon: Icons.rate_review_rounded,
                        title: '리뷰어로 활동하기',
                        description: '미션을 수행하고 보상을 받아요',
                        gradient: HwahaeColors.gradientWarm,
                        accentColor: HwahaeColors.warning,
                      ),
                      const SizedBox(height: 16),
                      _buildUserTypeCard(
                        type: UserType.business,
                        icon: Icons.storefront_rounded,
                        title: '우리 가게 등록하기',
                        description: '진성 리뷰로 신뢰도를 높여요',
                        gradient: HwahaeColors.gradientAccent,
                        accentColor: HwahaeColors.accent,
                      ),
                      const SizedBox(height: 16),
                      _buildUserTypeCard(
                        type: UserType.consumer,
                        icon: Icons.search_rounded,
                        title: '리뷰만 보고 싶어요',
                        description: '검증된 리뷰로 좋은 곳을 찾아요',
                        gradient: HwahaeColors.gradientPrimary,
                        accentColor: HwahaeColors.primary,
                      ),
                    ],
                  ),
                ),
                // 로그인 링크
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '이미 계정이 있으신가요? ',
                        style: HwahaeTypography.bodySmall.copyWith(
                          color: HwahaeColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _completeOnboarding,
                        child: Text(
                          '로그인',
                          style: HwahaeTypography.labelMedium.copyWith(
                            color: HwahaeColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: HwahaeColors.gradientPrimary,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: HwahaeColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.verified_user_rounded,
            size: 36,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '암행어흥',
          style: HwahaeTypography.headlineLarge.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '진짜 리뷰, 진짜 신뢰',
          style: HwahaeTypography.bodyMedium.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildUserTypeCard({
    required UserType type,
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradient,
    required Color accentColor,
  }) {
    final isSelected = _selectedUserType == type;

    return GestureDetector(
      onTap: () => _onUserTypeSelected(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.08) : HwahaeColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : HwahaeColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: HwahaeTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: HwahaeTypography.bodySmall.copyWith(
                      color: HwahaeColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: isSelected ? accentColor : HwahaeColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _onUserTypeSelected(UserType type) async {
    setState(() {
      _selectedUserType = type;
    });

    // 잠시 대기 후 분기 처리
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    // 사용자 타입별 분기
    switch (type) {
      case UserType.consumer:
        // 소비자: 바로 홈으로
        await _completeOnboardingWithType(type);
        if (mounted) context.go('/home');
        break;
      case UserType.reviewer:
        // 리뷰어: 온보딩 후 튜토리얼 미션
        setState(() {
          _showTypeSelection = false;
          _currentPage = 0;
        });
        break;
      case UserType.business:
        // 업체: 온보딩 후 무료 신뢰도 분석
        setState(() {
          _showTypeSelection = false;
          _currentPage = 0;
        });
        break;
    }
  }

  Future<void> _completeOnboardingWithType(UserType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingKey, true);
    await prefs.setString('user_type_preference', type.name);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 뒤로가기 버튼
          GestureDetector(
            onTap: () {
              setState(() {
                _showTypeSelection = true;
                _selectedUserType = null;
                _currentPage = 0;
              });
            },
            child: Row(
              children: [
                Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 18,
                  color: HwahaeColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '뒤로',
                  style: HwahaeTypography.bodyMedium.copyWith(
                    color: HwahaeColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // 로고
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: HwahaeColors.gradientPrimary,
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '암행어흥',
                style: HwahaeTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          // 건너뛰기
          TextButton(
            onPressed: () async {
              await _completeOnboardingWithType(_selectedUserType!);
              if (mounted) context.go('/login');
            },
            style: TextButton.styleFrom(
              foregroundColor: HwahaeColors.textSecondary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(60, 36),
            ),
            child: const Text('건너뛰기'),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingPageData page, bool isActive) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 배경 아이콘 + 메인 아이콘
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // 배경 원형 그라디언트
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              page.accentColor.withOpacity(0.15),
                              page.accentColor.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                      // 배경 아이콘
                      Positioned(
                        right: 20,
                        top: 20,
                        child: Icon(
                          page.backgroundIcon,
                          size: 60,
                          color: page.accentColor.withOpacity(0.1),
                        ),
                      ),
                      // 메인 아이콘 박스
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: page.gradient,
                          ),
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(
                              color: page.gradient[0].withOpacity(0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Icon(
                          page.icon,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // 제목
                  Text(
                    page.title,
                    style: HwahaeTypography.displaySmall.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // 설명
                  Text(
                    page.description,
                    style: HwahaeTypography.bodyLarge.copyWith(
                      color: HwahaeColors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // 기능 태그들
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: page.features.map((feature) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: page.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: page.accentColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: page.accentColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              feature,
                              style: HwahaeTypography.labelMedium.copyWith(
                                color: page.accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIndicators() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_pages.length, (index) {
          final isActive = _currentPage == index;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 32 : 8,
              height: 8,
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(colors: _pages[index].gradient)
                    : null,
                color: isActive ? null : HwahaeColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomSection() {
    final isLastPage = _currentPage == _pages.length - 1;

    // 타입별 CTA 텍스트 및 액션 설정
    String primaryCtaText;
    IconData primaryCtaIcon;
    VoidCallback primaryCtaAction;

    switch (_selectedUserType) {
      case UserType.reviewer:
        primaryCtaText = isLastPage ? '첫 미션 체험하기' : '다음';
        primaryCtaIcon = isLastPage ? Icons.play_circle_filled : Icons.arrow_forward;
        primaryCtaAction = isLastPage
            ? () async {
                await _completeOnboardingWithType(UserType.reviewer);
                if (mounted) context.go('/tutorial-mission');
              }
            : () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
        break;
      case UserType.business:
        primaryCtaText = isLastPage ? '무료로 신뢰도 분석하기' : '다음';
        primaryCtaIcon = isLastPage ? Icons.auto_awesome : Icons.arrow_forward;
        primaryCtaAction = isLastPage
            ? () async {
                await _completeOnboardingWithType(UserType.business);
                if (mounted) context.push('/try-free');
              }
            : () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
        break;
      default:
        primaryCtaText = '시작하기';
        primaryCtaIcon = Icons.arrow_forward;
        primaryCtaAction = _completeOnboarding;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          // 메인 CTA 버튼
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _pages[_currentPage].gradient,
              ),
              borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
              boxShadow: [
                BoxShadow(
                  color: _pages[_currentPage].accentColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: primaryCtaAction,
                borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      primaryCtaIcon,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      primaryCtaText,
                      style: HwahaeTypography.button.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 건너뛰기 버튼 (마지막 페이지가 아닐 때만)
          if (!isLastPage)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () async {
                  await _completeOnboardingWithType(_selectedUserType!);
                  if (mounted) context.go('/login');
                },
                child: Text(
                  '나중에 할게요',
                  style: HwahaeTypography.bodyMedium.copyWith(
                    color: HwahaeColors.textSecondary,
                  ),
                ),
              ),
            ),

          // 뒤로가기 (타입 선택으로)
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _showTypeSelection = true;
                _selectedUserType = null;
                _currentPage = 0;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_back_ios,
                  size: 14,
                  color: HwahaeColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  '다른 유형 선택하기',
                  style: HwahaeTypography.bodySmall.copyWith(
                    color: HwahaeColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final IconData backgroundIcon;
  final String title;
  final String description;
  final List<Color> gradient;
  final Color accentColor;
  final List<String> features;

  _OnboardingPageData({
    required this.icon,
    required this.backgroundIcon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.accentColor,
    required this.features,
  });
}
