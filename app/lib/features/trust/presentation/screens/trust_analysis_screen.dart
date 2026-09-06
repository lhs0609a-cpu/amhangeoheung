import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';

/// 신뢰도 분석 데이터 모델
class TrustAnalysisData {
  final String businessName;
  final String badgeLevel;
  final double overallScore;
  final int totalReviews;
  final int verifiedReviews;
  final Map<String, double> categoryScores;
  final List<TrustTrend> monthlyTrend;
  final List<ReviewDistribution> ratingDistribution;
  final List<StrengthItem> strengths;
  final List<WeaknessItem> weaknesses;
  final CompetitorComparison competitorComparison;

  /// 감찰관이 실제로 쓴 지적사항. weaknesses 는 카테고리 점수에서 계산한
  /// 추정치라 개선 여부를 말할 수 없지만, 이쪽은 리뷰를 건너 추적된다.
  final List<InspectionFinding> findings;

  /// 지적 → 약속 → 재감찰
  final List<InspectionStep> timeline;

  TrustAnalysisData({
    required this.businessName,
    required this.badgeLevel,
    required this.overallScore,
    required this.totalReviews,
    required this.verifiedReviews,
    required this.categoryScores,
    required this.monthlyTrend,
    required this.ratingDistribution,
    required this.strengths,
    required this.weaknesses,
    required this.competitorComparison,
    this.findings = const [],
    this.timeline = const [],
  });
}

class TrustTrend {
  final String month;
  final double score;

  TrustTrend({required this.month, required this.score});
}

class ReviewDistribution {
  final int rating;
  final int count;
  final double percentage;

  ReviewDistribution({
    required this.rating,
    required this.count,
    required this.percentage,
  });
}

class StrengthItem {
  final String title;
  final String description;
  final double score;
  final IconData icon;

  StrengthItem({
    required this.title,
    required this.description,
    required this.score,
    required this.icon,
  });
}

class WeaknessItem {
  final String title;
  final String description;
  final String suggestion;
  final double score;

  WeaknessItem({
    required this.title,
    required this.description,
    required this.suggestion,
    required this.score,
  });
}

class CompetitorComparison {
  final double myScore;
  final double categoryAverage;
  final double topPerformer;
  final int rankInCategory;
  final int totalInCategory;

  CompetitorComparison({
    required this.myScore,
    required this.categoryAverage,
    required this.topPerformer,
    required this.rankInCategory,
    required this.totalInCategory,
  });
}

List<InspectionFinding> _parseFindings(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map((f) {
    final count = (f['recurrence_count'] ?? 1) as int;
    return InspectionFinding(
      title: f['title']?.toString() ?? '',
      // 재발한 지적은 "고치겠다고 하고 안 고친" 항목이라 그 사실을 적는다.
      detail: count > 1 ? '$count차례 연속 지적됨' : f['detail']?.toString(),
      fixed: f['status'] == 'fixed',
    );
  }).where((f) => f.title.isNotEmpty).toList();
}

InspectionStepKind _stepKind(String? kind) {
  switch (kind) {
    case 'promise':
      return InspectionStepKind.promise;
    case 'verified':
      return InspectionStepKind.verified;
    default:
      return InspectionStepKind.finding;
  }
}

String _stepLabel(InspectionStepKind kind) {
  switch (kind) {
    case InspectionStepKind.finding:
      return '지적';
    case InspectionStepKind.promise:
      return '개선 약속';
    case InspectionStepKind.verified:
      return '개선 확인';
  }
}

String _shortDate(String? iso) {
  final d = DateTime.tryParse(iso ?? '');
  if (d == null) return '';
  final l = d.toLocal();
  return '${l.year}.${l.month.toString().padLeft(2, '0')}'
      '.${l.day.toString().padLeft(2, '0')}';
}

List<InspectionStep> _parseTimeline(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map((s) {
    final kind = _stepKind(s['kind']?.toString());
    return InspectionStep(
      kind: kind,
      label: _stepLabel(kind),
      date: _shortDate(s['at']?.toString()),
      detail: s['title']?.toString(),
    );
  }).toList();
}

