import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';

/// 리뷰 상세 데이터 모델
class ReviewDetailData {
  final String id;
  final String reviewerName;
  final String reviewerGrade;
  final String reviewerSpecialty;
  final int reviewerReviewCount;
  final bool isVerified;
  final String businessName;
  final String businessCategory;
  final String businessAddress;
  final String? businessBadge;
  final double totalScore;
  final Map<String, int> detailScores;
  final String content;
  final List<String> pros;
  final List<String> cons;
  final List<String> photos;
  final String? businessResponse;
  final DateTime? businessResponseAt;
  final int helpfulCount;
  final bool isHelpful;
  final DateTime createdAt;

  ReviewDetailData({
    required this.id,
    required this.reviewerName,
    required this.reviewerGrade,
    required this.reviewerSpecialty,
    required this.reviewerReviewCount,
    required this.isVerified,
    required this.businessName,
    required this.businessCategory,
    required this.businessAddress,
    this.businessBadge,
    required this.totalScore,
    required this.detailScores,
    required this.content,
    required this.pros,
    required this.cons,
    required this.photos,
    this.businessResponse,
    this.businessResponseAt,
    required this.helpfulCount,
    required this.isHelpful,
    required this.createdAt,
  });
}

/// 리뷰 상세 데이터 Provider
final reviewDetailProvider =
    FutureProvider.family<ReviewDetailData, String>((ref, reviewId) async {
  await Future.delayed(const Duration(milliseconds: 600));

  return ReviewDetailData(
    id: reviewId,
    reviewerName: '맛집탐험가',
    reviewerGrade: 'master',
    reviewerSpecialty: '음식점 전문',
    reviewerReviewCount: 128,
    isVerified: true,
    businessName: '맛있는 한식당',
    businessCategory: '한식',
    businessAddress: '강남구 역삼동',
    businessBadge: 'gold',
    totalScore: 4.2,
    detailScores: {
      '대기 시간': 3,
      '음식 맛': 5,
      '청결도': 4,
      '직원 응대': 4,
      '가성비': 5,
    },
    content: '강남역 근처에서 점심을 먹기 위해 방문했습니다. '
        '점심시간이라 대기가 조금 있었지만 (약 15분), '
        '맛있는 음식으로 충분히 보상받았습니다.\n\n'
        '주문한 김치찌개는 적당히 매콤하고 깊은 맛이 있었어요. '
        '특히 김치가 잘 익어서 시원한 맛이 일품이었습니다. '
        '반찬도 신선하고 양도 충분했습니다.\n\n'
        '직원분들도 바쁜 와중에도 친절하게 응대해주셨어요. '
        '가격 대비 만족스러운 식사였습니다.',
    pros: ['김치찌개 맛이 일품', '신선한 반찬', '친절한 직원'],
    cons: ['점심시간 대기가 길어요 (약 15분)', '테이블 간격이 좁아서 조금 불편했습니다'],
    photos: ['photo1.jpg', 'photo2.jpg', 'photo3.jpg', 'photo4.jpg', 'photo5.jpg'],
    businessResponse: '소중한 리뷰 감사합니다! '
        '말씀해주신 대기 시간 문제는 다음 달부터 예약 시스템을 도입하여 개선하겠습니다. '
        '다음 방문 시에는 더 나은 서비스로 보답하겠습니다.',
    businessResponseAt: DateTime.now().subtract(const Duration(days: 2)),
    helpfulCount: 24,
    isHelpful: false,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  );
});

class ReviewDetailScreen extends ConsumerStatefulWidget {
  final String reviewId;

  const ReviewDetailScreen({super.key, required this.reviewId});

