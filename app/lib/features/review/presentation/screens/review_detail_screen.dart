import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/models/review_model.dart';
import '../../../../shared/widgets/ui/ui.dart';

/// 리뷰 상세 데이터 모델
class ReviewDetailData {
  final String id;
  final String reviewerName;
  final String reviewerGrade;
  final String reviewerSpecialty;
  final int reviewerReviewCount;
  final bool isVerified;
  final String businessId;
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
  final String? improvementPromise;
  final int helpfulCount;
  final bool isHelpful;
  final DateTime createdAt;
  // Anonymization fields (for business view)
  final bool isAnonymized;
  final String? displayVisitDate;   // "2월 초순" style fuzzy date
  final String? displayTimeSlot;    // "오후" style time slot

  ReviewDetailData({
    required this.id,
    required this.reviewerName,
    required this.reviewerGrade,
    required this.reviewerSpecialty,
    required this.reviewerReviewCount,
    required this.isVerified,
    required this.businessId,
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
    this.improvementPromise,
    required this.helpfulCount,
    required this.isHelpful,
    required this.createdAt,
    this.isAnonymized = false,
    this.displayVisitDate,
    this.displayTimeSlot,
  });

  factory ReviewDetailData.fromReviewModel(ReviewModel model) {
    final reviewer = model.reviewer;
    final business = model.business;
    return ReviewDetailData(
      id: model.id,
      reviewerName: reviewer?.nickname ?? '리뷰어',
      reviewerGrade: reviewer?.reviewerGrade ?? 'rookie',
      reviewerSpecialty: '',
      reviewerReviewCount: 0,
      isVerified: model.status == 'published' || model.status == 'preview',
      businessId: model.businessId,
      businessName: business?.name ?? '업체',
      businessCategory: business?.category ?? '',
      businessAddress: business?.addressCity ?? '',
      businessBadge: business?.badgeLevel,
      totalScore: model.totalScore,
      detailScores: model.scores ?? {},
      content: model.detailedReview ?? model.summary ?? '',
      pros: model.pros,
      cons: model.cons,
      photos: model.photos.map((p) => p.url).toList(),
      businessResponse: model.businessResponse,
      businessResponseAt: model.respondedAt,
      improvementPromise: model.improvementPromise,
      helpfulCount: model.helpfulCount,
      isHelpful: false,
      createdAt: model.createdAt,
      isAnonymized: reviewer?.nickname?.startsWith('암행어흥') ?? false,
      displayVisitDate: null,
      displayTimeSlot: null,
    );
  }
}

final _reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository();
});

/// Raw ReviewModel provider (for accessing topics, tips, alternatives)
final reviewModelProvider =
    FutureProvider.family<ReviewModel?, String>((ref, reviewId) async {
  final repository = ref.read(_reviewRepositoryProvider);
  final response = await repository.getReviewDetail(reviewId);
  return response.review;
});

