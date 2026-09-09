import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../review/data/models/review_model.dart';

class PublicInspectionReport {
  const PublicInspectionReport(
      {required this.summary,
      this.reviews = const [],
      this.reviewsUnavailable = false});
  final Map<String, dynamic> summary;
  final List<ReviewModel> reviews;
  final bool reviewsUnavailable;
}

final trustAnalysisProvider =
    FutureProvider.family<PublicInspectionReport, String>(
        (ref, businessId) async {
  final encodedId = Uri.encodeComponent(businessId);
  // 소비자가 여는 화면은 업체 전용 /report가 아닌 공개 API를 사용한다.
  final response =
      await ApiClient.instance.dio.get('/businesses/$encodedId/trust-analysis');
  final body = response.data;
  if (body is! Map || body['success'] != true || body['data'] is! Map) {
    throw const FormatException('Invalid public inspection report');
  }
  final summary = Map<String, dynamic>.from(body['data'] as Map);
  try {
    final reviewResponse = await ApiClient.instance.dio
        .get('/businesses/$encodedId/reviews', queryParameters: {'limit': 10});
    final reviewBody = reviewResponse.data;
    if (reviewBody is! Map ||
        reviewBody['success'] != true ||
        reviewBody['data']?['reviews'] is! List) {
      throw const FormatException('Invalid published reviews');
    }
    return PublicInspectionReport(
        summary: summary,
        reviews: (reviewBody['data']['reviews'] as List)
            .whereType<Map>()
            .map((item) => ReviewModel.fromJson({
                  ...Map<String, dynamic>.from(item),
                  'business': item['business'] ??
                      {
                        'id': businessId,
                        'name': summary['businessName'],
                        'category': summary['category'],
                      },
                }))
            .toList());
  } catch (_) {
    return PublicInspectionReport(summary: summary, reviewsUnavailable: true);
  }
});

