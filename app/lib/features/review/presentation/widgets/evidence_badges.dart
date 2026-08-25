import 'package:flutter/material.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';

class EvidenceBadges extends StatelessWidget {
  final bool gpsVerified;
  final bool receiptVerified;
  final int? stayDurationMinutes;

  const EvidenceBadges({
    super.key,
    this.gpsVerified = false,
    this.receiptVerified = false,
    this.stayDurationMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        if (gpsVerified) _buildBadge(Icons.location_on_rounded, 'GPS 인증', HwahaeColors.primary),
        if (receiptVerified) _buildBadge(Icons.receipt_long_rounded, '영수증 인증', HwahaeColors.success),
        if (stayDurationMinutes != null && stayDurationMinutes! > 0)
          _buildBadge(Icons.timer_rounded, '$stayDurationMinutes분 체류', HwahaeColors.warning),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: HwahaeTypography.captionSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
