import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../../../shared/widgets/hwahae/hwahae_cards.dart';

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
      return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}

/// 내 리뷰 목록 Provider
final myReviewsProvider = FutureProvider<List<MyReview>>((ref) async {
  try {
    final response = await ApiClient.instance.dio.get('/reviews/my');
    final data = response.data;
    if (data['success'] == true) {
      final list = data['data']['reviews'] as List? ?? [];
      return list.map((json) => MyReview.fromJson(json)).toList();
    }
  } catch (_) {}
  return [];
});

class MyReviewsScreen extends ConsumerStatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  ConsumerState<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends ConsumerState<MyReviewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('작성한 리뷰', style: HwahaeTypography.titleMedium),
        bottom: TabBar(
          controller: _tabController,
          labelColor: HwahaeColors.primary,
          unselectedLabelColor: HwahaeColors.textSecondary,
          indicatorColor: HwahaeColors.primary,
          tabs: const [
            Tab(text: '전체'),
            Tab(text: '승인됨'),
            Tab(text: '심사중'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReviewList('all'),
          _buildReviewList('approved'),
          _buildReviewList('pending'),
        ],
      ),
    );
  }

  Widget _buildReviewList(String filterStatus) {
    final reviewsAsync = ref.watch(myReviewsProvider);

    return reviewsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: HwahaeColors.primary)),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: HwahaeColors.textTertiary),
            const SizedBox(height: 16),
            Text('리뷰를 불러올 수 없습니다', style: HwahaeTypography.bodyMedium),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.invalidate(myReviewsProvider),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      data: (allReviews) {
        final reviews = filterStatus == 'all'
            ? allReviews
            : allReviews.where((r) => r.status == filterStatus).toList();

        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 64,
                  color: HwahaeColors.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  '작성한 리뷰가 없습니다',
                  style: HwahaeTypography.titleMedium.copyWith(
                    color: HwahaeColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '미션을 완료하고 리뷰를 작성해보세요',
                  style: HwahaeTypography.bodySmall.copyWith(
                    color: HwahaeColors.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myReviewsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              return _buildReviewCard(reviews[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildReviewCard(MyReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
        border: Border.all(color: HwahaeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(review.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusText(review.status),
                  style: HwahaeTypography.captionSmall.copyWith(
                    color: _getStatusColor(review.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                review.date,
                style: HwahaeTypography.captionMedium.copyWith(
                  color: HwahaeColors.textTertiary,
                ),
              ),
              if (review.status == 'approved') ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _shareReview(review),
                  child: Icon(
                    Icons.share_outlined,
                    size: 18,
                    color: HwahaeColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.businessName,
            style: HwahaeTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              HwahaeRatingBadge(rating: review.rating),
              const SizedBox(width: 8),
              Text(
                '${review.rating}점',
                style: HwahaeTypography.labelMedium.copyWith(
                  color: HwahaeColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.content,
            style: HwahaeTypography.bodySmall.copyWith(
              color: HwahaeColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.photo_outlined, size: 16, color: HwahaeColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                '${review.photoCount}장',
                style: HwahaeTypography.captionMedium.copyWith(
                  color: HwahaeColors.textTertiary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.payments_outlined, size: 16, color: HwahaeColors.success),
              const SizedBox(width: 4),
              Text(
                '${_formatCurrency(review.reward)}원',
                style: HwahaeTypography.captionMedium.copyWith(
                  color: HwahaeColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/reviews/${review.id}'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '자세히 보기',
                  style: HwahaeTypography.labelSmall.copyWith(
                    color: HwahaeColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return HwahaeColors.success;
      case 'pending':
        return HwahaeColors.warning;
      case 'rejected':
        return HwahaeColors.error;
      default:
        return HwahaeColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return '승인됨';
      case 'pending':
        return '심사중';
      case 'rejected':
        return '반려됨';
      default:
        return status;
    }
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Future<void> _shareReview(MyReview review) async {
    final stars = '★' * review.rating.floor() +
        (review.rating % 1 >= 0.5 ? '☆' : '');

    final shareText = '''
[암행어흥 리뷰]

📍 ${review.businessName}
⭐ $stars ${review.rating}점

"${review.content}"

---
암행어흥에서 더 많은 솔직한 리뷰를 확인하세요!
https://amhangeoheung.com/reviews/${review.id}
''';

    await Share.share(
      shareText,
      subject: '${review.businessName} 리뷰 공유',
    );
  }
}
