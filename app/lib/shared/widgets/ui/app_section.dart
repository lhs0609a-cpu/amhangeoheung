import 'package:flutter/material.dart';

import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/hwahae_colors.dart';
import '../../../core/theme/hwahae_theme.dart';
import '../../../core/theme/hwahae_typography.dart';

/// 섹션 제목 줄.
///
/// 화면마다 제각각이던 "제목 + 전체보기" 조합을 통일한다. 이모지는 제목 앞에
/// 붙이되 스크린리더에는 읽히지 않도록 제외한다.
class AppSectionHeader extends StatelessWidget {
  final String title;

  /// 제목 아래 한 줄 설명
  final String? subtitle;

  /// 제목 앞 이모지 (장식용)
  final String? emoji;

  /// 우측 액션 라벨. 미지정 시 '전체보기'
  final String? actionLabel;
  final VoidCallback? onAction;

  /// 좌우 여백을 직접 관리하고 싶을 때 false
  final bool applyGutter;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.emoji,
    this.actionLabel,
    this.onAction,
    this.applyGutter = true,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (emoji != null) ...[
                    ExcludeSemantics(
                      child: Text(emoji!, style: const TextStyle(fontSize: 17)),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      style: HwahaeTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: HwahaeTypography.captionLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (onAction != null)
          Pressable(
            onTap: onAction,
            scale: 0.94,
            semanticLabel: actionLabel ?? '전체보기',
            child: Padding(
              // 텍스트만 있으면 터치 영역이 좁아지므로 패딩으로 넓힌다.
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel ?? '전체보기',
                    style: HwahaeTypography.labelMedium.copyWith(
                      color: HwahaeColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 17,
                    color: HwahaeColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    if (!applyGutter) return row;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppLayout.gutterOf(context)),
      child: row,
    );
  }
}

/// 제목 + 본문을 묶는 섹션. 위쪽 여백과 제목-본문 간격을 표준화한다.
class AppSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? emoji;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;

  /// 섹션 위 여백. 화면 첫 섹션은 0 으로 준다.
  final double topGap;

  const AppSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.emoji,
    this.actionLabel,
    this.onAction,
    this.topGap = AppLayout.sectionGap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: topGap),
        AppSectionHeader(
          title: title,
          subtitle: subtitle,
          emoji: emoji,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
        const SizedBox(height: AppLayout.headerGap),
        child,
      ],
    );
  }
}

/// 하단 고정 액션 바.
///
/// 스크롤 콘텐츠 위에 떠 있는 CTA. 제스처 인셋과 키보드 높이를 자동으로 흡수해
/// iPhone 홈 인디케이터에 버튼이 겹치지 않는다.
class AppStickyBar extends StatelessWidget {
  final Widget child;

  /// 버튼 위에 붙는 보조 정보 (총액, 안내 문구 등)
  final Widget? info;

  /// 콘텐츠 위에 얹힐 때 상단 구분선을 그릴지
  final bool showDivider;

  const AppStickyBar({
    super.key,
    required this.child,
    this.info,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: AppMotion.base,
      curve: AppMotion.standard,
      // 키보드가 올라오면 그 위로 붙어 올라간다.
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppLayout.gutterOf(context),
          12,
          AppLayout.gutterOf(context),
          12 + (keyboardInset > 0 ? 0 : bottomInset),
        ),
        decoration: BoxDecoration(
          color: HwahaeColors.surface,
          border: showDivider
              ? const Border(
                  top: BorderSide(color: HwahaeColors.borderLight, width: 1),
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (info != null) ...[
              info!,
              const SizedBox(height: 10),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// 얇은 구분선. 좌우 여백이 들어간 리스트용.
class AppDivider extends StatelessWidget {
  final double indent;

  const AppDivider({super.key, this.indent = 16});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      endIndent: indent,
      color: HwahaeColors.borderLight,
    );
  }
}

/// 정보/주의 안내 배너. 화면 상단이나 폼 위에 놓는다.
class AppNotice extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const AppNotice({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.color = HwahaeColors.info,
    this.onTap,
  });

  const AppNotice.warning({
    super.key,
    required this.message,
    this.onTap,
  })  : icon = Icons.warning_amber_rounded,
        color = HwahaeColors.warning;

  const AppNotice.success({
    super.key,
    required this.message,
    this.onTap,
  })  : icon = Icons.check_circle_outline_rounded,
        color = HwahaeColors.success;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.99,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: HwahaeTypography.bodySmall.copyWith(
                  color: HwahaeColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: HwahaeColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

/// 스크롤 콘텐츠 맨 아래 여백.
///
/// 화면마다 `SizedBox(height: 120)` 같은 매직 넘버를 쓰면 기기별 제스처 인셋이
/// 반영되지 않아 마지막 항목이 홈 인디케이터/하단 네비게이션에 가린다.
/// 이 위젯은 실제 인셋을 읽어 계산한다.
class AppBottomSpacer extends StatelessWidget {
  /// 하단 플로팅 네비게이션이 있는 탭 화면이면 true.
  /// push 로 열린 상세 화면은 false.
  final bool withNavBar;

  /// 하단 고정 CTA 등 추가로 피해야 할 높이
  final double extra;

  const AppBottomSpacer({super.key, this.withNavBar = true, this.extra = 0});

  /// push 로 열린 화면용 (하단 네비게이션 없음)
  const AppBottomSpacer.plain({super.key, this.extra = 0}) : withNavBar = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppLayout.bottomScrollInset(
        context,
        withNavBar: withNavBar,
        extra: extra,
      ),
    );
  }
}

/// [AppBottomSpacer] 의 sliver 버전.
class SliverBottomSpacer extends StatelessWidget {
  final bool withNavBar;
  final double extra;

  const SliverBottomSpacer({super.key, this.withNavBar = true, this.extra = 0});

  const SliverBottomSpacer.plain({super.key, this.extra = 0})
      : withNavBar = false;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: AppBottomSpacer(withNavBar: withNavBar, extra: extra),
    );
  }
}
