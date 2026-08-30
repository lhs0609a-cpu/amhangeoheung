import 'package:flutter/material.dart';

import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/hwahae_colors.dart';
import '../../../core/theme/hwahae_theme.dart';
import '../../../core/theme/hwahae_typography.dart';

/// 선택 가능한 필터 칩.
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  /// 선택 상태의 강조 색. 미지정 시 브랜드 컬러.
  final Color? accent;

  /// 라벨 뒤 개수 표시 (예: "카페 12")
  final int? count;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.accent,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? HwahaeColors.primary;

    return Pressable(
      onTap: onTap,
      scale: 0.94,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        // 칩 높이 36 + 상하 여백으로 최소 터치 타깃을 확보한다.
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? tint : HwahaeColors.surface,
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusFull),
          border: Border.all(
            color: selected ? tint : HwahaeColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected
                    ? HwahaeColors.onColor(tint)
                    : HwahaeColors.textSecondary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: HwahaeTypography.chip.copyWith(
                color: selected
                    ? HwahaeColors.onColor(tint)
                    : HwahaeColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 5),
              Text(
                '$count',
                style: HwahaeTypography.chip.copyWith(
                  color: selected
                      ? HwahaeColors.onColor(tint).withValues(alpha: 0.8)
                      : HwahaeColors.textTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 가로 스크롤 필터 칩 줄.
///
/// 화면 좌우 끝까지 스크롤되도록 gutter 를 padding 으로 넣는다(자르지 않는다).
class AppChipBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color? accent;

  /// 각 칩 뒤에 붙일 개수. 길이가 labels 와 다르면 무시한다.
  final List<int>? counts;

  const AppChipBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.accent,
    this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final withCounts = counts != null && counts!.length == labels.length;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.gutterOf(context),
          vertical: 4,
        ),
        physics: const BouncingScrollPhysics(),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => AppChip(
          label: labels[index],
          selected: index == selectedIndex,
          accent: accent,
          count: withCounts ? counts![index] : null,
          onTap: () => onSelected(index),
        ),
      ),
    );
  }
}

/// 상태/속성 표시용 정적 배지. 탭할 수 없다.
class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  /// true 면 색을 채우고, false 면 연한 배경 + 색 텍스트
  final bool filled;
  final bool compact;

  const AppBadge({
    super.key,
    required this.label,
    this.color = HwahaeColors.primary,
    this.icon,
    this.filled = false,
    this.compact = false,
  });

  /// 미션 유형(hidden/season/urgent/premium)에 맞는 색을 자동 적용한다.
  factory AppBadge.missionType(String type, {bool filled = true}) {
    final label = switch (type.toLowerCase()) {
      'hidden' => '히든',
      'season' => '시즌',
      'urgent' => '긴급',
      'premium' => '프리미엄',
      _ => '일반',
    };
    final icon = switch (type.toLowerCase()) {
      'hidden' => Icons.visibility_off_rounded,
      'season' => Icons.auto_awesome_rounded,
      'urgent' => Icons.bolt_rounded,
      'premium' => Icons.workspace_premium_rounded,
      _ => Icons.flag_rounded,
    };
    return AppBadge(
      label: label,
      color: HwahaeColors.getMissionTypeColor(type),
      icon: icon,
      filled: filled,
      compact: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    // filled 배지의 배경은 등급·미션 유형 등 밝기가 제각각이라
    // 흰색을 고정하면 골드 계열에서 읽히지 않는다.
    final foreground = filled ? HwahaeColors.onColor(color) : color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusXS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 10 : 12, color: foreground),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style:
                (compact ? HwahaeTypography.badge : HwahaeTypography.labelSmall)
                    .copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

/// 진행률 막대. 등급 진행도, 미션 모집률 등에 사용.
class AppProgressBar extends StatelessWidget {
  /// 0.0 ~ 1.0
  final double value;
  final Color? color;
  final double height;

  /// 진행률에 따라 색을 자동 변경 (모집 마감 임박 = 빨강)
  final bool autoColor;

  const AppProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 6,
    this.autoColor = false,
  });

  Color get _resolved {
    if (color != null) return color!;
    if (!autoColor) return HwahaeColors.primary;
    if (value >= 0.9) return HwahaeColors.error;
    if (value >= 0.7) return HwahaeColors.warning;
    return HwahaeColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(height: height, color: HwahaeColors.surfaceContainer),
          LayoutBuilder(
            builder: (context, constraints) => AnimatedContainer(
              duration: AppMotion.slow,
              curve: AppMotion.decelerate,
              height: height,
              width: constraints.maxWidth * clamped,
              decoration: BoxDecoration(
                color: _resolved,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
