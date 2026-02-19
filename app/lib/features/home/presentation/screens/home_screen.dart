import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../../../core/providers/user_type_provider.dart';
import '../../../review/data/models/review_model.dart';
import '../../../mission/data/models/mission_model.dart';
import '../../providers/home_provider.dart';
import '../../../../shared/widgets/hwahae/hwahae_cards.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/skeleton_widgets.dart';
import '../../../ranking/data/models/ranking_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentBannerIndex = 0;

  final List<String> _categories = [
    '전체',
    '음식점',
    '카페',
    '뷰티',
    '건강',
    '레저',
    '교육',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(homeDataProvider.notifier).loadHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeDataProvider);
    final userType = ref.watch(userTypeProvider);

    return Scaffold(
      backgroundColor: HwahaeColors.background,
      body: homeState.error != null && !homeState.isLoading
          ? _buildErrorView(homeState.error!)
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(homeDataProvider.notifier).loadHomeData();
              },
              color: HwahaeColors.primary,
              backgroundColor: HwahaeColors.surface,
              child: CustomScrollView(
                slivers: [
                  // 앱바
                  _buildAppBar(),

                  // 리뷰어 홈: "오늘의 미션 브리핑" 레이아웃
                  if (userType == UserType.reviewer) ...[
                    // 진행 중 미션 스티키 카드
                    SliverToBoxAdapter(child: _buildActiveMissionCard(homeState)),
                    // 오늘의 미션 추천
                    SliverToBoxAdapter(child: _buildMissionsSection(homeState)),
                    // 정산 대기 금액 카드
                    SliverToBoxAdapter(child: _buildSettlementCard()),
                    // 등급 진행 상황
                    SliverToBoxAdapter(child: _buildGradeProgressCard()),
                    // 베스트 리뷰
                    SliverToBoxAdapter(child: _buildBestReviewsSection(homeState)),
                  ],

                  // 소비자 홈: 검색 + 탐색 레이아웃
                  if (userType == UserType.consumer) ...[
                    // 검색 바
                    SliverToBoxAdapter(child: _buildSearchBar()),
                    // 내 주변 TOP 업체
                    SliverToBoxAdapter(child: _buildTopBusinessSection(homeState)),
                    // 카테고리 탭
                    SliverToBoxAdapter(child: _buildCategoryTabs()),
                    // 최근 인증 리뷰 피드
                    SliverToBoxAdapter(child: _buildBestReviewsSection(homeState)),
                    // 카테고리별 탐색
                    SliverToBoxAdapter(child: _buildCategoryExplore()),
                  ],

                  // 업체 홈: 대시보드 요약 (실제 대시보드로 리다이렉트)
                  if (userType == UserType.business) ...[
                    SliverToBoxAdapter(child: _buildQuickActions()),
                    SliverToBoxAdapter(child: _buildTopBusinessSection(homeState)),
                    SliverToBoxAdapter(child: _buildBestReviewsSection(homeState)),
                  ],

                  // 하단 여백 (네비게이션 바 고려)
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
    );
  }

  /// 리뷰어 홈: 진행 중 미션 스티키 카드
  Widget _buildActiveMissionCard(HomeDataState homeState) {
    final activeMissions = homeState.availableMissions
        .where((m) => m.status == 'in_progress' || m.status == 'assigned')
        .toList();

    if (activeMissions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: HwahaeColors.gradientPrimary,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.explore_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '새로운 미션을 찾아보세요',
                      style: HwahaeTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '내 주변 미션을 확인해보세요',
                      style: HwahaeTypography.captionLarge.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => context.push('/missions'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '미션 찾기',
                    style: HwahaeTypography.labelSmall.copyWith(
                      color: HwahaeColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final mission = activeMissions.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: InkWell(
        onTap: () => context.push('/missions/${mission.id}'),
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: HwahaeColors.gradientWarm,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.flag_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '진행 중 미션',
                      style: HwahaeTypography.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mission.business?.name ?? mission.category ?? '미션',
                      style: HwahaeTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (mission.daysUntilDeadline != null)
                      Text(
                        'D-${mission.daysUntilDeadline}',
                        style: HwahaeTypography.captionLarge.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (activeMissions.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${activeMissions.length - 1}',
                    style: HwahaeTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  /// 리뷰어 홈: 정산 대기 금액 카드
  Widget _buildSettlementCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: InkWell(
        onTap: () => context.push('/settlements'),
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: HwahaeColors.surface,
            borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
            border: Border.all(color: HwahaeColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: HwahaeColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: HwahaeColors.secondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '정산 대기',
                      style: HwahaeTypography.captionLarge.copyWith(
                        color: HwahaeColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '0원',
                      style: HwahaeTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: HwahaeColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 리뷰어 홈: 등급 진행 상황
  Widget _buildGradeProgressCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: InkWell(
        onTap: () => context.push('/ranking?tab=reviewer'),
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: HwahaeColors.surface,
            borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
            border: Border.all(color: HwahaeColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: HwahaeColors.gradeRookie.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.eco_rounded, size: 14, color: HwahaeColors.gradeRookie),
                        const SizedBox(width: 4),
                        Text(
                          'Rookie',
                          style: HwahaeTypography.labelSmall.copyWith(
                            color: HwahaeColors.gradeRookie,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '다음 등급까지',
                    style: HwahaeTypography.captionMedium.copyWith(
                      color: HwahaeColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.0,
                  minHeight: 8,
                  backgroundColor: HwahaeColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(HwahaeColors.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '미션 0/5 완료',
                style: HwahaeTypography.captionMedium.copyWith(
                  color: HwahaeColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 소비자 홈: 검색 바
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: InkWell(
        onTap: () => context.push('/search'),
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: HwahaeColors.surfaceVariant,
            borderRadius: BorderRadius.circular(HwahaeTheme.radiusFull),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: HwahaeColors.textTertiary),
              const SizedBox(width: 12),
              Text(
                '업체, 카테고리, 지역 검색',
                style: HwahaeTypography.bodyMedium.copyWith(
                  color: HwahaeColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 소비자 홈: 카테고리별 탐색
  Widget _buildCategoryExplore() {
    final categories = [
      {'icon': Icons.restaurant, 'label': '음식점', 'gradient': HwahaeColors.gradientWarm},
      {'icon': Icons.coffee, 'label': '카페', 'gradient': HwahaeColors.gradientAccent},
      {'icon': Icons.spa, 'label': '뷰티', 'gradient': HwahaeColors.gradientSunset},
      {'icon': Icons.fitness_center, 'label': '건강', 'gradient': HwahaeColors.gradientCool},
      {'icon': Icons.park, 'label': '레저', 'gradient': HwahaeColors.gradientOcean},
      {'icon': Icons.school, 'label': '교육', 'gradient': HwahaeColors.gradientPrimary},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildSectionHeader('카테고리별 탐색'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return InkWell(
                onTap: () => context.push('/search'),
                borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
                child: Container(
                  decoration: BoxDecoration(
                    color: HwahaeColors.surface,
                    borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
                    border: Border.all(color: HwahaeColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: cat['gradient'] as List<Color>),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(cat['icon'] as IconData, color: Colors.white, size: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat['label'] as String,
                        style: HwahaeTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(String errorMessage) {
    return SafeArea(
      child: Column(
        children: [
          _buildLogoHeader(),
          Expanded(
            child: ErrorView.fromMessage(
              message: errorMessage,
              onRetry: () {
                ref.read(homeDataProvider.notifier).loadHomeData();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: HwahaeColors.gradientPrimary,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: HwahaeColors.gradientPrimary,
            ).createShader(bounds),
            child: Text(
              '암행어흥',
              style: HwahaeTypography.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: HwahaeColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: HwahaeColors.gradientPrimary,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: HwahaeColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: HwahaeColors.gradientPrimary,
            ).createShader(bounds),
            child: Text(
              '암행어흥',
              style: HwahaeTypography.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      actions: [
        _buildActionButton(
          icon: Icons.search_rounded,
          onTap: () => context.push('/search'),
        ),
        const SizedBox(width: 4),
        _buildActionButton(
          icon: Icons.notifications_outlined,
          onTap: () => context.push('/notifications'),
          showBadge: true,
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: HwahaeColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              color: HwahaeColors.textPrimary,
              size: 22,
            ),
            if (showBadge)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: HwahaeColors.gradientWarm,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: HwahaeColors.surface, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerSlider() {
    final banners = [
      _BannerData(
        title: '암행어흥과 함께',
        subtitle: '투명한 소비 문화를\n만들어요',
        buttonText: '자세히 보기',
        gradient: HwahaeColors.gradientPrimary,
        icon: Icons.verified_user_rounded,
      ),
      _BannerData(
        title: '이번 달 미션',
        subtitle: '5만원 보상\n미션 참여하기',
        buttonText: '미션 참여',
        gradient: HwahaeColors.gradientAccent,
        icon: Icons.flag_rounded,
      ),
      _BannerData(
        title: '신뢰 리뷰어 되기',
        subtitle: '등급 혜택을\n확인하세요',
        buttonText: '등급 안내',
        gradient: HwahaeColors.gradientCool,
        icon: Icons.workspace_premium_rounded,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          CarouselSlider.builder(
            itemCount: banners.length,
            options: CarouselOptions(
              height: 170,
              viewportFraction: 0.9,
              enlargeCenterPage: true,
              enlargeFactor: 0.15,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              onPageChanged: (index, reason) {
                setState(() {
                  _currentBannerIndex = index;
                });
              },
            ),
            itemBuilder: (context, index, realIndex) {
              final banner = banners[index];
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: banner.gradient,
                  ),
                  borderRadius: BorderRadius.circular(HwahaeTheme.radiusXL),
                  boxShadow: [
                    BoxShadow(
                      color: banner.gradient[0].withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            banner.title,
                            style: HwahaeTypography.labelMedium.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            banner.subtitle,
                            style: HwahaeTypography.headlineSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              banner.buttonText,
                              style: HwahaeTypography.labelSmall.copyWith(
                                color: banner.gradient[0],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        banner.icon,
                        size: 36,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          // 인디케이터
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentBannerIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  gradient: _currentBannerIndex == index
                      ? const LinearGradient(colors: HwahaeColors.gradientPrimary)
                      : null,
                  color: _currentBannerIndex == index
                      ? null
                      : HwahaeColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final homeState = ref.watch(homeDataProvider);
    final selectedCategory = homeState.selectedCategory;

    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 20),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == selectedCategory;

          return GestureDetector(
            onTap: () {
              ref.read(homeDataProvider.notifier).setCategory(category);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(colors: HwahaeColors.gradientPrimary)
                    : null,
                color: isSelected ? null : HwahaeColors.surface,
                borderRadius: BorderRadius.circular(HwahaeTheme.radiusFull),
                border: isSelected
                    ? null
                    : Border.all(color: HwahaeColors.border),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: HwahaeColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                category,
                style: HwahaeTypography.labelMedium.copyWith(
                  color: isSelected
                      ? HwahaeColors.onPrimary
                      : HwahaeColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 사용자 타입별 퀵 액션
  Widget _buildQuickActions() {
    final userType = ref.watch(userTypeProvider);
    List<_QuickActionData> actions;

    switch (userType) {
      case UserType.reviewer:
        actions = [
          _QuickActionData(
            icon: Icons.flag_rounded,
            label: '진행 중 미션',
            gradient: HwahaeColors.gradientWarm,
            onTap: () => context.push('/missions'),
          ),
          _QuickActionData(
            icon: Icons.account_balance_wallet,
            label: '정산',
            gradient: HwahaeColors.gradientAccent,
            onTap: () => context.push('/settlements'),
          ),
          _QuickActionData(
            icon: Icons.rate_review_rounded,
            label: '내 리뷰',
            gradient: HwahaeColors.gradientPrimary,
            onTap: () => context.push('/my-reviews'),
          ),
          _QuickActionData(
            icon: Icons.workspace_premium_rounded,
            label: '등급/혜택',
            gradient: HwahaeColors.gradientCool,
            onTap: () => context.push('/ranking?tab=reviewer'),
          ),
        ];
        break;
      case UserType.business:
        actions = [
          _QuickActionData(
            icon: Icons.preview_rounded,
            label: '선공개 리뷰',
            gradient: HwahaeColors.gradientWarm,
            onTap: () => context.push('/preview-reviews'),
          ),
          _QuickActionData(
            icon: Icons.analytics_rounded,
            label: '신뢰도 분석',
            gradient: HwahaeColors.gradientAccent,
            onTap: () => context.push('/dashboard'),
          ),
          _QuickActionData(
            icon: Icons.campaign_rounded,
            label: '미션 등록',
            gradient: HwahaeColors.gradientPrimary,
            onTap: () => context.push('/missions'),
          ),
          _QuickActionData(
            icon: Icons.payment_rounded,
            label: '구독 관리',
            gradient: HwahaeColors.gradientCool,
            onTap: () => context.push('/pricing'),
          ),
        ];
        break;
      case UserType.consumer:
      default:
        actions = [
          _QuickActionData(
            icon: Icons.search_rounded,
            label: '업체 검색',
            gradient: HwahaeColors.gradientPrimary,
            onTap: () => context.push('/search'),
          ),
          _QuickActionData(
            icon: Icons.star_rounded,
            label: 'TOP 업체',
            gradient: HwahaeColors.gradientWarm,
            onTap: () => context.push('/ranking'),
          ),
          _QuickActionData(
            icon: Icons.rate_review_rounded,
            label: '베스트 리뷰',
            gradient: HwahaeColors.gradientAccent,
            onTap: () => context.push('/reviews'),
          ),
          _QuickActionData(
            icon: Icons.thumb_up_rounded,
            label: '리뷰 요청',
            gradient: HwahaeColors.gradientCool,
            onTap: () => context.push('/search'),
          ),
        ];
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사용자 타입 표시
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getUserTypeColor(userType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getUserTypeIcon(userType),
                        size: 14,
                        color: _getUserTypeColor(userType),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getUserTypeLabel(userType),
                        style: HwahaeTypography.labelSmall.copyWith(
                          color: _getUserTypeColor(userType),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _showChangeUserTypeDialog,
                  child: Text(
                    '변경',
                    style: HwahaeTypography.labelSmall.copyWith(
                      color: HwahaeColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 퀵 액션 그리드
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: actions.map((action) {
              return _buildQuickActionItem(action);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(_QuickActionData action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: action.gradient),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: action.gradient[0].withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  action.icon,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              if (action.badge != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: HwahaeColors.error,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      action.badge!,
                      style: HwahaeTypography.captionSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            action.label,
            style: HwahaeTypography.captionMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getUserTypeColor(UserType userType) {
    switch (userType) {
      case UserType.reviewer:
        return HwahaeColors.warning;
      case UserType.business:
        return HwahaeColors.accent;
      case UserType.consumer:
        return HwahaeColors.primary;
    }
  }

  IconData _getUserTypeIcon(UserType userType) {
    switch (userType) {
      case UserType.reviewer:
        return Icons.rate_review_rounded;
      case UserType.business:
        return Icons.storefront_rounded;
      case UserType.consumer:
        return Icons.person_rounded;
    }
  }

  String _getUserTypeLabel(UserType userType) {
    switch (userType) {
      case UserType.reviewer:
        return '리뷰어';
      case UserType.business:
        return '업체';
      case UserType.consumer:
        return '소비자';
    }
  }

  void _showChangeUserTypeDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '사용 유형 변경',
              style: HwahaeTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '홈 화면에 표시되는 정보가 변경됩니다.',
              style: HwahaeTypography.bodySmall.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            _buildUserTypeOption(UserType.reviewer, '리뷰어', '미션 수행 및 보상', Icons.rate_review_rounded, HwahaeColors.warning),
            _buildUserTypeOption(UserType.business, '업체', '신뢰도 관리 및 미션 등록', Icons.storefront_rounded, HwahaeColors.accent),
            _buildUserTypeOption(UserType.consumer, '소비자', '리뷰 탐색 및 업체 검색', Icons.person_rounded, HwahaeColors.primary),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeOption(UserType type, String title, String description, IconData icon, Color color) {
    final currentType = ref.watch(userTypeProvider);
    final isSelected = currentType == type;

    return InkWell(
      onTap: () async {
        await ref.read(userTypeProvider.notifier).setUserType(type);
        if (mounted) Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : HwahaeColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : HwahaeColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: HwahaeTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: HwahaeTypography.captionMedium.copyWith(
                      color: HwahaeColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? emoji, VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (emoji != null) ...[
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: HwahaeTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: HwahaeColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      '전체 보기',
                      style: HwahaeTypography.labelSmall.copyWith(
                        color: HwahaeColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: HwahaeColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBusinessSection(HomeDataState homeState) {
    final businesses = homeState.topBusinesses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('이번 달 TOP 업체', emoji: '🏆', onSeeAll: () {
          context.push('/ranking');
        }),
        if (businesses.isEmpty)
          _buildEmptyState(icon: Icons.store_outlined, message: 'TOP 업체 데이터가 없습니다')
        else
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: businesses.length.clamp(0, 5),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _buildTopBusinessCard(businesses[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTopBusinessCard(RegionalRankingModel business) {
    final rank = business.rank;
    final gradients = [
      HwahaeColors.gradientWarm,
      HwahaeColors.gradientCool,
      HwahaeColors.gradientAccent,
      [HwahaeColors.textSecondary, HwahaeColors.textTertiary],
      [HwahaeColors.textSecondary, HwahaeColors.textTertiary],
    ];
    final gradientIndex = (rank - 1).clamp(0, gradients.length - 1);

    return GestureDetector(
      onTap: () {
        if (business.businessId != null) {
          context.push('/trust/${business.businessId}');
        }
      },
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: HwahaeColors.surface,
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
          border: Border.all(
            color: rank <= 3
                ? gradients[gradientIndex][0].withOpacity(0.2)
                : HwahaeColors.border,
          ),
          boxShadow: rank <= 3
              ? [
                  BoxShadow(
                    color: gradients[gradientIndex][0].withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 순위 배지
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: rank <= 3
                    ? LinearGradient(colors: gradients[gradientIndex])
                    : null,
                color: rank > 3 ? HwahaeColors.surfaceVariant : null,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: HwahaeTypography.labelLarge.copyWith(
                  color: rank <= 3 ? Colors.white : HwahaeColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // 업체 아이콘
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: HwahaeColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: HwahaeColors.textSecondary,
                size: 26,
              ),
            ),
            const SizedBox(height: 10),
            // 업체명
            Text(
              business.businessName ?? '${rank}위 업체',
              style: HwahaeTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // 신뢰도
            Text(
              business.trustScore != null
                  ? '신뢰도 ${business.trustScore!.toStringAsFixed(0)}%'
                  : '신뢰도 -',
              style: HwahaeTypography.captionSmall.copyWith(
                color: HwahaeColors.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionsSection(HomeDataState homeState) {
    final missions = homeState.filteredMissions;
    final categoryLabel = homeState.selectedCategory == '전체'
        ? '참여 가능한 미션'
        : '${homeState.selectedCategory} 미션';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        _buildSectionHeader(categoryLabel, emoji: '✨', onSeeAll: () {
          context.push('/missions');
        }),
        if (homeState.isLoading)
          SkeletonListView(
            itemCount: 3,
            itemBuilder: (_, __) => const MissionCardSkeleton(),
          )
        else if (missions.isEmpty)
          _buildEmptyState(
            icon: Icons.flag_outlined,
            message: homeState.selectedCategory == '전체'
                ? '참여 가능한 미션이 없습니다'
                : '${homeState.selectedCategory} 카테고리에 미션이 없습니다',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: missions.length.clamp(0, 3),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final mission = missions[index];
              return HwahaeMissionCard(
                title: mission.business?.name ?? mission.category ?? '미션',
                category: mission.category ?? '',
                region: mission.region,
                rewardAmount: mission.reviewerFee,
                daysRemaining: mission.daysUntilDeadline,
                isUrgent: (mission.daysUntilDeadline ?? 99) <= 3,
                currentParticipants: mission.currentApplicants,
                maxParticipants: mission.maxApplicants,
                onTap: () {
                  context.push('/missions/${mission.id}');
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildBestReviewsSection(HomeDataState homeState) {
    final reviews = homeState.filteredReviews;
    final reviewLabel = homeState.selectedCategory == '전체'
        ? '베스트 리뷰'
        : '${homeState.selectedCategory} 리뷰';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        _buildSectionHeader(reviewLabel, emoji: '📝', onSeeAll: () {
          context.push('/reviews');
        }),
        if (homeState.isLoading)
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const ReviewCardSkeleton(),
            ),
          )
        else if (reviews.isEmpty)
          _buildEmptyState(
            icon: Icons.rate_review_outlined,
            message: homeState.selectedCategory == '전체'
                ? '등록된 리뷰가 없습니다'
                : '${homeState.selectedCategory} 카테고리에 리뷰가 없습니다',
          )
        else
          SizedBox(
            height: 270,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: reviews.length.clamp(0, 5),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return SizedBox(
                  width: 300,
                  child: _buildCompactReviewCard(review),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCompactReviewCard(ReviewModel review) {
    final authorName = review.reviewer?.nickname ?? '익명';
    final storeName = review.business?.name ?? '업체';
    final content = review.summary ?? review.detailedReview ?? '';

    return GestureDetector(
      onTap: () {
        context.push('/reviews/${review.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: HwahaeColors.surface,
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
          border: Border.all(color: HwahaeColors.border),
          boxShadow: [
            BoxShadow(
              color: HwahaeColors.primary.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: HwahaeColors.gradientPrimary,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    authorName.isNotEmpty ? authorName[0] : '?',
                    style: HwahaeTypography.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: HwahaeTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        storeName,
                        style: HwahaeTypography.captionMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                HwahaeRatingBadge(rating: review.totalScore),
              ],
            ),
            const SizedBox(height: 14),

            // 리뷰 내용
            Expanded(
              child: Text(
                content,
                style: HwahaeTypography.bodySmall.copyWith(
                  height: 1.6,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 10),

            // 하단 정보
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: HwahaeColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.thumb_up_rounded,
                        size: 14,
                        color: HwahaeColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${review.helpfulCount}',
                        style: HwahaeTypography.captionMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (review.status == 'published')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: HwahaeColors.gradientAccent,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '인증됨',
                          style: HwahaeTypography.captionSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopReviewersSection() {
    final homeState = ref.watch(homeDataProvider);
    final reviewers = homeState.topReviewers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        _buildSectionHeader('우수 리뷰어', emoji: '👑', onSeeAll: () {
          context.push('/ranking?tab=reviewer');
        }),
        if (reviewers.isEmpty)
          _buildEmptyState(icon: Icons.person_outline, message: '우수 리뷰어 데이터가 없습니다')
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: reviewers.length.clamp(0, 6),
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return _buildReviewerChip(reviewers[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildReviewerChip(ReviewerRankingModel reviewer) {
    final grade = reviewer.reviewerGrade ?? 'silver';
    final colors = HwahaeColors.getGradeGradient(grade);
    final displayName = reviewer.nickname ?? '리뷰어';
    final initial = displayName.isNotEmpty ? displayName[0] : '?';

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors[0].withOpacity(0.15),
                    colors[1].withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors[0].withOpacity(0.3),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: HwahaeTypography.titleSmall.copyWith(
                  color: colors[0],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: colors[0].withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '${reviewer.rank}',
                  style: HwahaeTypography.badge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          displayName,
          style: HwahaeTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        HwahaeGradeBadge(grade: grade, showLabel: false),
      ],
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: HwahaeColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 32,
                color: HwahaeColors.textTertiary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: HwahaeTypography.bodyMedium.copyWith(
                color: HwahaeColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerData {
  final String title;
  final String subtitle;
  final String buttonText;
  final List<Color> gradient;
  final IconData icon;

  _BannerData({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.gradient,
    required this.icon,
  });
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final String? badge;
  final VoidCallback onTap;

  _QuickActionData({
    required this.icon,
    required this.label,
    required this.gradient,
    this.badge,
    required this.onTap,
  });
}
