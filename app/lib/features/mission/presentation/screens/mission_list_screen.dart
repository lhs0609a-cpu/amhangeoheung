import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/hwahae/hwahae_cards.dart';
import '../../providers/mission_provider.dart';
import '../../data/models/mission_model.dart';

class MissionListScreen extends ConsumerStatefulWidget {
  const MissionListScreen({super.key});

  @override
  ConsumerState<MissionListScreen> createState() => _MissionListScreenState();
}

class _MissionListScreenState extends ConsumerState<MissionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() {
    Future.microtask(() {
      ref.read(availableMissionsProvider.notifier).loadMissions();
      ref.read(myMissionsProvider.notifier).loadMissions();
    });
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
        title: Text(
          '미션',
          style: HwahaeTypography.headlineSmall,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '참여 가능'),
            Tab(text: '진행 중'),
            Tab(text: '완료'),
          ],
          labelColor: HwahaeColors.primary,
          labelStyle: HwahaeTypography.labelLarge,
          unselectedLabelColor: HwahaeColors.textSecondary,
          unselectedLabelStyle: HwahaeTypography.labelMedium,
          indicatorColor: HwahaeColors.primary,
          indicatorWeight: 3,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AvailableMissionsTab(onRefresh: _loadData),
          _OngoingMissionsTab(onRefresh: _loadData),
          _CompletedMissionsTab(onRefresh: _loadData),
        ],
      ),
    );
  }
}

// 참여 가능 미션 탭
class _AvailableMissionsTab extends ConsumerWidget {
  final VoidCallback onRefresh;

  const _AvailableMissionsTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(availableMissionsProvider);

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: HwahaeColors.primary),
      );
    }

    if (state.error != null) {
      return ErrorView.fromMessage(
        message: state.error!,
        onRetry: () {
          ref.read(availableMissionsProvider.notifier).loadMissions();
        },
      );
    }

    if (state.missions.isEmpty) {
      return EmptyView(
        title: '참여 가능한 미션이 없습니다',
        message: '새로운 미션이 등록되면 알려드릴게요',
        icon: Icons.flag_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(availableMissionsProvider.notifier).loadMissions();
      },
      color: HwahaeColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.missions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final mission = state.missions[index];
          return _MissionCard(mission: mission, type: 'available');
        },
      ),
    );
  }
}

// 진행 중 미션 탭
class _OngoingMissionsTab extends ConsumerWidget {
  final VoidCallback onRefresh;

  const _OngoingMissionsTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myMissionsProvider);

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: HwahaeColors.primary),
      );
    }

    if (state.error != null) {
      return ErrorView.fromMessage(
        message: state.error!,
        onRetry: () {
          ref.read(myMissionsProvider.notifier).loadMissions();
        },
      );
    }

    final ongoingMissions = state.ongoingMissions;

    if (ongoingMissions.isEmpty) {
      return EmptyView(
        title: '진행 중인 미션이 없습니다',
        message: '미션에 참여해보세요',
        icon: Icons.assignment_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(myMissionsProvider.notifier).loadMissions();
      },
      color: HwahaeColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: ongoingMissions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final mission = ongoingMissions[index];
          return _MissionCard(mission: mission, type: 'ongoing');
        },
      ),
    );
  }
}

// 완료 미션 탭
class _CompletedMissionsTab extends ConsumerWidget {
  final VoidCallback onRefresh;

  const _CompletedMissionsTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myMissionsProvider);

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: HwahaeColors.primary),
      );
    }

    if (state.error != null) {
      return ErrorView.fromMessage(
        message: state.error!,
        onRetry: () {
          ref.read(myMissionsProvider.notifier).loadMissions();
        },
      );
    }

    final completedMissions = state.completedMissions;

    if (completedMissions.isEmpty) {
      return EmptyView(
        title: '완료된 미션이 없습니다',
        message: '미션을 완료하면 여기에 표시됩니다',
        icon: Icons.check_circle_outline,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(myMissionsProvider.notifier).loadMissions();
      },
      color: HwahaeColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: completedMissions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final mission = completedMissions[index];
          return _MissionCard(mission: mission, type: 'completed');
        },
      ),
    );
  }
}

// 미션 카드 위젯
class _MissionCard extends StatelessWidget {
  final MissionModel mission;
  final String type;

  const _MissionCard({
    required this.mission,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = type == 'completed';
    final isOngoing = type == 'ongoing';

    Color statusColor;
    String statusText;

    if (isCompleted) {
      statusColor = HwahaeColors.success;
      statusText = '완료';
    } else if (isOngoing) {
      statusColor = HwahaeColors.warning;
      statusText = '진행중';
    } else {
      statusColor = HwahaeColors.primary;
      statusText = '모집중';
    }

    return GestureDetector(
      onTap: () => context.push('/missions/${mission.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HwahaeColors.surface,
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          border: Border.all(color: HwahaeColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상태 뱃지 + 마감일
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: HwahaeTypography.captionMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                if (!isCompleted && mission.daysUntilDeadline != null)
                  _buildDeadlineBadge(mission.daysUntilDeadline!),
              ],
            ),
            const SizedBox(height: 12),

            // 업체 정보
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: HwahaeColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(mission.category),
                    color: HwahaeColors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.business?.name ?? mission.category ?? '미션',
                        style: HwahaeTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${mission.region ?? '지역 미정'} • ${mission.category ?? ''}',
                        style: HwahaeTypography.captionMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // 보상 + 액션
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.payment,
                      size: 16,
                      color: HwahaeColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '페이백 ${_formatCurrency(mission.reviewerFee)}원',
                      style: HwahaeTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: HwahaeColors.primary,
                      ),
                    ),
                  ],
                ),
                _buildActionButton(context, isOngoing, isCompleted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineBadge(int days) {
    final isUrgent = days <= 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent
            ? HwahaeColors.error.withOpacity(0.1)
            : HwahaeColors.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUrgent)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.schedule,
                size: 12,
                color: HwahaeColors.error,
              ),
            ),
          Text(
            days == 0 ? '오늘 마감' : 'D-$days',
            style: HwahaeTypography.captionMedium.copyWith(
              color: isUrgent ? HwahaeColors.error : HwahaeColors.textSecondary,
              fontWeight: isUrgent ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, bool isOngoing, bool isCompleted) {
    if (isOngoing) {
      return TextButton(
        onPressed: () => context.push('/write-review/${mission.id}'),
        child: Text(
          '리뷰 작성',
          style: HwahaeTypography.labelMedium.copyWith(
            color: HwahaeColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (isCompleted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            color: HwahaeColors.success,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '리뷰 제출 완료',
            style: HwahaeTypography.captionMedium.copyWith(
              color: HwahaeColors.success,
            ),
          ),
        ],
      );
    }

    // 참여 가능
    final current = mission.currentApplicants ?? 0;
    final max = mission.maxApplicants ?? 20;

    return Text(
      '$current/$max명 신청',
      style: HwahaeTypography.captionMedium.copyWith(
        color: HwahaeColors.textSecondary,
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case '음식점':
      case '한식':
      case '일식':
      case '중식':
        return Icons.restaurant;
      case '카페':
        return Icons.local_cafe;
      case '뷰티':
        return Icons.face;
      case '건강':
        return Icons.fitness_center;
      case '레저':
        return Icons.sports_tennis;
      case '교육':
        return Icons.school;
      default:
        return Icons.storefront;
    }
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
