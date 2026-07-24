import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/hwahae/hwahae_cards.dart';

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

class PortfolioScreen extends ConsumerWidget {
  final String userId;

  const PortfolioScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioProvider(userId));

    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('포트폴리오', style: HwahaeTypography.titleMedium),
      ),
      body: portfolioAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: HwahaeColors.primary)),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: HwahaeColors.textTertiary),
              const SizedBox(height: 16),
              Text('포트폴리오를 불러올 수 없습니다', style: HwahaeTypography.bodyMedium),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(portfolioProvider(userId)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (data) {
          final profile = data?['reviewer'] ?? {};
          final reviews = data?['reviews'] as List? ?? [];

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(portfolioProvider(userId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // 프로필 헤더
                  Container(
                    padding: const EdgeInsets.all(24),
                    color: HwahaeColors.surface,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: HwahaeColors.primaryContainer,
                          backgroundImage: profile['profile_image'] != null
                              ? NetworkImage(profile['profile_image'])
                              : null,
                          child: profile['profile_image'] == null
                              ? const Icon(Icons.person, size: 48, color: HwahaeColors.primary)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile['nickname'] ?? profile['name'] ?? '리뷰어',
                          style: HwahaeTypography.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        if (profile['reviewer_grade'] != null)
                          HwahaeGradeBadge(
                            grade: profile['reviewer_grade'],
                            showLabel: true,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 통계
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: HwahaeColors.surface,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('완료 미션', '${profile['completed_missions'] ?? 0}'),
                        _buildStat('작성 리뷰', '${reviews.length}'),
                        _buildStat('신뢰도', '${profile['trust_score'] ?? 0}%'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 전문 분야
                  if ((profile['specialties'] as List?)?.isNotEmpty == true)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: HwahaeColors.surface,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('전문 분야', style: HwahaeTypography.titleMedium),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (profile['specialties'] as List)
                                .map((s) => Chip(
                                      label: Text(s.toString()),
                                      backgroundColor: HwahaeColors.primaryContainer,
                                      labelStyle: HwahaeTypography.labelSmall.copyWith(
                                        color: HwahaeColors.primary,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  // 리뷰 목록
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: HwahaeColors.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('작성한 리뷰', style: HwahaeTypography.titleMedium),
                        const SizedBox(height: 16),
                        if (reviews.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                '아직 작성한 리뷰가 없습니다',
                                style: HwahaeTypography.bodyMedium.copyWith(
                                  color: HwahaeColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        else
                          ...reviews.map((review) => _buildReviewItem(review)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: HwahaeTypography.headlineMedium),
        const SizedBox(height: 4),
        Text(
          label,
          style: HwahaeTypography.captionMedium.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem(dynamic review) {
    final json = review as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: HwahaeColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                json['business']?['name'] ?? '업체',
                style: HwahaeTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              HwahaeRatingBadge(rating: (json['overall_score'] ?? 0).toDouble()),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            json['content'] ?? '',
            style: HwahaeTypography.bodySmall.copyWith(color: HwahaeColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
