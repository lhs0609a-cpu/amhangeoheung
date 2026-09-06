import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 앱 전역 스크롤 동작.
///
/// - iOS/Android 모두 바운스 물리를 쓴다. 안드로이드 기본 글로우는 스크롤이
///   끝났다는 신호가 약하고, 리스트가 많은 이 앱에서는 바운스가 더 자연스럽다.
/// - 마우스/트랙패드 드래그를 허용해 데스크톱 웹 빌드에서도 스크롤이 된다.
/// - 안드로이드 오버스크롤 글로우 인디케이터를 제거한다(바운스와 중복).
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
