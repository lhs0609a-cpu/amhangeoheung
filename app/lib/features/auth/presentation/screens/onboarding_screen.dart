import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/user_type_provider.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';

/// 온보딩 화면
/// 사용자 타입 선택 → 타입별 최적화된 온보딩 경험 제공
///
/// 유형은 [userTypeProvider] 를 통해 저장한다. 예전에는 SharedPreferences 에
/// 직접 써서, 이미 만들어진 Notifier 는 옛 값을 들고 있었다. 업체를 골라도
/// 앱을 다시 켜기 전까지 탭이 소비자 것으로 남았다.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.features,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final List<String> features;
}

/// 유형 선택 카드에 필요한 것들.
class _TypeChoice {
  const _TypeChoice({
    required this.type,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final UserType type;
  final IconData icon;
  final String title;
  final String description;
  final Color color;
}

const _choices = <_TypeChoice>[
  _TypeChoice(
    type: UserType.reviewer,
    icon: Icons.rate_review_rounded,
    title: '감찰관으로 활동하기',
    description: '미션을 수행하고 보수를 받아요',
    color: HwahaeColors.primary,
  ),
  _TypeChoice(
    type: UserType.business,
    icon: Icons.storefront_rounded,
    title: '우리 가게 등록하기',
    description: '진짜 리뷰로 신뢰도를 쌓아요',
    color: HwahaeColors.accent,
  ),
  _TypeChoice(
    type: UserType.consumer,
    icon: Icons.search_rounded,
    title: '리뷰만 보고 싶어요',
    description: '검증된 리뷰로 좋은 곳을 찾아요',
    color: HwahaeColors.info,
  ),
];

/// 유형별 소개 장면.
///
/// 문구는 실제로 있는 기능만 적는다. "AI 가 검증한다"고 써 있었지만 실제
/// 검증은 GPS 체류 확인 · 영수증 OCR · 담합 감지다. 없는 기술을 파는 것은
/// 이 제품이 파는 신뢰와 정면으로 부딪힌다.
List<_OnboardingPage> _pagesFor(UserType? type) {
  switch (type) {
    case UserType.reviewer:
      return const [
        _OnboardingPage(
          icon: Icons.workspace_premium_rounded,
          title: '감찰관으로\n보수를 받으세요',
          description: '실제로 다녀와 본 대로 적으면\n미션 보수가 정산됩니다',
          color: HwahaeColors.primary,
          features: ['미션 보수', '등급 시스템', '우선 배정'],
        ),
        _OnboardingPage(
          icon: Icons.verified_user_rounded,
          title: '첫 미션을\n체험해보세요',
          description: '튜토리얼 미션을 마치면\n바로 감찰관 활동을 시작할 수 있어요',
          color: HwahaeColors.accent,
          features: ['튜토리얼 미션', 'GPS 체류 확인', '첫 보수'],
        ),
      ];
    case UserType.business:
      return const [
        _OnboardingPage(
          icon: Icons.storefront_rounded,
          title: '우리 가게\n신뢰도를 쌓아요',
          description: '실제로 다녀온 사람의 리뷰만 모입니다\n'
              '지적을 고치면 고친 기록도 함께 남습니다',
          color: HwahaeColors.accent,
          features: ['감찰 리포트', '지적 추적', '72시간 선공개'],
        ),
        _OnboardingPage(
          icon: Icons.auto_awesome_rounded,
          title: '무료로 시작하세요',
          description: '지금 우리 가게 신뢰도를 확인하고\n무엇을 고치면 되는지 보세요',
          color: HwahaeColors.primary,
          features: ['무료 신뢰도 분석', '리뷰 진단', '개선 항목'],
        ),
      ];
    default:
      return const [
        _OnboardingPage(
          icon: Icons.verified_user_rounded,
          title: '진짜 리뷰만\n모았습니다',
          description: '교육을 마친 감찰관이 실제로 다녀와서 쓴 리뷰만 남습니다\n'
              'GPS 체류와 영수증으로 방문을 확인합니다',
          color: HwahaeColors.primary,
          features: ['GPS 체류 확인', '영수증 확인', '담합 감지'],
        ),
      ];
  }
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  UserType? _selectedUserType;
  bool _showTypeSelection = true;

  List<_OnboardingPage> get _pages => _pagesFor(_selectedUserType);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _markOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingKey, true);
  }

  Future<void> _saveType(UserType type) async {
    await _markOnboarded();
    // Notifier 를 거쳐야 앱의 현재 상태까지 같이 바뀐다.
    await ref.read(userTypeProvider.notifier).setUserType(type);
  }

  Future<void> _goToLogin() async {
    await _markOnboarded();
    if (mounted) context.go('/login');
  }