/// 리뷰 상세 데이터 Provider — 실제 API 연동
final reviewDetailProvider =
    FutureProvider.family<ReviewDetailData, String>((ref, reviewId) async {
  final repository = ref.read(_reviewRepositoryProvider);
  final response = await repository.getReviewDetail(reviewId);

  if (!response.success || response.review == null) {
    throw Exception(response.message ?? '리뷰를 불러오는데 실패했습니다');
  }

  return ReviewDetailData.fromReviewModel(response.review!);
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
  ReviewModel? _reviewModel;

  @override
  Widget build(BuildContext context) {
    final reviewAsync = ref.watch(reviewDetailProvider(widget.reviewId));
    // Also watch the raw model for topics/tips/alternatives
    final modelAsync = ref.watch(reviewModelProvider(widget.reviewId));
    modelAsync.whenData((model) => _reviewModel = model);

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
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
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
            Semantics(
              label: '리뷰 공유',
              child: IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => _shareReview(review),
                tooltip: '공유',
              ),
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

              // 토픽 태그
              if (_reviewModel != null && _reviewModel!.topics.isNotEmpty)
                _buildTopicsSection(_reviewModel!),

              // 꿀팁
              if (_reviewModel != null && _reviewModel!.contentTips != null && _reviewModel!.contentTips!.isNotEmpty)
                _buildTipsSection(_reviewModel!),

              // 사진
              if (review.photos.isNotEmpty) _buildPhotos(review),

              // 업체 답변
              if (review.businessResponse != null) _buildBusinessResponse(review),

              // 대안 업체 (낮은 평점 시)
              if (_reviewModel != null && _reviewModel!.alternatives.isNotEmpty)
                _buildAlternativesSection(_reviewModel!),

              // 유용성 투표
              _buildHelpfulSection(review),

              const AppBottomSpacer.plain(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewerInfo(ReviewDetailData review) {
    // Anonymized view for business owners
    if (review.isAnonymized) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: HwahaeColors.surface,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: HwahaeColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(Icons.person, color: HwahaeColors.textTertiary, size: 28),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.reviewerName, // "암행어흥 #XXXX" from backend
                    style: HwahaeTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (review.displayVisitDate != null) ...[
                        Icon(Icons.calendar_today, size: 12, color: HwahaeColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          review.displayVisitDate!,
                          style: HwahaeTypography.bodySmall.copyWith(
                            color: HwahaeColors.textSecondary,
                          ),
                        ),
                      ],
                      if (review.displayVisitDate != null && review.displayTimeSlot != null)
                        Text(' • ', style: HwahaeTypography.bodySmall.copyWith(color: HwahaeColors.textTertiary)),
                      if (review.displayTimeSlot != null)
                        Text(
                          _getTimeSlotLabel(review.displayTimeSlot!),
                          style: HwahaeTypography.bodySmall.copyWith(
                            color: HwahaeColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (review.isVerified)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: HwahaeColors.success.withValues(alpha: 0.1),
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

    // Normal view for reviewers / public
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
                colors: [gradeColor, gradeColor.withValues(alpha: 0.7)],
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
                        color: gradeColor.withValues(alpha: 0.1),
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
                color: HwahaeColors.success.withValues(alpha: 0.1),
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

  String _getTimeSlotLabel(String slot) {
    switch (slot) {
      case 'morning': return '오전';
      case 'lunch': return '점심';
      case 'afternoon': return '오후';
      case 'evening': return '저녁';
      case 'night': return '밤';
      default: return slot;
    }
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
        onTap: review.businessId.isEmpty
            ? null
            : () => context.push('/trust/${review.businessId}'),
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
              child: Icon(_getCategoryIcon(review.businessCategory), color: HwahaeColors.textSecondary),
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
                        color: badgeColor.withValues(alpha: 0.1),
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
            HwahaeColors.primary.withValues(alpha: 0.1),
            HwahaeColors.primary.withValues(alpha: 0.05),
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
                color: HwahaeColors.success.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: HwahaeColors.success.withValues(alpha: 0.2)),
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
                color: HwahaeColors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: HwahaeColors.error.withValues(alpha: 0.2)),
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
              return Semantics(
                label: '리뷰 사진 ${index + 1}/${review.photos.length}',
                image: true,
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.black,
                        insetPadding: EdgeInsets.zero,
                        child: Stack(
                          children: [
                            Center(
                              child: Container(
                                color: HwahaeColors.surfaceVariant,
                                child: const Icon(
                                  Icons.image,
                                  size: 120,
                                  color: HwahaeColors.textTertiary,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 40,
                              right: 16,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    decoration: BoxDecoration(
                      color: HwahaeColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.image,
                      color: HwahaeColors.textTertiary,
                    ),
                  ),
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
        color: HwahaeColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HwahaeColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.store, size: 18, color: HwahaeColors.primary),
              const SizedBox(width: 8),
              Text(
                '업체 측 답변',
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
          // 개선 약속
          if (review.improvementPromise != null && review.improvementPromise!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HwahaeColors.success.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: HwahaeColors.success.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.handshake, size: 16, color: HwahaeColors.success),
                      const SizedBox(width: 6),
                      Text(
                        '개선 약속',
                        style: HwahaeTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: HwahaeColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review.improvementPromise!,
                    style: HwahaeTypography.bodySmall.copyWith(
                      height: 1.5,
                      color: HwahaeColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHelpfulSection(ReviewDetailData review) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HwahaeColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '이 리뷰가 도움이 되었나요?',
            style: HwahaeTypography.bodySmall.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleHelpful,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isHelpful
                      ? HwahaeColors.primary.withValues(alpha: 0.1)
                      : HwahaeColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isHelpful ? HwahaeColors.primary : HwahaeColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isHelpful ? Icons.thumb_up : Icons.thumb_up_outlined,
                      size: 18,
                      color: _isHelpful ? HwahaeColors.primary : HwahaeColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '도움됨 $_helpfulCount',
                      style: HwahaeTypography.labelSmall.copyWith(
                        color: _isHelpful ? HwahaeColors.primary : HwahaeColors.textSecondary,
                        fontWeight: _isHelpful ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareReview(ReviewDetailData review) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '리뷰 공유하기',
              style: HwahaeTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            // 증거 배지
            if (review.isVerified)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HwahaeColors.success.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HwahaeColors.success.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, size: 16, color: HwahaeColors.success),
                    const SizedBox(width: 6),
                    Text(
                      'GPS 인증',
                      style: HwahaeTypography.labelSmall.copyWith(
                        color: HwahaeColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.receipt_long, size: 16, color: HwahaeColors.success),
                    const SizedBox(width: 6),
                    Text(
                      '영수증 인증',
                      style: HwahaeTypography.labelSmall.copyWith(
                        color: HwahaeColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.timer, size: 16, color: HwahaeColors.success),
                    const SizedBox(width: 6),
                    Text(
                      '체류시간 인증',
                      style: HwahaeTypography.labelSmall.copyWith(
                        color: HwahaeColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            // 공유 옵션
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: HwahaeColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.share, color: HwahaeColors.textPrimary),
              ),
              title: const Text('공유하기'),
              subtitle: const Text('다른 앱으로 리뷰를 공유합니다'),
              onTap: () {
                Navigator.pop(context);
                _doShareReview(review);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _doShareReview(ReviewDetailData review) {
    final contentPreview = review.content.length > 100
        ? '${review.content.substring(0, 100)}...'
        : review.content;
    Share.share(
      '${review.businessName} 리뷰\n\n'
      '평점: ${review.totalScore.toStringAsFixed(1)}/5.0\n\n'
      '$contentPreview\n\n'
      '암행어흥에서 더 많은 리뷰를 확인하세요!',
    );
  }

  void _toggleHelpful() {
    final wasHelpful = _isHelpful;
    setState(() {
      _isHelpful = !_isHelpful;
      _helpfulCount += _isHelpful ? 1 : -1;
    });
    // 실제 API 호출
    final repository = ref.read(_reviewRepositoryProvider);
    repository.markHelpful(widget.reviewId).then((response) {
      if (!response.success && mounted) {
        // 실패 시 롤백
        setState(() {
          _isHelpful = wasHelpful;
          _helpfulCount += wasHelpful ? 1 : -1;
        });
      }
    });
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case '음식점':
      case '식당':
      case '레스토랑':
        return Icons.restaurant;
      case '카페':
      case '커피':
        return Icons.local_cafe;
      case '뷰티':
      case '미용':
      case '헤어':
        return Icons.spa;
      case '숙박':
      case '호텔':
        return Icons.hotel;
      case '병원':
      case '의료':
        return Icons.local_hospital;
      case '쇼핑':
      case '마트':
        return Icons.shopping_bag;
      default:
        return Icons.store;
    }
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

  // ---------------------------------------------------------------------------
  // Topics section
  // ---------------------------------------------------------------------------

  Widget _buildTopicsSection(ReviewModel model) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      color: HwahaeColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('리뷰 토픽', style: HwahaeTypography.titleSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: model.topics.map((topic) {
              final isPositive = topic.isPositive;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPositive
                      ? HwahaeColors.success.withValues(alpha: 0.1)
                      : HwahaeColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPositive ? HwahaeColors.success : HwahaeColors.error,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  topic.topicLabel,
                  style: HwahaeTypography.bodySmall.copyWith(
                    color: isPositive ? HwahaeColors.success : HwahaeColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tips section
  // ---------------------------------------------------------------------------

  Widget _buildTipsSection(ReviewModel model) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      color: HwahaeColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: HwahaeColors.warning, size: 20),
              const SizedBox(width: 8),
              Text('꿀팁/노하우', style: HwahaeTypography.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HwahaeColors.warningLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              model.contentTips!,
              style: HwahaeTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Alternatives section (shown when review score < 3.0)
  // ---------------------------------------------------------------------------

  Widget _buildAlternativesSection(ReviewModel model) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      color: HwahaeColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.thumb_up_alt, color: HwahaeColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('더 나은 대안', style: HwahaeTypography.titleSmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '같은 카테고리에서 높은 평가를 받은 업체들이에요',
            style: HwahaeTypography.captionLarge.copyWith(color: HwahaeColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ...model.alternatives.map((alt) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HwahaeColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: HwahaeColors.border),
                ),
                child: InkWell(
                  onTap: () => context.push('/trust/${alt.id}'),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: HwahaeColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.store, color: HwahaeColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alt.name ?? '업체',
                              style: HwahaeTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${alt.addressCity ?? ''} • 리뷰 ${alt.totalReviews}개',
                              style: HwahaeTypography.captionLarge.copyWith(color: HwahaeColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: HwahaeColors.warning, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            alt.trustWeightedRating > 0
                                ? alt.trustWeightedRating.toStringAsFixed(1)
                                : alt.averageRating.toStringAsFixed(1),
                            style: HwahaeTypography.labelLarge.copyWith(
                              color: HwahaeColors.warning,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
