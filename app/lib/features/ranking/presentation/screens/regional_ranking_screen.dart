import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../data/models/ranking_model.dart';
import '../../providers/ranking_provider.dart';

class RegionalRankingScreen extends ConsumerStatefulWidget {
  final String? initialRegion;
  final String? initialCategory;

  const RegionalRankingScreen({
    super.key,
    this.initialRegion,
    this.initialCategory,
  });

  @override
  ConsumerState<RegionalRankingScreen> createState() =>
      _RegionalRankingScreenState();
}

class _RegionalRankingScreenState extends ConsumerState<RegionalRankingScreen> {
  late String? selectedRegion;
  late String? selectedCategory;

  @override
  void initState() {
    super.initState();
    selectedRegion = widget.initialRegion;
    selectedCategory = widget.initialCategory;
  }

  String _getHeaderTitle() {
    final region = selectedRegion ?? '전국';
    final category = _getCategoryDisplayName(selectedCategory);
    return '$region $category 신뢰도 TOP 10';
  }

  String _getCategoryDisplayName(String? category) {
    if (category == null) return '전체';
    switch (category) {
      case 'restaurant':
        return '맛집';
      case 'cafe':
        return '카페';
      case 'beauty':
        return '뷰티';
      case 'retail':
        return '소매점';
      case 'service':
        return '서비스';
      default:
        return category;
    }
  }

