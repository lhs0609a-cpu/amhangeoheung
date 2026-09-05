import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';

/// 포트폴리오 데이터 Provider
final portfolioProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  try {
    // 리뷰어의 공개 프로필 조회
    final response = await ApiClient.instance.dio.get('/users/$userId/portfolio');
    final data = response.data;
    if (data['success'] == true) {
      return data['data'];
    }
  } catch (_) {}
  return null;
});

/// 리뷰어의 공개 포트폴리오.
///
/// 남이 보는 화면이다. 감찰관 본인의 신원은 드러나지 않아야 하므로
/// 여기에 실명·연락처·소속 업체는 올리지 않는다.
class PortfolioScreen extends ConsumerWidget {
  final String userId;

  const PortfolioScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioProvider(userId));

    return AppScreen(
      title: '포트폴리오',
      onRefresh: () async => ref.refresh(portfolioProvider(userId).future),
      child: portfolioAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: 120),
          child: Center(
            child: CircularProgressIndicator(color: HwahaeColors.primary),
          ),
        ),
        error: (error, stack) => AppErrorState(
          message: '포트폴리오를 불러올 수 없습니다',
          onRetry: () => ref.invalidate(portfolioProvider(userId)),
        ),
        data: (data) {
          if (data == null) {
            return AppErrorState(
              message: '포트폴리오를 불러올 수 없습니다',
              onRetry: () => ref.invalidate(portfolioProvider(userId)),
            );
          }

          final profile = (data['reviewer'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{};
          final reviews = data['reviews'] as List? ?? const [];
          final specialties = profile['specialties'] as List? ?? const [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _Header(profile: profile),
              const SizedBox(height: AppLayout.cardGap),
              Row(
                children: [
                  Expanded(
                    child: AppStatTile(
                      label: '완료 미션',
                      value: '${profile['completed_missions'] ?? 0}',
                      caption: '건',
                    ),
                  ),
                  const SizedBox(width: AppLayout.cardGap),
                  Expanded(
                    child: AppStatTile(
                      label: '작성 리뷰',
                      value: '${reviews.length}',
                      caption: '건',
                    ),
                  ),
                  const SizedBox(width: AppLayout.cardGap),
                  Expanded(
                    child: AppStatTile(
                      label: '신뢰도',
                      value: '${profile['trust_score'] ?? 0}%',
                      accent: HwahaeColors.accent,
                    ),
                  ),
                ],
              ),
              if (specialties.isNotEmpty)
                AppSection(
                  title: '전문 분야',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in specialties)
                        AppChip(label: s.toString(), selected: true),
                    ],
                  ),
                ),
              AppSection(
                title: '작성한 리뷰',
                subtitle: reviews.isEmpty ? null : '${reviews.length}건',
                child: reviews.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.rate_review_outlined,
                        title: '아직 공개된 리뷰가 없네',
                        compact: true,
                      )
                    : Column(
                        children: [
                          for (final review in reviews)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppLayout.cardGap,
                              ),
                              child: _ReviewItem(
                                review: (review as Map).cast<String, dynamic>(),
                              ),
                            ),
                        ],
                      ),
              ),
              const AppBottomSpacer.plain(),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final image = profile['profile_image'] as String?;
    final grade = profile['reviewer_grade'] as String?;

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: HwahaeColors.primaryContainer,
            backgroundImage: image != null ? NetworkImage(image) : null,
            child: image == null
                ? const AppMascot.sato(size: 62)
                : null,
          ),
          const SizedBox(height: 14),
          Text(
            profile['nickname'] ?? profile['name'] ?? '리뷰어',
            style: HwahaeTypography.headlineSmall,
          ),
          if (grade != null) ...[
            const SizedBox(height: 8),
            AppBadge.grade(grade, compact: false),
          ],
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({required this.review});

  final Map<String, dynamic> review;

  @override
  Widget build(BuildContext context) {
    final business = (review['business'] as Map?)?.cast<String, dynamic>();
    final content = review['content'] as String? ?? '';

    return AppCard(
      style: AppCardStyle.outlined,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  business?['name'] ?? '업체',
                  style: HwahaeTypography.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppBadge.rating(
                (review['overall_score'] as num?)?.toDouble() ?? 0,
              ),
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              content,
              style: HwahaeTypography.bodySmall.copyWith(
                color: HwahaeColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
