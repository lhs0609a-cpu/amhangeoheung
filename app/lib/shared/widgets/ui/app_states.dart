import 'package:flutter/material.dart';

import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/hwahae_colors.dart';
import '../../../core/theme/hwahae_typography.dart';
import 'app_button.dart';

/// 빈 상태.
///
/// "데이터 없음"으로 끝내지 않고 다음 행동을 제시하는 것이 핵심이다.
/// 아이콘은 원형 톤 배경 위에 올려 허전함을 줄인다.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;

  /// 다음 행동 버튼
  final String? actionLabel;
  final VoidCallback? onAction;

  /// 보조 행동 (텍스트 버튼)
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  final Color? accent;

  /// 리스트 안에 인라인으로 넣을 때 true (수직 여백을 줄인다)
  final bool compact;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.accent,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? HwahaeColors.primary;
    final iconBox = compact ? 56.0 : 84.0;

    return FadeSlideIn(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.gutterOf(context) + 8,
          vertical: compact ? 24 : 48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tint.withValues(alpha: 0.14),
                    tint.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: compact ? 26 : 36, color: tint),
            ),
            SizedBox(height: compact ? 14 : 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: (compact
                      ? HwahaeTypography.titleMedium
                      : HwahaeTypography.headlineSmall)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: HwahaeTypography.bodySmall.copyWith(
                  color: HwahaeColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? 16 : 24),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                size: compact ? AppButtonSize.small : AppButtonSize.medium,
                expanded: false,
              ),
            ],
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 4),
              AppButton.ghost(
                label: secondaryLabel!,
                onPressed: onSecondary,
                size: AppButtonSize.small,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 오류 상태. 원인별로 문구와 아이콘을 다르게 줘야 사용자가 대처할 수 있다.
class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  /// 네트워크 오류면 아이콘/문구를 오프라인 톤으로 바꾼다.
  final bool isNetworkError;
  final bool compact;

  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.isNetworkError = false,
    this.compact = false,
  });

  /// 예외 메시지 문자열에서 네트워크 오류 여부를 추정한다.
  factory AppErrorState.fromMessage(String message, {VoidCallback? onRetry}) {
    final lower = message.toLowerCase();
    final isNetwork = lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('timeout') ||
        lower.contains('연결') ||
        lower.contains('인터넷');
    return AppErrorState(
      message: message,
      onRetry: onRetry,
      isNetworkError: isNetwork,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon:
          isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
      title: isNetworkError ? '연결이 불안정해요' : '문제가 발생했어요',
      message: isNetworkError ? '네트워크 상태를 확인하고 다시 시도해주세요.' : message,
      accent: isNetworkError ? HwahaeColors.warning : HwahaeColors.error,
      actionLabel: onRetry == null ? null : '다시 시도',
      onAction: onRetry,
      compact: compact,
    );
  }
}

/// 화면 전체를 덮는 로딩 오버레이. 결제/제출처럼 되돌릴 수 없는 작업에 쓴다.
class AppLoadingOverlay extends StatelessWidget {
  final bool visible;
  final String? message;
  final Widget child;

  const AppLoadingOverlay({
    super.key,
    required this.visible,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (visible)
          Positioned.fill(
            child: AbsorbPointer(
              child: AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: AppMotion.base,
                child: ColoredBox(
                  color: HwahaeColors.background.withValues(alpha: 0.72),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(strokeWidth: 2.6),
                        ),
                        if (message != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            message!,
                            style: HwahaeTypography.bodySmall.copyWith(
                              color: HwahaeColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
