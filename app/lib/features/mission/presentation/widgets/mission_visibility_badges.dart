import 'package:flutter/material.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';

class HiddenMissionBadge extends StatelessWidget {
  final bool isLocked;
  final String? requiredGrade;

  const HiddenMissionBadge({super.key, this.isLocked = false, this.requiredGrade});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLocked
              ? [Colors.grey.shade400, Colors.grey.shade600]
              : [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLocked ? Icons.lock_rounded : Icons.visibility_off_rounded,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isLocked ? '${requiredGrade ?? ""} 이상' : 'HIDDEN',
            style: HwahaeTypography.captionSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SeasonMissionBadge extends StatelessWidget {
  final Duration? remainingTime;

  const SeasonMissionBadge({super.key, this.remainingTime});

  @override
  Widget build(BuildContext context) {
    String timeText = 'SEASON';
    if (remainingTime != null) {
      if (remainingTime!.inDays > 0) {
        timeText = 'D-${remainingTime!.inDays}';
      } else if (remainingTime!.inHours > 0) {
        timeText = '${remainingTime!.inHours}h';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEA580C), Color(0xFFF97316)],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            timeText,
            style: HwahaeTypography.captionSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class GlowContainer extends StatelessWidget {
  final Widget child;
  final List<Color> glowColors;

  const GlowContainer({
    super.key,
    required this.child,
    this.glowColors = const [Color(0xFFEA580C), Color(0xFFF97316)],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: glowColors[0].withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: glowColors[0].withOpacity(0.3), width: 1.5),
      ),
      child: child,
    );
  }
}
