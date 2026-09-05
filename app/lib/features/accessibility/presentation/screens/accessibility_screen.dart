import 'package:flutter/material.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';

/// 접근성 상태 화면.
///
/// **여기에 스위치를 두지 않는다.** 예전에는 "큰 텍스트 · 고대비 · 모션 줄이기"
/// 스위치 세 개가 있었지만 아무 것도 읽지 않는 죽은 상태였다. 켜도 아무 일이
/// 일어나지 않는 스위치는 없는 것보다 나쁘다 — 사용자가 조치를 했다고 믿고
/// 화면을 떠나기 때문이다.
///
/// 실제로 앱이 따르는 값은 전부 OS 설정이다. 그래서 이 화면은 조작판이 아니라
/// **지금 무엇이 적용돼 있는지 보여주는 계기판**이고, 바꾸는 곳은 시스템
/// 설정이라고 알려준다.
class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    // main.dart 가 0.9~1.3 으로 조인 뒤의 값이다. 사용자가 보는 실제 배율.
    final scale = media.textScaler.scale(1.0);

    return AppScreen(
      title: '접근성',
      subtitle: 'OS 설정을 따릅니다',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          AppSection(
            title: '지금 적용된 설정',
            subtitle: '기기의 접근성 설정을 그대로 반영합니다',
            topGap: 0,
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _StatusRow(
                    icon: Icons.text_fields_rounded,
                    title: '글자 크기',
                    value: '${(scale * 100).round()}%',
                    detail: scale >= 1.3
                        ? '앱 상한(130%)에 도달했습니다'
                        : '기기 설정을 따릅니다',
                    on: scale > 1.0,
                  ),
                  const AppDivider(),
                  _StatusRow(
                    icon: Icons.format_bold_rounded,
                    title: '굵은 글씨',
                    value: media.boldText ? '켜짐' : '꺼짐',
                    on: media.boldText,
                  ),
                  const AppDivider(),
                  _StatusRow(
                    icon: Icons.motion_photos_off_rounded,
                    title: '모션 줄이기',
                    value: media.disableAnimations ? '켜짐' : '꺼짐',
                    detail: media.disableAnimations
                        ? '화면 전환과 등장 효과를 끕니다'
                        : null,
                    on: media.disableAnimations,
                  ),
                  const AppDivider(),
                  _StatusRow(
                    icon: Icons.record_voice_over_rounded,
                    title: '스크린 리더',
                    value: media.accessibleNavigation ? '사용 중' : '꺼짐',
                    on: media.accessibleNavigation,
                  ),
                ],
              ),
            ),
          ),
          AppSection(
            title: '바꾸는 곳',
            child: AppNotice(
              message: '설정 앱 › 접근성 에서 바꾸면 이 앱에도 바로 반영됩니다. '
                  '앱을 다시 시작하지 않아도 됩니다.',
              icon: Icons.settings_rounded,
              color: HwahaeColors.info,
            ),
          ),
          AppSection(
            title: '앱이 보장하는 것',
            subtitle: '설정과 무관하게 항상 지킵니다',
            child: AppCard(
              style: AppCardStyle.outlined,
              padding: EdgeInsets.zero,
              child: Column(
                children: const [
                  _GuaranteeRow(
                    title: '색 대비 WCAG AA',
                    detail: '본문 4.5:1, 조작 경계 3:1 이상. 팔레트를 바꾸면 '
                        '대비 테스트가 먼저 깨지도록 해뒀습니다.',
                  ),
                  AppDivider(),
                  _GuaranteeRow(
                    title: '최소 터치 영역 48pt',
                    detail: '버튼·목록 행·아이콘 버튼 모두 손가락이 닿는 '
                        '크기를 밑돌지 않습니다.',
                  ),
                  AppDivider(),
                  _GuaranteeRow(
                    title: '색만으로 알리지 않기',
                    detail: '지적·개선 같은 판정은 색과 함께 글자와 아이콘으로도 '
                        '표시합니다.',
                  ),
                ],
              ),
            ),
          ),
          AppSection(
            title: '도움이 필요하시면',
            child: Text(
              '접근성 때문에 쓰기 어려운 화면이 있으면 고객센터로 알려주세요. '
              '어느 화면에서 무엇이 막혔는지 적어주시면 그 화면부터 고칩니다.',
              style: HwahaeTypography.bodySmall.copyWith(
                color: HwahaeColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          const AppBottomSpacer.plain(),
        ],
      ),
    );
  }
}

/// OS 에서 읽어온 값 하나. 조작할 수 없으므로 스위치가 아니라 배지로 보여준다.
class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.on,
    this.detail,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? detail;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return AppListRow(
      icon: icon,
      iconColor: on ? HwahaeColors.accent : HwahaeColors.textTertiary,
      title: title,
      subtitle: detail,
      trailing: AppBadge(
        label: value,
        color: on ? HwahaeColors.accent : HwahaeColors.textTertiary,
        filled: false,
        compact: true,
      ),
    );
  }
}

class _GuaranteeRow extends StatelessWidget {
  const _GuaranteeRow({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: HwahaeColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: HwahaeTypography.titleSmall),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: HwahaeTypography.captionMedium.copyWith(
                    color: HwahaeColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