/// 신뢰도 분석 데이터 Provider (API 연동)
final trustAnalysisProvider =
    FutureProvider.family<TrustAnalysisData, String>((ref, businessId) async {
  try {
    final response = await ApiClient.instance.dio.get('/businesses/$businessId/report');
    final data = response.data;

    if (data['success'] == true) {
      final report = data['data'];
      final business = report['business'] ?? {};
      final scores = report['categoryScores'] as Map<String, dynamic>? ?? {};
      final trends = report['monthlyTrend'] as List? ?? [];
      final dist = report['ratingDistribution'] as List? ?? [];
      final pros = report['strengths'] as List? ?? [];
      final cons = report['weaknesses'] as List? ?? [];
      final comp = report['competitorComparison'] as Map<String, dynamic>? ?? {};

      return TrustAnalysisData(
        businessName: business['name'] ?? '업체',
        badgeLevel: business['badge_level'] ?? 'none',
        overallScore: (report['trustScore'] ?? report['overall_score'] ?? 0).toDouble(),
        totalReviews: report['totalReviews'] ?? 0,
        verifiedReviews: report['verifiedReviews'] ?? 0,
        categoryScores: scores.map((k, v) => MapEntry(k, (v as num).toDouble())),
        monthlyTrend: trends.map((t) => TrustTrend(
          month: t['month'] ?? '',
          score: (t['score'] ?? 0).toDouble(),
        )).toList(),
        ratingDistribution: dist.map((d) => ReviewDistribution(
          rating: d['rating'] ?? 0,
          count: d['count'] ?? 0,
          percentage: (d['percentage'] ?? 0).toDouble(),
        )).toList(),
        strengths: pros.map((s) => StrengthItem(
          title: s['title'] ?? '',
          description: s['description'] ?? '',
          score: (s['score'] ?? 0).toDouble(),
          icon: Icons.check_circle_outline,
        )).toList(),
        weaknesses: cons.map((w) => WeaknessItem(
          title: w['title'] ?? '',
          description: w['description'] ?? '',
          suggestion: w['suggestion'] ?? '',
          score: (w['score'] ?? 0).toDouble(),
        )).toList(),
        findings: _parseFindings(report['findings']),
        timeline: _parseTimeline(report['timeline']),
        competitorComparison: CompetitorComparison(
          myScore: (comp['myScore'] ?? 0).toDouble(),
          categoryAverage: (comp['categoryAverage'] ?? 0).toDouble(),
          topPerformer: (comp['topPerformer'] ?? 0).toDouble(),
          rankInCategory: comp['rankInCategory'] ?? 0,
          totalInCategory: comp['totalInCategory'] ?? 0,
        ),
      );
    }
  } catch (_) {}

  // API 실패 시 빈 데이터
  return TrustAnalysisData(
    businessName: '',
    badgeLevel: 'none',
    overallScore: 0,
    totalReviews: 0,
    verifiedReviews: 0,
    categoryScores: {},
    monthlyTrend: [],
    ratingDistribution: [],
    strengths: [],
    weaknesses: [],
    competitorComparison: CompetitorComparison(
      myScore: 0,
      categoryAverage: 0,
      topPerformer: 0,
      rankInCategory: 0,
      totalInCategory: 0,
    ),
  );
});

class TrustAnalysisScreen extends ConsumerWidget {
  final String businessId;

