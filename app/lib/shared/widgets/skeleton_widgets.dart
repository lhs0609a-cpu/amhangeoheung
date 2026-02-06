import 'package:flutter/material.dart';
import '../../core/theme/hwahae_colors.dart';
import '../../core/theme/hwahae_theme.dart';

/// 스켈레톤 로딩 애니메이션을 위한 Shimmer 효과
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? HwahaeColors.surfaceVariant;
    final highlightColor =
        widget.highlightColor ?? HwahaeColors.surface;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                0.0,
                (_animation.value + 2) / 4,
                1.0,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

/// 기본 스켈레톤 박스
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: HwahaeColors.surfaceVariant,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// 원형 스켈레톤 (아바타용)
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: HwahaeColors.surfaceVariant,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// 텍스트 라인 스켈레톤
class SkeletonLine extends StatelessWidget {
  final double? width;
  final double height;

  const SkeletonLine({
    super.key,
    this.width,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: HwahaeColors.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// 미션 카드 스켈레톤
class MissionCardSkeleton extends StatelessWidget {
  const MissionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HwahaeColors.surface,
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          border: Border.all(color: HwahaeColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 태그
            Row(
              children: [
                const SkeletonBox(width: 60, height: 24, borderRadius: 12),
                const SizedBox(width: 8),
                const SkeletonBox(width: 80, height: 24, borderRadius: 12),
                const Spacer(),
                const SkeletonBox(width: 50, height: 20, borderRadius: 4),
              ],
            ),
            const SizedBox(height: 12),
            // 제목
            const SkeletonLine(width: 200, height: 18),
            const SizedBox(height: 8),
            // 서브 텍스트
            const SkeletonLine(width: 120, height: 14),
            const SizedBox(height: 16),
            // 하단 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SkeletonLine(width: 80, height: 14),
                const SkeletonBox(width: 100, height: 32, borderRadius: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 리뷰 카드 스켈레톤
class ReviewCardSkeleton extends StatelessWidget {
  const ReviewCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HwahaeColors.surface,
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          border: Border.all(color: HwahaeColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                const SkeletonCircle(size: 36),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonLine(width: 80, height: 14),
                    SizedBox(height: 4),
                    SkeletonLine(width: 60, height: 12),
                  ],
                ),
                const Spacer(),
                const SkeletonBox(width: 40, height: 24, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 12),
            // 리뷰 내용 라인들
            const SkeletonLine(height: 14),
            const SizedBox(height: 6),
            const SkeletonLine(height: 14),
            const SizedBox(height: 6),
            const SkeletonLine(width: 200, height: 14),
            const SizedBox(height: 6),
            const SkeletonLine(width: 150, height: 14),
            const SizedBox(height: 6),
            const SkeletonLine(width: 180, height: 14),
            const Spacer(),
            // 하단 정보
            Row(
              children: const [
                SkeletonBox(width: 50, height: 20, borderRadius: 4),
                SizedBox(width: 12),
                SkeletonBox(width: 60, height: 20, borderRadius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 업체 카드 스켈레톤
class BusinessCardSkeleton extends StatelessWidget {
  const BusinessCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: HwahaeColors.surface,
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          border: Border.all(color: HwahaeColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SkeletonCircle(size: 28),
            SizedBox(height: 8),
            SkeletonBox(width: 48, height: 48, borderRadius: 12),
            SizedBox(height: 8),
            SkeletonLine(width: 60, height: 14),
            SizedBox(height: 4),
            SkeletonLine(width: 50, height: 12),
          ],
        ),
      ),
    );
  }
}

/// 리뷰어 스켈레톤
class ReviewerChipSkeleton extends StatelessWidget {
  const ReviewerChipSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Column(
        children: const [
          SkeletonCircle(size: 64),
          SizedBox(height: 8),
          SkeletonLine(width: 50, height: 12),
          SizedBox(height: 4),
          SkeletonBox(width: 40, height: 16, borderRadius: 8),
        ],
      ),
    );
  }
}

/// 프로필 헤더 스켈레톤
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SkeletonCircle(size: 80),
            const SizedBox(height: 16),
            const SkeletonLine(width: 100, height: 20),
            const SizedBox(height: 8),
            const SkeletonLine(width: 150, height: 14),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                3,
                (index) => Column(
                  children: const [
                    SkeletonLine(width: 40, height: 24),
                    SizedBox(height: 4),
                    SkeletonLine(width: 50, height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 리스트 아이템 스켈레톤
class ListItemSkeleton extends StatelessWidget {
  final bool hasLeading;
  final bool hasTrailing;

  const ListItemSkeleton({
    super.key,
    this.hasLeading = true,
    this.hasTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (hasLeading) ...[
              const SkeletonCircle(size: 48),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonLine(height: 16),
                  SizedBox(height: 6),
                  SkeletonLine(width: 150, height: 14),
                ],
              ),
            ),
            if (hasTrailing) ...[
              const SizedBox(width: 12),
              const SkeletonBox(width: 60, height: 32, borderRadius: 16),
            ],
          ],
        ),
      ),
    );
  }
}

/// 스켈레톤 리스트 빌더
class SkeletonListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsets? padding;
  final double? itemSpacing;

  const SkeletonListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.itemSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: itemSpacing ?? 12),
      itemBuilder: itemBuilder,
    );
  }
}
