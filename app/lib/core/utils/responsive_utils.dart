import 'package:flutter/material.dart';

/// 반응형 디자인 유틸리티
/// 다양한 화면 크기에 대응하는 레이아웃 헬퍼
class ResponsiveUtils {
  /// 화면 크기 브레이크포인트
  static const double mobileBreakpoint = 480;
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;

  /// 현재 디바이스 타입 반환
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// 모바일 여부
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// 소형 모바일 여부 (320px 이하)
  static bool isSmallMobile(BuildContext context) {
    return MediaQuery.of(context).size.width <= 320;
  }

  /// 태블릿 여부
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// 데스크톱 여부
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// 화면 너비에 따른 값 반환
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  /// 화면 너비 기준 패딩
  static EdgeInsets responsivePadding(BuildContext context) {
    return responsiveValue(
      context,
      mobile: const EdgeInsets.symmetric(horizontal: 16),
      tablet: const EdgeInsets.symmetric(horizontal: 24),
      desktop: const EdgeInsets.symmetric(horizontal: 32),
    );
  }

  /// 반응형 그리드 컬럼 수
  static int responsiveGridColumns(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }

  /// 반응형 카드 너비
  static double? responsiveCardWidth(BuildContext context) {
    if (isDesktop(context)) return 400;
    if (isTablet(context)) return 350;
    return null; // 모바일에서는 전체 너비
  }

  /// 반응형 폰트 크기 조절 배율
  static double fontScaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width <= 320) return 0.85; // 아주 작은 화면
    if (width <= 375) return 0.95; // iPhone SE 등
    if (width >= 768) return 1.1; // 태블릿
    return 1.0;
  }

  /// 화면 높이 기준 공간 계산 (키보드 고려)
  static double availableHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom -
        mediaQuery.viewInsets.bottom;
  }

  /// 안전 영역 패딩
  static EdgeInsets safeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      bottom: mediaQuery.padding.bottom,
    );
  }
}

/// 디바이스 타입
enum DeviceType { mobile, tablet, desktop }

/// 반응형 레이아웃 빌더 위젯
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveUtils.desktopBreakpoint) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= ResponsiveUtils.mobileBreakpoint) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}

/// 반응형 패딩 위젯
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
  });

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtils.responsiveValue(
      context,
      mobile: mobilePadding ?? const EdgeInsets.symmetric(horizontal: 16),
      tablet: tabletPadding ?? const EdgeInsets.symmetric(horizontal: 24),
      desktop: desktopPadding ?? const EdgeInsets.symmetric(horizontal: 32),
    );

    return Padding(padding: padding, child: child);
  }
}

/// 반응형 그리드 위젯
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveUtils.responsiveValue(
      context,
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: columns == 1 ? constraints.maxWidth : itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

/// 반응형 컨테이너 - 최대 너비 제한
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;
  final Alignment alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: padding ?? ResponsiveUtils.responsivePadding(context),
        child: child,
      ),
    );
  }
}

/// 텍스트 스케일 래퍼
class ScaledText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? minScaleFactor;
  final double? maxScaleFactor;

  const ScaledText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.minScaleFactor,
    this.maxScaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final scaleFactor = ResponsiveUtils.fontScaleFactor(context).clamp(
      minScaleFactor ?? 0.8,
      maxScaleFactor ?? 1.2,
    );

    final scaledStyle = style?.copyWith(
      fontSize: (style?.fontSize ?? 14) * scaleFactor,
    );

    return Text(
      text,
      style: scaledStyle ?? TextStyle(fontSize: 14 * scaleFactor),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// 키보드 인식 스크롤뷰
class KeyboardAwareScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;

  const KeyboardAwareScrollView({
    super.key,
    required this.child,
    this.padding,
    this.controller,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      controller: controller,
      physics: physics,
      padding: EdgeInsets.only(
        left: padding?.left ?? 0,
        right: padding?.right ?? 0,
        top: padding?.top ?? 0,
        bottom: (padding?.bottom ?? 0) + bottomInset,
      ),
      child: child,
    );
  }
}

/// 화면 방향에 따른 빌더
class OrientationBuilder2 extends StatelessWidget {
  final Widget Function(BuildContext, Orientation) builder;

  const OrientationBuilder2({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) => builder(context, orientation),
    );
  }
}

/// 반응형 슬리버 그리드
class ResponsiveSliverGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final double spacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const ResponsiveSliverGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = 16,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveUtils.responsiveValue(
      context,
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
    );

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      delegate: SliverChildBuilderDelegate(
        itemBuilder,
        childCount: itemCount,
      ),
    );
  }
}