  const TrustAnalysisScreen({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(trustAnalysisProvider(businessId));

    return Scaffold(
      backgroundColor: HwahaeColors.background,
      body: analysisAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: HwahaeColors.primary),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: HwahaeColors.error),
              const SizedBox(height: 16),
              Text('데이터를 불러오는데 실패했습니다', style: HwahaeTypography.bodyMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(trustAnalysisProvider(businessId)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (data) => _buildContent(context, ref, data),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, TrustAnalysisData data) {
    return RefreshIndicator(
      color: HwahaeColors.primary,
      onRefresh: () async {
        ref.invalidate(trustAnalysisProvider(businessId));
      },
      child: CustomScrollView(
        slivers: [
          // 헤더
          _buildHeader(data),

          // 콘텐츠
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 종합 점수 카드
                _buildOverallScoreCard(data),
                const SizedBox(height: 20),

                // 지적사항 — 이 화면의 주인공이라 차트보다 위에 둔다.
                // 별점은 어디에나 있지만 "무엇이 잘못됐는지"는 감찰에서만 나온다.
                _buildFindings(data),

                // 카테고리별 점수
                _buildCategoryScores(data),
                const SizedBox(height: 20),

                // 신뢰도 추이 차트
                _buildTrendChart(data),
                const SizedBox(height: 20),

                // 평점 분포
                _buildRatingDistribution(data),
                const SizedBox(height: 20),

                // 경쟁사 비교
                _buildCompetitorComparison(data),
                const SizedBox(height: 20),

                // 강점
                _buildStrengths(data),
                const SizedBox(height: 20),

                // 개선점
                _buildWeaknesses(data),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(TrustAnalysisData data) {
    final badgeColor = _getBadgeColor(data.badgeLevel);

    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: HwahaeColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: HwahaeColors.gradientCool,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, color: badgeColor, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _getBadgeName(data.badgeLevel),
                              style: HwahaeTypography.labelMedium.copyWith(
                                color: badgeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.businessName,
                    style: HwahaeTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '총 ${data.totalReviews}개 리뷰 중 ${data.verifiedReviews}개 검증됨',
                    style: HwahaeTypography.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      title: Text(
        '신뢰도 분석',
        style: HwahaeTypography.titleMedium.copyWith(color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildOverallScoreCard(TrustAnalysisData data) {
    final scoreColor = data.overallScore >= 90
        ? HwahaeColors.success
        : data.overallScore >= 70
            ? HwahaeColors.warning
            : HwahaeColors.error;

    final scoreGrade = data.overallScore >= 90
        ? 'A+'
        : data.overallScore >= 80
            ? 'A'
            : data.overallScore >= 70
                ? 'B'
                : data.overallScore >= 60
                    ? 'C'
                    : 'D';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor.withValues(alpha: 0.1),
            scoreColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // 점수 게이지
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    value: data.overallScore / 100,
                    strokeWidth: 10,
                    backgroundColor: scoreColor.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      scoreGrade,
                      style: HwahaeTypography.headlineLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      '${data.overallScore.toStringAsFixed(1)}점',
                      style: HwahaeTypography.bodySmall.copyWith(
                        color: HwahaeColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // 설명
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '종합 신뢰도 점수',
                  style: HwahaeTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getScoreDescription(data.overallScore),
                  style: HwahaeTypography.bodyMedium.copyWith(
                    color: HwahaeColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildMiniStat(Icons.reviews, '${data.totalReviews}', '리뷰'),
                    const SizedBox(width: 16),
                    // 리뷰가 0건이면 0/0 = NaN 이고 NaN.toInt() 는 예외를 던진다.
                    // 아직 감찰되지 않은 업체에서 실제로 화면이 죽던 자리다.
                    _buildMiniStat(
                      Icons.verified,
                      data.totalReviews == 0
                          ? '-'
                          : '${(data.verifiedReviews / data.totalReviews * 100).round()}%',
                      '검증률',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 감찰이 끝난 업체에만 인장이 찍힌다. 0건이면 SealBadge 가 스스로
          // 아무것도 그리지 않는다.
          if (data.verifiedReviews > 0) ...[
            const SizedBox(width: 12),
            SealBadge(count: data.verifiedReviews, size: 58),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: HwahaeColors.primary),
        const SizedBox(width: 4),
        Text(
          value,
          style: HwahaeTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: HwahaeTypography.labelSmall.copyWith(color: HwahaeColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCategoryScores(TrustAnalysisData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '카테고리별 평점',
            style: HwahaeTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...data.categoryScores.entries.map((entry) {
            final color = _getCategoryColor(entry.value);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      entry.key,
                      style: HwahaeTypography.bodySmall,
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: HwahaeColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: entry.value / 5,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color, color.withValues(alpha: 0.7)],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 36,
                    child: Text(
                      entry.value.toStringAsFixed(1),
                      style: HwahaeTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTrendChart(TrustAnalysisData data) {
    final spots = data.monthlyTrend.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.score);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                '신뢰도 추이',
                style: HwahaeTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: HwahaeColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, size: 14, color: HwahaeColors.success),
                    const SizedBox(width: 4),
                    Text(
                      '+7.3%',
                      style: HwahaeTypography.labelSmall.copyWith(
                        color: HwahaeColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: HwahaeColors.divider,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < data.monthlyTrend.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              data.monthlyTrend[value.toInt()].month,
                              style: HwahaeTypography.labelSmall.copyWith(
                                color: HwahaeColors.textSecondary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      interval: 10,
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
                borderData: FlBorderData(show: false),
                minY: 70,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: HwahaeColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: HwahaeColors.surface,
                          strokeWidth: 2,
                          strokeColor: HwahaeColors.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          HwahaeColors.primary.withValues(alpha: 0.3),
                          HwahaeColors.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => HwahaeColors.textPrimary,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)}점',
                          HwahaeTypography.labelSmall.copyWith(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution(TrustAnalysisData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '평점 분포',
            style: HwahaeTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...data.ratingDistribution.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Row(
                      children: [
                        Text(
                          '${item.rating}',
                          style: HwahaeTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.star, size: 12, color: HwahaeColors.ratingStar),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: HwahaeColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: item.percentage / 100,
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  HwahaeColors.ratingStar,
                                  HwahaeColors.ratingStar.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${item.count}건 (${item.percentage.toStringAsFixed(1)}%)',
                      style: HwahaeTypography.labelSmall.copyWith(
                        color: HwahaeColors.textSecondary,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCompetitorComparison(TrustAnalysisData data) {
    final comparison = data.competitorComparison;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                '동종업계 비교',
                style: HwahaeTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: HwahaeColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '상위 ${((comparison.rankInCategory / comparison.totalInCategory) * 100).toInt()}%',
                  style: HwahaeTypography.labelSmall.copyWith(
                    color: HwahaeColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildComparisonItem(
                  '내 점수',
                  comparison.myScore,
                  HwahaeColors.primary,
                  true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildComparisonItem(
                  '업계 평균',
                  comparison.categoryAverage,
                  HwahaeColors.textSecondary,
                  false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildComparisonItem(
                  '1위 업체',
                  comparison.topPerformer,
                  HwahaeColors.gradeGold,
                  false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HwahaeColors.infoLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: HwahaeColors.info, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${comparison.totalInCategory}개 업체 중 ${comparison.rankInCategory}위입니다',
                    style: HwahaeTypography.bodySmall.copyWith(
                      color: HwahaeColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(String label, double score, Color color, bool isHighlighted) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withValues(alpha: 0.1) : HwahaeColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted ? Border.all(color: color.withValues(alpha: 0.3)) : null,
      ),
      child: Column(
        children: [
          Text(
            score.toStringAsFixed(1),
            style: HwahaeTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: isHighlighted ? color : HwahaeColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: HwahaeTypography.labelSmall.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengths(TrustAnalysisData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                  color: HwahaeColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.thumb_up, color: HwahaeColors.success, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                '강점',
                style: HwahaeTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...data.strengths.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HwahaeColors.successLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: HwahaeColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, color: HwahaeColors.success, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.title,
                              style: HwahaeTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.star, size: 14, color: HwahaeColors.ratingStar),
                            const SizedBox(width: 2),
                            Text(
                              item.score.toStringAsFixed(1),
                              style: HwahaeTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: HwahaeTypography.bodySmall.copyWith(
                            color: HwahaeColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  /// 지적사항 목록.
  ///
  /// 백엔드가 아직 "개선 확인 여부"를 내려주지 않으므로 전부 미개선으로
  /// 표시한다. 고쳐졌는지 모르는데 고쳤다고 적으면 이 제품의 존재 이유가
  /// 무너지므로, 데이터가 생기기 전까지는 지어내지 않는다.
  Widget _buildFindings(TrustAnalysisData data) {
    // 감찰관이 실제로 쓴 지적이 있으면 그것을 쓴다. 없을 때만 카테고리 점수에서
    // 계산한 추정치(weaknesses)로 대체하며, 그때는 개선 여부를 알 수 없으므로
    // 전부 미개선으로 둔다 — 모르는데 고쳤다고 적으면 제품이 죽는다.
    final List<InspectionFinding> findings = data.findings.isNotEmpty
        ? data.findings
        : data.weaknesses
            .map((w) => InspectionFinding(
                  title: w.title,
                  detail: w.description.isEmpty ? null : w.description,
                ))
            .toList();

    if (findings.isEmpty) return const SizedBox.shrink();

    final int fixed = findings.where((f) => f.fixed).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('지적하고, 고쳤나', style: HwahaeTypography.headlineSmall),
            const SizedBox(width: 10),
            Expanded(
              child: Container(height: 2, color: HwahaeColors.border),
            ),
          ],
        ),
        if (data.findings.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '지적된 ${findings.length}건 중 $fixed건을 고쳤어요',
            style: HwahaeTypography.bodyMedium
                .copyWith(color: HwahaeColors.textSecondary),
          ),
        ],
        const SizedBox(height: 12),
        ...findings.map(
          (f) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: FindingCard(finding: f),
          ),
        ),
        if (data.timeline.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HwahaeColors.surface,
              borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
              border: Border.all(color: HwahaeColors.border, width: 2),
              boxShadow: AppElevation.sticker(3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('감찰 이력', style: HwahaeTypography.overline),
                const SizedBox(height: 13),
                InspectionTimeline(steps: data.timeline),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildWeaknesses(TrustAnalysisData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                  color: HwahaeColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lightbulb_outline, color: HwahaeColors.warning, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                '개선 제안',
                style: HwahaeTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...data.weaknesses.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HwahaeColors.warningLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.title,
                        style: HwahaeTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: HwahaeColors.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.score.toStringAsFixed(1),
                          style: HwahaeTypography.labelSmall.copyWith(
                            color: HwahaeColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: HwahaeTypography.bodySmall.copyWith(
                      color: HwahaeColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: HwahaeColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tips_and_updates, size: 14, color: HwahaeColors.info),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.suggestion,
                            style: HwahaeTypography.labelSmall.copyWith(
                              color: HwahaeColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Color _getBadgeColor(String badge) {
    switch (badge.toLowerCase()) {
      case 'platinum':
        return HwahaeColors.gradePlatinum;
      case 'gold':
        return HwahaeColors.gradeGold;
      case 'silver':
        return HwahaeColors.gradeSilver;
      case 'bronze':
        return HwahaeColors.gradeBronze;
      default:
        return HwahaeColors.textSecondary;
    }
  }

  String _getBadgeName(String badge) {
    switch (badge.toLowerCase()) {
      case 'platinum':
        return '플래티넘';
      case 'gold':
        return '골드';
      case 'silver':
        return '실버';
      case 'bronze':
        return '브론즈';
      default:
        return '일반';
    }
  }

  Color _getCategoryColor(double score) {
    if (score >= 4.5) return HwahaeColors.success;
    if (score >= 4.0) return HwahaeColors.primary;
    if (score >= 3.5) return HwahaeColors.warning;
    return HwahaeColors.error;
  }

  String _getScoreDescription(double score) {
    if (score >= 90) return '업계 최상위 수준의 신뢰도입니다. 지속적인 관리로 유지해주세요!';
    if (score >= 80) return '우수한 신뢰도입니다. 조금만 더 노력하면 최상위권 진입이 가능합니다.';
    if (score >= 70) return '평균 이상의 신뢰도입니다. 개선점을 참고하여 점수를 높여보세요.';
    if (score >= 60) return '개선이 필요한 수준입니다. 아래 제안사항을 확인해주세요.';
    return '즉각적인 개선이 필요합니다. 고객 피드백을 적극 반영해주세요.';
  }
}
