import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';
import '../../data/models/detection_test_model.dart';
import '../../providers/detection_test_provider.dart';

/// 은밀성 통계.
///
/// 감찰관이 업체에 들키지 않았는지를 보여주는 화면이다. 들킨 것은 리뷰어의
/// 실패이므로 인주색(지적)으로, 끝까지 감춘 것은 풀색(확인됨)으로 표시한다 —
/// 팔레트 약속대로 붉은 것은 항상 "고쳐야 할 것"이어야 한다.
class StealthStatsScreen extends ConsumerWidget {
  const StealthStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(stealthStatsProvider);

    return AppScreen(
      title: '은밀성 통계',
      onRefresh: () async => ref.refresh(stealthStatsProvider.future),
      child: statsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: 120),
          child: Center(
            child: CircularProgressIndicator(color: HwahaeColors.primary),
          ),
        ),
        error: (e, _) => AppErrorState.fromMessage(
          '$e',
          onRetry: () => ref.invalidate(stealthStatsProvider),
        ),
        data: (stats) => _Content(stats: stats),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.stats});

  final StealthStats stats;

  @override
  Widget build(BuildContext context) {
    if (stats.totalTests == 0) {
      return const AppEmptyState(
        icon: Icons.visibility_off_rounded,
        title: '아직 역탐지 테스트가 없네',
        message: '감찰을 마치면 업체가 "누가 감찰관이었는지" 맞혀본다.\n'
            '못 맞힐수록 네 은밀성 점수가 올라간다.',
        showMascot: true,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 26),
          child: Column(
            children: [
              _ScoreRing(score: stats.stealthScore),
              const SizedBox(height: 18),
              Text(
                _gradeLabel(stats.stealthScore),
                style: HwahaeTypography.headlineSmall.copyWith(
                  color: _scoreColor(stats.stealthScore),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppLayout.cardGap),
        Row(
          children: [
            Expanded(
              child: AppStatTile(
                label: '총 테스트',
                value: '${stats.totalTests}',
                caption: '회',
              ),
            ),
            const SizedBox(width: AppLayout.cardGap),
            Expanded(
              child: AppStatTile(
                label: '들킨 횟수',
                value: '${stats.detectedCount}',
                caption: '회',
                accent: stats.detectedCount > 0
                    ? HwahaeColors.secondary
                    : HwahaeColors.accent,
              ),
            ),
            const SizedBox(width: AppLayout.cardGap),
            Expanded(
              child: AppStatTile(
                label: '감지율',
                value: '${stats.detectionRate}%',
                accent: _scoreColor(100 - stats.detectionRate.toDouble()),
              ),
            ),
          ],
        ),
        if (stats.advice.isNotEmpty) ...[
          const SizedBox(height: AppLayout.cardGap),
          AppNotice(
            message: stats.advice,
            icon: Icons.lightbulb_outline_rounded,
            color: HwahaeColors.primaryDark,
          ),
        ],
        if (stats.recentTests.isNotEmpty)
          AppSection(
            title: '최근 테스트 결과',
            child: AppCard(
              style: AppCardStyle.outlined,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < stats.recentTests.length; i++) ...[
                    if (i > 0) const AppDivider(),
                    _TestRow(test: stats.recentTests[i]),
                  ],
                ],
              ),
            ),
          ),
        const AppBottomSpacer.plain(),
      ],
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score);

    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: CircularProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              strokeWidth: 11,
              strokeCap: StrokeCap.round,
              backgroundColor: HwahaeColors.surfaceContainer,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toStringAsFixed(0),
                style: HwahaeTypography.displaySmall.copyWith(color: color),
              ),
              Text(
                '은밀성 점수',
                style: HwahaeTypography.captionMedium.copyWith(
                  color: HwahaeColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TestRow extends StatelessWidget {
  const _TestRow({required this.test});

  final DetectionTest test;

  @override
  Widget build(BuildContext context) {
    // 만료는 업체가 끝내 못 맞힌 것이므로 미감지와 같게 친다.
    final expired = test.status == 'expired';
    final score = expired ? 0 : (test.detectionScore ?? 0);
    final detected = !expired && score >= 70;

    final color = detected ? HwahaeColors.secondary : HwahaeColors.accent;
    final label = expired
        ? '미감지 (만료)'
        : detected
            ? '들켰음'
            : '미감지';

    return AppListRow(
      icon: detected
          ? Icons.visibility_rounded
          : Icons.visibility_off_rounded,
      iconColor: color,
      title: label,
      subtitle: test.createdAt == null
          ? null
          : '${test.createdAt!.month}월 ${test.createdAt!.day}일',
      trailing: Text(
        '$score점',
        style: HwahaeTypography.titleSmall.copyWith(color: color),
      ),
    );
  }
}

Color _scoreColor(double score) {
  if (score >= 75) return HwahaeColors.accent;
  if (score >= 45) return HwahaeColors.warning;
  return HwahaeColors.error;
}

String _gradeLabel(double score) {
  if (score >= 90) return '완벽한 은밀성';
  if (score >= 70) return '우수한 은밀성';
  if (score >= 50) return '보통';
  if (score >= 30) return '주의 필요';
  return '위험';
}
