import 'package:flutter/material.dart';

import '../../../core/theme/app_elevation.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/hwahae_colors.dart';
import '../../../core/theme/hwahae_theme.dart';
import '../../../core/theme/hwahae_typography.dart';

/// 버튼 위계. 한 화면에 primary 는 하나만 둔다.
enum AppButtonVariant {
  /// 화면의 주 행동. 그라디언트 + 글로우.
  primary,

  /// 보조 행동. 채운 배경, 글로우 없음.
  secondary,

  /// 브랜드 톤 배경 위 브랜드 텍스트. 카드 안 인라인 액션에 적합.
  tonal,

  /// 테두리만.
  outline,

  /// 배경 없음. 취소/건너뛰기.
  ghost,

  /// 파괴적 행동(삭제, 해지).
  danger,
}

enum AppButtonSize {
  /// 카드 안 인라인 (높이 36)
  small,

  /// 기본 (높이 48) - 최소 터치 타깃과 동일
  medium,

  /// 화면 하단 주 CTA (높이 56)
  large,
}

/// 앱 전역 버튼.
///
/// 기존 HwahaePrimaryButton 대비: 누름 스케일, 햅틱, 로딩 중 라벨 자리 유지(레이아웃
/// 점프 방지), 최소 터치 타깃 보장, 아이콘 좌/우 배치를 지원한다.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;

  /// 아이콘을 라벨 오른쪽에 둘지 (기본은 왼쪽)
  final bool trailingIcon;

  /// 로딩 중에는 탭이 막히고 스피너가 뜬다. 버튼 폭은 유지된다.
  final bool isLoading;

  /// 가로를 꽉 채울지
  final bool expanded;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon = false,
    this.isLoading = false,
    this.expanded = true,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.large,
    this.icon,
    this.trailingIcon = false,
    this.isLoading = false,
    this.expanded = true,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon = false,
    this.isLoading = false,
    this.expanded = true,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.tonal({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon = false,
    this.isLoading = false,
    this.expanded = true,
  }) : variant = AppButtonVariant.tonal;

  const AppButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon = false,
    this.isLoading = false,
    this.expanded = true,
  }) : variant = AppButtonVariant.outline;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon = false,
    this.isLoading = false,
    this.expanded = false,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon = false,
    this.isLoading = false,
    this.expanded = true,
  }) : variant = AppButtonVariant.danger;

  bool get _enabled => onPressed != null && !isLoading;

  double get _height => switch (size) {
        AppButtonSize.small => 36,
        AppButtonSize.medium => AppLayout.minTapTarget,
        AppButtonSize.large => 56,
      };

  double get _radius => switch (size) {
        AppButtonSize.small => HwahaeTheme.radiusSM,
        AppButtonSize.medium => HwahaeTheme.radiusMD,
        AppButtonSize.large => HwahaeTheme.radiusLG,
      };

  EdgeInsets get _padding => switch (size) {
        AppButtonSize.small => const EdgeInsets.symmetric(horizontal: 14),
        AppButtonSize.medium => const EdgeInsets.symmetric(horizontal: 20),
        AppButtonSize.large => const EdgeInsets.symmetric(horizontal: 24),
      };

  TextStyle get _textStyle => switch (size) {
        AppButtonSize.small => HwahaeTypography.buttonSmall,
        AppButtonSize.medium => HwahaeTypography.button,
        AppButtonSize.large => HwahaeTypography.button
            .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      };

  double get _iconSize => size == AppButtonSize.small ? 16 : 18;

  double get _pressScale => switch (size) {
        AppButtonSize.small => 0.94,
        AppButtonSize.medium => 0.96,
        AppButtonSize.large => 0.975,
      };

  _ButtonPalette _palette() {
    switch (variant) {
      case AppButtonVariant.primary:
        // 골드 면 위의 흰 글자는 1.86:1 로 읽히지 않는다. 먹색이면 7.02:1.
        return const _ButtonPalette(
          gradient: HwahaeColors.gradientPrimary,
          foreground: HwahaeColors.onPrimary,
          glowColor: HwahaeColors.primary,
        );
      case AppButtonVariant.secondary:
        return const _ButtonPalette(
          background: HwahaeColors.textPrimary,
          foreground: HwahaeColors.textOnDark,
        );
      case AppButtonVariant.tonal:
        // 연한 골드 면에 골드 글자는 1.58:1 이라 사실상 보이지 않는다. 5.03:1.
        return const _ButtonPalette(
          background: HwahaeColors.primaryContainer,
          foreground: HwahaeColors.onPrimaryContainer,
        );
      case AppButtonVariant.outline:
        return const _ButtonPalette(
          background: Colors.transparent,
          foreground: HwahaeColors.textPrimary,
          // 테두리가 이 버튼의 유일한 경계라 카드용 border 로는 모자란다.
          border: HwahaeColors.borderStrong,
        );
      case AppButtonVariant.ghost:
        return const _ButtonPalette(
          background: Colors.transparent,
          foreground: HwahaeColors.textSecondary,
        );
      case AppButtonVariant.danger:
        // error 면 위의 흰 글자는 4.27:1 로 본문 기준에 모자라 면을 한 단계 내린다.
        return const _ButtonPalette(
          background: HwahaeColors.errorStrong,
          foreground: HwahaeColors.textOnDark,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette();
    final foreground = _enabled
        ? palette.foreground
        : palette.foreground.withValues(alpha: 0.55);

    final decoration = BoxDecoration(
      color: palette.gradient == null
          ? (_enabled
              ? palette.background
              : Color.alphaBlend(
                  palette.background!.withValues(alpha: 0.35),
                  HwahaeColors.surfaceVariant,
                ))
          : null,
      gradient: palette.gradient == null
          ? null
          : LinearGradient(
              colors: _enabled
                  ? palette.gradient!
                  : palette.gradient!
                      .map((c) => c.withValues(alpha: 0.45))
                      .toList(growable: false),
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
      borderRadius: BorderRadius.circular(_radius),
      border: palette.border == null
          ? null
          : Border.all(color: palette.border!, width: 1.2),
      // 글로우는 primary + large 조합(= 화면의 주 CTA)에서만. 남용하면 싸구려로 보인다.
      boxShadow:
          _enabled && palette.glowColor != null && size == AppButtonSize.large
              ? AppElevation.glow(palette.glowColor!)
              : null,
    );

    final content = Stack(
      alignment: Alignment.center,
      children: [
        // 로딩 중에도 라벨 자리를 남겨 버튼 폭이 흔들리지 않게 한다.
        Opacity(
          opacity: isLoading ? 0 : 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null && !trailingIcon) ...[
                Icon(icon, size: _iconSize, color: foreground),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: _textStyle.copyWith(color: foreground),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              if (icon != null && trailingIcon) ...[
                const SizedBox(width: 8),
                Icon(icon, size: _iconSize, color: foreground),
              ],
            ],
          ),
        ),
        if (isLoading)
          SizedBox(
            width: _iconSize + 2,
            height: _iconSize + 2,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          ),
      ],
    );

    final button = Pressable(
      onTap: _enabled ? onPressed : null,
      scale: _pressScale,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        height: _height,
        padding: _padding,
        decoration: decoration,
        alignment: Alignment.center,
        child: content,
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _ButtonPalette {
  final Color? background;
  final List<Color>? gradient;
  final Color foreground;
  final Color? border;
  final Color? glowColor;

  const _ButtonPalette({
    this.background,
    this.gradient,
    required this.foreground,
    this.border,
    this.glowColor,
  });
}

/// 아이콘 전용 버튼. 시각적 크기와 무관하게 터치 타깃 48dp 를 보장한다.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? background;
  final double iconSize;

  /// 알림 개수 등 우상단 배지. 0 이하면 표시하지 않는다.
  final int badgeCount;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.background,
    this.iconSize = 22,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final button = Pressable(
      onTap: onPressed,
      scale: 0.9,
      semanticLabel: tooltip,
      child: SizedBox(
        width: AppLayout.minTapTarget,
        height: AppLayout.minTapTarget,
        child: Center(
          child: Container(
            width: background == null ? null : AppLayout.iconButtonSize,
            height: background == null ? null : AppLayout.iconButtonSize,
            alignment: Alignment.center,
            decoration: background == null
                ? null
                : BoxDecoration(color: background, shape: BoxShape.circle),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: iconSize,
                  color: onPressed == null
                      ? HwahaeColors.textDisabled
                      : (color ?? HwahaeColors.textPrimary),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: BoxDecoration(
                        // 작고 굵은 흰 글씨라 error 면(4.27:1)으로는 모자란다.
                        color: HwahaeColors.errorStrong,
                        borderRadius:
                            BorderRadius.circular(HwahaeTheme.radiusFull),
                        border:
                            Border.all(color: HwahaeColors.surface, width: 1.5),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: HwahaeTypography.badge
                            .copyWith(color: HwahaeColors.textOnDark),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
