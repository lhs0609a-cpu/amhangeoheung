import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';

class CompetitionFeedWidget extends StatelessWidget {
  final List<Map<String, dynamic>> missions;

  const CompetitionFeedWidget({super.key, required this.missions});

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
                  color: HwahaeColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_fire_department_rounded, size: 20, color: HwahaeColors.error),
              ),
              const SizedBox(width: 12),
              Text('경쟁사 동향', style: HwahaeTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          ...missions.take(5).map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: HwahaeColors.error, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${m['businesses']?['name'] ?? '경쟁 업체'}가 미션을 등록했어요',
                        style: HwahaeTypography.bodySmall,
                      ),
                      Text(
                        '${m['category'] ?? ''} / ${m['region'] ?? ''}',
                        style: HwahaeTypography.captionSmall.copyWith(color: HwahaeColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/missions/create'),
              style: OutlinedButton.styleFrom(foregroundColor: HwahaeColors.primary),
              child: const Text('우리도 미션 등록하기'),
            ),
          ),
        ],
      ),
    );
  }
}
