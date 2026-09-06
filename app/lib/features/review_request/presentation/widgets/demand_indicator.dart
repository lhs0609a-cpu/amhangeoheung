import 'package:flutter/material.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';

class DemandIndicator extends StatelessWidget {
  final int requestCount;
  final VoidCallback? onTap;

  const DemandIndicator({super.key, required this.requestCount, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (requestCount <= 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: HwahaeColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HwahaeColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_rounded, size: 16, color: HwahaeColors.warning),
            const SizedBox(width: 6),
            Text(
              '$requestCount명이 이 가게 리뷰를 원해요',
              style: HwahaeTypography.captionMedium.copyWith(
                color: HwahaeColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
