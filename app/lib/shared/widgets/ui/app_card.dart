import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_elevation.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/hwahae_colors.dart';
import '../../../core/theme/hwahae_theme.dart';
import '../../../core/theme/hwahae_typography.dart';

enum AppCardStyle {
  /// 기본. 흰 표면 + 부드러운 그림자.
  elevated,

  /// 그림자 없이 테두리만. 리스트가 길 때 시각적 소음을 줄인다.
  outlined,

  /// 배경보다 살짝 어두운 면. 카드 안의 하위 블록에 쓴다.
  sunken,

  /// 브랜드 그라디언트. 화면당 1개 이하로 제한한다.
  gradient,

  /// 반투명 + 블러. 이미지/그라디언트 위에 얹을 때만.
  glass,
}

/// 앱 전역 카드 컨테이너.
///
/// [onTap] 을 주면 자동으로 누름 애니메이션과 햅틱이 붙는다.
class AppCard extends StatelessWidget {
  final Widget child;
  final AppCardStyle style;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? radius;

  /// gradient 스타일에서 사용할 색. 미지정 시 브랜드 그라디언트.
  final List<Color>? gradientColors;

  /// outlined 스타일의 강조 테두리 색 (선택 상태 표현 등)
  final Color? borderColor;

  final String? semanticLabel;

  const AppCard({
    super.key,
    required this.child,
    this.style = AppCardStyle.elevated,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius,
    this.gradientColors,
    this.borderColor,
    this.semanticLabel,
  });

  double get _radius => radius ?? HwahaeTheme.radiusLG;

  BoxDecoration _decoration() {
    switch (style) {
      case AppCardStyle.elevated:
        return BoxDecoration(
          color: HwahaeColors.surface,
          borderRadius: BorderRadius.circular(_radius),
          border: borderColor == null
              ? null
              : Border.all(color: borderColor!, width: 1.5),
          boxShadow: AppElevation.level2,
        );
      case AppCardStyle.outlined:
        return BoxDecoration(
          color: HwahaeColors.surface,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(
            color: borderColor ?? HwahaeColors.borderLight,
            width: borderColor == null ? 1 : 1.5,
          ),
        );
      case AppCardStyle.sunken:
        return BoxDecoration(
          color: HwahaeColors.surfaceVariant,
          borderRadius: BorderRadius.circular(_radius),
        );
      case AppCardStyle.gradient:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors ?? HwahaeColors.gradientPrimary,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: AppElevation.glow(
            (gradientColors ?? HwahaeColors.gradientPrimary).first,
            strength: 0.7,
          ),
        );
      case AppCardStyle.glass:
        return BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      padding: padding,
      decoration: _decoration(),
      child: child,
    );

    if (style == AppCardStyle.glass) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: content,
        ),
      );
    }

    if (onTap != null || onLongPress != null) {
      content = Pressable(
        onTap: onTap,
        onLongPress: onLongPress,
        // 큰 면적일수록 축소폭을 작게 해야 자연스럽다.
        scale: 0.985,
        semanticLabel: semanticLabel,
        child: content,
      );
    }

    return margin == null ? content : Padding(padding: margin!, child: content);
  }
}

/// 라벨 + 값 + 추세를 보여주는 지표 타일. 대시보드/프로필 요약에 사용.
class AppStatTile extends StatelessWidget {
  final String label;
  final String value;

  /// 값 아래 보조 설명 (예: "지난주 대비")
  final String? caption;
  final IconData? icon;
  final Color? accent;

  /// 양수면 상승(초록), 음수면 하락(빨강) 화살표를 붙인다.
  final double? deltaPercent;
  final VoidCallback? onTap;

  const AppStatTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.accent,
    this.deltaPercent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = accent ?? HwahaeColors.primary;
    final delta = deltaPercent;

    return AppCard(
      style: AppCardStyle.elevated,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      semanticLabel: '$label $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(HwahaeTheme.radiusSM),
                  ),
                  child: Icon(icon, size: 16, color: accentColor),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  style: HwahaeTypography.captionMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: HwahaeTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (delta != null) ...[
                const SizedBox(width: 6),
                Icon(
                  delta >= 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 13,
                  color: delta >= 0 ? HwahaeColors.success : HwahaeColors.error,
                ),
                Text(
                  '${delta.abs().toStringAsFixed(1)}%',
                  style: HwahaeTypography.labelSmall.copyWith(
                    color:
                        delta >= 0 ? HwahaeColors.success : HwahaeColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              style: HwahaeTypography.captionSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// 설정/메뉴용 행. 좌측 아이콘 + 제목/부제 + 우측 액세서리.
class AppListRow extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;

  /// 우측에 놓을 위젯. 미지정이고 [onTap] 이 있으면 셰브론을 보여준다.
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  const AppListRow({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint = destructive
        ? HwahaeColors.error
        : (iconColor ?? HwahaeColors.textSecondary);

    return Pressable(
      onTap: onTap,
      scale: 0.99,
      semanticLabel: title,
      child: Container(
        // 최소 터치 타깃 보장
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.transparent,
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(HwahaeTheme.radiusSM),
                ),
                child: Icon(icon, size: 18, color: tint),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: HwahaeTypography.titleSmall.copyWith(
                      color: destructive
                          ? HwahaeColors.error
                          : HwahaeColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: HwahaeTypography.captionMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                (onTap == null
                    ? const SizedBox.shrink()
                    : const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: HwahaeColors.textTertiary,
                      )),
          ],
        ),
      ),
    );
  }
}
