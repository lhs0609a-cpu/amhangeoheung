import 'package:flutter/material.dart';

/// 모바일 우선 레이아웃 토큰.
///
/// 화면마다 흩어져 있던 매직 넘버(하단 120px 여백, 좌우 16px 등)를 한 곳으로 모은다.
/// 값을 바꾸면 앱 전체 리듬이 함께 움직인다.
class AppLayout {
  AppLayout._();

  // === 화면 가장자리 ===
  /// 기본 좌우 여백. 4.7" ~ 6.9" 전 구간에서 한 손 조작 안전 영역을 확보한다.
  static const double gutter = 16.0;

  /// 소형 단말(360dp 미만)용 좁은 여백
  static const double gutterCompact = 12.0;

  /// 태블릿 이상에서 본문이 과도하게 늘어나지 않도록 하는 최대 폭
  static const double maxContentWidth = 560.0;

  // === 수직 리듬 ===
  /// 섹션과 섹션 사이
  static const double sectionGap = 28.0;

  /// 섹션 제목과 내용 사이
  static const double headerGap = 12.0;

  /// 카드와 카드 사이
  static const double cardGap = 12.0;

  // === 하단 네비게이션 ===
  /// 플로팅 네비게이션 바 자체 높이
  static const double navBarHeight = 64.0;

  /// 네비게이션 바가 화면 아래에서 띄워진 거리
  static const double navBarMargin = 12.0;

  /// 스크롤 콘텐츠가 네비게이션 바에 가리지 않기 위한 최소 하단 여백
  /// (기기 제스처 인셋은 [bottomScrollInset] 에서 추가로 더한다)
  static const double navBarClearance = navBarHeight + navBarMargin * 2;

  // === 터치 타깃 ===
  /// WCAG 2.2 / Material 권장 최소 터치 크기
  static const double minTapTarget = 48.0;

  /// 아이콘 버튼 기본 크기
  static const double iconButtonSize = 44.0;

  // === 하단 고정 CTA ===
  /// 하단 고정 액션 바의 콘텐츠 높이 (패딩 제외)
  static const double stickyBarContentHeight = 52.0;

  /// 현재 화면 폭에 맞는 좌우 여백
  static double gutterOf(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 360 ? gutterCompact : gutter;
  }

  /// 좌우 여백 EdgeInsets
  static EdgeInsets horizontalPadding(BuildContext context) {
    return EdgeInsets.symmetric(horizontal: gutterOf(context));
  }

  /// 스크롤 뷰 하단에 넣어야 할 여백.
  ///
  /// [withNavBar] 가 true 면 플로팅 하단 네비게이션 높이를,
  /// [extra] 로 화면별 추가 여백(예: 하단 고정 CTA)을 더한다.
  /// 제스처 내비게이션 인셋(iPhone 홈 인디케이터 등)은 항상 포함한다.
  static double bottomScrollInset(
    BuildContext context, {
    bool withNavBar = true,
    double extra = 0,
  }) {
    final viewPadding = MediaQuery.viewPaddingOf(context).bottom;
    return (withNavBar ? navBarClearance : 0) + viewPadding + extra + 16;
  }

  /// 키보드가 올라온 만큼의 높이 (0이면 닫힌 상태)
  static double keyboardInset(BuildContext context) {
    return MediaQuery.viewInsetsOf(context).bottom;
  }

  /// 큰 화면에서 본문 폭을 제한하고 가운데 정렬한다.
  static Widget constrain(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxContentWidth),
        child: child,
      ),
    );
  }
}

/// 자주 쓰는 MediaQuery 조회를 짧게 쓰기 위한 확장.
///
/// `MediaQuery.of(context)` 전체를 구독하면 키보드가 열릴 때마다 화면 전체가
/// 리빌드된다. 아래 게터는 필요한 축만 구독하는 `*Of` API 를 사용한다.
extension AppLayoutContext on BuildContext {
  /// 화면 크기
  Size get screenSize => MediaQuery.sizeOf(this);

  /// 소형 단말 여부 (아이폰 SE 급)
  bool get isCompactWidth => MediaQuery.sizeOf(this).width < 360;

  /// 세로가 짧은 단말 여부 - 히어로 영역을 줄여야 하는 기준
  bool get isShortHeight => MediaQuery.sizeOf(this).height < 700;

  /// 좌우 기본 여백
  double get gutter => AppLayout.gutterOf(this);

  /// 상단 상태바 높이
  double get topInset => MediaQuery.viewPaddingOf(this).top;

  /// 하단 제스처 인셋
  double get bottomInset => MediaQuery.viewPaddingOf(this).bottom;

  /// 키보드 높이
  double get keyboardInset => MediaQuery.viewInsetsOf(this).bottom;

  /// 키보드가 올라와 있는지
  bool get isKeyboardOpen => MediaQuery.viewInsetsOf(this).bottom > 0;

  /// 하단 네비게이션을 고려한 스크롤 여백
  double bottomScrollInset({bool withNavBar = true, double extra = 0}) {
    return AppLayout.bottomScrollInset(this,
        withNavBar: withNavBar, extra: extra);
  }
}
