import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/user_type_provider.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/hwahae_colors.dart';
import '../../core/theme/hwahae_typography.dart';
import 'offline_banner.dart';

/// 네비게이션 항목 정의
class _NavItem {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// 센터 FAB 설정
class _CenterFabConfig {
  final IconData icon;
  final String route;
  final String label;

  const _CenterFabConfig({
    required this.icon,
    required this.route,
    required this.label,
  });
}

/// 탭 화면 공통 셸.
///
/// 하단 네비게이션은 화면 위에 떠 있는 알약(pill) 형태다. 콘텐츠가 그 뒤로
/// 흐르면서 블러 처리되어 "화면이 계속 이어진다"는 느낌을 준다.
/// 각 화면은 [AppLayout.bottomScrollInset] 으로 하단 여백을 확보한다.
class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  /// 사용자 유형별 네비게이션 항목
  static List<_NavItem> _getNavItems(UserType userType) {
    switch (userType) {
      case UserType.reviewer:
        return const [
          _NavItem(
              route: '/home',
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: '홈'),
          _NavItem(
              route: '/missions',
              icon: Icons.explore_outlined,
              activeIcon: Icons.explore_rounded,
              label: '미션'),
          // 센터 FAB 자리 (index 2)
          _NavItem(
              route: '/my-activity',
              icon: Icons.assignment_outlined,
              activeIcon: Icons.assignment_rounded,
              label: '내 활동'),
          _NavItem(
              route: '/profile',
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: '프로필'),
        ];
      case UserType.consumer:
        return const [
          _NavItem(
              route: '/home',
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: '홈'),
          _NavItem(
              route: '/search',
              icon: Icons.search_outlined,
              activeIcon: Icons.search_rounded,
              label: '검색'),
          // 센터 FAB 자리 (index 2)
          _NavItem(
              route: '/reviews',
              icon: Icons.edit_note_outlined,
              activeIcon: Icons.edit_note_rounded,
              label: '리뷰'),
          _NavItem(
              route: '/profile',
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: '프로필'),
        ];
      case UserType.business:
        return const [
          _NavItem(
              route: '/dashboard',
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
              label: '대시보드'),
          _NavItem(
              route: '/missions',
              icon: Icons.campaign_outlined,
              activeIcon: Icons.campaign_rounded,
              label: '미션관리'),
          // 센터 FAB 자리 (index 2)
          _NavItem(
              route: '/reviews',
              icon: Icons.rate_review_outlined,
              activeIcon: Icons.rate_review_rounded,
              label: '리뷰'),
          _NavItem(
              route: '/profile',
              icon: Icons.more_horiz_outlined,
              activeIcon: Icons.more_horiz_rounded,
              label: '더보기'),
        ];
    }
  }

  /// 사용자 유형별 센터 FAB 설정
  static _CenterFabConfig _getCenterFab(UserType userType) {
    switch (userType) {
      case UserType.reviewer:
        return const _CenterFabConfig(
          icon: Icons.edit_rounded,
          route: '/missions',
          label: '리뷰 작성',
        );
      case UserType.consumer:
        return const _CenterFabConfig(
          icon: Icons.emoji_events_rounded,
          route: '/ranking',
          label: '랭킹',
        );
      case UserType.business:
        return const _CenterFabConfig(
          icon: Icons.analytics_rounded,
          route: '/trust-overview',
          label: '분석',
        );
    }
  }

  /// 현재 경로가 [route] 탭에 속하는지.
  ///
  /// 단순 startsWith 는 `/review` 가 `/review-request` 까지 잡아버리므로,
  /// 경로 세그먼트 경계(`/` 또는 문자열 끝)까지 확인한다.
  static bool _matchesRoute(String location, String route) {
    if (location == route) return true;
    return location.startsWith('$route/');
  }

  int _calculateSelectedIndex(BuildContext context, UserType userType) {
    final location = GoRouterState.of(context).uri.path;
    final navItems = _getNavItems(userType);
    final centerRoute = _getCenterFab(userType).route;

    // 센터 FAB 라우트가 일반 탭과 겹칠 수 있으므로(리뷰어의 /missions) 탭을 먼저 본다.
    for (int i = 0; i < navItems.length; i++) {
      if (_matchesRoute(location, navItems[i].route)) {
        // 센터 FAB 이 index 2 를 차지하므로 뒤쪽 두 개는 한 칸 밀린다.
        return i < 2 ? i : i + 1;
      }
    }

    if (_matchesRoute(location, centerRoute)) return 2;

    return 0;
  }

