import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// 접근성 유틸리티
/// 스크린 리더 및 접근성 기능 지원을 위한 헬퍼
class AccessibilityUtils {
  AccessibilityUtils._();

  /// 접근성 활성화 여부 확인
  static bool isAccessibilityEnabled(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }

  /// 스크린 리더 사용 여부 확인
  static bool isScreenReaderEnabled(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }

  /// 애니메이션 축소 설정 확인
  static bool reduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// 볼드 텍스트 설정 확인
  static bool boldText(BuildContext context) {
    return MediaQuery.of(context).boldText;
  }

  /// 고대비 설정 확인
  static bool highContrast(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// 접근성 적합 텍스트 스케일 반환
  static double getAccessibleTextScale(BuildContext context) {
    final scale = MediaQuery.of(context).textScaler.scale(1.0);
    // 최소 1.0, 최대 2.0으로 제한하여 레이아웃 깨짐 방지
    return scale.clamp(1.0, 2.0);
  }

  /// 접근성 친화적 터치 영역 크기 (최소 48x48)
  static const double minTouchTargetSize = 48.0;

  /// 접근성 친화적 아이콘 크기
  static const double accessibleIconSize = 24.0;

  /// 스크린 리더 알림 전송
  static void announceToScreenReader(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }
}

/// 접근성 래퍼 위젯들

/// 버튼용 시맨틱 래퍼
class SemanticButton extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final VoidCallback? onTap;
  final bool isEnabled;
  final bool isSelected;

  const SemanticButton({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.onTap,
    this.isEnabled = true,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: isEnabled,
      selected: isSelected,
      label: label,
      hint: hint,
      onTap: isEnabled ? onTap : null,
      child: child,
    );
  }
}

/// 이미지용 시맨틱 래퍼
class SemanticImage extends StatelessWidget {
  final Widget child;
  final String label;
  final bool excludeFromSemantics;

  const SemanticImage({
    super.key,
    required this.child,
    required this.label,
    this.excludeFromSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: label,
      excludeSemantics: excludeFromSemantics,
      child: child,
    );
  }
}

/// 헤더용 시맨틱 래퍼
class SemanticHeader extends StatelessWidget {
  final Widget child;
  final String? label;

  const SemanticHeader({
    super.key,
    required this.child,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: label,
      child: child,
    );
  }
}

/// 링크용 시맨틱 래퍼
class SemanticLink extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final VoidCallback? onTap;

  const SemanticLink({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: label,
      hint: hint ?? '탭하여 열기',
      onTap: onTap,
      child: child,
    );
  }
}

/// 텍스트 필드용 시맨틱 래퍼
class SemanticTextField extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final String? value;
  final bool isObscured;
  final bool isMultiline;
  final bool isReadOnly;

  const SemanticTextField({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.value,
    this.isObscured = false,
    this.isMultiline = false,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: label,
      hint: hint,
      value: value,
      obscured: isObscured,
      multiline: isMultiline,
      readOnly: isReadOnly,
      child: child,
    );
  }
}

/// 슬라이더용 시맨틱 래퍼
class SemanticSlider extends StatelessWidget {
  final Widget child;
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;

  const SemanticSlider({
    super.key,
    required this.child,
    required this.label,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      slider: true,
      label: label,
      value: '${(value * 100).round()}%',
      increasedValue: value < max ? '${((value + 0.1).clamp(min, max) * 100).round()}%' : null,
      decreasedValue: value > min ? '${((value - 0.1).clamp(min, max) * 100).round()}%' : null,
      onIncrease: onChanged != null && value < max
          ? () => onChanged!((value + 0.1).clamp(min, max))
          : null,
      onDecrease: onChanged != null && value > min
          ? () => onChanged!((value - 0.1).clamp(min, max))
          : null,
      child: child,
    );
  }
}

