import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 모션 시스템 - 앱 전체 애니메이션의 단일 기준점
///
/// 값은 "체감 속도"를 기준으로 정했다. 모바일에서 300ms 를 넘어가는 전환은
/// 느리게 느껴지므로, 화면 전환을 제외한 모든 마이크로 인터랙션은 220ms 이하다.
class AppMotion {
  AppMotion._();

  // === Duration ===
  /// 눌림/색 변화 등 즉각 반응이 필요한 것
  static const Duration instant = Duration(milliseconds: 90);

  /// 아이콘 토글, 체크, 뱃지
  static const Duration fast = Duration(milliseconds: 140);

  /// 기본값. 카드 확장, 리스트 항목 등장
  static const Duration base = Duration(milliseconds: 220);

  /// 시트/다이얼로그 등 레이어 전환
  static const Duration slow = Duration(milliseconds: 320);

  /// 온보딩 히어로 등 연출용
  static const Duration deliberate = Duration(milliseconds: 480);

  // === Curve ===
  /// 표준 진입/이탈. 감속이 강해 "무게감" 있게 멈춘다.
  static const Curve standard = Cubic(0.2, 0, 0, 1);

  /// 화면에 들어오는 요소 (감속)
  static const Curve decelerate = Cubic(0.05, 0.7, 0.1, 1);

  /// 화면에서 나가는 요소 (가속)
  static const Curve accelerate = Cubic(0.3, 0, 1, 1);

  /// 강조가 필요한 등장 - 살짝 오버슈트
  static const Curve emphasized = Cubic(0.34, 1.28, 0.64, 1);

  /// 눌림 해제
  static const Curve spring = Cubic(0.2, 1.2, 0.3, 1);

  // === Stagger ===
  /// 리스트 항목이 순차 등장할 때 항목 간 지연
  static const Duration staggerStep = Duration(milliseconds: 45);

  /// 순차 등장 최대 항목 수 (그 이상은 지연 없이 즉시 등장 - 스크롤 성능 보호)
  static const int staggerMaxItems = 8;

  /// [index] 번째 항목의 등장 지연. 상한을 둬서 긴 리스트가 늦게 그려지지 않게 한다.
  static Duration staggerDelay(int index) {
    final capped = index.clamp(0, staggerMaxItems);
    return staggerStep * capped;
  }
}

/// 햅틱 - 플랫폼별 강도 차이를 흡수하고 의미 단위로 노출한다.
class AppHaptics {
  AppHaptics._();

  static bool _enabled = true;

  /// 접근성 설정 등으로 햅틱을 끄고 싶을 때
  static void setEnabled(bool value) => _enabled = value;

  /// 탭/선택 - 가장 흔한 피드백
  static void tap() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  /// 버튼 확정 액션
  static void press() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// 성공/완료
  static void success() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// 오류/차단
  static void error() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }
}

/// 누르면 살짝 줄어드는 래퍼.
///
/// 카드/버튼/타일 어디에나 감쌀 수 있고, 터치 영역은 그대로 유지된다.
/// [onTap] 이 null 이면 애니메이션과 햅틱 모두 비활성화된다.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// 눌렀을 때 축소 비율. 큰 카드일수록 작게(0.98), 작은 버튼일수록 크게(0.94).
  final double scale;

  /// 눌렀을 때 투명도
  final double pressedOpacity;

  /// 햅틱 사용 여부
  final bool haptic;

  /// 스크린리더 라벨
  final String? semanticLabel;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.pressedOpacity = 1.0,
    this.haptic = true,
    this.semanticLabel,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  bool get _interactive => widget.onTap != null || widget.onLongPress != null;

  void _setPressed(bool value) {
    if (!_interactive || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final content = AnimatedScale(
      scale: _pressed ? widget.scale : 1.0,
      duration: _pressed ? AppMotion.instant : AppMotion.base,
      curve: _pressed ? AppMotion.standard : AppMotion.spring,
      child: AnimatedOpacity(
        opacity: _pressed ? widget.pressedOpacity : 1.0,
        duration: AppMotion.instant,
        child: widget.child,
      ),
    );

    return Semantics(
      label: widget.semanticLabel,
      button: _interactive,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap == null
            ? null
            : () {
                if (widget.haptic) AppHaptics.tap();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                if (widget.haptic) AppHaptics.press();
                widget.onLongPress!();
              },
        child: content,
      ),
    );
  }
}

/// 아래에서 살짝 올라오며 페이드인. 리스트/섹션 등장에 사용.
///
/// 한 번만 재생되며, 스크롤 재구성 시 다시 재생되지 않는다.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  /// 시작 지점의 수직 오프셋(px). 음수면 위에서 내려온다.
  final double offset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.base,
    this.offset = 12,
  });

  /// 리스트 항목용 - 인덱스에 따라 자동으로 지연을 계산한다.
  factory FadeSlideIn.staggered({
    Key? key,
    required int index,
    required Widget child,
    double offset = 12,
  }) {
    return FadeSlideIn(
      key: key,
      delay: AppMotion.staggerDelay(index),
      offset: offset,
      child: child,
    );
  }

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.decelerate,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 모션 축소 설정이 켜져 있으면 애니메이션 없이 바로 보여준다.
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - _animation.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
