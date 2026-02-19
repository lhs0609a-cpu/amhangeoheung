import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/hwahae_colors.dart';
import '../../core/theme/hwahae_typography.dart';
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

  const _CenterFabConfig({
    required this.icon,
    required this.route,
    this.label,
  });
}

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  /// 사용자 유형별 네비게이션 항목
  static List<_NavItem> _getNavItems(UserType userType) {
    switch (userType) {
      case UserType.reviewer:
        return const [
          _NavItem(route: '/home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: '홈'),
          _NavItem(route: '/missions', icon: Icons.flag_outlined, activeIcon: Icons.flag_rounded, label: '미션'),
          // 센터 FAB 자리 (index 2)
          _NavItem(route: '/my-activity', icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: '내 활동'),
          _NavItem(route: '/profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: '프로필'),
        ];
      case UserType.consumer:
        return const [
          _NavItem(route: '/home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: '홈'),
          _NavItem(route: '/search', icon: Icons.search_outlined, activeIcon: Icons.search_rounded, label: '검색'),
          // 센터 FAB 자리 (index 2)
          _NavItem(route: '/reviews', icon: Icons.edit_note_outlined, activeIcon: Icons.edit_note_rounded, label: '리뷰'),
          _NavItem(route: '/profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: '프로필'),
        ];
      case UserType.business:
        return const [
          _NavItem(route: '/dashboard', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: '대시보드'),
          _NavItem(route: '/missions', icon: Icons.campaign_outlined, activeIcon: Icons.campaign_rounded, label: '미션관리'),
          // 센터 FAB 자리 (index 2)
          _NavItem(route: '/reviews', icon: Icons.rate_review_outlined, activeIcon: Icons.rate_review_rounded, label: '리뷰'),
          _NavItem(route: '/profile', icon: Icons.more_horiz_outlined, activeIcon: Icons.more_horiz_rounded, label: '더보기'),
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

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: HwahaeColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: HwahaeColors.primary.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 왼쪽 2개 탭
                _buildNavItem(
                  context,
                  index: 0,
                  currentIndex: currentIndex,
                  icon: navItems[0].icon,
                  activeIcon: navItems[0].activeIcon,
                  label: navItems[0].label,
                  userType: userType,
                ),
                _buildNavItem(
                  context,
                  index: 1,
                  currentIndex: currentIndex,
                  icon: navItems[1].icon,
                  activeIcon: navItems[1].activeIcon,
                  label: navItems[1].label,
                  userType: userType,
                ),
                // 센터 FAB
                _buildCenterNavItem(
                  context,
                  index: 2,
                  currentIndex: currentIndex,
                  config: centerFab,
                  userType: userType,
                ),
                // 오른쪽 2개 탭
                _buildNavItem(
                  context,
                  index: 3,
                  currentIndex: currentIndex,
                  icon: navItems[2].icon,
                  activeIcon: navItems[2].activeIcon,
                  label: navItems[2].label,
                  userType: userType,
                ),
                _buildNavItem(
                  context,
                  index: 4,
                  currentIndex: currentIndex,
                  icon: navItems[3].icon,
                  activeIcon: navItems[3].activeIcon,
                  label: navItems[3].label,
                  userType: userType,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required int currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required UserType userType,
  }) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: Semantics(
        label: label,
        button: true,
        selected: isSelected,
        child: InkWell(
          onTap: () => _onItemTapped(context, index, userType),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 16 : 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [
                              Color(0xFFF0EEFF),
                              Color(0xFFE8E4FF),
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    size: 24,
                    color: isSelected
                        ? HwahaeColors.primary
                        : HwahaeColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: HwahaeTypography.bottomNav.copyWith(
                    color: isSelected
                        ? HwahaeColors.primary
                        : HwahaeColors.textTertiary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterNavItem(
    BuildContext context, {
    required int index,
    required int currentIndex,
    required _CenterFabConfig config,
    required UserType userType,
  }) {
    final isSelected = index == currentIndex;

    return Semantics(
      label: config.label ?? '중앙 버튼',
      button: true,
      child: InkWell(
        onTap: () => _onItemTapped(context, index, userType),
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSelected
                  ? HwahaeColors.gradientPrimary
                  : [
                      HwahaeColors.primary.withOpacity(0.8),
                      HwahaeColors.primaryLight.withOpacity(0.8),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: HwahaeColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            config.icon,
            size: 28,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