/// 체크박스용 시맨틱 래퍼
class SemanticCheckbox extends StatelessWidget {
  final Widget child;
  final String label;
  final bool isChecked;
  final ValueChanged<bool>? onChanged;

  const SemanticCheckbox({
    super.key,
    required this.child,
    required this.label,
    required this.isChecked,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: isChecked,
      label: label,
      onTap: onChanged != null ? () => onChanged!(!isChecked) : null,
      child: child,
    );
  }
}

/// 라디오 버튼용 시맨틱 래퍼
class SemanticRadio extends StatelessWidget {
  final Widget child;
  final String label;
  final bool isSelected;
  final bool isInGroup;
  final VoidCallback? onTap;

  const SemanticRadio({
    super.key,
    required this.child,
    required this.label,
    required this.isSelected,
    this.isInGroup = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      inMutuallyExclusiveGroup: isInGroup,
      label: label,
      onTap: onTap,
      child: child,
    );
  }
}

/// 진행률 표시용 시맨틱 래퍼
class SemanticProgress extends StatelessWidget {
  final Widget child;
  final String label;
  final double? value; // null이면 indeterminate
  final String? valueLabel;

  const SemanticProgress({
    super.key,
    required this.child,
    required this.label,
    this.value,
    this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: valueLabel ?? (value != null ? '${(value! * 100).round()}%' : '로딩 중'),
      child: child,
    );
  }
}

/// 알림/배지용 시맨틱 래퍼
class SemanticBadge extends StatelessWidget {
  final Widget child;
  final String label;
  final int? count;

  const SemanticBadge({
    super.key,
    required this.child,
    required this.label,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = count != null && count! > 0
        ? '$label, $count개의 알림'
        : label;

    return Semantics(
      label: semanticLabel,
      child: child,
    );
  }
}

/// 탭 바용 시맨틱 래퍼
class SemanticTab extends StatelessWidget {
  final Widget child;
  final String label;
  final bool isSelected;
  final int index;
  final int totalTabs;

  const SemanticTab({
    super.key,
    required this.child,
    required this.label,
    required this.isSelected,
    required this.index,
    required this.totalTabs,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      label: '$label, 탭 ${index + 1} / $totalTabs',
      child: child,
    );
  }
}

/// 카드/컨테이너용 시맨틱 래퍼
class SemanticContainer extends StatelessWidget {
  final Widget child;
  final String? label;
  final String? hint;
  final VoidCallback? onTap;
  final bool excludeSemantics;

  const SemanticContainer({
    super.key,
    required this.child,
    this.label,
    this.hint,
    this.onTap,
    this.excludeSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      hint: hint,
      onTap: onTap,
      excludeSemantics: excludeSemantics,
      child: child,
    );
  }
}

/// 정렬 순서 지정용 시맨틱 래퍼
class SemanticSortKey extends StatelessWidget {
  final Widget child;
  final double order;
  final String? name;

  const SemanticSortKey({
    super.key,
    required this.child,
    required this.order,
    this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      sortKey: OrdinalSortKey(order, name: name),
      child: child,
    );
  }
}

/// 라이브 리전 - 동적 콘텐츠 알림
class SemanticLiveRegion extends StatelessWidget {
  final Widget child;
  final String? label;

  const SemanticLiveRegion({
    super.key,
    required this.child,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: label,
      child: child,
    );
  }
}

/// 접근성 친화적 터치 영역 확장 위젯
class AccessibleTouchTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double minSize;

  const AccessibleTouchTarget({
    super.key,
    required this.child,
    this.onTap,
    this.minSize = AccessibilityUtils.minTouchTargetSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minSize,
          minHeight: minSize,
        ),
        child: Center(child: child),
      ),
    );
  }
}

/// 접근성 포커스 트래버셜 그룹
class AccessibleFocusGroup extends StatelessWidget {
  final Widget child;
  final String? debugLabel;
  final bool skipTraversal;

  const AccessibleFocusGroup({
    super.key,
    required this.child,
    this.debugLabel,
    this.skipTraversal = false,
  });

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: child,
    );
  }
}

