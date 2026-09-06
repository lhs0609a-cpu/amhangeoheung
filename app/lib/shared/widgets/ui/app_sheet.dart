import 'package:flutter/material.dart';

import '../../../core/theme/app_elevation.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/hwahae_colors.dart';
import '../../../core/theme/hwahae_theme.dart';
import '../../../core/theme/hwahae_typography.dart';
import 'app_button.dart';

/// 모바일에서 선택/확인은 화면 중앙 다이얼로그보다 하단 시트가 낫다.
/// 엄지 도달 범위 안에 있고, 드래그로 닫을 수 있으며, 화면 맥락을 가리지 않는다.
///
/// [builder] 안에서 `Navigator.pop(context, value)` 로 결과를 돌려준다.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) builder,

  /// 시트 상단 제목
  String? title,

  /// 제목 아래 설명
  String? subtitle,

  /// 내용이 길어 스크롤이 필요한 경우 true (화면의 92%까지 늘어난다)
  bool scrollable = false,

  /// 바깥 탭/드래그로 닫을 수 있는지
  bool dismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    backgroundColor: Colors.transparent,
    barrierColor: AppGlass.scrim,
    // 시트 내부에서 SafeArea 를 직접 다루므로 기본 처리는 끈다.
    useSafeArea: false,
    builder: (sheetContext) => _AppSheetShell(
      title: title,
      subtitle: subtitle,
      scrollable: scrollable,
      dismissible: dismissible,
      child: builder(sheetContext),
    ),
  );
}

class _AppSheetShell extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final bool scrollable;
  final bool dismissible;

  const _AppSheetShell({
    required this.child,
    this.title,
    this.subtitle,
    required this.scrollable,
    required this.dismissible,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight =
        MediaQuery.sizeOf(context).height * (scrollable ? 0.92 : 0.85);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 드래그 핸들 - 닫을 수 있다는 어포던스
        if (dismissible)
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              decoration: BoxDecoration(
                color: HwahaeColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          )
        else
          const SizedBox(height: 12),
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title!,
                  style: HwahaeTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: HwahaeTypography.captionLarge),
                ],
              ],
            ),
          ),
        Flexible(child: child),
        // 홈 인디케이터 + 키보드를 피한다.
        SizedBox(height: keyboardInset > 0 ? keyboardInset : bottomInset + 8),
      ],
    );

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(HwahaeTheme.radiusXL),
        ),
      ),
      child: body,
    );
  }
}

/// 확인/취소 시트. 파괴적 행동에는 [destructive] 를 켜서 빨간 버튼을 쓴다.
///
/// 반환값: 확인 true / 취소·닫힘 false
Future<bool> showAppConfirm({
  required BuildContext context,
  required String title,
  String? message,
  String confirmLabel = '확인',
  String cancelLabel = '취소',
  bool destructive = false,
  IconData? icon,
}) async {
  final result = await showAppSheet<bool>(
    context: context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (icon != null) ...[
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color:
                      (destructive ? HwahaeColors.error : HwahaeColors.primary)
                          .withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color:
                      destructive ? HwahaeColors.error : HwahaeColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: HwahaeTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: HwahaeTypography.bodySmall.copyWith(
                color: HwahaeColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: AppButton.outline(
                  label: cancelLabel,
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: destructive
                    ? AppButton.danger(
                        label: confirmLabel,
                        onPressed: () {
                          AppHaptics.press();
                          Navigator.of(sheetContext).pop(true);
                        },
                      )
                    : AppButton(
                        label: confirmLabel,
                        onPressed: () {
                          AppHaptics.press();
                          Navigator.of(sheetContext).pop(true);
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  return result ?? false;
}

/// 목록 중 하나를 고르는 시트. 라디오 다이얼로그를 대체한다.
Future<int?> showAppOptionSheet({
  required BuildContext context,
  required String title,
  required List<String> options,
  int? selectedIndex,
  String? subtitle,
  List<IconData>? icons,
}) {
  return showAppSheet<int>(
    context: context,
    title: title,
    subtitle: subtitle,
    scrollable: options.length > 6,
    builder: (sheetContext) => ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      physics: options.length > 6
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final isSelected = index == selectedIndex;
        return Pressable(
          onTap: () => Navigator.of(sheetContext).pop(index),
          scale: 0.98,
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? HwahaeColors.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
            ),
            child: Row(
              children: [
                if (icons != null && icons.length == options.length) ...[
                  Icon(
                    icons[index],
                    size: 20,
                    color: isSelected
                        ? HwahaeColors.primary
                        : HwahaeColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    options[index],
                    style: HwahaeTypography.titleSmall.copyWith(
                      color: isSelected
                          ? HwahaeColors.primary
                          : HwahaeColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: HwahaeColors.primary,
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// 시트 내부에서 하단에 붙는 액션 영역. 스크롤되는 본문과 분리한다.
class AppSheetActions extends StatelessWidget {
  final Widget child;

  const AppSheetActions({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppLayout.gutterOf(context) + 4,
        12,
        AppLayout.gutterOf(context) + 4,
        4,
      ),
      child: child,
    );
  }
}
