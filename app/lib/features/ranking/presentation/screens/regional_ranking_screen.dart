import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';
import '../../data/models/ranking_model.dart';
import '../../providers/ranking_provider.dart';

/// 업종 필터. 예전에는 같은 칩 코드가 다섯 번 복사돼 있어서, 업종을 하나
/// 늘리려면 다섯 번째 복사본을 만들어야 했다.
const _categories = <({String? value, String label})>[
  (value: null, label: '전체'),
  (value: 'restaurant', label: '맛집'),
  (value: 'cafe', label: '카페'),
  (value: 'beauty', label: '뷰티'),
  (value: 'retail', label: '소매점'),
  (value: 'service', label: '서비스'),
];

String _categoryLabel(String? value) =>
    _categories
        .firstWhere(
          (c) => c.value == value,
          orElse: () => (value: value, label: value ?? '전체'),
        )
        .label;

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

  String get _headerTitle {
    final region = selectedRegion ?? '전국';
    return '$region ${_categoryLabel(selectedCategory)} 신뢰도 TOP 10';
  }

  void _shareRanking() {
    Share.share(
      '암행어흥에서 확인한 $_headerTitle\n\n'
      '실제로 다녀온 감찰관이 남긴 리뷰로 매긴 순위입니다.\n'
      '업체가 돈을 내도 이 순위는 바꿀 수 없습니다.',
      subject: _headerTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = {'region': selectedRegion, 'category': selectedCategory};
    final rankingAsync = ref.watch(regionalRankingProvider(filter));
    final regionsAsync = ref.watch(availableRegionsProvider);

    return AppScreen(
      title: '지역별 랭킹',
      bottomBar: AppBottomActionBar(
        child: AppButton.outline(
          label: '이 랭킹 공유',
          icon: Icons.share_outlined,
          onPressed: _shareRanking,
        ),
      ),
      onRefresh: () async {
        ref.invalidate(regionalRankingProvider(filter));
        ref.invalidate(availableRegionsProvider);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            _headerTitle,
            style: HwahaeTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '실제로 다녀온 감찰관의 리뷰로만 매깁니다',
            style: HwahaeTypography.bodySmall.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _FilterGroup(
            label: '지역',
            child: regionsAsync.when(
              data: (regionsMap) => _ChipRow(
                labels: ['전국', ...regionsMap.keys],
                selectedIndex: selectedRegion == null
                    ? 0
                    : regionsMap.keys.toList().indexOf(selectedRegion!) + 1,
                onSelected: (index) => setState(() {
                  selectedRegion =
                      index == 0 ? null : regionsMap.keys.elementAt(index - 1);
                }),
              ),
              loading: () => const _ChipRowSkeleton(),
              // 지역 목록을 못 불러오면 조용히 사라지고 있었다. 필터가
              // 아예 없는 화면과 구분되지 않는다.
              error: (_, __) => Text(
                '지역 목록을 불러오지 못했습니다',
                style: HwahaeTypography.captionMedium.copyWith(
                  color: HwahaeColors.textTertiary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _FilterGroup(
            label: '업종',
            child: _ChipRow(
              labels: [for (final c in _categories) c.label],
              selectedIndex:
                  _categories.indexWhere((c) => c.value == selectedCategory),
              onSelected: (index) => setState(
                () => selectedCategory = _categories[index].value,
              ),
            ),
          ),
          const SizedBox(height: 20),
          rankingAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                child: CircularProgressIndicator(color: HwahaeColors.primary),
              ),
            ),
            error: (error, _) => AppErrorState(
              message: '랭킹을 불러올 수 없습니다',
              onRetry: () => ref.invalidate(regionalRankingProvider(filter)),
            ),
            data: (rankings) {
              if (rankings.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.leaderboard_outlined,
                  title: '아직 순위가 없네',
                  message: '이 조건에 감찰이 끝난 가게가 없어',
                  showMascot: true,
                );
              }
              return Column(
                children: [
                  for (final ranking in rankings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppLayout.cardGap),
                      child: _RankingCard(
                        ranking: ranking,
                        onTap: () =>
                            context.push('/trust/${ranking.businessId}'),
                      ),
                    ),
                ],
              );
            },
          ),
          const AppBottomSpacer.plain(),
        ],
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: HwahaeTypography.labelMedium.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < labels.length; i++)
          AppChip(
            label: labels[i],
            selected: i == selectedIndex,
            onTap: () => onSelected(i),
          ),
      ],
    );
  }
}

class _ChipRowSkeleton extends StatelessWidget {
  const _ChipRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final width in const [52.0, 68.0, 60.0, 74.0])
          Container(
            width: width,
            height: 34,
            decoration: BoxDecoration(
              color: HwahaeColors.surfaceContainer,
              borderRadius: BorderRadius.circular(17),
            ),
          ),
      ],
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({required this.ranking, required this.onTap});

  final RegionalRankingModel ranking;
  final VoidCallback onTap;

  /// 1~3위 색. 예전에는 순금색(#FFD700)을 썼는데 흰 바탕에서 1.4:1 이라
  /// 정작 등수 숫자가 보이지 않았다. 팔레트의 등급색을 쓰고, 숫자는 면을
  /// 채운 뒤 [HwahaeColors.onColor] 로 고른다.
  Color get _rankColor => switch (ranking.rank) {
        1 => HwahaeColors.gradeGold,
        2 => HwahaeColors.gradeSilver,
        3 => HwahaeColors.gradeBronze,
        _ => HwahaeColors.surfaceContainer,
      };

  bool get _isPodium => ranking.rank <= 3;

  @override
  Widget build(BuildContext context) {
    final color = _rankColor;
    final level = ranking.badgeLevel;
    final badge = (level == null || level.isEmpty || level == 'none')
        ? null
        : level;

    return AppCard(
      style: AppCardStyle.outlined,
      onTap: onTap,
      borderColor: _isPodium ? color : null,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '${ranking.rank}',
                style: HwahaeTypography.headlineSmall.copyWith(
                  color: _isPodium
                      ? HwahaeColors.onColor(color)
                      : HwahaeColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        ranking.businessName ?? '이름 없음',
                        style: HwahaeTypography.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 신뢰 배지는 등수와 다른 것이다. 등수는 이 목록 안의
                    // 순서고, 배지는 감찰 이력으로 얻은 등급이라 목록을
                    // 벗어나도 따라다닌다.
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      AppBadge.grade(badge),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppBadge(
                      label: '신뢰도 '
                          '${(ranking.trustScore ?? 0).toStringAsFixed(1)}',
                      color: HwahaeColors.accent,
                      icon: Icons.verified_rounded,
                      compact: true,
                    ),
                    _MetaText(
                      icon: Icons.rate_review_outlined,
                      text: '리뷰 ${ranking.reviewCount}',
                    ),
                    _MetaText(
                      icon: Icons.star_rounded,
                      text: (ranking.avgRating ?? 0).toStringAsFixed(1),
                      color: HwahaeColors.primaryDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: HwahaeColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? HwahaeColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          text,
          style: HwahaeTypography.captionMedium.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
