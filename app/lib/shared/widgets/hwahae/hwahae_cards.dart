import 'package:flutter/material.dart';
import '../../../core/theme/hwahae_colors.dart';
import '../../../core/theme/hwahae_typography.dart';
import '../../../core/theme/hwahae_theme.dart';

/// 미션 카드 - 힙한 디자인
class HwahaeMissionCard extends StatelessWidget {
  final String title;
  final String category;
  final String? region;
  final int rewardAmount;
  final int? daysRemaining;
  final bool isUrgent;
  final int currentParticipants;
  final int maxParticipants;
  final VoidCallback? onTap;

  const HwahaeMissionCard({
    super.key,
    required this.title,
    required this.category,
    this.region,
    required this.rewardAmount,
    this.daysRemaining,
    this.isUrgent = false,
    this.currentParticipants = 0,
    this.maxParticipants = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: HwahaeColors.surface,
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
          border: Border.all(
            color: isUrgent
                ? HwahaeColors.accent.withOpacity(0.3)
                : HwahaeColors.border,
            width: isUrgent ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isUrgent
                  ? HwahaeColors.accent.withOpacity(0.08)
                  : HwahaeColors.primary.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 태그
            Row(
              children: [
                _buildGradientTag(category),
                if (region != null && region!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildTag(region!, HwahaeColors.surfaceVariant,
                      HwahaeColors.textSecondary),
                ],
                const Spacer(),
                if (isUrgent) _buildUrgentBadge(),
              ],
            ),
            const SizedBox(height: 14),

            // 제목
            Text(
              title,
              style: HwahaeTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),

            // 하단 정보
            Row(
              children: [
                // 보상금액
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: HwahaeColors.gradientAccent,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_formatCurrency(rewardAmount)}원',
                    style: HwahaeTypography.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),

                // 마감일 & 참여자
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: HwahaeColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (daysRemaining != null) ...[
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: isUrgent
                              ? HwahaeColors.accent
                              : HwahaeColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          daysRemaining! > 0 ? 'D-$daysRemaining' : '오늘 마감',
                          style: HwahaeTypography.captionMedium.copyWith(
                            color: isUrgent
                                ? HwahaeColors.accent
                                : HwahaeColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 1,
                          height: 12,
                          color: HwahaeColors.border,
                        ),
                      ],
                      Icon(
                        Icons.people_alt_rounded,
                        size: 14,
                        color: HwahaeColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$currentParticipants/$maxParticipants',
                        style: HwahaeTypography.captionMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: HwahaeColors.gradientPrimary,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: HwahaeTypography.captionSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: HwahaeTypography.captionSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildUrgentBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: HwahaeColors.gradientWarm,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '마감임박',
            style: HwahaeTypography.badge.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

/// 평점 배지 - 힙한 디자인
class HwahaeRatingBadge extends StatelessWidget {
  final double rating;
  final bool showLabel;
  final bool large;

  const HwahaeRatingBadge({
    super.key,
    required this.rating,
    this.showLabel = true,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 10,
        vertical: large ? 6 : 5,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRatingColor(),
            _getRatingColor().withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _getRatingColor().withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: large ? 18 : 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: (large ? HwahaeTypography.labelLarge : HwahaeTypography.labelSmall).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor() {
    if (rating >= 4.5) return HwahaeColors.secondary;
    if (rating >= 4.0) return HwahaeColors.primary;
    if (rating >= 3.0) return HwahaeColors.warning;
    return HwahaeColors.error;
  }
}

/// 등급 배지 - 힙한 그라디언트 디자인
class HwahaeGradeBadge extends StatelessWidget {
  final String grade;
  final bool showLabel;
  final bool large;

  const HwahaeGradeBadge({
    super.key,
    required this.grade,
    this.showLabel = true,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = HwahaeColors.getGradeGradient(grade);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 10,
        vertical: large ? 6 : 5,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getGradeIcon(),
            size: large ? 16 : 12,
            color: Colors.white,
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              _getGradeLabel(),
              style: (large ? HwahaeTypography.labelMedium : HwahaeTypography.badge).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getGradeIcon() {
    switch (grade.toLowerCase()) {
      case 'diamond':
        return Icons.diamond_rounded;
      case 'platinum':
        return Icons.workspace_premium_rounded;
      case 'gold':
        return Icons.emoji_events_rounded;
      case 'silver':
        return Icons.military_tech_rounded;
      case 'bronze':
        return Icons.stars_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  String _getGradeLabel() {
    switch (grade.toLowerCase()) {
      case 'diamond':
        return '다이아몬드';
      case 'platinum':
        return '플래티넘';
      case 'gold':
        return '골드';
      case 'silver':
        return '실버';
      case 'bronze':
        return '브론즈';
      default:
        return '루키';
    }
  }
}

/// 힙한 정보 카드
class HwahaeInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;

  const HwahaeInfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors ?? HwahaeColors.gradientPrimary,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
          boxShadow: [
            BoxShadow(
              color: (gradientColors?.first ?? HwahaeColors.primary)
                  .withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: HwahaeTypography.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: HwahaeTypography.captionMedium.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// 힙한 통계 카드
class HwahaeStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final String? trend;
  final bool isPositive;

  const HwahaeStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.trend,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? HwahaeColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
        border: Border.all(color: HwahaeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: cardColor,
                ),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? HwahaeColors.successLight
                        : HwahaeColors.errorLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 12,
                        color: isPositive
                            ? HwahaeColors.success
                            : HwahaeColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend!,
                        style: HwahaeTypography.captionSmall.copyWith(
                          color: isPositive
                              ? HwahaeColors.success
                              : HwahaeColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: HwahaeTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: HwahaeTypography.captionMedium,
          ),
        ],
      ),
    );
  }
}
