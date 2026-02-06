import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../../../shared/widgets/hwahae/hwahae_cards.dart';

/// 업체 랭킹 모델
class BusinessRanking {
  final String id;
  final int rank;
  final String name;
  final String category;
  final String region;
  final double trustScore;
  final int reviewCount;
  final double avgRating;
  final int rankChange; // 양수: 상승, 음수: 하락, 0: 유지
  final String? imageUrl;

  BusinessRanking({
    required this.id,
    required this.rank,
    required this.name,
    required this.category,
    required this.region,
    required this.trustScore,
    required this.reviewCount,
    required this.avgRating,
    this.rankChange = 0,
    this.imageUrl,
  });
}

/// 리뷰어 랭킹 모델
class ReviewerRanking {
  final String id;
  final int rank;
  final String nickname;
  final String grade;
  final int completedMissions;
  final double avgRating;
  final int helpfulCount;
  final int rankChange;
  final String? profileImage;
  final List<String> specialties;

  ReviewerRanking({
    required this.id,
    required this.rank,
    required this.nickname,
    required this.grade,
    required this.completedMissions,
    required this.avgRating,
    required this.helpfulCount,
    this.rankChange = 0,
    this.profileImage,
    this.specialties = const [],
  });
}

/// 랭킹 데이터 Provider (Mock 데이터)
final businessRankingProvider = FutureProvider<List<BusinessRanking>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 800));
  return List.generate(20, (index) {
    final categories = ['음식점', '카페', '뷰티', '건강', '레저', '교육'];
    final regions = ['강남구', '마포구', '송파구', '서초구', '용산구', '종로구'];
    return BusinessRanking(
      id: 'business_$index',
      rank: index + 1,
      name: '${categories[index % categories.length]} ${index + 1}호점',
      category: categories[index % categories.length],
      region: regions[index % regions.length],
      trustScore: 98.0 - (index * 0.8),
      reviewCount: 150 - (index * 5),
      avgRating: 4.9 - (index * 0.05),
      rankChange: index < 3 ? (3 - index) : (index % 5 == 0 ? -1 : 0),
    );
  });
});

final reviewerRankingProvider = FutureProvider<List<ReviewerRanking>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 800));
  final grades = ['diamond', 'diamond', 'platinum', 'platinum', 'gold', 'gold', 'gold', 'silver', 'silver', 'silver'];
  final specialtiesList = [
    ['음식점', '카페'],
    ['뷰티', '건강'],
    ['음식점'],
    ['레저', '교육'],
    ['카페', '뷰티'],
  ];

  return List.generate(20, (index) {
    return ReviewerRanking(
      id: 'reviewer_$index',
      rank: index + 1,
      nickname: '리뷰마스터${index + 1}',
      grade: grades[index % grades.length],
      completedMissions: 100 - (index * 3),
      avgRating: 4.9 - (index * 0.03),
      helpfulCount: 500 - (index * 20),
      rankChange: index < 3 ? (2 - index) : (index % 4 == 0 ? 1 : index % 3 == 0 ? -1 : 0),
      specialties: specialtiesList[index % specialtiesList.length],
    );
  });
});

class RankingScreen extends ConsumerStatefulWidget {
  final String? initialTab;

  const RankingScreen({super.key, this.initialTab});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '이번 달';

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTab == 'reviewer' ? 1 : 0;
    _tabController = TabController(length: 2, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              pinned: true,
              snap: true,
              backgroundColor: HwahaeColors.surface,
              elevation: 0,
              scrolledUnderElevation: 0,
              expandedHeight: 180,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: HwahaeColors.surface,
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: '업체 랭킹'),
                      Tab(text: '리뷰어 랭킹'),
                    ],
                    labelColor: HwahaeColors.primary,
                    labelStyle: HwahaeTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelColor: HwahaeColors.textSecondary,
                    unselectedLabelStyle: HwahaeTypography.labelMedium,
                    indicatorColor: HwahaeColors.primary,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _BusinessRankingTab(selectedPeriod: _selectedPeriod),
            _ReviewerRankingTab(selectedPeriod: _selectedPeriod),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: HwahaeColors.gradientPrimary,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.leaderboard_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '랭킹',
                    style: HwahaeTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  _buildPeriodSelector(),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '신뢰도 높은 업체와 우수 리뷰어를 확인하세요',
                style: HwahaeTypography.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: PopupMenuButton<String>(
        initialValue: _selectedPeriod,
        onSelected: (value) {
          setState(() {
            _selectedPeriod = value;
          });
        },
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        itemBuilder: (context) => [
          _buildPopupItem('이번 달'),
          _buildPopupItem('이번 주'),
          _buildPopupItem('전체'),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedPeriod,
              style: HwahaeTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (_selectedPeriod == value)
            const Icon(Icons.check, size: 18, color: HwahaeColors.primary)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }
}

