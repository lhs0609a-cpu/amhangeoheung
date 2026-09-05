import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';
import '../../data/models/training_module_model.dart';
import '../../providers/certification_provider.dart';
import '../widgets/certification_badge.dart';

/// 3일 교육 과정의 각 날.
class _Day {
  const _Day(this.number, this.title, this.subtitle);
  final int number;
  final String title;
  final String subtitle;
}

const _days = <_Day>[
  _Day(1, '암행어흥의 철학', '왜 객관적 리뷰가 중요한가, 평가 기준 학습'),
  _Day(2, '현장 행동 수칙', '신분 노출 방지, 사진 촬영 가이드, 문제 대응'),
  _Day(3, '리뷰 작성 실습', '객관적 글쓰기, 실전 연습, 종합 시험'),
];

class CertificationHomeScreen extends ConsumerWidget {
  const CertificationHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(certificationNotifierProvider);

    return AppScreen(
      title: '리뷰어 인증',
      subtitle: '3일 과정',
      onRefresh: () =>
          ref.read(certificationNotifierProvider.notifier).loadStatus(),
      child: statusAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: 120),
          child: Center(
            child: CircularProgressIndicator(color: HwahaeColors.primary),
          ),
        ),
        error: (e, _) => AppErrorState.fromMessage(
          '$e',
          onRetry: () =>
              ref.read(certificationNotifierProvider.notifier).loadStatus(),
        ),
        data: (status) => _Content(status: status),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.status});

  final CertificationStatus status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        if (status.isCertified) ...[
          _Certificate(status: status),
          const SizedBox(height: AppLayout.cardGap),
          Center(child: CertificationBadge(level: status.certificationLevel)),
          const SizedBox(height: AppLayout.cardGap),
        ],
        _StatusCard(status: status),
        AppSection(
          title: '교육 과정',
          child: Column(
            children: [
              for (final day in _days) ...[
                _DayCard(day: day, status: status),
                const SizedBox(height: AppLayout.cardGap),
              ],
            ],
          ),
        ),
        if (status.qualityScore > 0) _QualityCard(status: status),
        const AppBottomSpacer.plain(),
      ],
    );
  }
}

/// 상태별 색과 문구. 인주색은 실제로 조치가 필요한 상태에만 쓴다.
({Color color, String label, IconData icon}) _statusFace(
  CertificationStatus status,
) {
  if (status.isCertified) {
    return (
      color: HwahaeColors.accent,
      label: '인증 완료',
      icon: Icons.verified_rounded,
    );
  }
  if (status.status == 'suspended') {
    return (
      color: HwahaeColors.secondary,
      label: '인증 정지',
      icon: Icons.gpp_bad_rounded,
    );
  }
  if (status.status == 'failed') {
    return (
      color: HwahaeColors.warning,
      label: '시험 불합격',
      icon: Icons.refresh_rounded,
    );
  }
  return (
    color: HwahaeColors.primaryDark,
    label: '교육 진행 중',
    icon: Icons.school_rounded,
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});

  final CertificationStatus status;

  @override
  Widget build(BuildContext context) {
    final face = _statusFace(status);
    final progress = _overallProgress(status);

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Icon(face.icon, color: face.color, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      face.label,
                      style: HwahaeTypography.titleMedium
                          .copyWith(color: face.color),
                    ),
                    if (!status.isCertified) ...[
                      const SizedBox(height: 2),
                      Text(
                        '전체 진행률 ${(progress * 100).round()}%',
                        style: HwahaeTypography.captionMedium.copyWith(
                          color: HwahaeColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppProgressBar(value: progress, color: face.color, height: 10),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.status});

  final _Day day;
  final CertificationStatus status;

  @override
  Widget build(BuildContext context) {
    final completed = status.isDayCompleted(day.number);
    final unlocked = status.isDayUnlocked(day.number);
    final progress = status.dayProgress[day.number];

    final (icon, color) = completed
        ? (Icons.check_circle_rounded, HwahaeColors.accent)
        : unlocked
            ? (Icons.play_circle_fill_rounded, HwahaeColors.primaryDark)
            : (Icons.lock_rounded, HwahaeColors.textDisabled);

    final muted = HwahaeColors.textTertiary;

    return AppCard(
      style: unlocked ? AppCardStyle.elevated : AppCardStyle.outlined,
      onTap: unlocked
          ? () => context.push('/certification/training/${day.number}')
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day ${day.number}. ${day.title}',
                  style: HwahaeTypography.titleSmall.copyWith(
                    color: unlocked ? HwahaeColors.textPrimary : muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  day.subtitle,
                  style: HwahaeTypography.captionMedium.copyWith(
                    color: unlocked ? HwahaeColors.textSecondary : muted,
                    height: 1.45,
                  ),
                ),
                if (progress != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${progress.completed}/${progress.total} 모듈 완료',
                    style: HwahaeTypography.captionSmall.copyWith(color: muted),
                  ),
                ],
              ],
            ),
          ),
          if (unlocked && !completed)
            const Padding(
              padding: EdgeInsets.only(top: 4, left: 6),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: HwahaeColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}