  void _backToTypeSelection() {
    setState(() {
      _showTypeSelection = true;
      _selectedUserType = null;
      _currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showTypeSelection) return _buildTypeSelection();

    return Scaffold(
      backgroundColor: HwahaeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) =>
                    _PageView(page: _pages[index]),
              ),
            ),
            _buildIndicators(),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelection() {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 36),
              const AppMascot.eoheung(size: 120),
              const SizedBox(height: 14),
              Text(
                '암행어흥',
                style: HwahaeTypography.headlineLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '업체가 돈을 내지만, 업체가 결과를 못 바꿉니다',
                textAlign: TextAlign.center,
                style: HwahaeTypography.bodySmall.copyWith(
                  color: HwahaeColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                '어떤 목적으로 쓰시나요?',
                style: HwahaeTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '고른 유형에 맞게 화면이 바뀝니다',
                style: HwahaeTypography.bodyMedium.copyWith(
                  color: HwahaeColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              for (final choice in _choices) ...[
                _TypeCard(
                  choice: choice,
                  selected: _selectedUserType == choice.type,
                  onTap: () => _onUserTypeSelected(choice.type),
                ),
                const SizedBox(height: AppLayout.cardGap),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '이미 계정이 있으신가요?',
                    style: HwahaeTypography.bodySmall.copyWith(
                      color: HwahaeColors.textSecondary,
                    ),
                  ),
                  AppButton.ghost(
                    label: '로그인',
                    size: AppButtonSize.small,
                    onPressed: _goToLogin,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: '다른 유형 고르기',
            onPressed: _backToTypeSelection,
          ),
          Row(
            children: [
              const AppMascot.eoheung(size: 26),
              const SizedBox(width: 6),
              Text('암행어흥', style: HwahaeTypography.labelLarge),
            ],
          ),
          AppButton.ghost(
            label: '건너뛰기',
            size: AppButtonSize.small,
            onPressed: () async {
              if (_selectedUserType != null) {
                await _saveType(_selectedUserType!);
              }
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIndicators() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < _pages.length; index++)
            GestureDetector(
              onTap: () => _pageController.animateToPage(
                index,
                duration: AppMotion.slow,
                curve: AppMotion.standard,
              ),
              child: AnimatedContainer(
                duration: AppMotion.slow,
                curve: AppMotion.standard,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 32 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? _pages[index].color
                      : HwahaeColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    final isLastPage = _currentPage == _pages.length - 1;

    void nextPage() => _pageController.nextPage(
          duration: AppMotion.slow,
          curve: AppMotion.standard,
        );

    final (label, icon, action) = switch (_selectedUserType) {
      UserType.reviewer when isLastPage => (
          '첫 미션 체험하기',
          Icons.play_circle_filled_rounded,
          () async {
            await _saveType(UserType.reviewer);
            if (mounted) context.go('/tutorial-mission');
          },
        ),
      UserType.business when isLastPage => (
          '무료로 신뢰도 분석하기',
          Icons.auto_awesome_rounded,
          () async {
            await _saveType(UserType.business);
            if (mounted) context.push('/try-free');
          },
        ),
      _ when !isLastPage => ('다음', Icons.arrow_forward_rounded, nextPage),
      _ => ('시작하기', Icons.arrow_forward_rounded, _goToLogin),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          AppButton(
            label: label,
            icon: icon,
            trailingIcon: true,
            size: AppButtonSize.large,
            onPressed: action,
          ),
          if (!isLastPage) ...[
            const SizedBox(height: 6),
            AppButton.ghost(
              label: '나중에 할게요',
              onPressed: () async {
                if (_selectedUserType != null) {
                  await _saveType(_selectedUserType!);
                }
                if (mounted) context.go('/login');
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onUserTypeSelected(UserType type) async {
    setState(() => _selectedUserType = type);

    if (type == UserType.consumer) {
      // 소비자는 소개할 것이 한 장뿐이라 바로 홈으로 보낸다.
      await _saveType(type);
      if (mounted) context.go('/home');
      return;
    }

    setState(() {
      _showTypeSelection = false;
      _currentPage = 0;
    });
    // PageView 를 새로 만들 때 컨트롤러가 옛 위치를 들고 있지 않도록.
    if (_pageController.hasClients) _pageController.jumpToPage(0);
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final _TypeChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: choice.title,
      selected: selected,
      button: true,
      child: AppCard(
        style: AppCardStyle.outlined,
        onTap: onTap,
        borderColor: selected ? choice.color : null,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: choice.color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                choice.icon,
                size: 26,
                // 유형마다 면 밝기가 달라서 흰색을 고정하면 골드에서 사라진다.
                color: HwahaeColors.onColor(choice.color),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(choice.title, style: HwahaeTypography.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    choice.description,
                    style: HwahaeTypography.bodySmall.copyWith(
                      color: HwahaeColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: selected ? choice.color : HwahaeColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  const _PageView({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                color: page.color,
                borderRadius: BorderRadius.circular(32),
                boxShadow: AppElevation.sticker(4, color: page.color),
              ),
              child: Icon(
                page.icon,
                size: 54,
                color: HwahaeColors.onColor(page.color),
              ),
            ),
            const SizedBox(height: 36),
            Text(
              page.title,
              style: HwahaeTypography.displaySmall.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(
              page.description,
              style: HwahaeTypography.bodyLarge.copyWith(
                color: HwahaeColors.textSecondary,
                height: 1.65,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final feature in page.features)
                  AppBadge(
                    label: feature,
                    color: page.color,
                    icon: Icons.check_circle_rounded,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
