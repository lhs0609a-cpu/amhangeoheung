import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/skeleton_widgets.dart';
import '../../../../shared/widgets/ui/ui.dart';
import '../../data/models/review_model.dart';
import '../../providers/review_provider.dart';

/// 목록 정렬.
///
/// 서버가 정렬을 지원하지 않아서 받아온 목록 안에서 정렬한다. 예전에는
/// 시트에서 고를 수는 있는데 고른 값을 아무 데도 쓰지 않아, 무엇을 골라도
/// 순서가 그대로였다.
enum _Sort {
  latest('최신순'),
  rating('평점 높은순'),
  helpful('도움순');

  const _Sort(this.label);
  final String label;

  List<ReviewModel> apply(List<ReviewModel> reviews) {
    final sorted = [...reviews];
    switch (this) {
      case _Sort.latest:
        sorted.sort((a, b) => (b.publishedAt ?? b.createdAt)
            .compareTo(a.publishedAt ?? a.createdAt));
      case _Sort.rating:
        sorted.sort((a, b) => b.totalScore.compareTo(a.totalScore));
      case _Sort.helpful:
        sorted.sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount));
    }
    return sorted;
  }
}

/// 인증 상태 필터. 이것도 예전에는 칩만 있고 동작이 없었다.
enum _Verified {
  all('전체'),
  verified('인증됨'),
  unverified('미인증');

  const _Verified(this.label);
  final String label;

  bool matches(ReviewModel review) => switch (this) {
        _Verified.all => true,
        _Verified.verified => review.status == 'published',
        _Verified.unverified => review.status != 'published',
      };
}

class ReviewListScreen extends ConsumerStatefulWidget {
  const ReviewListScreen({super.key});