class _QualityCard extends StatelessWidget {
  const _QualityCard({required this.status});

  final CertificationStatus status;

  @override
  Widget build(BuildContext context) {
    final passing = status.qualityScore >= 70;

    return AppSection(
      title: '리뷰 품질 점수',
      subtitle: '70점 아래로 내려가면 인증이 정지됩니다',
      child: AppCard(
        child: Row(
          children: [
            Text(
              '${status.qualityScore.toStringAsFixed(1)}점',
              style: HwahaeTypography.displaySmall.copyWith(
                color: passing ? HwahaeColors.accent : HwahaeColors.warning,
              ),
            ),
            const Spacer(),
            if (status.warningCount > 0)
              AppBadge(
                label: '경고 ${status.warningCount}회',
                color: HwahaeColors.secondary,
                icon: Icons.warning_amber_rounded,
              ),
          ],
        ),
      ),
    );
  }
}

/// 수료증.
///
/// 감찰 인장([SealBadge])과 헷갈리지 않게 생김새를 다르게 둔다. 인장은 업체가
/// 감찰받았다는 표시이고 이건 감찰관이 교육을 마쳤다는 표시다.
class _Certificate extends StatelessWidget {
  const _Certificate({required this.status});

  final CertificationStatus status;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      borderColor: HwahaeColors.primary,
      style: AppCardStyle.outlined,
      child: Column(
        children: [
          const AppMascot.sato(size: 78),
          const SizedBox(height: 10),
          Text(
            '암행어사 수료증',
            style: HwahaeTypography.headlineSmall.copyWith(letterSpacing: 2),
          ),
          const SizedBox(height: 10),
          const Divider(color: HwahaeColors.onPrimaryContainer, thickness: 1),
          const SizedBox(height: 12),
          Text(
            '위 사람은 암행어흥 리뷰어 교육 과정을\n성실히 이수하였음을 인증합니다.',
            textAlign: TextAlign.center,
            style: HwahaeTypography.bodySmall.copyWith(
              color: HwahaeColors.textSecondary,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 16),
          if (status.certificationDate != null)
            Text(
              '인증일: ${_formatDate(status.certificationDate!)}',
              style: HwahaeTypography.captionMedium.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
          if (status.finalExamScore != null) ...[
            const SizedBox(height: 3),
            Text(
              // 예전에는 여기에 status.certificationId 를 찍었는데 모델에
              // 없는 필드다. status 가 dynamic 이라 분석기가 못 잡았고,
              // 수료증은 인증된 사람에게만 보이므로 인증을 마치는 순간
              // NoSuchMethodError 가 났을 자리다.
              '최종 시험 ${status.finalExamScore}점',
              style: HwahaeTypography.captionSmall.copyWith(
                color: HwahaeColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.year}년 ${date.month}월 ${date.day}일';

double _overallProgress(CertificationStatus status) {
  if (status.isCertified) return 1.0;

  var completed = 0;
  var total = 0;
  for (var day = 1; day <= 3; day++) {
    final dp = status.dayProgress[day];
    if (dp != null) {
      completed += dp.completed;
      total += dp.total;
    }
  }
  if (total == 0) return 0.0;
  return completed / total;
}
