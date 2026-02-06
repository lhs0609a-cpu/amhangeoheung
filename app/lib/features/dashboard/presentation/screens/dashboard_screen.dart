import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';

/// 대시보드 통계 모델
class DashboardStats {
  final int totalMissions;
  final int completedMissions;
  final int activeMissions;
  final int pendingReviews;
  final int publishedReviews;
  final double averageRating;
  final double trustScore;
  final int totalSpent;
  final Map<String, int> missionsByStatus;
  final List<MonthlyData> monthlyTrend;
  final List<RecentReview> recentReviews;

  DashboardStats({
    required this.totalMissions,
    required this.completedMissions,
    required this.activeMissions,
    required this.pendingReviews,
    required this.publishedReviews,
    required this.averageRating,
    required this.trustScore,
    required this.totalSpent,
    required this.missionsByStatus,
    required this.monthlyTrend,
    required this.recentReviews,
  });
}

class MonthlyData {
  final String month;
  final int missions;
  final int reviews;
  final double avgRating;

  MonthlyData({
    required this.month,
    required this.missions,
    required this.reviews,
    required this.avgRating,
  });
}

class RecentReview {
  final String id;
  final String reviewerNickname;
  final String reviewerGrade;
  final double rating;
  final String summary;
  final String status;
  final DateTime createdAt;

  RecentReview({
    required this.id,
    required this.reviewerNickname,
    required this.reviewerGrade,
    required this.rating,
    required this.summary,
    required this.status,
    required this.createdAt,
  });
}