  @override
  ConsumerState<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends ConsumerState<ReviewListScreen> {
  static const List<String> _categories = [
    '전체',
    '음식점',
    '카페',
    '병원',
    '미용실',
    '온라인몰',
  ];

  int _categoryIndex = 0;
  _Sort _sort = _Sort.latest;
  _Verified _verified = _Verified.all;
  bool _isCompactMode = false;

  String get _selectedCategory => _categories[_categoryIndex];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(reviewsProvider.notifier).loadReviews();
    });
  }

  void _onCategorySelected(int index) {
    setState(() => _categoryIndex = index);
    final category = index == 0 ? null : _categories[index];
    ref.read(reviewsProvider.notifier).setCategory(category);
  }

  Future<void> _reload() {
    final category = _categoryIndex == 0 ? null : _selectedCategory;
    return ref.read(reviewsProvider.notifier).loadReviews(category: category);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewsProvider);
    final gutter = AppLayout.gutterOf(context);

    return AppScreen(
      title: '인증 리뷰',
      hasBottomNav: true,
      applyGutter: false,
      onRefresh: _reload,
      actions: [
        AppIconButton(
          icon: _isCompactMode
              ? Icons.view_agenda_outlined
              : Icons.view_list_outlined,
          tooltip: _isCompactMode ? '상세 보기' : '컴팩트 보기',
          onPressed: () => setState(() => _isCompactMode = !_isCompactMode),
        ),
        AppIconButton(
          icon: Icons.tune_rounded,
          tooltip: '정렬과 필터',
          // 기본값이 아니면 뱃지로 알린다. 필터를 걸어둔 걸 잊고 "리뷰가
          // 없다"고 오해하는 일이 흔하다.
          badgeCount: (_sort == _Sort.latest ? 0 : 1) +
              (_verified == _Verified.all ? 0 : 1),
          onPressed: _showFilterSheet,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: AppChipBar(
              labels: _categories,
              selectedIndex: _categoryIndex,
              onSelected: _onCategorySelected,
            ),
          ),
          const SizedBox(height: 12),
          _buildBody(state, gutter),
          const AppBottomSpacer(),
        ],
      ),
    );
  }

  Widget _buildBody(ReviewsState state, double gutter) {
    if (state.isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: gutter),
        child: const Column(
          children: [
            ReviewCardSkeleton(),
            SizedBox(height: 16),
            ReviewCardSkeleton(),
            SizedBox(height: 16),
            ReviewCardSkeleton(),
          ],
        ),
      );
    }

    if (state.error != null) {
      return AppErrorState.fromMessage(state.error!, onRetry: _reload);
    }

    final reviews =
        _sort.apply(state.reviews.where(_verified.matches).toList());

    if (reviews.isEmpty) {
      final filtered =
          _categoryIndex != 0 || _verified != _Verified.all;
      return AppEmptyState(
        icon: Icons.rate_review_outlined,
        title: filtered ? '조건에 맞는 리뷰가 없네' : '아직 리뷰가 없네',
        message: filtered
            ? '필터를 풀면 다른 리뷰가 보일 거야'
            : '감찰이 끝나면 여기에 올라온다',
        showMascot: !filtered,
        actionLabel: filtered ? '필터 풀기' : null,
        onAction: filtered
            ? () {
                setState(() {
                  _verified = _Verified.all;
                  _sort = _Sort.latest;
                });
                _onCategorySelected(0);
              }
            : null,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      child: Column(
        children: [
          for (final review in reviews)
            Padding(
              padding: EdgeInsets.only(bottom: _isCompactMode ? 8 : 16),
              child: _isCompactMode
                  ? _CompactReviewCard(review: review)
                  : _ReviewCard(
                      review: review,
                      onHelpful: () => _markHelpful(review),
                      onShare: () => _share(review),
                    ),
            ),
        ],
      ),
    );
  }

  Future<void> _markHelpful(ReviewModel review) async {
    final ok = await ref.read(reviewsProvider.notifier).markHelpful(review.id);
    if (!mounted) return;
    if (ok) {
      AppToast.success(context, '도움이 됐다고 표시했어요');
    } else {
      AppToast.error(context, '표시하지 못했습니다');
    }
  }

  Future<void> _share(ReviewModel review) async {
    final name = review.business?.name ?? '이 가게';
    await Share.share(
      '[암행어흥] $name — ${review.totalScore.toStringAsFixed(1)}점\n'
      '${review.summary ?? (review.pros.isNotEmpty ? review.pros.first : '')}\n\n'
      'https://amhangeoheung.com/reviews/${review.id}',
      subject: '$name 감찰 리뷰',
    );
  }

  Future<void> _showFilterSheet() async {
    await showAppSheet<void>(
      context: context,
      title: '정렬과 필터',
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('정렬', style: HwahaeTypography.labelMedium.copyWith(
                color: HwahaeColors.textSecondary,
              )),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sort in _Sort.values)
                    AppChip(
                      label: sort.label,
                      selected: _sort == sort,
                      onTap: () {
                        setSheetState(() {});
                        setState(() => _sort = sort);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text('인증 상태', style: HwahaeTypography.labelMedium.copyWith(
                color: HwahaeColors.textSecondary,
              )),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final v in _Verified.values)
                    AppChip(
                      label: v.label,
                      selected: _verified == v,
                      onTap: () {
                        setSheetState(() {});
                        setState(() => _verified = v);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),
              AppSheetActions(
                child: AppButton(
                  label: '닫기',
                  onPressed: () => Navigator.of(sheetContext).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatTimeAgo(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);
  if (difference.inDays > 365) return '${difference.inDays ~/ 365}년 전';
  if (difference.inDays > 30) return '${difference.inDays ~/ 30}개월 전';
  if (difference.inDays > 0) return '${difference.inDays}일 전';
  if (difference.inHours > 0) return '${difference.inHours}시간 전';
  if (difference.inMinutes > 0) return '${difference.inMinutes}분 전';
  return '방금 전';
}

IconData _categoryIcon(String? category) {
  switch (category) {
    case '음식점':
    case '한식':
    case '중식':
    case '일식':
    case '양식':
      return Icons.restaurant_rounded;
    case '카페':
      return Icons.local_cafe_rounded;
    case '병원':
      return Icons.local_hospital_rounded;
    case '미용실':
    case '뷰티':
      return Icons.content_cut_rounded;
    case '온라인몰':
      return Icons.shopping_bag_rounded;
    default:
      return Icons.storefront_rounded;
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.onHelpful,
    required this.onShare,
  });

  final ReviewModel review;
  final VoidCallback onHelpful;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final reviewerName = review.reviewer?.nickname ?? '익명 감찰관';
    final reviewerGrade = review.reviewer?.gradeDisplayName ?? '루키';
    final businessName = review.business?.name ?? '알 수 없는 업체';
    final businessCategory = review.business?.category;
    final businessCity = review.business?.addressCity;
    final badgeLevel = review.business?.badgeLevel;
    final timeAgo = _formatTimeAgo(review.publishedAt ?? review.createdAt);

    return Semantics(
      label: '$businessName, 별점 ${review.totalScore.toStringAsFixed(1)}, '
          '$timeAgo',
      button: true,
      child: AppCard(
        style: AppCardStyle.outlined,
        padding: EdgeInsets.zero,
        onTap: () => context.push('/reviews/${review.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const AppMascot.sato(size: 38),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                reviewerName,
                                style: HwahaeTypography.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            AppBadge(
                              label: reviewerGrade,
                              color: HwahaeColors.primaryDark,
                              compact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeAgo,
                          style: HwahaeTypography.captionMedium.copyWith(
                            color: HwahaeColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (review.status == 'published')
                    AppBadge(
                      label: '인증됨',
                      color: HwahaeColors.accent,
                      icon: Icons.verified_rounded,
                      compact: true,
                    ),
                ],
              ),
            ),
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
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: HwahaeColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _categoryIcon(businessCategory),
                      size: 20,
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
                          style: HwahaeTypography.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (businessCity != null) businessCity,
                            if (businessCategory != null) businessCategory,
                          ].join(' · '),
                          style: HwahaeTypography.captionMedium.copyWith(
                            color: HwahaeColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (badgeLevel != null &&
                      badgeLevel.isNotEmpty &&
                      badgeLevel != 'none') ...[
                    const SizedBox(width: 6),
                    AppBadge.grade(badgeLevel),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  AppBadge.rating(review.totalScore, compact: false),
                  const SizedBox(width: 12),
                  if (review.scores != null)
                    Expanded(
                      child: Wrap(
                        spacing: 12,
                        children: [
                          for (final entry in review.scores!.entries.take(3))
                            _MiniScore(label: entry.key, score: entry.value),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (review.summary?.isNotEmpty == true)
                    Text(
                      review.summary!,
                      style: HwahaeTypography.bodyMedium.copyWith(height: 1.55),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (review.pros.isNotEmpty)
                    Text(
                      review.pros.join(', '),
                      style: HwahaeTypography.bodyMedium.copyWith(height: 1.55),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (review.cons.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    // 지적은 이 제품의 핵심이라 눈에 띄어야 한다. 인주색을
                    // 쓰는 것이 맞는 몇 안 되는 자리다.
                    AppNotice(
                      message: review.cons.first,
                      icon: Icons.error_outline_rounded,
                      color: HwahaeColors.secondary,
                    ),
                  ],
                ],
              ),
            ),
            if (review.photos.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  itemCount: review.photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => _Thumb(
                    url: review.photos[i].url,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            const AppDivider(indent: 0),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              child: Row(
                children: [
                  // 예전에는 도움됨·댓글·공유가 전부 아무 동작이 없는
                  // 그림이었다. 동작이 있는 것만 남긴다 — 댓글 기능은
                  // 서버에 없다.
                  AppButton.ghost(
                    label: '도움됨 ${review.helpfulCount}',
                    icon: Icons.thumb_up_outlined,
                    size: AppButtonSize.small,
                    onPressed: onHelpful,
                  ),
                  const Spacer(),
                  AppButton.ghost(
                    label: '공유',
                    icon: Icons.share_outlined,
                    size: AppButtonSize.small,
                    onPressed: onShare,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  const _MiniScore({required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: HwahaeTypography.captionMedium.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
        Text('$score', style: HwahaeTypography.titleSmall),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: HwahaeColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        image: url.isNotEmpty
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: url.isEmpty
          ? const Icon(Icons.image_outlined, color: HwahaeColors.textTertiary)
          : null,
    );
  }
}

/// 컴팩트 리뷰 카드: 업체명 + 별점 + 한 줄 요약 + 사진 1장
class _CompactReviewCard extends StatelessWidget {
  const _CompactReviewCard({required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    final businessName = review.business?.name ?? '알 수 없는 업체';
    final timeAgo = _formatTimeAgo(review.publishedAt ?? review.createdAt);
    final summary =
        review.summary ?? (review.pros.isNotEmpty ? review.pros.first : '');

    return Semantics(
      label: '$businessName, 별점 ${review.totalScore.toStringAsFixed(1)}',
      button: true,
      child: AppCard(
        style: AppCardStyle.outlined,
        padding: const EdgeInsets.all(12),
        onTap: () => context.push('/reviews/${review.id}'),
        child: Row(
          children: [
            if (review.photos.isNotEmpty) ...[
              SizedBox(
                width: 54,
                height: 54,
                child: _Thumb(url: review.photos.first.url),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          businessName,
                          style: HwahaeTypography.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      AppBadge.rating(review.totalScore),
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
                  const SizedBox(height: 3),
                  Text(
                    timeAgo,
                    style: HwahaeTypography.captionSmall.copyWith(
                      color: HwahaeColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: HwahaeColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