/// 업체 랭킹 탭
class _BusinessRankingTab extends ConsumerWidget {
  final String selectedPeriod;

  const _BusinessRankingTab({required this.selectedPeriod});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(businessRankingProvider);

    return rankingAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: HwahaeColors.primary),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: HwahaeColors.error),
            const SizedBox(height: 16),
            Text('랭킹을 불러올 수 없습니다', style: HwahaeTypography.bodyMedium),
          ],
        ),
      ),
      data: (rankings) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(businessRankingProvider);
        },
        color: HwahaeColors.primary,
        child: CustomScrollView(
          slivers: [
            // TOP 3 특별 섹션
            SliverToBoxAdapter(
              child: _buildTop3Section(context, rankings.take(3).toList()),
            ),
            // 나머지 랭킹 리스트
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ranking = rankings[index + 3];
                    return _BusinessRankingCard(ranking: ranking);
                  },
                  childCount: rankings.length - 3,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildTop3Section(BuildContext context, List<BusinessRanking> top3) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: HwahaeColors.gradientWarm),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'TOP 3 업체',
                style: HwahaeTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // 2위
              if (top3.length > 1)
                Expanded(child: _buildTop3Card(context, top3[1], 2)),
              const SizedBox(width: 8),
              // 1위 (중앙, 더 크게)
              Expanded(
                flex: 1,
                child: _buildTop3Card(context, top3[0], 1, isFirst: true),
              ),
              const SizedBox(width: 8),
              // 3위
              if (top3.length > 2)
                Expanded(child: _buildTop3Card(context, top3[2], 3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTop3Card(BuildContext context, BusinessRanking ranking, int position, {bool isFirst = false}) {
    final gradients = {
      1: HwahaeColors.gradientWarm,
      2: [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)],
      3: [const Color(0xFFCD7F32), const Color(0xFFB87333)],
    };

    return GestureDetector(
      onTap: () => context.push('/trust/${ranking.id}'),
      child: Container(
        padding: EdgeInsets.all(isFirst ? 16 : 12),
        decoration: BoxDecoration(
          color: HwahaeColors.surface,
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
          border: Border.all(
            color: gradients[position]![0].withOpacity(0.3),
            width: isFirst ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: gradients[position]![0].withOpacity(0.15),
              blurRadius: isFirst ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 순위 배지
            Container(
              width: isFirst ? 48 : 36,
              height: isFirst ? 48 : 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradients[position]!),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradients[position]![0].withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$position',
                  style: (isFirst ? HwahaeTypography.titleMedium : HwahaeTypography.titleSmall).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(height: isFirst ? 14 : 10),
            // 업체 아이콘
            Container(
              width: isFirst ? 56 : 44,
              height: isFirst ? 56 : 44,
              decoration: BoxDecoration(
                color: HwahaeColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _getCategoryIcon(ranking.category),
                color: HwahaeColors.primary,
                size: isFirst ? 28 : 22,
              ),
            ),
            SizedBox(height: isFirst ? 12 : 8),
            // 업체명
            Text(
              ranking.name,
              style: (isFirst ? HwahaeTypography.titleSmall : HwahaeTypography.labelMedium).copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            // 카테고리
            Text(
              ranking.category,
              style: HwahaeTypography.captionMedium.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
            SizedBox(height: isFirst ? 12 : 8),
            // 신뢰도
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradients[position]!),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '신뢰도 ${ranking.trustScore.toStringAsFixed(0)}%',
                style: HwahaeTypography.captionSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '음식점':
        return Icons.restaurant;
      case '카페':
        return Icons.local_cafe;
      case '뷰티':
        return Icons.face;
      case '건강':
        return Icons.fitness_center;
      case '레저':
        return Icons.sports_tennis;
      case '교육':
        return Icons.school;
      default:
        return Icons.storefront;
    }
  }
}

/// 업체 랭킹 카드
class _BusinessRankingCard extends StatelessWidget {
  final BusinessRanking ranking;

  const _BusinessRankingCard({required this.ranking});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/trust/${ranking.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HwahaeColors.surface,
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          border: Border.all(color: HwahaeColors.border),
        ),
        child: Row(
          children: [
            // 순위
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Text(
                    '${ranking.rank}',
                    style: HwahaeTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: HwahaeColors.primary,
                    ),
                  ),
                  if (ranking.rankChange != 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ranking.rankChange > 0
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          size: 16,
                          color: ranking.rankChange > 0
                              ? HwahaeColors.success
                              : HwahaeColors.error,
                        ),
                        Text(
                          '${ranking.rankChange.abs()}',
                          style: HwahaeTypography.captionSmall.copyWith(
                            color: ranking.rankChange > 0
                                ? HwahaeColors.success
                                : HwahaeColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 업체 아이콘
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: HwahaeColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(ranking.category),
                color: HwahaeColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            // 업체 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ranking.name,
                    style: HwahaeTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${ranking.category} • ${ranking.region}',
                        style: HwahaeTypography.captionMedium,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: HwahaeColors.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '리뷰 ${ranking.reviewCount}',
                          style: HwahaeTypography.captionSmall.copyWith(
                            color: HwahaeColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 신뢰도
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${ranking.trustScore.toStringAsFixed(0)}%',
                  style: HwahaeTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: HwahaeColors.secondary,
                  ),
                ),
                Text(
                  '신뢰도',
                  style: HwahaeTypography.captionSmall.copyWith(
                    color: HwahaeColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '음식점':
        return Icons.restaurant;
      case '카페':
        return Icons.local_cafe;
      case '뷰티':
        return Icons.face;
      case '건강':
        return Icons.fitness_center;
      case '레저':
        return Icons.sports_tennis;
      case '교육':
        return Icons.school;
      default:
        return Icons.storefront;
    }
  }
}

/// 리뷰어 랭킹 탭
class _ReviewerRankingTab extends ConsumerWidget {
  final String selectedPeriod;

  const _ReviewerRankingTab({required this.selectedPeriod});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(reviewerRankingProvider);

    return rankingAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: HwahaeColors.primary),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: HwahaeColors.error),
            const SizedBox(height: 16),
            Text('랭킹을 불러올 수 없습니다', style: HwahaeTypography.bodyMedium),
          ],
        ),
      ),
      data: (rankings) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(reviewerRankingProvider);
        },
        color: HwahaeColors.primary,
        child: CustomScrollView(
          slivers: [
            // TOP 3 특별 섹션
            SliverToBoxAdapter(
              child: _buildTop3Section(context, rankings.take(3).toList()),
            ),
            // 등급 안내 배너
            SliverToBoxAdapter(
              child: _buildGradeBanner(context),
            ),
            // 나머지 랭킹 리스트
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ranking = rankings[index + 3];
                    return _ReviewerRankingCard(ranking: ranking);
                  },
                  childCount: rankings.length - 3,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildTop3Section(BuildContext context, List<ReviewerRanking> top3) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: HwahaeColors.gradientCool),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'TOP 3 리뷰어',
                style: HwahaeTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // 2위
              if (top3.length > 1)
                Expanded(child: _buildTop3ReviewerCard(context, top3[1], 2)),
              const SizedBox(width: 8),
              // 1위 (중앙, 더 크게)
              Expanded(
                flex: 1,
                child: _buildTop3ReviewerCard(context, top3[0], 1, isFirst: true),
              ),
              const SizedBox(width: 8),
              // 3위
              if (top3.length > 2)
                Expanded(child: _buildTop3ReviewerCard(context, top3[2], 3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTop3ReviewerCard(BuildContext context, ReviewerRanking ranking, int position, {bool isFirst = false}) {
    final gradients = {
      1: HwahaeColors.gradientWarm,
      2: [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)],
      3: [const Color(0xFFCD7F32), const Color(0xFFB87333)],
    };
    final gradeColors = HwahaeColors.getGradeGradient(ranking.grade);

    return GestureDetector(
      onTap: () => context.push('/portfolio/${ranking.id}'),
      child: Container(
        padding: EdgeInsets.all(isFirst ? 16 : 12),
        decoration: BoxDecoration(
          color: HwahaeColors.surface,
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
          border: Border.all(
            color: gradeColors[0].withOpacity(0.3),
            width: isFirst ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: gradeColors[0].withOpacity(0.15),
              blurRadius: isFirst ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 순위 배지
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: isFirst ? 64 : 48,
                  height: isFirst ? 64 : 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradeColors),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      ranking.nickname.isNotEmpty ? ranking.nickname[0] : '?',
                      style: (isFirst ? HwahaeTypography.headlineSmall : HwahaeTypography.titleMedium).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: isFirst ? 24 : 20,
                    height: isFirst ? 24 : 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradients[position]!),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '$position',
                        style: HwahaeTypography.captionSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isFirst ? 12 : 8),
            // 닉네임
            Text(
              ranking.nickname,
              style: (isFirst ? HwahaeTypography.titleSmall : HwahaeTypography.labelMedium).copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            // 등급 배지
            HwahaeGradeBadge(grade: ranking.grade, showLabel: true),
            SizedBox(height: isFirst ? 10 : 6),
            // 완료 미션
            Text(
              '미션 ${ranking.completedMissions}회',
              style: HwahaeTypography.captionMedium.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HwahaeColors.primary.withOpacity(0.1),
            HwahaeColors.accent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
        border: Border.all(color: HwahaeColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: HwahaeColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: HwahaeColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '리뷰어 등급 시스템',
                  style: HwahaeTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: HwahaeColors.primary,
                  ),
                ),
                Text(
                  '미션 완료 수와 리뷰 품질에 따라 등급이 결정됩니다',
                  style: HwahaeTypography.captionMedium.copyWith(
                    color: HwahaeColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: HwahaeColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

/// 리뷰어 랭킹 카드
class _ReviewerRankingCard extends StatelessWidget {
  final ReviewerRanking ranking;

  const _ReviewerRankingCard({required this.ranking});

  @override
  Widget build(BuildContext context) {
    final gradeColors = HwahaeColors.getGradeGradient(ranking.grade);

    return GestureDetector(
      onTap: () => context.push('/portfolio/${ranking.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HwahaeColors.surface,
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          border: Border.all(color: HwahaeColors.border),
        ),
        child: Row(
          children: [
            // 순위
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Text(
                    '${ranking.rank}',
                    style: HwahaeTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: HwahaeColors.primary,
                    ),
                  ),
                  if (ranking.rankChange != 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ranking.rankChange > 0
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          size: 16,
                          color: ranking.rankChange > 0
                              ? HwahaeColors.success
                              : HwahaeColors.error,
                        ),
                        Text(
                          '${ranking.rankChange.abs()}',
                          style: HwahaeTypography.captionSmall.copyWith(
                            color: ranking.rankChange > 0
                                ? HwahaeColors.success
                                : HwahaeColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 프로필 아바타
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradeColors),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  ranking.nickname.isNotEmpty ? ranking.nickname[0] : '?',
                  style: HwahaeTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 리뷰어 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ranking.nickname,
                        style: HwahaeTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      HwahaeGradeBadge(grade: ranking.grade, showLabel: false),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '미션 ${ranking.completedMissions}회',
                        style: HwahaeTypography.captionMedium,
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded, size: 12, color: HwahaeColors.warning),
                      Text(
                        ' ${ranking.avgRating.toStringAsFixed(1)}',
                        style: HwahaeTypography.captionMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 도움됨 카운트
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.thumb_up_rounded, size: 14, color: HwahaeColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      '${ranking.helpfulCount}',
                      style: HwahaeTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: HwahaeColors.accent,
                      ),
                    ),
                  ],
                ),
                Text(
                  '도움됨',
                  style: HwahaeTypography.captionSmall.copyWith(
                    color: HwahaeColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
