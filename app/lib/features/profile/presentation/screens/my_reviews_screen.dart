import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';

/// 내 리뷰 데이터 모델
class MyReview {
  final String id;
  final String businessName;
  final double rating;
  final String content;
  final String date;
  final String status;
  final int photoCount;
  final int reward;

  MyReview({
    required this.id,
    required this.businessName,
    required this.rating,
    required this.content,
    required this.date,
    required this.status,
    required this.photoCount,
    required this.reward,
  });

  factory MyReview.fromJson(Map<String, dynamic> json) {
    return MyReview(
      id: json['id'] ?? '',
      businessName: json['business']?['name'] ?? json['business_name'] ?? '업체',
      rating: (json['overall_score'] ?? json['rating'] ?? 0).toDouble(),
      content: json['content'] ?? '',
      date: _formatDate(json['created_at']),
      status: json['status'] ?? 'pending',
      photoCount: (json['photos'] as List?)?.length ?? json['photo_count'] ?? 0,
      reward: json['reviewer_fee'] ?? json['reward'] ?? 0,
    );
  }

  static String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.year}.${dt.month.toString().padLeft(2, '0')}'
          '.${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}

/// 내 리뷰 목록 Provider
///
/// 예전에는 오류를 삼키고 빈 목록을 돌려줬다. 그러면 통신이 끊겼을 때
/// "작성한 리뷰가 없습니다"라고 말하게 된다 — 리뷰를 쓴 사람에게 없다고
/// 하는 것은 그냥 거짓말이다. 실패는 실패로 올려보내고 화면이 다시
/// 시도할 수 있게 한다.
final myReviewsProvider = FutureProvider<List<MyReview>>((ref) async {
  final response = await ApiClient.instance.dio.get('/reviews/my');
  final data = response.data;
  if (data['success'] != true) {
    throw Exception(data['message'] ?? '리뷰를 불러오지 못했습니다');
  }
  final list = data['data']['reviews'] as List? ?? [];
  return list.map((json) => MyReview.fromJson(json)).toList();
});

/// 상태 필터.
enum _Filter {
  all('전체', null),
  approved('승인됨', 'approved'),
  pending('심사중', 'pending');

  const _Filter(this.label, this.status);
  final String label;
  final String? status;
}

class MyReviewsScreen extends ConsumerStatefulWidget {
  const MyReviewsScreen({super.key, this.isTab = false});

  /// 하단 네비게이션이 있는 탭으로 열렸는지.
  /// 켜면 목록 아래에 네비게이션 높이만큼 여백을 둔다.
  final bool isTab;

  @override
  ConsumerState<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends ConsumerState<MyReviewsScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(myReviewsProvider);

    return AppScreen(
      title: widget.isTab ? '내 활동' : '작성한 리뷰',
      hasBottomNav: widget.isTab,
      onRefresh: () async => ref.refresh(myReviewsProvider.future),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          AppChipBar(
            labels: [for (final f in _Filter.values) f.label],
            selectedIndex: _filter.index,
            onSelected: (i) => setState(() => _filter = _Filter.values[i]),
            counts: reviewsAsync.maybeWhen(
              data: (all) => [
                for (final f in _Filter.values)
                  f.status == null
                      ? all.length
                      : all.where((r) => r.status == f.status).length,
              ],
              orElse: () => null,
            ),
          ),
          const SizedBox(height: 16),
          reviewsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(
                child: CircularProgressIndicator(color: HwahaeColors.primary),
              ),
            ),
            error: (error, _) => AppErrorState(
              message: '리뷰를 불러올 수 없습니다',
              onRetry: () => ref.invalidate(myReviewsProvider),
            ),
            data: (all) {
              final reviews = _filter.status == null
                  ? all
                  : all.where((r) => r.status == _filter.status).toList();

              if (reviews.isEmpty) {
                return AppEmptyState(
                  icon: Icons.rate_review_outlined,
                  title: _filter == _Filter.all
                      ? '아직 쓴 리뷰가 없네'
                      : '${_filter.label} 리뷰가 없네',
                  message: _filter == _Filter.all
                      ? '미션을 마치면 여기에 쌓인다'
                      : null,
                  showMascot: _filter == _Filter.all,
                );
              }

              return Column(
                children: [
                  for (final review in reviews)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppLayout.cardGap),
                      child: _ReviewCard(
                        review: review,
                        onShare: () => _shareReview(review),
                      ),
                    ),
                ],
              );
            },
          ),
          const AppBottomSpacer(),
        ],
      ),
    );
  }

  Future<void> _shareReview(MyReview review) async {
    final full = review.rating.floor();
    final stars = '★' * full + (review.rating - full >= 0.5 ? '☆' : '');

    final shareText = '''
[암행어흥 리뷰]

📍 ${review.businessName}
⭐ $stars ${review.rating}점

"${review.content}"

---
암행어흥에서 더 많은 솔직한 리뷰를 확인하세요!
https://amhangeoheung.com/reviews/${review.id}
''';

    await Share.share(shareText, subject: '${review.businessName} 리뷰 공유');
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.onShare});

  final MyReview review;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (review.status) {
      'approved' => ('승인됨', HwahaeColors.accent),
      'pending' => ('심사중', HwahaeColors.warning),
      'rejected' => ('반려됨', HwahaeColors.secondary),
      _ => (review.status, HwahaeColors.textSecondary),
    };

    return AppCard(
      style: AppCardStyle.outlined,
      onTap: () => context.push('/reviews/${review.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppBadge(label: statusLabel, color: statusColor, compact: true),
              const Spacer(),
              Text(
                review.date,
                style: HwahaeTypography.captionMedium.copyWith(
                  color: HwahaeColors.textTertiary,
                ),
              ),
              if (review.status == 'approved')
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: AppIconButton(
                    icon: Icons.share_outlined,
                    iconSize: 17,
                    tooltip: '리뷰 공유',
                    onPressed: onShare,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  review.businessName,
                  style: HwahaeTypography.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppBadge.rating(review.rating),
            ],
          ),
          if (review.content.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.content,
              style: HwahaeTypography.bodySmall.copyWith(
                color: HwahaeColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.photo_outlined,
                size: 15,
                color: HwahaeColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                '${review.photoCount}장',
                style: HwahaeTypography.captionMedium.copyWith(
                  color: HwahaeColors.textTertiary,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.payments_outlined,
                size: 15,
                color: HwahaeColors.accent,
              ),
              const SizedBox(width: 4),
              Text(
                '${_formatCurrency(review.reward)}원',
                style: HwahaeTypography.captionMedium.copyWith(
                  color: HwahaeColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(int amount) {
  return amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
}
