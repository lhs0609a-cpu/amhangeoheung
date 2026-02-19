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
import '../../providers/season_provider.dart';
import '../../data/models/mission_model.dart';
import '../../data/models/season_model.dart';
import '../widgets/mission_visibility_badges.dart';
import '../../../../shared/widgets/grade_progress_widget.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../certification/providers/certification_provider.dart';

class MissionListScreen extends ConsumerStatefulWidget {
  const MissionListScreen({super.key});

  @override
  ConsumerState<MissionListScreen> createState() => _MissionListScreenState();
}

class _MissionListScreenState extends ConsumerState<MissionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedMissionType; // 드롭다운 유형 필터

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2탭으로 간소화
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

  Widget _buildCertificationBanner() {
    final certStatus = ref.watch(certificationStatusProvider);
    return certStatus.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (status) {
        if (status.status == 'certified') return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: HwahaeColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: HwahaeColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.school, size: 18, color: HwahaeColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '미션 지원을 위해 교육 인증이 필요합니다',
                  style: HwahaeTypography.bodySmall.copyWith(
                    color: HwahaeColors.warning,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/certification'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: const Size(48, 32),
                ),
                child: Text(
                  '시작하기',
                  style: HwahaeTypography.labelSmall.copyWith(
                    color: HwahaeColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradeProgressBanner() {
    final profileState = ref.watch(profileProvider);
    final grade = profileState.user?.reviewerInfo?.grade;
    if (grade == null || grade == 'master') return const SizedBox.shrink();

    return GradeProgressWidget(
      currentGrade: grade,
      completedMissions: profileState.stats?.completedMissions ?? 0,
      trustScore: profileState.stats?.trustScore ?? 0.0,
      compact: true,
      onTap: () => context.push('/ranking?tab=reviewer'),
    );
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
        actions: [
          // 유형 드롭다운 필터
          _buildTypeDropdown(),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '가능한 미션'),
            Tab(text: '내 미션'),
          ],
          labelColor: HwahaeColors.primary,
          labelStyle: HwahaeTypography.labelLarge,
          unselectedLabelColor: HwahaeColors.textSecondary,
          unselectedLabelStyle: HwahaeTypography.labelMedium,
          indicatorColor: HwahaeColors.primary,
          indicatorWeight: 3,
        ),
      ),
      body: Column(
        children: [
          _buildCertificationBanner(),
          _buildGradeProgressBanner(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AvailableMissionsTab(onRefresh: _loadData),
                _MyMissionsTab(onRefresh: _loadData),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 미션 유형 드롭다운 필터
  Widget _buildTypeDropdown() {
    final types = <MapEntry<String?, String>>[
      const MapEntry(null, '전체 유형'),
      const MapEntry('visit', '방문'),
      const MapEntry('delivery', '배송'),
      const MapEntry('online', '온라인'),
      const MapEntry('phone', '전화'),
    ];

    return PopupMenuButton<String?>(
      onSelected: (value) {
        setState(() {
          _selectedMissionType = value;
        });
        ref.read(availableMissionsProvider.notifier).loadMissions(type: value);
      },
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedMissionType != null
              ? HwahaeColors.primary.withOpacity(0.1)
              : HwahaeColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 16,
              color: _selectedMissionType != null
                  ? HwahaeColors.primary
                  : HwahaeColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              types.firstWhere((e) => e.key == _selectedMissionType).value,
              style: HwahaeTypography.labelSmall.copyWith(
                color: _selectedMissionType != null
                    ? HwahaeColors.primary
                    : HwahaeColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (_) => types.map((entry) {
        return PopupMenuItem<String?>(
          value: entry.key,
          child: Row(
            children: [
              if (entry.key == _selectedMissionType)
                const Icon(Icons.check, size: 16, color: HwahaeColors.primary)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text(
                entry.value,
                style: HwahaeTypography.bodyMedium.copyWith(
                  fontWeight: entry.key == _selectedMissionType
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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

    final seasonsAsync = ref.watch(activeSeasonsProvider);
    final hiddenAsync = ref.watch(hiddenMissionsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(availableMissionsProvider.notifier).loadMissions();
        ref.invalidate(activeSeasonsProvider);
        ref.invalidate(hiddenMissionsProvider);
      },
      color: HwahaeColors.primary,
      child: CustomScrollView(
        slivers: [
          // 미션 유형 필터 칩
          SliverToBoxAdapter(
            child: _MissionTypeFilterChips(),
          ),

          // 시즌 배너 캐러셀
          seasonsAsync.when(
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (seasons) {
              if (seasons.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
              return SliverToBoxAdapter(
                child: _SeasonBannerCarousel(seasons: seasons),
              );
            },
          ),

          // 히든 미션 섹션
          hiddenAsync.when(
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (response) {
              if (!response.success || response.missions.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: _HiddenMissionsSection(missions: response.missions),
              );
            },
          ),

          // 일반 미션 목록
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final mission = state.missions[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: index < state.missions.length - 1 ? 12 : 0),
                    child: _MissionCard(mission: mission, type: 'available'),
                  );
                },
                childCount: state.missions.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 시즌 배너 캐러셀
class _SeasonBannerCarousel extends StatelessWidget {
  final List<SeasonModel> seasons;

  const _SeasonBannerCarousel({required this.seasons});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        itemCount: seasons.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final season = seasons[index];
          final remaining = season.endAt.difference(DateTime.now());

          return GestureDetector(
            onTap: () => context.push('/seasons/${season.id}'),
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: HwahaeColors.gradientAccent,
                ),
                borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
                boxShadow: [
                  BoxShadow(
                    color: HwahaeColors.accent.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SeasonBadge(),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              remaining.inDays > 0 ? 'D-${remaining.inDays}' : '오늘 마감',
                              style: HwahaeTypography.captionSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    season.name,
                    style: HwahaeTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    season.description ?? '시즌 미션에 참여하고 추가 보상을 받으세요!',
                    style: HwahaeTypography.captionMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 히든 미션 섹션
class _HiddenMissionsSection extends StatelessWidget {
  final List<MissionModel> missions;

  const _HiddenMissionsSection({required this.missions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HiddenBadge(),
              const SizedBox(width: 8),
              Text(
                '히든 미션',
                style: HwahaeTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${missions.length}개',
                style: HwahaeTypography.captionMedium.copyWith(
                  color: HwahaeColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: missions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final mission = missions[index];
                return GestureDetector(
                  onTap: () => context.push('/missions/${mission.id}'),
                  child: GlowContainer(
                    child: Container(
                      width: 180,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: HwahaeColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: HwahaeColors.accent.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lock_open, size: 14, color: HwahaeColors.accent),
                              const SizedBox(width: 4),
                              Text(
                                mission.minReviewerGrade?.toUpperCase() ?? 'GOLD',
                                style: HwahaeTypography.captionSmall.copyWith(
                                  color: HwahaeColors.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              if (mission.bonusRate > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: HwahaeColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '+${(mission.bonusRate * 100).toInt()}%',
                                    style: HwahaeTypography.captionSmall.copyWith(
                                      color: HwahaeColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            mission.business?.name ?? mission.category ?? '히든 미션',
                            style: HwahaeTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatCurrency(mission.reviewerFee)}원',
                            style: HwahaeTypography.captionMedium.copyWith(
                              color: HwahaeColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

// 내 미션 탭 (진행 중 + 완료 통합)
class _MyMissionsTab extends ConsumerStatefulWidget {
  final VoidCallback onRefresh;

  const _MyMissionsTab({required this.onRefresh});

  @override
  ConsumerState<_MyMissionsTab> createState() => _MyMissionsTabState();
}

class _MyMissionsTabState extends ConsumerState<_MyMissionsTab> {
  String _filter = 'all'; // all, ongoing, completed

  @override
  Widget build(BuildContext context) {
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

    final allMissions = [
      ...state.ongoingMissions,
      ...state.completedMissions,
    ];

    final filteredMissions = _filter == 'ongoing'
        ? state.ongoingMissions
        : _filter == 'completed'
            ? state.completedMissions
            : allMissions;

    if (allMissions.isEmpty) {
      return EmptyView(
        title: '내 미션이 없습니다',
        message: '미션에 참여해보세요',
        icon: Icons.assignment_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(myMissionsProvider.notifier).loadMissions();
      },
      color: HwahaeColors.primary,
      child: Column(
        children: [
          // 하위 필터 칩
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('all', '전체 ${allMissions.length}'),
                const SizedBox(width: 8),
                _buildFilterChip('ongoing', '진행 중 ${state.ongoingMissions.length}'),
                const SizedBox(width: 8),
                _buildFilterChip('completed', '완료 ${state.completedMissions.length}'),
              ],
            ),
          ),
          Expanded(
            child: filteredMissions.isEmpty
                ? Center(
                    child: Text(
                      _filter == 'ongoing'
                          ? '진행 중인 미션이 없습니다'
                          : '완료된 미션이 없습니다',
                      style: HwahaeTypography.bodyMedium.copyWith(
                        color: HwahaeColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredMissions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final mission = filteredMissions[index];
                      final isCompleted = state.completedMissions.contains(mission);
                      return _MissionCard(
                        mission: mission,
                        type: isCompleted ? 'completed' : 'ongoing',
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? HwahaeColors.primary.withOpacity(0.1)
              : HwahaeColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: HwahaeColors.primary.withOpacity(0.3))
              : null,
        ),
        child: Text(
          label,
          style: HwahaeTypography.labelSmall.copyWith(
            color: isSelected ? HwahaeColors.primary : HwahaeColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
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

    return Semantics(
      label: '${mission.business?.name ?? mission.category ?? '미션'}, ${statusText}, 페이백 ${_formatCurrency(mission.reviewerFee)}원',
      button: true,
      child: GestureDetector(
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
                if (mission.isHidden) ...[
                  const SizedBox(width: 6),
                  const HiddenBadge(),
                ],
                if (mission.isSeason) ...[
                  const SizedBox(width: 6),
                  const SeasonBadge(),
                ],
                // 미션 유형 배지
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: mission.missionTypeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(mission.missionTypeIcon, size: 12, color: mission.missionTypeColor),
                      const SizedBox(width: 2),
                      Text(
                        mission.missionTypeDisplayName,
                        style: HwahaeTypography.captionSmall.copyWith(
                          color: mission.missionTypeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
        ),
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

// 미션 유형 필터 칩
class _MissionTypeFilterChips extends ConsumerWidget {
  const _MissionTypeFilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(availableMissionsProvider);
    final selectedType = state.typeFilter;

    final types = [
      _TypeFilterData(null, '전체', Icons.apps, HwahaeColors.primary),
      _TypeFilterData('visit', '방문', Icons.store, const Color(0xFF4CAF50)),
      _TypeFilterData('delivery', '배송', Icons.local_shipping, const Color(0xFF2196F3)),
      _TypeFilterData('online', '온라인', Icons.language, const Color(0xFF9C27B0)),
      _TypeFilterData('phone', '전화', Icons.phone, const Color(0xFFFF9800)),
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(0, 12, 0, 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = types[index];
          final isSelected = selectedType == type.value;

          return FilterChip(
            selected: isSelected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(type.icon, size: 16,
                  color: isSelected ? Colors.white : type.color),
                const SizedBox(width: 4),
                Text(type.label),
              ],
            ),
            labelStyle: HwahaeTypography.labelSmall.copyWith(
              color: isSelected ? Colors.white : HwahaeColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            backgroundColor: HwahaeColors.surface,
            selectedColor: type.color,
            side: BorderSide(
              color: isSelected ? type.color : HwahaeColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onSelected: (_) {
              ref.read(availableMissionsProvider.notifier).loadMissions(type: type.value);
            },
          );
        },
      ),
    );
  }
}

class _TypeFilterData {
  final String? value;
  final String label;
  final IconData icon;
  final Color color;

  _TypeFilterData(this.value, this.label, this.icon, this.color);
}
