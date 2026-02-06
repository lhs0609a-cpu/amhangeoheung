import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../../../shared/widgets/hwahae/hwahae_cards.dart';

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

  Widget _buildReviewList(String status) {
    // 실제로는 API에서 데이터를 가져와야 함
    final reviews = _getMockReviews(status);

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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return _buildReviewCard(review);
      },
    );
  }

  Widget _buildReviewCard(_MockReview review) {
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
          // 헤더
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

          // 업체명
          Text(
            review.businessName,
            style: HwahaeTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // 평점
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

          // 리뷰 내용 미리보기
          Text(
            review.content,
            style: HwahaeTypography.bodySmall.copyWith(
              color: HwahaeColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // 하단 정보
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

  List<_MockReview> _getMockReviews(String status) {
    final allReviews = [
      _MockReview(
        id: '1',
        businessName: '맛있는 식당',
        rating: 4.5,
        content: '음식이 정말 맛있었어요. 특히 된장찌개가 일품이었습니다. 다음에 또 방문하고 싶네요.',
        date: '2024.01.15',
        status: 'approved',
        photoCount: 5,
        reward: 30000,
      ),
      _MockReview(
        id: '2',
        businessName: '힙한 카페',
        rating: 4.0,
        content: '분위기가 좋고 커피도 맛있었습니다. 다만 가격이 조금 비싼 편이에요.',
        date: '2024.01.12',
        status: 'pending',
        photoCount: 3,
        reward: 25000,
      ),
      _MockReview(
        id: '3',
        businessName: '뷰티샵 A',
        rating: 4.8,
        content: '시술이 깔끔하고 직원분들이 친절해요. 만족스러웠습니다.',
        date: '2024.01.10',
        status: 'approved',
        photoCount: 4,
        reward: 35000,
      ),
    ];

    if (status == 'all') return allReviews;
    return allReviews.where((r) => r.status == status).toList();
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Future<void> _shareReview(_MockReview review) async {
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

class _MockReview {
  final String id;
  final String businessName;
  final double rating;
  final String content;
  final String date;
  final String status;
  final int photoCount;
  final int reward;

  _MockReview({
    required this.id,
    required this.businessName,
    required this.rating,
    required this.content,
    required this.date,
    required this.status,
    required this.photoCount,
    required this.reward,
  });
}
