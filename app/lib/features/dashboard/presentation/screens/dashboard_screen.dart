import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
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

/// 대시보드 데이터 Provider — 실제 API 호출
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  try {
    final api = ApiClient();

    // 사용자의 비즈니스 목록 조회 후 첫 번째 비즈니스 대시보드 로드
    final myBusinessesRes = await api.get('/businesses/my/list');
    final businesses = myBusinessesRes.data['data']?['businesses'] as List?;

    if (businesses == null || businesses.isEmpty) {
      return _emptyDashboardStats();
    }

    final businessId = businesses.first['id'];
    final dashboardRes = await api.get('/businesses/$businessId/dashboard');
    final data = dashboardRes.data['data'];

    if (data == null) {
      return _emptyDashboardStats();
    }

    final stats = data['stats'] ?? {};
    final trend = data['trend']?['monthly'] as List? ?? [];
    final recentReviewsData = data['recentReviews'] as List? ?? [];
    final roi = data['roi'] ?? {};

    // 미션 현황 집계
    final missionsByStatus = <String, int>{};
    final completedMissions = stats['completedMissions'] ?? 0;
    final pendingMissions = stats['pendingMissions'] ?? 0;
    final totalMissions = completedMissions + pendingMissions;
    missionsByStatus['완료'] = completedMissions;
    missionsByStatus['진행중'] = pendingMissions;

    return DashboardStats(
      totalMissions: totalMissions,
      completedMissions: completedMissions,
      activeMissions: pendingMissions,
      pendingReviews: stats['pendingReviews'] ?? 0,
      publishedReviews: stats['totalReviews'] ?? 0,
      averageRating: (stats['averageRating'] ?? 0).toDouble(),
      trustScore: (data['badge']?['progress']?['ratingProgress'] ?? 0).toDouble(),
      totalSpent: (roi['subscriptionCost'] ?? 0).toInt(),
      missionsByStatus: missionsByStatus,
      monthlyTrend: trend.map<MonthlyData>((m) => MonthlyData(
        month: m['month'] ?? '',
        missions: 0,
        reviews: m['reviewCount'] ?? 0,
        avgRating: (m['averageRating'] ?? 0).toDouble(),
      )).toList(),
      recentReviews: recentReviewsData.map<RecentReview>((r) => RecentReview(
        id: r['id'] ?? '',
        reviewerNickname: r['reviewerNickname'] ?? '리뷰어',
        reviewerGrade: r['reviewerGrade'] ?? 'rookie',
        rating: (r['score'] ?? 0).toDouble(),
        summary: r['summary'] ?? '',
        status: r['status'] ?? 'published',
        createdAt: DateTime.tryParse(r['date'] ?? '') ?? DateTime.now(),
      )).toList(),
    );
  } catch (e) {
    debugPrint('[DashboardStats] Error loading dashboard: $e');
    throw Exception('대시보드 데이터를 불러오는데 실패했습니다: $e');
  }
});

DashboardStats _emptyDashboardStats() {
  return DashboardStats(
    totalMissions: 0,
    completedMissions: 0,
    activeMissions: 0,
    pendingReviews: 0,
    publishedReviews: 0,
    averageRating: 0.0,
    trustScore: 0.0,
    totalSpent: 0,
    missionsByStatus: {'완료': 0, '진행중': 0},
    monthlyTrend: [],
    recentReviews: [],
  );
}

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
                  onPressed: () => context.push('/notifications'),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () => context.push('/settings'),
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
                    // 최상단: 신뢰도 점수 대형 카드 (토스 "내 신용점수" 스타일)
                    _buildTrustScoreCard(stats),
                    const SizedBox(height: 16),

                    // 선공개 리뷰 긴급 카드 (대응 필요 리뷰)
                    if (stats.pendingReviews > 0)
                      _buildUrgentReviewCard(stats),
                    if (stats.pendingReviews > 0)
                      const SizedBox(height: 16),

                    // 핵심 KPI 3개 가로 스크롤
                    _buildKpiHorizontalScroll(stats),
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

                    // 빠른 액션 (배지 추가)
                    _buildQuickActions(),
                    const SizedBox(height: 120),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 선공개 리뷰 긴급 카드 (배민 사장님앱 참고)
  Widget _buildUrgentReviewCard(DashboardStats stats) {
    return InkWell(
      onTap: () => context.push('/preview-reviews'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HwahaeColors.warning.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: HwahaeColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.rate_review_rounded, color: HwahaeColors.warning, size: 26),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: HwahaeColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${stats.pendingReviews}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '대응 필요 리뷰 ${stats.pendingReviews}건',
                    style: HwahaeTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: HwahaeColors.warning,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '72시간 내 미응답 시 자동 공개됩니다',
                    style: HwahaeTypography.captionLarge.copyWith(
                      color: HwahaeColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: HwahaeColors.warning),
          ],
        ),
      ),
    );
  }

  /// 핵심 KPI 3개 가로 스크롤
  Widget _buildKpiHorizontalScroll(DashboardStats stats) {
    final kpis = [
      _KpiData(
        title: '평균 평점',
        value: stats.averageRating.toStringAsFixed(1),
        subtitle: '리뷰 ${stats.publishedReviews}건',
        icon: Icons.star_rounded,
        color: HwahaeColors.warning,
        change: '+0.2',
        isPositive: true,
      ),
      _KpiData(
        title: '완료 미션',
        value: '${stats.completedMissions}',
        subtitle: '전체 ${stats.totalMissions}건',
        icon: Icons.flag_rounded,
        color: HwahaeColors.success,
        change: '+${stats.completedMissions}',
        isPositive: true,
      ),
      _KpiData(
        title: '총 지출',
        value: _formatCurrency(stats.totalSpent),
        subtitle: '이번 달',
        icon: Icons.account_balance_wallet_rounded,
        color: HwahaeColors.info,
        change: null,
        isPositive: true,
      ),
    ];

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kpis.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final kpi = kpis[index];
          return Container(
            width: 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HwahaeColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HwahaeColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(kpi.icon, color: kpi.color, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        kpi.title,
                        style: HwahaeTypography.captionLarge.copyWith(
                          color: HwahaeColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  kpi.value,
                  style: HwahaeTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      kpi.subtitle,
                      style: HwahaeTypography.captionMedium.copyWith(
                        color: HwahaeColors.textTertiary,
                      ),
                    ),
                    if (kpi.change != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        kpi.change!,
                        style: HwahaeTypography.captionMedium.copyWith(
                          color: kpi.isPositive ? HwahaeColors.success : HwahaeColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
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
                onPressed: () => context.push('/preview-reviews'),
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
                onTap: () => context.push('/missions'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.rate_review_outlined,
                label: '리뷰 관리',
                color: HwahaeColors.secondary,
                onTap: () => context.push('/preview-reviews'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.analytics_outlined,
                label: '분석 보기',
                color: HwahaeColors.info,
                onTap: () => context.push('/pricing'),
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

/// KPI 데이터 모델
class _KpiData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? change;
  final bool isPositive;

  _KpiData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.change,
    this.isPositive = true,
  });
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