  void _onItemTapped(
      BuildContext context, int index, int currentIndex, UserType userType) {
    final navItems = _getNavItems(userType);
    final centerFab = _getCenterFab(userType);

    // 이미 선택된 탭을 다시 누르면 이동하지 않는다(스택 리셋 깜빡임 방지).
    if (index == currentIndex) {
      AppHaptics.tap();
      return;
    }

    AppHaptics.tap();

    if (index == 2) {
      context.go(centerFab.route);
      return;
    }

    final navIndex = index < 2 ? index : index - 1;
    if (navIndex >= 0 && navIndex < navItems.length) {
      context.go(navItems[navIndex].route);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userType = ref.watch(userTypeProvider);
    final currentIndex = _calculateSelectedIndex(context, userType);
    final navItems = _getNavItems(userType);
    final centerFab = _getCenterFab(userType);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      backgroundColor: HwahaeColors.background,
      // 콘텐츠가 떠 있는 네비게이션 바 뒤로 흐르게 한다.
      extendBody: true,
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      // 키보드가 올라오면 네비게이션 바를 숨긴다. 좁은 화면에서 입력 영역을 최대한 확보.
      bottomNavigationBar: keyboardOpen
          ? null
          : Padding(
              padding: EdgeInsets.fromLTRB(
                AppLayout.gutterOf(context),
                0,
                AppLayout.gutterOf(context),
                // 홈 인디케이터가 있는 기기에서는 그만큼 더 띄운다.
                AppLayout.navBarMargin +
                    (bottomInset > 0 ? bottomInset - 8 : 8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: AppLayout.navBarHeight,
                    decoration: BoxDecoration(
                      color: HwahaeColors.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: HwahaeColors.borderLight.withValues(alpha: 0.8),
                      ),
                      boxShadow: AppElevation.level3,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: [
                        _NavTab(
                          item: navItems[0],
                          selected: currentIndex == 0,
                          onTap: () =>
                              _onItemTapped(context, 0, currentIndex, userType),
                        ),
                        _NavTab(
                          item: navItems[1],
                          selected: currentIndex == 1,
                          onTap: () =>
                              _onItemTapped(context, 1, currentIndex, userType),
                        ),
                        _CenterTab(
                          config: centerFab,
                          selected: currentIndex == 2,
                          onTap: () =>
                              _onItemTapped(context, 2, currentIndex, userType),
                        ),
                        _NavTab(
                          item: navItems[2],
                          selected: currentIndex == 3,
                          onTap: () =>
                              _onItemTapped(context, 3, currentIndex, userType),
                        ),
                        _NavTab(
                          item: navItems[3],
                          selected: currentIndex == 4,
                          onTap: () =>
                              _onItemTapped(context, 4, currentIndex, userType),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// 일반 탭 하나.
///
/// 선택되면 아이콘 뒤에 브랜드 톤 알약이 나타나고 라벨이 굵어진다.
/// 아이콘은 살짝 위로 올라가 "튀어오르는" 느낌을 준다.
class _NavTab extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? HwahaeColors.primary : HwahaeColors.textTertiary;

    return Expanded(
      child: Semantics(
        label: item.label,
        button: true,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: AppMotion.base,
                  curve: AppMotion.emphasized,
                  padding: EdgeInsets.symmetric(
                    horizontal: selected ? 16 : 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? HwahaeColors.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    selected ? item.activeIcon : item.icon,
                    size: 22,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: AppMotion.base,
                  curve: AppMotion.standard,
                  style: HwahaeTypography.bottomNav.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 가운데 강조 버튼. 다른 탭보다 한 단계 위에 있는 행동이다.
class _CenterTab extends StatelessWidget {
  final _CenterFabConfig config;
  final bool selected;
  final VoidCallback onTap;

  const _CenterTab({
    required this.config,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: config.label,
      button: true,
      selected: selected,
      child: Pressable(
        onTap: onTap,
        scale: 0.9,
        // Pressable 이 이미 햅틱을 울리므로 onTap 쪽에서 중복 호출하지 않는다.
        haptic: false,
        child: Container(
          width: 52,
          height: 52,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: HwahaeColors.gradientPrimary,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppElevation.glow(
              HwahaeColors.primary,
              strength: selected ? 1.0 : 0.6,
            ),
          ),
          child: Icon(config.icon, size: 25, color: Colors.white),
        ),
      ),
    );
  }
}