/// 별점용 시맨틱 래퍼
class SemanticRating extends StatelessWidget {
  final Widget child;
  final double rating;
  final double maxRating;
  final String? label;

  const SemanticRating({
    super.key,
    required this.child,
    required this.rating,
    this.maxRating = 5.0,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final ratingLabel = label ?? '평점';
    return Semantics(
      label: '$ratingLabel ${rating.toStringAsFixed(1)}점, 최대 ${maxRating.toStringAsFixed(0)}점',
      child: child,
    );
  }
}

/// 가격 표시용 시맨틱 래퍼
class SemanticPrice extends StatelessWidget {
  final Widget child;
  final int amount;
  final String? label;
  final bool isDiscounted;
  final int? originalAmount;

  const SemanticPrice({
    super.key,
    required this.child,
    required this.amount,
    this.label,
    this.isDiscounted = false,
    this.originalAmount,
  });

  @override
  Widget build(BuildContext context) {
    String priceLabel;
    if (isDiscounted && originalAmount != null) {
      final discount = ((originalAmount! - amount) / originalAmount! * 100).round();
      priceLabel = '${label ?? '가격'} ${_formatCurrency(amount)}원, 원래 가격 ${_formatCurrency(originalAmount!)}원에서 $discount% 할인';
    } else {
      priceLabel = '${label ?? '가격'} ${_formatCurrency(amount)}원';
    }

    return Semantics(
      label: priceLabel,
      child: child,
    );
  }

  String _formatCurrency(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}

/// 날짜/시간 표시용 시맨틱 래퍼
class SemanticDateTime extends StatelessWidget {
  final Widget child;
  final DateTime dateTime;
  final String? label;
  final bool includeTime;

  const SemanticDateTime({
    super.key,
    required this.child,
    required this.dateTime,
    this.label,
    this.includeTime = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일';
    final timeStr = includeTime
        ? ' ${dateTime.hour}시 ${dateTime.minute}분'
        : '';
    final fullLabel = label != null
        ? '$label $dateStr$timeStr'
        : '$dateStr$timeStr';

    return Semantics(
      label: fullLabel,
      child: child,
    );
  }
}

/// 상태 표시용 시맨틱 래퍼
class SemanticStatus extends StatelessWidget {
  final Widget child;
  final String status;
  final String? label;
  final bool isImportant;

  const SemanticStatus({
    super.key,
    required this.child,
    required this.status,
    this.label,
    this.isImportant = false,
  });

  @override
  Widget build(BuildContext context) {
    final fullLabel = label != null ? '$label: $status' : status;

    return Semantics(
      label: fullLabel,
      liveRegion: isImportant,
      child: child,
    );
  }
}

/// 접근성 헬퍼 확장 메서드
extension AccessibilityExtensions on BuildContext {
  /// 접근성 설정 확인
  bool get isAccessibilityEnabled => AccessibilityUtils.isAccessibilityEnabled(this);

  /// 모션 축소 설정 확인
  bool get reduceMotion => AccessibilityUtils.reduceMotion(this);

  /// 볼드 텍스트 설정 확인
  bool get boldText => AccessibilityUtils.boldText(this);

  /// 고대비 설정 확인
  bool get highContrast => AccessibilityUtils.highContrast(this);

  /// 텍스트 스케일
  double get accessibleTextScale => AccessibilityUtils.getAccessibleTextScale(this);
}

/// 접근성 친화적 애니메이션 Duration 반환
Duration accessibleDuration(BuildContext context, Duration normal) {
  if (AccessibilityUtils.reduceMotion(context)) {
    return Duration.zero;
  }
  return normal;
}

/// 접근성 친화적 Curve 반환
Curve accessibleCurve(BuildContext context, Curve normal) {
  if (AccessibilityUtils.reduceMotion(context)) {
    return Curves.linear;
  }
  return normal;
}