/// 대시보드 데이터 Provider (Mock 데이터)
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  await Future.delayed(const Duration(milliseconds: 800));

  return DashboardStats(
    totalMissions: 48,
    completedMissions: 35,
    activeMissions: 8,
    pendingReviews: 5,
    publishedReviews: 32,
    averageRating: 4.6,
    trustScore: 92.5,
    totalSpent: 2850000,
    missionsByStatus: {
      '완료': 35,
      '진행중': 8,
      '모집중': 3,
      '대기': 2,
    },
    monthlyTrend: [
      MonthlyData(month: '9월', missions: 5, reviews: 4, avgRating: 4.3),
      MonthlyData(month: '10월', missions: 7, reviews: 6, avgRating: 4.5),
      MonthlyData(month: '11월', missions: 8, reviews: 7, avgRating: 4.4),
      MonthlyData(month: '12월', missions: 10, reviews: 9, avgRating: 4.7),
      MonthlyData(month: '1월', missions: 12, reviews: 10, avgRating: 4.6),
      MonthlyData(month: '2월', missions: 6, reviews: 4, avgRating: 4.8),
    ],
    recentReviews: [
      RecentReview(
        id: '1',
        reviewerNickname: '리뷰마스터',
        reviewerGrade: 'gold',
        rating: 4.8,
        summary: '전반적으로 만족스러운 서비스였습니다. 특히 직원분들이 친절하셨어요.',
        status: 'published',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      RecentReview(
        id: '2',
        reviewerNickname: '솔직한리뷰어',
        reviewerGrade: 'silver',
        rating: 4.2,
        summary: '음식 맛은 좋았지만 대기 시간이 조금 길었습니다.',
        status: 'preview',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      RecentReview(
        id: '3',
        reviewerNickname: '꼼꼼체크',
        reviewerGrade: 'platinum',
        rating: 4.9,
        summary: '청결도와 서비스 모두 훌륭했습니다. 재방문 의사 있습니다.',
        status: 'published',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
  );
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: HwahaeColors.background,
      body: RefreshIndicator(
        color: HwahaeColors.primary,
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: HwahaeColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: HwahaeColors.gradientPrimary,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '안녕하세요!',
                            style: HwahaeTypography.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '오늘의 비즈니스 현황입니다',
                            style: HwahaeTypography.headlineSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              title: Text(
                '대시보드',
                style: HwahaeTypography.titleMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),

            // Content
            statsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: HwahaeColors.primary),
                ),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: HwahaeColors.error),
                      const SizedBox(height: 16),
                      Text('데이터를 불러오는데 실패했습니다', style: HwahaeTypography.bodyMedium),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(dashboardStatsProvider),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (stats) => SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 요약 카드
                    _buildSummaryCards(stats),
                    const SizedBox(height: 24),

                    // 신뢰도 점수 카드
                    _buildTrustScoreCard(stats),
                    const SizedBox(height: 24),

                    // 미션 현황 파이 차트
                    _buildMissionStatusChart(stats),
                    const SizedBox(height: 24),

                    // 월별 트렌드 차트
                    _buildMonthlyTrendChart(stats),
                    const SizedBox(height: 24),

                    // 최근 리뷰
                    _buildRecentReviews(stats),
                    const SizedBox(height: 24),

                    // 빠른 액션
                    _buildQuickActions(),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(DashboardStats stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: '전체 미션',
                value: '${stats.totalMissions}',
                subtitle: '완료 ${stats.completedMissions}건',
                icon: Icons.assignment_outlined,
                color: HwahaeColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: '진행중 미션',
                value: '${stats.activeMissions}',
                subtitle: '모집중 ${stats.missionsByStatus['모집중'] ?? 0}건',
                icon: Icons.pending_actions_outlined,
                color: HwahaeColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: '평균 평점',
                value: stats.averageRating.toStringAsFixed(1),
                subtitle: '리뷰 ${stats.publishedReviews}건',
                icon: Icons.star_outline,
                color: HwahaeColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: '총 지출',
                value: _formatCurrency(stats.totalSpent),
                subtitle: '이번 달',
                icon: Icons.account_balance_wallet_outlined,
                color: HwahaeColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrustScoreCard(DashboardStats stats) {
    final scoreColor = stats.trustScore >= 90
        ? HwahaeColors.success
        : stats.trustScore >= 70
            ? HwahaeColors.warning
            : HwahaeColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor.withOpacity(0.1),
            scoreColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // 점수 표시
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: stats.trustScore / 100,
                    strokeWidth: 8,
                    backgroundColor: scoreColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stats.trustScore.toStringAsFixed(1),
                      style: HwahaeTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      '점',
                      style: HwahaeTypography.bodySmall.copyWith(
                        color: HwahaeColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // 설명
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified, color: scoreColor, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '신뢰도 점수',
                      style: HwahaeTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  stats.trustScore >= 90
                      ? '훌륭합니다! 높은 신뢰도를 유지하고 있어요.'
                      : stats.trustScore >= 70
                          ? '좋은 점수입니다. 조금만 더 노력해보세요!'
                          : '신뢰도 개선이 필요합니다.',
                  style: HwahaeTypography.bodyMedium.copyWith(
                    color: HwahaeColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildScoreIndicator('리뷰 품질', 95, HwahaeColors.success),
                    const SizedBox(width: 16),
                    _buildScoreIndicator('응답률', 88, HwahaeColors.info),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreIndicator(String label, int score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: HwahaeTypography.labelSmall.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: color.withOpacity(0.2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: score / 100,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$score%',
              style: HwahaeTypography.labelSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMissionStatusChart(DashboardStats stats) {
    final colors = [
      HwahaeColors.success,
      HwahaeColors.primary,
      HwahaeColors.info,
      HwahaeColors.warning,
    ];

    final entries = stats.missionsByStatus.entries.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '미션 현황',
            style: HwahaeTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // 파이 차트
              SizedBox(
                width: 120,
                height: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: entries.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return PieChartSectionData(
                        value: item.value.toDouble(),
                        color: colors[index % colors.length],
                        radius: 25,
                        showTitle: false,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // 범례
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final total = stats.missionsByStatus.values.fold(0, (a, b) => a + b);
                    final percentage = (item.value / total * 100).toStringAsFixed(0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colors[index % colors.length],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.key,
                              style: HwahaeTypography.bodySmall,
                            ),
                          ),
                          Text(
                            '${item.value}건',
                            style: HwahaeTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$percentage%',
                            style: HwahaeTypography.labelSmall.copyWith(
                              color: HwahaeColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendChart(DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '월별 추이',
                style: HwahaeTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  _buildChartLegend('미션', HwahaeColors.primary),
                  const SizedBox(width: 16),
                  _buildChartLegend('리뷰', HwahaeColors.secondary),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 15,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => HwahaeColors.textPrimary,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final data = stats.monthlyTrend[groupIndex];
                      final label = rodIndex == 0 ? '미션' : '리뷰';
                      final value = rodIndex == 0 ? data.missions : data.reviews;
                      return BarTooltipItem(
                        '$label: $value건',
                        HwahaeTypography.labelSmall.copyWith(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < stats.monthlyTrend.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              stats.monthlyTrend[value.toInt()].month,
                              style: HwahaeTypography.labelSmall.copyWith(
                                color: HwahaeColors.textSecondary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: HwahaeTypography.labelSmall.copyWith(
                            color: HwahaeColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: HwahaeColors.divider,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: stats.monthlyTrend.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data.missions.toDouble(),
                        color: HwahaeColors.primary,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: data.reviews.toDouble(),
                        color: HwahaeColors.secondary,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: HwahaeTypography.labelSmall.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentReviews(DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '최근 리뷰',
                style: HwahaeTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  '전체보기',
                  style: HwahaeTypography.labelMedium.copyWith(
                    color: HwahaeColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...stats.recentReviews.map((review) => _buildReviewItem(review)),
        ],
      ),
    );
  }

  Widget _buildReviewItem(RecentReview review) {
    final gradeColor = _getGradeColor(review.reviewerGrade);
    final statusColor = review.status == 'published'
        ? HwahaeColors.success
        : HwahaeColors.warning;
    final statusText = review.status == 'published' ? '공개' : '선공개';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 아바타
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gradeColor, gradeColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                review.reviewerNickname[0],
                style: HwahaeTypography.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 리뷰 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      review.reviewerNickname,
                      style: HwahaeTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: gradeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getGradeName(review.reviewerGrade),
                        style: HwahaeTypography.labelSmall.copyWith(
                          color: gradeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusText,
                        style: HwahaeTypography.labelSmall.copyWith(
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: HwahaeColors.ratingStar, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: HwahaeTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimeAgo(review.createdAt),
                      style: HwahaeTypography.labelSmall.copyWith(
                        color: HwahaeColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  review.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: HwahaeTypography.bodySmall.copyWith(
                    color: HwahaeColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '빠른 액션',
          style: HwahaeTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.add_circle_outline,
                label: '미션 등록',
                color: HwahaeColors.primary,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.rate_review_outlined,
                label: '리뷰 관리',
                color: HwahaeColors.secondary,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.analytics_outlined,
                label: '분석 보기',
                color: HwahaeColors.info,
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade.toLowerCase()) {
      case 'diamond':
        return HwahaeColors.gradeDiamond;
      case 'platinum':
        return HwahaeColors.gradePlatinum;
      case 'gold':
        return HwahaeColors.gradeGold;
      case 'silver':
        return HwahaeColors.gradeSilver;
      default:
        return HwahaeColors.gradeRookie;
    }
  }

  String _getGradeName(String grade) {
    switch (grade.toLowerCase()) {
      case 'diamond':
        return '다이아';
      case 'platinum':
        return '플래티넘';
      case 'gold':
        return '골드';
      case 'silver':
        return '실버';
      default:
        return '루키';
    }
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 10000).toStringAsFixed(0)}만';
    } else if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(1)}만';
    }
    return NumberFormat('#,###').format(amount);
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    }
    return DateFormat('M/d').format(dateTime);
  }
}

/// 요약 카드 위젯
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Icon(
                Icons.trending_up,
                color: HwahaeColors.success,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: HwahaeTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: HwahaeTypography.bodySmall.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: HwahaeTypography.labelSmall.copyWith(
              color: HwahaeColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 빠른 액션 버튼 위젯
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: HwahaeTypography.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
