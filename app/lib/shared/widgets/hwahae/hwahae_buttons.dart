import 'package:flutter/material.dart';

import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/hwahae_colors.dart';
import '../ui/app_button.dart';

/// 아래 세 위젯은 [AppButton] 의 얇은 래퍼다.
///
/// 이전에는 각자 ElevatedButton/OutlinedButton/TextButton 을 따로 스타일링해서
/// 눌림 반응도 햅틱도 없고 터치 타깃도 제각각이었다. 호출부를 전부 고치는 대신
/// 껍데기만 남기고 실제 구현을 AppButton 으로 넘겨, 기존 화면이 그대로
/// 새 인터랙션을 물려받게 한다.
///
/// 새로 작성하는 화면에서는 [AppButton] 을 직접 쓴다.

/// Primary Button - 주요 액션용
class HwahaePrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const HwahaePrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      expanded: isFullWidth,
      variant: AppButtonVariant.primary,
      // 기존 호출부의 버튼 높이(약 48)를 유지한다. large 로 올리면 이미 짜인
      // 레이아웃에서 하단 CTA 가 화면을 밀어낸다.
      size: AppButtonSize.medium,
    );
  }
}

/// Secondary Button - 보조 액션용
class HwahaeSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const HwahaeSecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      expanded: isFullWidth,
      variant: AppButtonVariant.outline,
      size: AppButtonSize.medium,
    );
  }
}

/// Text Button - 텍스트 액션용
class HwahaeTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  const HwahaeTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // AppButton.ghost 는 색을 고정하므로, 색 지정이 있으면 직접 그린다.
    if (color == null) {
      return AppButton.ghost(
        label: text,
        onPressed: onPressed,
        icon: icon,
        size: AppButtonSize.small,
      );
    }

    return Pressable(
      onTap: onPressed,
      scale: 0.94,
      semanticLabel: text,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppLayout.minTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: onPressed == null
                        ? HwahaeColors.textDisabled
                        : color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
