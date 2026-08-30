import 'package:flutter/material.dart';
import '../../core/constants/grade_benefits.dart';
import '../../core/theme/hwahae_colors.dart';
import '../../core/theme/hwahae_typography.dart';
import '../../core/theme/hwahae_theme.dart';

/// 리뷰어 등급 진행바 위젯
/// compact: 미션 리스트 상단 배너용 (한 줄)
/// full: 프로필 화면용 (상세 정보 포함)
class GradeProgressWidget extends StatelessWidget {
  final String currentGrade;
  final int completedMissions;
  final double trustScore;
  final bool compact;
  final VoidCallback? onTap;

  const GradeProgressWidget({
    super.key,
    required this.currentGrade,
    required this.completedMissions,
    required this.trustScore,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompact(context) : _buildFull(context);
  }

  Widget _buildCompact(BuildContext context) {
    final gradeInfo = ReviewerGrades.getGradeInfo(currentGrade);
    final nextGrade = ReviewerGrades.getNextGrade(currentGrade);
    final progress = ReviewerGrades.calculateProgress(
      currentGrade, completedMissions, trustScore,
    );

    if (nextGrade == null) return const SizedBox.shrink();

    final missionsNeeded = nextGrade.requiredMissions - completedMissions;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradeInfo.colors[0].withValues(alpha: 0.08),
              nextGrade.colors[0].withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          border: Border.all(
            color: gradeInfo.colors[0].withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            // 현재 등급 아이콘
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradeInfo.colors),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(gradeInfo.icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            // 진행바 + 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        gradeInfo.label,
                        style: HwahaeTypography.labelSmall.copyWith(
                          color: gradeInfo.colors[0],
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 12, color: HwahaeColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        nextGrade.label,
                        style: HwahaeTypography.labelSmall.copyWith(
                          color: nextGrade.colors[0],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '미션 ${missionsNeeded > 0 ? missionsNeeded : 0}개 더!',
                        style: HwahaeTypography.captionSmall.copyWith(
                          color: HwahaeColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 진행바
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: HwahaeColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(gradeInfo.colors[0]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: HwahaeColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    final gradeInfo = ReviewerGrades.getGradeInfo(currentGrade);
    final nextGrade = ReviewerGrades.getNextGrade(currentGrade);
    final progress = ReviewerGrades.calculateProgress(
      currentGrade, completedMissions, trustScore,
    );
    final isMaxGrade = nextGrade == null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: HwahaeColors.surface,
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
          border: Border.all(color: HwahaeColors.border),
          boxShadow: HwahaeTheme.shadowSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 현재 등급 + 배지
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradeInfo.colors),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: gradeInfo.colors[0].withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(gradeInfo.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            gradeInfo.label,
                            style: HwahaeTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: gradeInfo.colors),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '현재 등급',
                              style: HwahaeTypography.captionSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        gradeInfo.description,
                        style: HwahaeTypography.captionMedium.copyWith(
                          color: HwahaeColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (isMaxGrade) ...[
              // 최고 등급 달성
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      gradeInfo.colors[0].withValues(alpha: 0.1),
                      gradeInfo.colors[1].withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: gradeInfo.colors[0].withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, color: gradeInfo.colors[0], size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '최고 등급을 달성했어요!',
                            style: HwahaeTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: gradeInfo.colors[0],
                            ),
                          ),
                          Text(
                            '모든 혜택을 누리고 있습니다',
                            style: HwahaeTypography.captionMedium.copyWith(
                              color: HwahaeColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // 다음 등급까지 진행바
              Row(
                children: [
                  Text(
                    '다음 등급',
                    style: HwahaeTypography.labelSmall.copyWith(
                      color: HwahaeColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: nextGrade.colors[0].withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(nextGrade.icon, size: 14, color: nextGrade.colors[0]),
                        const SizedBox(width: 4),
                        Text(
                          nextGrade.label,
                          style: HwahaeTypography.labelSmall.copyWith(
                            color: nextGrade.colors[0],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: HwahaeTypography.labelMedium.copyWith(
                      color: gradeInfo.colors[0],
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 진행바
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: HwahaeColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(gradeInfo.colors[0]),
                ),
              ),

              const SizedBox(height: 16),

              // 요구 조건 상세
              Row(
                children: [
                  Expanded(
                    child: _buildRequirementItem(
                      icon: Icons.flag_rounded,
                      label: '완료 미션',
                      current: completedMissions,
                      required_: nextGrade.requiredMissions,
                      color: gradeInfo.colors[0],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRequirementItem(
                      icon: Icons.star_rounded,
                      label: '신뢰도',
                      currentDouble: trustScore,
                      requiredDouble: nextGrade.requiredTrustScore,
                      color: gradeInfo.colors[0],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 다음 등급 혜택 미리보기
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: nextGrade.colors[0].withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: nextGrade.colors[0].withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: nextGrade.colors[0]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getNextGradeTeaser(nextGrade),
                        style: HwahaeTypography.captionMedium.copyWith(
                          color: nextGrade.colors[0],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementItem({
    required IconData icon,
    required String label,
    int? current,
    int? required_,
    double? currentDouble,
    double? requiredDouble,
    required Color color,
  }) {
    final isInt = current != null;
    final met = isInt
        ? current >= required_!
        : currentDouble! >= requiredDouble!;

    final currentStr = isInt ? '$current' : currentDouble!.toStringAsFixed(1);
    final requiredStr = isInt ? '$required_' : requiredDouble!.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HwahaeColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: met ? HwahaeColors.success : HwahaeColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: HwahaeTypography.captionSmall.copyWith(
                  color: HwahaeColors.textSecondary,
                ),
              ),
              if (met) ...[
                const Spacer(),
                Icon(Icons.check_circle, size: 14, color: HwahaeColors.success),
              ],
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: currentStr,
                  style: HwahaeTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: met ? HwahaeColors.success : color,
                  ),
                ),
                TextSpan(
                  text: ' / $requiredStr',
                  style: HwahaeTypography.captionMedium.copyWith(
                    color: HwahaeColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getNextGradeTeaser(ReviewerGradeInfo nextGrade) {
    final highlights = nextGrade.benefits
        .where((b) => b.isHighlighted)
        .take(2)
        .map((b) => b.title)
        .toList();

    if (highlights.isEmpty) {
      return '${nextGrade.label} 등급이 되면 더 많은 혜택을!';
    }

    return '${nextGrade.label}까지: ${highlights.join(', ')} 해금!';
  }
}