class TrustAnalysisScreen extends ConsumerWidget {
  const TrustAnalysisScreen({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(trustAnalysisProvider(businessId));
    return AppScreen(
        title: '감찰 리포트',
        scrollable: false,
        child: report.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => SingleChildScrollView(
              child: AppErrorState.fromMessage('감찰 리포트를 불러오지 못했어요.',
                  onRetry: () =>
                      ref.invalidate(trustAnalysisProvider(businessId)))),
          data: (data) => AppLayout.constrain(RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(trustAnalysisProvider(businessId));
              await ref.read(trustAnalysisProvider(businessId).future);
            },
            child: _content(context, ref, data),
          )),
        ));
  }

  Widget _content(
      BuildContext context, WidgetRef ref, PublicInspectionReport report) {
    final data = report.summary;
    final findings =
        (data['findings'] as List? ?? []).whereType<Map>().toList();
    final timeline =
        (data['timeline'] as List? ?? []).whereType<Map>().toList();
    final count = data['totalReviews'] as num?;
    final average = data['averageScore'] as num?;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(AppLayout.gutterOf(context)),
      children: [
        Text(data['category'] as String? ?? '업종 미제공',
            style: HwahaeTypography.bodySmall),
        const SizedBox(height: 8),
        Text(data['businessName'] as String? ?? '업체명 미제공',
            style: HwahaeTypography.headlineLarge),
        const SizedBox(height: 10),
        Text('감찰 기록과 업체의 답변을 함께 살펴보세요.', style: HwahaeTypography.bodyMedium),
        const SizedBox(height: 24),
        _section('지적사항과 개선 기록', '개선 약속과 확인 결과를 구분해서 읽어주세요.'),
        const SizedBox(height: 12),
        if (data['findingsAvailable'] != true)
          AppCard(
              style: AppCardStyle.outlined,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('지적사항 기록을 확인할 수 없어요.',
                        style: HwahaeTypography.bodyMedium),
                    const SizedBox(height: 8),
                    Text('기록이 없다는 뜻은 아니에요. 잠시 후 다시 확인해 주세요.',
                        style: HwahaeTypography.bodySmall),
                    TextButton(
                        onPressed: () =>
                            ref.invalidate(trustAnalysisProvider(businessId)),
                        child: const Text('다시 시도')),
                  ]))
        else if (findings.isEmpty)
          AppCard(
              style: AppCardStyle.outlined,
              child: Text('등록된 지적사항이 없어요.\n문제가 없음을 보증하는 표시는 아닙니다.',
                  style: HwahaeTypography.bodyMedium))
        else
          ...findings.map((finding) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _finding(finding))),
        if (timeline.isNotEmpty) ...[
          const SizedBox(height: 12),
          _section('변화의 기록', '감찰에서 남긴 기록을 시간순으로 보여드려요.'),
          const SizedBox(height: 12),
          AppCard(
              style: AppCardStyle.outlined,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: timeline
                      .map((step) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                              '${_date(step['at'])} · ${switch (step['kind']) {
                                'promise' => '업체 약속',
                                'verified' => '개선 처리 기록',
                                _ => '지적 기록',
                              }}\n${step['title'] ?? ''}',
                              style: HwahaeTypography.bodySmall)))
                      .toList())),
        ],
        const SizedBox(height: 28),
        _section('공개 리뷰의 평가', '평균 점수는 방문 자료의 신뢰도를 뜻하지 않아요.'),
        const SizedBox(height: 12),
        AppCard(
            style: AppCardStyle.outlined,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  count != null && count > 0 && average != null
                      ? '${average.toStringAsFixed(1)} / 5'
                      : '평가 정보 없음',
                  style: HwahaeTypography.headlineLarge),
              const SizedBox(height: 6),
              Text(count == null ? '공개 리뷰 수 미제공' : '공개 리뷰 ${count.toInt()}개 기준',
                  style: HwahaeTypography.bodySmall),
            ])),
        const SizedBox(height: 28),
        _section('최근 공개 리뷰', '좋았던 점과 아쉬운 점, 답변은 원문에서 확인하세요.'),
        const SizedBox(height: 12),
        if (report.reviewsUnavailable)
          AppCard(
              style: AppCardStyle.outlined,
              child: Column(children: [
                Text('리뷰 원문 목록을 불러오지 못했어요.',
                    style: HwahaeTypography.bodyMedium),
                TextButton(
                    onPressed: () =>
                        ref.invalidate(trustAnalysisProvider(businessId)),
                    child: const Text('다시 시도')),
              ]))
        else if (report.reviews.isEmpty)
          AppCard(
              style: AppCardStyle.outlined,
              child:
                  Text('아직 공개된 리뷰가 없어요.', style: HwahaeTypography.bodyMedium))
        else
          ...report.reviews.map((review) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DiscoveryReviewCard(
                  review: review,
                  onTap: () => context
                      .push('/reviews/${Uri.encodeComponent(review.id)}')))),
        if (report.reviews.length >= 10)
          Text('최근 공개 리뷰 최대 10개를 표시합니다.',
              style: HwahaeTypography.captionMedium),
        const SizedBox(height: 20),
        AppButton.outline(
            label: '다른 가게도 찾아보기', onPressed: () => context.go('/search')),
        const AppBottomSpacer.plain(),
      ],
    );
  }

  Widget _section(String title, String subtitle) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: HwahaeTypography.titleLarge),
        const SizedBox(height: 6),
        Text(subtitle,
            style: HwahaeTypography.bodySmall
                .copyWith(color: HwahaeColors.textSecondary)),
      ]);

  Widget _finding(Map finding) {
    final wasMarkedFixed = finding['status'] == 'fixed';
    return AppCard(
        style: AppCardStyle.outlined,
        borderColor:
            wasMarkedFixed ? HwahaeColors.border : HwahaeColors.secondary,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(wasMarkedFixed ? '개선 처리 기록' : '개선 확인 대기',
              style: HwahaeTypography.bodySmall.copyWith(
                  color: wasMarkedFixed
                      ? HwahaeColors.textSecondary
                      : HwahaeColors.onSecondaryContainer)),
          const SizedBox(height: 8),
          Text(finding['title']?.toString() ?? '',
              style: HwahaeTypography.titleMedium),
          if (finding['detail'] != null) ...[
            const SizedBox(height: 8),
            Text('${finding['detail']}', style: HwahaeTypography.bodySmall)
          ],
          const SizedBox(height: 8),
          Text('최초 기록 ${_date(finding['first_found_at'])}',
              style: HwahaeTypography.captionMedium),
          if (finding['promise']?.toString().isNotEmpty == true) ...[
            const Divider(height: 24),
            Text('업체의 개선 약속', style: HwahaeTypography.titleSmall),
            const SizedBox(height: 8),
            Text('${finding['promise']}', style: HwahaeTypography.bodyMedium),
            const SizedBox(height: 6),
            Text('약속은 개선 확인과 다릅니다.', style: HwahaeTypography.captionMedium),
          ],
          if (wasMarkedFixed) ...[
            const SizedBox(height: 10),
            // 과거 자동 해결 기록은 항목별 증거가 없어 재감찰 인증처럼 표현하지 않는다.
            Text('이전 개선 처리 기록입니다. 항목별 재감찰 근거 확인이 필요합니다.',
                style: HwahaeTypography.bodySmall),
          ],
        ]));
  }

  String _date(dynamic raw) {
    final value = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    return value == null
        ? '날짜 미제공'
        : '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
  }
}
