import 'package:flutter/material.dart';

import '../../../core/theme/app_elevation.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/hwahae_colors.dart';
import '../../../core/theme/hwahae_theme.dart';
import '../../../core/theme/hwahae_typography.dart';

/// 토스트(스낵바) 표준화.
///
/// 앱 곳곳에서 `ScaffoldMessenger.showSnackBar(SnackBar(...))` 를 직접 부르면
/// 색/모양/지속시간이 제각각이 된다. 여기로 통일하고, 하단 네비게이션 바 위로
/// 띄워 CTA 를 가리지 않게 한다.
class AppToast {
  AppToast._();

  static void success(BuildContext context, String message,
      {String? actionLabel, VoidCallback? onAction}) {
    AppHaptics.success();
    _show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      accent: HwahaeColors.accentLight,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void error(BuildContext context, String message,
      {String? actionLabel, VoidCallback? onAction}) {
    AppHaptics.error();
    _show(
      context,
      message: message,
      icon: Icons.error_rounded,
      accent: HwahaeColors.secondaryLight,
      // 오류는 읽을 시간이 더 필요하다.
      duration: const Duration(seconds: 4),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void info(BuildContext context, String message,
      {String? actionLabel, VoidCallback? onAction}) {
    _show(
      context,
      message: message,
      icon: Icons.info_rounded,
      accent: HwahaeColors.surfaceContainer,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void warning(BuildContext context, String message,
      {String? actionLabel, VoidCallback? onAction}) {
    AppHaptics.error();
    _show(
      context,
      message: message,
      icon: Icons.warning_rounded,
      accent: HwahaeColors.primary,
      duration: const Duration(seconds: 4),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color accent,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    // 이전 토스트가 남아 쌓이지 않도록 즉시 교체한다.
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        // 하단 플로팅 네비게이션을 가리지 않게 띄운다.
        margin: EdgeInsets.fromLTRB(
          AppLayout.gutter,
          0,
          AppLayout.gutter,
          AppLayout.navBarClearance + MediaQuery.viewPaddingOf(context).bottom,
        ),
        content: _ToastBody(
          message: message,
          icon: icon,
          accent: accent,
          actionLabel: actionLabel,
          onAction: onAction == null
              ? null
              : () {
                  messenger.hideCurrentSnackBar();
                  onAction();
                },
        ),
      ),
    );
  }
}

class _ToastBody extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color accent;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ToastBody({
    required this.message,
    required this.icon,
    required this.accent,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: HwahaeColors.textPrimary,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
        boxShadow: AppElevation.level3,
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: HwahaeTypography.bodySmall.copyWith(
                color: HwahaeColors.textOnDark,
                height: 1.35,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 8),
            Pressable(
              onTap: onAction,
              scale: 0.92,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  actionLabel!,
                  style: HwahaeTypography.labelMedium.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
