import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../data/models/review_model.dart';
import '../../providers/review_provider.dart';

class ReviewListScreen extends ConsumerStatefulWidget {
  const ReviewListScreen({super.key});

  @override
  ConsumerState<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends ConsumerState<ReviewListScreen> {
  String _selectedCategory = '전체';
  String _selectedSort = '최신순';
  bool _isCompactMode = false; // 컴팩트 모드 토글
  final List<String> _categories = ['전체', '음식점', '카페', '병원', '미용실', '온라인몰'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(reviewsProvider.notifier).loadReviews();
    });
  }

  /// Shimmer 스켈레톤 로딩
  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HwahaeColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HwahaeColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _shimmerBox(40, 40, isCircle: true),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(120, 14),
                      const SizedBox(height: 6),
                      _shimmerBox(80, 10),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _shimmerBox(double.infinity, 12),
              const SizedBox(height: 8),
              _shimmerBox(200, 12),
              const SizedBox(height: 12),
              Row(
                children: [
                  _shimmerBox(56, 56, borderRadius: 10),
                  const SizedBox(width: 8),
                  _shimmerBox(56, 56, borderRadius: 10),
                  const SizedBox(width: 8),
                  _shimmerBox(56, 56, borderRadius: 10),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox(double width, double height, {bool isCircle = false, double borderRadius = 6}) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: HwahaeColors.surfaceVariant,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    final categoryParam = category == '전체' ? null : category;
    ref.read(reviewsProvider.notifier).setCategory(categoryParam);
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}년 전';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}개월 전';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case '음식점':
      case '한식':
      case '중식':
      case '일식':
      case '양식':
        return Icons.restaurant;
      case '카페':
        return Icons.local_cafe;
      case '병원':
        return Icons.local_hospital;
      case '미용실':
      case '뷰티':
        return Icons.content_cut;
      case '온라인몰':
        return Icons.shopping_bag;
      default:
        return Icons.store;
    }
  }

  Color _getBadgeColor(String? badgeLevel) {
    switch (badgeLevel) {
      case 'platinum':
        return HwahaeColors.gradePlatinum;
      case 'gold':
        return HwahaeColors.gradeGold;
      case 'silver':
        return HwahaeColors.gradeSilver;
      case 'bronze':
        return HwahaeColors.gradeBronze;
      default:
        return HwahaeColors.textTertiary;
    }
  }

  String _getBadgeDisplayName(String? badgeLevel) {
    switch (badgeLevel) {
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

  @override
  Widget build(BuildContext context) {
    final reviewsState = ref.watch(reviewsProvider);

    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        title: const Text('인증 리뷰'),
        actions: [
          // 컴팩트/상세 보기 토글
          IconButton(
            icon: Icon(
              _isCompactMode ? Icons.view_agenda_outlined : Icons.view_list_outlined,
            ),
            onPressed: () {
              setState(() {
                _isCompactMode = !_isCompactMode;
              });
            },
            tooltip: _isCompactMode ? '상세 보기' : '컴팩트 보기',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 카테고리 필터
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      _onCategorySelected(category);
                    },
                    selectedColor: HwahaeColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : HwahaeColors.textSecondary,
                    ),
                    checkmarkColor: Colors.white,
                  ),
                );
              },
            ),
          ),

          // 리뷰 목록
          Expanded(
            child: _buildReviewList(reviewsState),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewList(ReviewsState state) {
    if (state.isLoading) {
      return _buildShimmerLoading();
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: HwahaeColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: HwahaeColors.error,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '리뷰를 불러올 수 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: const TextStyle(
                  fontSize: 14,
                  color: HwahaeColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  final categoryParam = _selectedCategory == '전체' ? null : _selectedCategory;
                  ref.read(reviewsProvider.notifier).loadReviews(category: categoryParam);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HwahaeColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: HwahaeColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rate_review_outlined,
                  size: 40,
                  color: HwahaeColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '리뷰가 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedCategory == '전체'
                    ? '아직 등록된 리뷰가 없습니다.'
                    : '$_selectedCategory 카테고리에 등록된 리뷰가 없습니다.',
                style: const TextStyle(
                  fontSize: 14,
                  color: HwahaeColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: HwahaeColors.primary,
      onRefresh: () async {
        final categoryParam = _selectedCategory == '전체' ? null : _selectedCategory;
        await ref.read(reviewsProvider.notifier).loadReviews(category: categoryParam);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.reviews.length,
        itemBuilder: (context, index) {
          return _isCompactMode
              ? _buildCompactReviewCard(context, state.reviews[index])
              : _buildReviewCard(context, state.reviews[index]);
        },
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, ReviewModel review) {
    final reviewerName = review.reviewer?.nickname ?? '익명 리뷰어';
    final reviewerGrade = review.reviewer?.gradeDisplayName ?? '루키';
    final businessName = review.business?.name ?? '알 수 없는 업체';
    final businessCategory = review.business?.category;
    final businessCity = review.business?.addressCity;
    final badgeLevel = review.business?.badgeLevel;
    final timeAgo = _formatTimeAgo(review.publishedAt ?? review.createdAt);

    return Semantics(
      label: '$businessName, 별점 ${review.totalScore.toStringAsFixed(1)}, $timeAgo',
      button: true,
      child: InkWell(
      onTap: () => context.push('/reviews/${review.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: HwahaeColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HwahaeColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: HwahaeColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.person, color: HwahaeColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              reviewerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: HwahaeColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                reviewerGrade,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: HwahaeColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                            fontSize: 12,
                            color: HwahaeColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (review.status == 'published')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: HwahaeColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: HwahaeColors.success,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '인증됨',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: HwahaeColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // 업체 정보
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HwahaeColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: HwahaeColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(businessCategory),
                      color: HwahaeColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          businessName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (businessCity != null) businessCity,
                            if (businessCategory != null) businessCategory,
                          ].join(' \u2022 '),
                          style: const TextStyle(
                            fontSize: 12,
                            color: HwahaeColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (badgeLevel != null && badgeLevel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getBadgeColor(badgeLevel).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_user,
                            size: 14,
                            color: _getBadgeColor(badgeLevel),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getBadgeDisplayName(badgeLevel),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getBadgeColor(badgeLevel),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // 점수
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.star, color: HwahaeColors.secondary, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    review.totalScore.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (review.scores != null)
                    ...review.scores!.entries.take(3).map(
                      (entry) => _buildMiniScore(entry.key, entry.value),
                    ),
                ],
              ),
            ),

            // 리뷰 내용
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 장점 요약 또는 리뷰 요약
                  if (review.summary != null && review.summary!.isNotEmpty)
                    Text(
                      review.summary!,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (review.pros.isNotEmpty)
                    Text(
                      review.pros.join(', '),
                      style: const TextStyle(fontSize: 14, height: 1.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // 개선점 (cons)
                  if (review.cons.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: HwahaeColors.error.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: HwahaeColors.error.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.thumb_down_outlined,
                            size: 16,
                            color: HwahaeColors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              review.cons.first,
                              style: const TextStyle(
                                fontSize: 13,
                                color: HwahaeColors.error,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 이미지
            if (review.photos.isNotEmpty)
              Container(
                height: 80,
                margin: const EdgeInsets.all(16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.photos.length,
                  itemBuilder: (context, i) {
                    final photo = review.photos[i];
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: HwahaeColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        image: photo.url.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(photo.url),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: photo.url.isEmpty
                          ? const Icon(
                              Icons.image,
                              color: HwahaeColors.textTertiary,
                            )
                          : null,
                    );
                  },
                ),
              )
            else
              const SizedBox(height: 16),

            // 하단 액션
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildActionButton(
                    Icons.thumb_up_outlined,
                    '도움됨 ${review.helpfulCount}',
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    Icons.comment_outlined,
                    '댓글',
                  ),
                  const Spacer(),
                  _buildActionButton(Icons.share_outlined, '공유'),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildMiniScore(String label, int score) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: HwahaeColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$score',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: HwahaeColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: HwahaeColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 컴팩트 리뷰 카드: 업체명 + 별점 + 한 줄 요약 + 사진 1장
  Widget _buildCompactReviewCard(BuildContext context, ReviewModel review) {
    final businessName = review.business?.name ?? '알 수 없는 업체';
    final timeAgo = _formatTimeAgo(review.publishedAt ?? review.createdAt);
    final hasPhoto = review.photos.isNotEmpty;
    final summary = review.summary ?? (review.pros.isNotEmpty ? review.pros.first : '');

    return Semantics(
      label: '$businessName, 별점 ${review.totalScore.toStringAsFixed(1)}',
      button: true,
      child: InkWell(
        onTap: () => context.push('/reviews/${review.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: HwahaeColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HwahaeColors.divider),
          ),
          child: Row(
            children: [
              // 사진 1장 (있으면)
              if (hasPhoto)
                Container(
                  width: 56,
                  height: 56,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: HwahaeColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    image: review.photos.first.url.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(review.photos.first.url),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: review.photos.first.url.isEmpty
                      ? const Icon(Icons.image, color: HwahaeColors.textTertiary, size: 20)
                      : null,
                ),
              // 텍스트 영역
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          businessName,
                          style: HwahaeTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 별점
                        Icon(Icons.star, color: HwahaeColors.getRatingColor(review.totalScore), size: 14),
                        const SizedBox(width: 2),
                        Text(
                          review.totalScore.toStringAsFixed(1),
                          style: HwahaeTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: HwahaeColors.getRatingColor(review.totalScore),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          timeAgo,
                          style: HwahaeTypography.captionSmall.copyWith(
                            color: HwahaeColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    if (summary.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        summary,
                        style: HwahaeTypography.bodySmall.copyWith(
                          color: HwahaeColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 18, color: HwahaeColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '필터',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('정렬', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['최신순', '평점 높은순', '도움순'].map((sort) {
                      return ChoiceChip(
                        label: Text(sort),
                        selected: _selectedSort == sort,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              _selectedSort = sort;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // 인증 상태 (카테고리 중복 제거 → 인증 상태 필터로 대체)
                  const Text('인증 상태', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['전체', '인증됨', '미인증'].map((status) {
                      return ChoiceChip(
                        label: Text(status),
                        selected: false,
                        onSelected: (selected) {},
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {});
                        _onCategorySelected(_selectedCategory);
                      },
                      child: const Text('적용하기'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