  void _shareRanking() {
    final region = selectedRegion ?? '전국';
    final category = _getCategoryDisplayName(selectedCategory);
    final title = '$region $category 신뢰도 TOP 10';

    Share.share(
      '암행어흥에서 확인한 $title\n\n신뢰할 수 있는 업체 리뷰를 확인해보세요!\n\n암행어흥 앱에서 더 많은 정보를 확인하세요.',
      subject: title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rankingAsync = ref.watch(regionalRankingProvider({
      'region': selectedRegion,
      'category': selectedCategory,
    }));
    final regionsAsync = ref.watch(availableRegionsProvider);

    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: HwahaeColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '지역별 랭킹',
          style: HwahaeTypography.headlineMedium.copyWith(
            color: HwahaeColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: HwahaeColors.border,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getHeaderTitle(),
                  style: HwahaeTypography.headlineLarge.copyWith(
                    color: HwahaeColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '신뢰할 수 있는 리뷰로 검증된 업체',
                  style: HwahaeTypography.bodySmall.copyWith(
                    color: HwahaeColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Filter Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: HwahaeColors.border,
                  width: 1,
                ),
              ),
            ),
            child: regionsAsync.when(
              data: (regionsMap) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Region Filter
                  Text(
                    '지역',
                    style: HwahaeTypography.captionMedium.copyWith(
                      color: HwahaeColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: '전국',
                        isSelected: selectedRegion == null,
                        onTap: () {
                          setState(() {
                            selectedRegion = null;
                          });
                        },
                      ),
                      ...regionsMap.keys.map((region) => _FilterChip(
                            label: region,
                            isSelected: selectedRegion == region,
                            onTap: () {
                              setState(() {
                                selectedRegion = region;
                              });
                            },
                          )),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category Filter
                  Text(
                    '카테고리',
                    style: HwahaeTypography.captionMedium.copyWith(
                      color: HwahaeColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: '전체',
                        isSelected: selectedCategory == null,
                        onTap: () {
                          setState(() {
                            selectedCategory = null;
                          });
                        },
                      ),
                      _FilterChip(
                        label: '맛집',
                        isSelected: selectedCategory == 'restaurant',
                        onTap: () {
                          setState(() {
                            selectedCategory = 'restaurant';
                          });
                        },
                      ),
                      _FilterChip(
                        label: '카페',
                        isSelected: selectedCategory == 'cafe',
                        onTap: () {
                          setState(() {
                            selectedCategory = 'cafe';
                          });
                        },
                      ),
                      _FilterChip(
                        label: '뷰티',
                        isSelected: selectedCategory == 'beauty',
                        onTap: () {
                          setState(() {
                            selectedCategory = 'beauty';
                          });
                        },
                      ),
                      _FilterChip(
                        label: '소매점',
                        isSelected: selectedCategory == 'retail',
                        onTap: () {
                          setState(() {
                            selectedCategory = 'retail';
                          });
                        },
                      ),
                      _FilterChip(
                        label: '서비스',
                        isSelected: selectedCategory == 'service',
                        onTap: () {
                          setState(() {
                            selectedCategory = 'service';
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: HwahaeColors.primary),
                ),
              ),
              error: (error, stack) => const SizedBox.shrink(),
            ),
          ),

          // Ranking List
          Expanded(
            child: rankingAsync.when(
              data: (rankings) {
                if (rankings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: HwahaeColors.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '랭킹 데이터가 없습니다',
                          style: HwahaeTypography.bodyMedium.copyWith(
                            color: HwahaeColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: rankings.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ranking = rankings[index];
                    return _RankingCard(
                      ranking: ranking,
                      onTap: () {
                        context.push('/trust/${ranking.businessId}');
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: HwahaeColors.primary),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: HwahaeColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '랭킹을 불러올 수 없습니다',
                      style: HwahaeTypography.bodyMedium.copyWith(
                        color: HwahaeColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: HwahaeTypography.captionMedium.copyWith(
                        color: HwahaeColors.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Share Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: HwahaeColors.border,
                  width: 1,
                ),
              ),
            ),
            child: ElevatedButton(
              onPressed: _shareRanking,
              style: ElevatedButton.styleFrom(
                backgroundColor: HwahaeColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.share, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '이 랭킹 공유',
                    style: HwahaeTypography.button.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? HwahaeColors.primary : Colors.white,
          border: Border.all(
            color: isSelected ? HwahaeColors.primary : HwahaeColors.border,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: HwahaeTypography.bodySmall.copyWith(
            color: isSelected ? Colors.white : HwahaeColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  final RegionalRankingModel ranking;
  final VoidCallback onTap;

  const _RankingCard({
    required this.ranking,
    required this.onTap,
  });

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return HwahaeColors.textSecondary;
    }
  }

  String _getBadgeEmoji(String? badgeLevel) {
    if (badgeLevel == null) return '';
    switch (badgeLevel.toLowerCase()) {
      case 'gold':
        return '🥇';
      case 'silver':
        return '🥈';
      case 'bronze':
        return '🥉';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ranking.rank <= 3
                ? _getRankColor(ranking.rank).withValues(alpha: 0.3)
                : HwahaeColors.border,
            width: ranking.rank <= 3 ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getRankColor(ranking.rank).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getRankColor(ranking.rank),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '${ranking.rank}',
                  style: HwahaeTypography.headlineMedium.copyWith(
                    color: _getRankColor(ranking.rank),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Business Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ranking.businessName ?? '이름 없음',
                          style: HwahaeTypography.headlineSmall.copyWith(
                            color: HwahaeColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (ranking.badgeLevel != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          _getBadgeEmoji(ranking.badgeLevel),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Trust Score
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: HwahaeColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: HwahaeColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '신뢰도 ${(ranking.trustScore ?? 0).toStringAsFixed(1)}',
                              style: HwahaeTypography.captionMedium.copyWith(
                                color: HwahaeColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Review Count
                      Icon(
                        Icons.rate_review,
                        size: 14,
                        color: HwahaeColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '리뷰 ${ranking.reviewCount}',
                        style: HwahaeTypography.captionMedium.copyWith(
                          color: HwahaeColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Avg Rating
                      Icon(
                        Icons.star,
                        size: 14,
                        color: HwahaeColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (ranking.avgRating ?? 0).toStringAsFixed(1),
                        style: HwahaeTypography.captionMedium.copyWith(
                          color: HwahaeColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: HwahaeColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
