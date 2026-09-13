import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/hwahae_colors.dart';
import '../../core/providers/user_type_provider.dart';
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
  final String? label;

  const _CenterFabConfig({required this.icon, required this.route, this.label});
}

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
            label: '홈',
          ),
          _NavItem(
            route: '/missions',
            icon: Icons.flag_outlined,
            activeIcon: Icons.flag_rounded,
            label: '미션',
          ),
          // 센터 FAB 자리 (index 2)
          _NavItem(
            route: '/ranking',
            icon: Icons.emoji_events_outlined,
            activeIcon: Icons.emoji_events_rounded,
            label: '랭킹',
          ),
          _NavItem(
            route: '/profile',
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: '프로필',
          ),
        ];
      case UserType.consumer:
        return const [
          _NavItem(
            route: '/home',
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: '홈',
          ),
          _NavItem(
            route: '/search',
            icon: Icons.search_outlined,
            activeIcon: Icons.search_rounded,
            label: '검색',
          ),
          // 센터 FAB 자리 (index 2)
          _NavItem(
            route: '/reviews',
            icon: Icons.edit_note_outlined,
            activeIcon: Icons.edit_note_rounded,
            label: '리뷰',
          ),
          _NavItem(
            route: '/profile',
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: '프로필',
          ),
        ];
      case UserType.business:
        return const [
          _NavItem(
            route: '/dashboard',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            label: '대시보드',
          ),
          _NavItem(
            route: '/missions',
            icon: Icons.campaign_outlined,
            activeIcon: Icons.campaign_rounded,
            label: '미션관리',
          ),
          // 센터 FAB 자리 (index 2)
          _NavItem(
            route: '/reviews',
            icon: Icons.rate_review_outlined,
            activeIcon: Icons.rate_review_rounded,
            label: '리뷰',
          ),
          _NavItem(
            route: '/profile',
            icon: Icons.more_horiz_outlined,
            activeIcon: Icons.more_horiz_rounded,
            label: '더보기',
          ),
        ];
    }
  }

  /// 사용자 유형별 센터 FAB 설정
  static _CenterFabConfig _getCenterFab(UserType userType) {
    switch (userType) {
      case UserType.reviewer:
        return const _CenterFabConfig(
          icon: Icons.edit_rounded,
          route: '/my-activity',
          label: '내 활동',
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

  /// 센터 FAB 라우트 목록 (선택 인덱스 계산용)
  static String _getCenterRoute(UserType userType) {
    return _getCenterFab(userType).route;
  }

  int _calculateSelectedIndex(BuildContext context, UserType userType) {
    final location = GoRouterState.of(context).uri.path;
    final navItems = _getNavItems(userType);
    final centerRoute = _getCenterRoute(userType);

    // 센터 FAB 라우트 확인
    if (location.startsWith(centerRoute)) return 2;

    // 네비게이션 항목 확인 (센터 FAB 이전: 0,1 / 이후: 3,4)
    for (int i = 0; i < navItems.length; i++) {
      final navIndex = i < 2 ? i : i + 1; // 센터 FAB 공간 건너뛰기
      if (location.startsWith(navItems[i].route)) return navIndex;
    }

    return 0;
  }

  void _onItemTapped(BuildContext context, int index, UserType userType) {
    final navItems = _getNavItems(userType);
    final centerFab = _getCenterFab(userType);

    if (index == 2) {
      // 센터 FAB
      context.go(centerFab.route);
      return;
    }

    // navItems 인덱스 변환: 0,1 → 0,1 / 3,4 → 2,3
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

    final destinations = [
      for (var i = 0; i < 5; i++)
        if (i == 2)
          NavigationDestination(
            icon: Icon(centerFab.icon),
            label: centerFab.label ?? '',
          )
        else
          NavigationDestination(
            icon: Icon(navItems[i < 2 ? i : i - 1].icon),
            selectedIcon: Icon(navItems[i < 2 ? i : i - 1].activeIcon),
            label: navItems[i < 2 ? i : i - 1].label,
          ),
    ];
    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: HwahaeColors.divider)),
        ),
        child: NavigationBar(
          height: 72,
          backgroundColor: HwahaeColors.surface,
          indicatorColor: HwahaeColors.primaryContainer,
          selectedIndex: currentIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) =>
              _onItemTapped(context, index, userType),
          destinations: destinations,
        ),
      ),
    );
  }
}
