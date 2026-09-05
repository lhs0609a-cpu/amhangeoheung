import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';
import '../../providers/notification_settings_provider.dart';

/// 알림 설정.
///
/// 예전에는 스위치 6개가 전부 화면 안의 지역 변수였다. 저장되는 곳도,
/// 백엔드 컬럼도 없어서 화면을 나가면 값이 사라지고 실제 발송에도 아무
/// 영향이 없었다. 지금은 `users` 테이블에 저장되고 발송 경로가 그 값을 본다.
class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);
    final s = state.settings;

    Future<void> apply(NotificationSettings next) async {
      final ok = await notifier.update(next);
      if (!ok && context.mounted) {
        AppToast.error(
          context,
          ref.read(notificationSettingsProvider).error ?? '저장하지 못했습니다',
        );
      }
    }

    if (state.isLoading) {
      return const AppScreen(
        title: '알림 설정',
        child: Padding(
          padding: EdgeInsets.only(top: 120),
          child: Center(
            child: CircularProgressIndicator(color: HwahaeColors.primary),
          ),
        ),
      );
    }

    return AppScreen(
      title: '알림 설정',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          AppSection(
            title: '알림 허용',
            topGap: 0,
            child: AppCard(
              padding: EdgeInsets.zero,
              child: _SwitchRow(
                icon: Icons.notifications_active_rounded,
                title: '푸시 알림',
                subtitle: s.push
                    ? '중요한 소식을 기기 알림으로 받습니다'
                    : '푸시는 오지 않고, 앱 안 알림 목록에만 쌓입니다',
                value: s.push,
                onChanged: (v) => apply(s.copyWith(push: v)),
              ),
            ),
          ),
          AppSection(
            title: '알림 종류',
            subtitle: '끈 종류는 알림 목록에도 쌓이지 않습니다',
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SwitchRow(
                    icon: Icons.flag_rounded,
                    title: '미션 알림',
                    subtitle: '새 미션, 배정, 마감',
                    value: s.mission,
                    onChanged: (v) => apply(s.copyWith(mission: v)),
                  ),
                  const AppDivider(indent: 60),
                  _SwitchRow(
                    icon: Icons.rate_review_rounded,
                    title: '리뷰 알림',
                    subtitle: '리뷰 게시, 이의 제기, 감찰 결과',
                    value: s.review,
                    onChanged: (v) => apply(s.copyWith(review: v)),
                  ),
                  const AppDivider(indent: 60),
                  _SwitchRow(
                    icon: Icons.payments_rounded,
                    title: '정산 알림',
                    subtitle: '정산 완료, 입금 실패',
                    value: s.settlement,
                    onChanged: (v) => apply(s.copyWith(settlement: v)),
                  ),
                  const AppDivider(indent: 60),
                  _SwitchRow(
                    icon: Icons.campaign_rounded,
                    title: '마케팅 알림',
                    subtitle: '이벤트, 추천인 소식, 경쟁 업체 동향',
                    value: s.marketing,
                    onChanged: (v) => apply(s.copyWith(marketing: v)),
                  ),
                ],
              ),
            ),
          ),
          AppSection(
            title: '방해 금지',
            child: AppCard(
              padding: EdgeInsets.zero,
              child: _SwitchRow(
                icon: Icons.nightlight_round,
                title: '야간 알림',
                subtitle: s.night
                    ? '밤에도 푸시가 옵니다'
                    : '21:00~08:00 에는 푸시를 보내지 않습니다 (알림은 남습니다)',
                value: s.night,
                onChanged: (v) => apply(s.copyWith(night: v)),
              ),
            ),
          ),
          const SizedBox(height: AppLayout.sectionGap),
          AppNotice(
            message: '자격 정지, 품질 경고, 담합 경고처럼 계정에 관한 통지는 '
                '설정과 무관하게 항상 보냅니다. 못 받아서 불이익을 보는 일이 '
                '없어야 하기 때문입니다.',
            icon: Icons.shield_outlined,
            color: HwahaeColors.info,
          ),
          const SizedBox(height: AppLayout.cardGap),
          Text(
            '기기 설정에서 알림을 차단한 경우에는 위 설정과 관계없이 알림이 '
            '오지 않습니다.',
            style: HwahaeTypography.captionMedium.copyWith(
              color: HwahaeColors.textTertiary,
              height: 1.5,
            ),
          ),
          const AppBottomSpacer.plain(),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppLayout.minTapTarget),
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: value
                      ? HwahaeColors.primaryContainer
                      : HwahaeColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: value
                      ? HwahaeColors.onPrimaryContainer
                      : HwahaeColors.textTertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: HwahaeTypography.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: HwahaeTypography.captionMedium.copyWith(
                        color: HwahaeColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 행 전체가 이미 탭을 받으므로 스위치는 표시만 한다.
              // 둘 다 콜백을 받으면 스위치를 눌렀을 때 두 번 토글된다.
              IgnorePointer(
                child: Switch(
                  value: value,
                  onChanged: (_) {},
                  activeThumbColor: HwahaeColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
