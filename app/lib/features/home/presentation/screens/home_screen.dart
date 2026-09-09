import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/business_categories.dart';
import '../../../../core/providers/user_type_provider.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';
import '../../../review/data/models/review_model.dart';
import '../../providers/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) _load();
    });
  }

  Future<void> _load() => ref.read(homeDataProvider.notifier).loadHomeData(
      includeMissions: ref.read(userTypeProvider) == UserType.reviewer);

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(homeDataProvider);
    final role = ref.watch(userTypeProvider);
    ref.listen(userTypeProvider, (previous, next) {
      if (previous != next) _load();
    });
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      body: AppLayout.constrain(RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: HwahaeColors.background,
              surfaceTintColor: HwahaeColors.background,
              title: Text('암행어흥', style: HwahaeTypography.headlineSmall),
              actions: [
                IconButton(
                  tooltip: '알림',
                  onPressed: () => context.push('/notifications'),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverPadding(
              padding:
                  EdgeInsets.symmetric(horizontal: AppLayout.gutterOf(context)),
              sliver: SliverList.list(children: [
                const SizedBox(height: 12),
                Text(
                  switch (role) {
                    UserType.consumer => '좋은 가게를 고르는\n새로운 기준',
                    UserType.reviewer => '직접 보고,\n있는 그대로 기록해요',
                    UserType.business => '고객의 경험에서\n다음 변화를 찾아요',
                  },
                  style: HwahaeTypography.headlineLarge,
                ),
                const SizedBox(height: 10),
                Text('좋았던 점도, 아쉬운 점도. 감찰 기록으로 확인하세요.',
                    style: HwahaeTypography.bodyMedium
                        .copyWith(color: HwahaeColors.textSecondary)),
                const SizedBox(height: 22),
                if (role == UserType.consumer) ...[
                  _search(),
                  const SizedBox(height: 16),
                  _categories(data),
                  const SizedBox(height: 20),
                  _welcome(),
                ] else ...[
                  _roleActions(role),
                  const SizedBox(height: 20),
                  _categories(data),
                ],
                if (role == UserType.reviewer) ..._missions(data),
                const SizedBox(height: AppLayout.sectionGap),
                _heading('최근 공개된 감찰', '좋았던 점과 아쉬운 점을 함께 읽어보세요.',
                    () => context.go('/reviews')),
                const SizedBox(height: 12),
                if (data.isLoading)
                  const DiscoveryLoading(label: '감찰 목록 불러오는 중')
                else if (data.reviewsError != null)
                  _retry(data.reviewsError!)
                else if (data.recentReviews.isEmpty)
                  _empty('아직 공개된 감찰이 없어요', '다른 업종의 기록을 살펴보세요.', data)
                else
                  ...data.recentReviews.map((review) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DiscoveryReviewCard(
                            review: review,
                            onTap: () => context.push(
                                '/reviews/${Uri.encodeComponent(review.id)}')),
                      )),
                const SizedBox(height: 16),
                _heading(
                    '지역별 ${data.selectedCategory} 랭킹',
                    '월간 지역별 순위예요. 지역은 상세에서 골라보세요.',
                    () => context.push(
                            Uri(path: '/ranking/regional', queryParameters: {
                          if (data.selectedCategory != '전체')
                            'category': data.selectedCategory,
                        }).toString())),
                const SizedBox(height: 12),
                if (data.isLoading)
                  const DiscoveryLoading(label: '랭킹 불러오는 중')
                else if (data.rankingsError != null)
                  _retry(data.rankingsError!)
                else if (data.topBusinesses.isEmpty)
                  _empty('아직 랭킹 정보가 없어요', '가게 이름으로 감찰 기록을 찾아보세요.', data)
                else
                  ...data.topBusinesses
                      .where((b) => b.businessId?.isNotEmpty == true)
                      .map((business) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              style: AppCardStyle.outlined,
                              onTap: () => context.push(
                                  '/trust/${Uri.encodeComponent(business.businessId!)}'),
                              child: Row(children: [
                                SizedBox(
                                    width: 32,
                                    child: Text(
                                        business.rank > 0
                                            ? '${business.rank}'
                                            : '—',
                                        style: HwahaeTypography.titleLarge)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(business.businessName ?? '업체명 미제공',
                                          style: HwahaeTypography.titleSmall),
                                      const SizedBox(height: 5),
                                      Text(
                                          [
                                            business.region,
                                            business.category,
                                            if (business.reviewCount != null)
                                              '리뷰 ${business.reviewCount}개'
                                          ]
                                              .whereType<String>()
                                              .where((v) => v.isNotEmpty)
                                              .join(' · '),
                                          style:
                                              HwahaeTypography.captionMedium),
                                    ])),
                                const Icon(Icons.chevron_right_rounded,
                                    color: HwahaeColors.textTertiary),
                              ]),
                            ),
                          )),
                const SizedBox(height: 18),
                Text('리뷰의 평가와 방문 자료 확인은 서로 다른 정보예요.\n가게의 장단점과 확인 범위를 함께 살펴보세요.',
                    style: HwahaeTypography.captionMedium
                        .copyWith(color: HwahaeColors.textSecondary)),
              ]),
            ),
            const SliverBottomSpacer(),
          ],
        ),
      )),
    );
  }

  Widget _search() => Pressable(
        semanticLabel: '가게 이름으로 검색',
        onTap: () => context.go('/search'),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: HwahaeColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HwahaeColors.borderStrong),
          ),
          child: Row(children: [
            const Icon(Icons.search_rounded),
            const SizedBox(width: 12),
            Expanded(
                child:
                    Text('어떤 가게가 궁금하세요?', style: HwahaeTypography.bodyMedium)),
          ]),
        ),
      );

  Widget _categories(HomeDataState data) => Wrap(
        spacing: 8,
        runSpacing: 4,
        children: businessCategories
            .map((category) => ChoiceChip(
                  label: Text(category),
                  selected: data.selectedCategory == category,
                  showCheckmark: false,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  selectedColor: HwahaeColors.primary,
                  labelStyle: HwahaeTypography.bodySmall
                      .copyWith(color: HwahaeColors.textPrimary),
                  onSelected: (_) =>
                      ref.read(homeDataProvider.notifier).setCategory(category),
                ))
            .toList(),
      );

  Widget _welcome() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: HwahaeColors.primaryContainer,
            borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('별점 너머의 이야기를\n만나보세요', style: HwahaeTypography.titleLarge),
                const SizedBox(height: 8),
                Text('직접 남긴 관찰과\n업체의 답변을 한곳에서.',
                    style: HwahaeTypography.bodySmall),
              ])),
          const SizedBox(width: 8),
          const ExcludeSemantics(child: AppMascot.eoheung(size: 90)),
        ]),
      );

  Widget _roleActions(UserType role) {
    final actions = role == UserType.reviewer
        ? [
            ('내 진행 감찰', Icons.assignment_outlined, '/my-activity'),
            ('정산 내역', Icons.account_balance_wallet_outlined, '/settlements'),
            ('교육과 인증', Icons.school_outlined, '/certification')
          ]
        : [
            ('업체 대시보드', Icons.dashboard_outlined, '/dashboard'),
            ('감찰 의뢰', Icons.add_task_rounded, '/missions/create'),
            ('공개 전 답변', Icons.forum_outlined, '/preview-reviews')
          ];
    return Column(
        children: actions
            .map((action) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                      style: AppCardStyle.outlined,
                      onTap: () => context.push(action.$3),
                      child: Row(children: [
                        Icon(action.$2),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(action.$1,
                                style: HwahaeTypography.titleSmall)),
                        const Icon(Icons.chevron_right_rounded)
                      ])),
                ))
            .toList());
  }

  List<Widget> _missions(HomeDataState data) => [
        const SizedBox(height: 24),
        _heading(
            '모집 중인 감찰', '배정 전에는 업체명이 공개되지 않아요.', () => context.go('/missions')),
        const SizedBox(height: 12),
        if (data.isLoading)
          const DiscoveryLoading(label: '감찰 모집 불러오는 중')
        else if (data.missionsError != null)
          _retry(data.missionsError!)
        else if (data.availableMissions.isEmpty)
          _empty('지금은 모집 중인 감찰이 없어요', '다른 업종도 확인해 보세요.', data)
        else
          ...data.availableMissions.map((mission) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                    style: AppCardStyle.outlined,
                    onTap: () => context
                        .push('/missions/${Uri.encodeComponent(mission.id)}'),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.lock_outline_rounded, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    '${mission.category ?? '업종 미정'} · ${mission.region ?? '지역 미정'}',
                                    style: HwahaeTypography.titleSmall))
                          ]),
                          const SizedBox(height: 10),
                          Text(mission.rewardDisplayText,
                              style: HwahaeTypography.titleMedium),
                          if (mission.recruitmentDeadline != null) ...[
                            const SizedBox(height: 6),
                            Text(
                                '모집 마감 ${DateFormat('M월 d일').format(mission.recruitmentDeadline!.toLocal())}',
                                style: HwahaeTypography.bodySmall),
                          ],
                          const SizedBox(height: 8),
                          Text('수행 조건과 보상 상세 보기',
                              style: HwahaeTypography.bodySmall),
                        ])),
              )),
      ];

  Widget _heading(String title, String subtitle, VoidCallback onTap) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(title, style: HwahaeTypography.titleLarge)),
            IconButton(
                tooltip: '$title 전체 보기',
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward_rounded))
          ]),
          Text(subtitle,
              style: HwahaeTypography.bodySmall
                  .copyWith(color: HwahaeColors.textSecondary)),
        ],
      );

  Widget _retry(String message) => AppCard(
      style: AppCardStyle.outlined,
      child: Semantics(
          liveRegion: true,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(message, style: HwahaeTypography.bodyMedium),
            const SizedBox(height: 8),
            TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('다시 시도')),
          ])));

  Widget _empty(String title, String message, HomeDataState data) => AppCard(
        style: AppCardStyle.outlined,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: HwahaeTypography.titleSmall),
          const SizedBox(height: 8),
          Text(message, style: HwahaeTypography.bodySmall),
          const SizedBox(height: 8),
          TextButton(
              onPressed: () {
                if (data.selectedCategory != '전체') {
                  ref.read(homeDataProvider.notifier).setCategory('전체');
                } else {
                  context.go('/search');
                }
              },
              child:
                  Text(data.selectedCategory != '전체' ? '전체 업종 보기' : '가게 검색하기')),
        ]),
      );
}

