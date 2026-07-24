import 'package:flutter/material.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import 'evidence_badges.dart';

class ReviewShareCard extends StatelessWidget {
  final String businessName;
  final double score;
  final String? summary;
  final List<String>? pros;
  final List<String>? cons;
  final bool gpsVerified;
  final bool receiptVerified;
  final int? stayDurationMinutes;
  final String? reviewerGrade;

  const ReviewShareCard({
    super.key,
    required this.businessName,
    required this.score,
    this.summary,
    this.pros,
    this.cons,
    this.gpsVerified = false,
    this.receiptVerified = false,
    this.stayDurationMinutes,
    this.reviewerGrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
        border: Border.all(color: HwahaeColors.border),
        boxShadow: HwahaeTheme.shadowMD,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: HwahaeColors.gradientPrimary),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text('암행어흥', style: HwahaeTypography.labelMedium.copyWith(
                color: HwahaeColors.primary, fontWeight: FontWeight.w700,
              )),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: HwahaeColors.gradientWarm),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${score.toStringAsFixed(1)}점',
                  style: HwahaeTypography.labelMedium.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(businessName, style: HwahaeTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          EvidenceBadges(
            gpsVerified: gpsVerified,
            receiptVerified: receiptVerified,
            stayDurationMinutes: stayDurationMinutes,
          ),
          if (summary != null) ...[
            const SizedBox(height: 12),
            Text(summary!, style: HwahaeTypography.bodySmall.copyWith(height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            '암행어흥 인증 리뷰 - 실제 방문 검증 완료',
            style: HwahaeTypography.captionSmall.copyWith(color: HwahaeColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