  @override
  ConsumerState<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends ConsumerState<ReviewDetailScreen> {
  bool _isHelpful = false;
  int _helpfulCount = 0;

  @override
  Widget build(BuildContext context) {
    final reviewAsync = ref.watch(reviewDetailProvider(widget.reviewId));

    return Scaffold(
      backgroundColor: HwahaeColors.background,
      body: reviewAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: HwahaeColors.primary),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: HwahaeColors.error),
              const SizedBox(height: 16),
              Text('리뷰를 불러오는데 실패했습니다', style: HwahaeTypography.bodyMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(reviewDetailProvider(widget.reviewId)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (review) {
          if (!_isHelpful && review.isHelpful) {
            _isHelpful = review.isHelpful;
          }
          if (_helpfulCount == 0) {
            _helpfulCount = review.helpfulCount;
          }
          return _buildContent(context, review);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ReviewDetailData review) {
    return CustomScrollView(
      slivers: [
        // AppBar
        SliverAppBar(
          floating: true,
          backgroundColor: HwahaeColors.surface,
          title: Text('리뷰 상세', style: HwahaeTypography.titleMedium),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _shareReview(review),
            ),
          ],
        ),

        // Content
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 리뷰어 정보
              _buildReviewerInfo(review),

              // 업체 정보
              _buildBusinessInfo(review),

              // 총점
              _buildTotalScore(review),

              // 세부 점수
              _buildDetailScores(review),

              // 리뷰 내용
              _buildReviewContent(review),

              // 사진
              if (review.photos.isNotEmpty) _buildPhotos(review),

              // 업체 답변
              if (review.businessResponse != null) _buildBusinessResponse(review),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewerInfo(ReviewDetailData review) {
    final gradeColor = _getGradeColor(review.reviewerGrade);

    return Container(
      padding: const EdgeInsets.all(16),
      color: HwahaeColors.surface,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gradeColor, gradeColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                review.reviewerName[0],
                style: HwahaeTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      review.reviewerName,
                      style: HwahaeTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: gradeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getGradeName(review.reviewerGrade),
                        style: HwahaeTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: gradeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${review.reviewerSpecialty} • 리뷰 ${review.reviewerReviewCount}개 작성',
                  style: HwahaeTypography.bodySmall.copyWith(
                    color: HwahaeColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (review.isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: HwahaeColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, size: 16, color: HwahaeColors.success),
                  const SizedBox(width: 4),
                  Text(
                    '인증됨',
                    style: HwahaeTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: HwahaeColors.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBusinessInfo(ReviewDetailData review) {
    final badgeColor = _getBadgeColor(review.businessBadge);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HwahaeColors.border),
      ),
      child: InkWell(
        onTap: () => context.push('/business/${review.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: HwahaeColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant, color: HwahaeColors.textSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.businessName,
                    style: HwahaeTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${review.businessAddress} • ${review.businessCategory}',
                    style: HwahaeTypography.bodySmall.copyWith(
                      color: HwahaeColors.textSecondary,
                    ),
                  ),
                  if (review.businessBadge != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user, size: 14, color: badgeColor),
                          const SizedBox(width: 4),
                          Text(
                            '${_getBadgeName(review.businessBadge!)} 인증 업체',
                            style: HwahaeTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: badgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: HwahaeColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalScore(ReviewDetailData review) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HwahaeColors.primary.withOpacity(0.1),
            HwahaeColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star, color: HwahaeColors.ratingStar, size: 32),
          const SizedBox(width: 8),
          Text(
            review.totalScore.toStringAsFixed(1),
            style: HwahaeTypography.displaySmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            ' / 5.0',
            style: HwahaeTypography.titleMedium.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailScores(ReviewDetailData review) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '세부 평가',
            style: HwahaeTypography.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...review.detailScores.entries.map((entry) => _buildScoreRow(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, int score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: HwahaeTypography.bodySmall.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < score ? Icons.star : Icons.star_border,
                  color: HwahaeColors.ratingStar,
                  size: 20,
                );
              }),
            ),
          ),
          Text(
            '$score.0',
            style: HwahaeTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewContent(ReviewDetailData review) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '리뷰 내용',
            style: HwahaeTypography.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            review.content,
            style: HwahaeTypography.bodyMedium.copyWith(
              height: 1.8,
            ),
          ),
          const SizedBox(height: 16),

          // 장점
          if (review.pros.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HwahaeColors.success.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: HwahaeColors.success.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.thumb_up, size: 18, color: HwahaeColors.success),
                      const SizedBox(width: 8),
                      Text(
                        '좋았던 점',
                        style: HwahaeTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: HwahaeColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...review.pros.map((pro) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: HwahaeTypography.bodySmall),
                        Expanded(child: Text(pro, style: HwahaeTypography.bodySmall)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 단점
          if (review.cons.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HwahaeColors.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: HwahaeColors.error.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.thumb_down, size: 18, color: HwahaeColors.error),
                      const SizedBox(width: 8),
                      Text(
                        '개선이 필요한 점',
                        style: HwahaeTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: HwahaeColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...review.cons.map((con) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: HwahaeTypography.bodySmall),
                        Expanded(child: Text(con, style: HwahaeTypography.bodySmall)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotos(ReviewDetailData review) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '사진',
            style: HwahaeTypography.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: review.photos.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: HwahaeColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.image,
                  color: HwahaeColors.textTertiary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessResponse(ReviewDetailData review) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HwahaeColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.store, size: 18, color: HwahaeColors.primary),
              const SizedBox(width: 8),
              Text(
                '업체 답변',
                style: HwahaeTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: HwahaeColors.primary,
                ),
              ),
              const Spacer(),
              if (review.businessResponseAt != null)
                Text(
                  _formatDate(review.businessResponseAt!),
                  style: HwahaeTypography.labelSmall.copyWith(
                    color: HwahaeColors.textTertiary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.businessResponse!,
            style: HwahaeTypography.bodySmall.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  void _shareReview(ReviewDetailData review) {
    Share.share(
      '${review.businessName} 리뷰\n\n'
      '평점: ${review.totalScore.toStringAsFixed(1)}/5.0\n\n'
      '${review.content.substring(0, review.content.length > 100 ? 100 : review.content.length)}...\n\n'
      '암행어흥에서 더 많은 리뷰를 확인하세요!',
    );
  }

  void _toggleHelpful() {
    setState(() {
      _isHelpful = !_isHelpful;
      _helpfulCount += _isHelpful ? 1 : -1;
    });
    // API 호출 - 실제로는 서버에 요청
  }

  Color _getGradeColor(String grade) {
    switch (grade.toLowerCase()) {
      case 'master':
        return HwahaeColors.gradeDiamond;
      case 'senior':
        return HwahaeColors.gradeGold;
      case 'regular':
        return HwahaeColors.primary;
      default:
        return HwahaeColors.textSecondary;
    }
  }

  String _getGradeName(String grade) {
    switch (grade.toLowerCase()) {
      case 'master':
        return '마스터';
      case 'senior':
        return '시니어';
      case 'regular':
        return '레귤러';
      default:
        return '루키';
    }
  }

  Color _getBadgeColor(String? badge) {
    switch (badge?.toLowerCase()) {
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
        return '';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '오늘';
    } else if (diff.inDays == 1) {
      return '어제';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    }
    return '${date.month}월 ${date.day}일';
  }
}