class DiscoveryLoading extends StatelessWidget {
  const DiscoveryLoading({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
      label: label,
      liveRegion: true,
      child: AppCard(
          style: AppCardStyle.outlined,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: HwahaeTypography.bodySmall),
            const SizedBox(height: 16),
            const LinearProgressIndicator(minHeight: 3),
          ])));
}

/// 원문 장단점을 같은 카드에 보존한다. 공개 상태는 방문 인증을 뜻하지 않는다.
class DiscoveryReviewCard extends StatelessWidget {
  const DiscoveryReviewCard(
      {super.key, required this.review, required this.onTap});
  final ReviewModel review;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        style: AppCardStyle.outlined,
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8, runSpacing: 4, children: [
            if (review.business?.category != null)
              Text(review.business!.category!,
                  style: HwahaeTypography.captionMedium),
            if (review.business?.addressCity != null)
              Text(review.business!.addressCity!,
                  style: HwahaeTypography.captionMedium),
            if (review.publishedAt != null)
              Text(
                  '${DateFormat('yy.MM.dd').format(review.publishedAt!.toLocal())} 공개',
                  style: HwahaeTypography.captionMedium),
          ]),
          const SizedBox(height: 8),
          Text(review.business?.name ?? '업체명 미제공',
              style: HwahaeTypography.titleLarge),
          if (review.summary?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(review.summary!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: HwahaeTypography.bodyMedium),
          ],
          const SizedBox(height: 16),
          _observation('좋았던 점', review.pros, false),
          const SizedBox(height: 8),
          _observation('아쉬운 점', review.cons, true),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: Text('원문과 평가 근거 보기', style: HwahaeTypography.bodySmall)),
            const Icon(Icons.arrow_forward_rounded, size: 18),
          ]),
        ]),
      );

  Widget _observation(String label, List<String> entries, bool concern) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: concern
              ? HwahaeColors.secondaryContainer
              : HwahaeColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: HwahaeTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: concern
                      ? HwahaeColors.onSecondaryContainer
                      : HwahaeColors.textPrimary)),
          const SizedBox(height: 4),
          Text(entries.isEmpty ? '작성된 내용이 없어요' : entries.first,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: HwahaeTypography.bodySmall
                  .copyWith(color: HwahaeColors.textPrimary)),
          if (entries.length > 1)
            Text('외 ${entries.length - 1}건 · 원문에서 확인',
                style: HwahaeTypography.captionMedium),
        ]),
      );
}
