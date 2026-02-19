import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../../../core/utils/map_launcher.dart';
import '../../../../shared/widgets/hwahae/hwahae_buttons.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../providers/mission_provider.dart';
import '../../providers/location_provider.dart';
import '../../data/models/mission_model.dart';
import '../../data/repositories/mission_repository.dart';

class MissionDetailScreen extends ConsumerWidget {
  final String missionId;

  const MissionDetailScreen({super.key, required this.missionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionAsync = ref.watch(missionDetailProvider(missionId));

    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text(
          '미션 상세',
          style: HwahaeTypography.titleMedium,
        ),
      ),
      body: missionAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: HwahaeColors.primary),
        ),
        error: (error, stack) => ErrorView.fromMessage(
          message: error.toString(),
          onRetry: () => ref.invalidate(missionDetailProvider(missionId)),
        ),
        data: (response) {
          if (!response.success || response.mission == null) {
            return ErrorView(
              errorType: ErrorType.notFound,
              errorMessage: response.message ?? '미션을 찾을 수 없습니다',
              onRetry: () => ref.invalidate(missionDetailProvider(missionId)),
            );
          }
          return _MissionDetailContent(mission: response.mission!);
        },
      ),
    );
  }
}

class _MissionDetailContent extends ConsumerStatefulWidget {
  final MissionModel mission;

  const _MissionDetailContent({required this.mission});

  @override
  ConsumerState<_MissionDetailContent> createState() => _MissionDetailContentState();
}

class _MissionDetailContentState extends ConsumerState<_MissionDetailContent> {
  MissionModel get mission => widget.mission;
  Timer? _stayTimer;

  @override
  void initState() {
    super.initState();
    // Start periodic timer for in_progress missions
    if (mission.status == 'in_progress') {
      _stayTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _stayTimer?.cancel();
    super.dispose();
  }

  /// Calculate stay duration since check-in
  Duration? _getStayDuration() {
    if (mission.checkInTime == null) return null;
    return DateTime.now().difference(mission.checkInTime!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              // 상단 고정: 업체명 + 보상금액 + 상태 (쿠팡 상품 상세 스타일)
              SliverToBoxAdapter(child: _buildStickyHeader()),

              // 진행 상태 Stepper
              SliverToBoxAdapter(child: _buildMissionStepper()),

              // 접기/펴기 섹션들 (ExpansionTile)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // 미션 안내 (접기)
                      _buildExpandableSection(
                        title: '미션 안내 (${mission.missionTypeDisplayName})',
                        icon: Icons.assignment_outlined,
                        initiallyExpanded: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...mission.verificationRequirements.asMap().entries.map((entry) =>
                              _buildMissionStep('${entry.key + 1}', entry.value),
                            ),
                            _buildMissionStep(
                              '${mission.verificationRequirements.length + 1}',
                              '정형화된 리뷰 작성 (단점 1개 이상 필수)',
                            ),
                          ],
                        ),
                      ),

                      // 평가 항목 (접기)
                      _buildExpandableSection(
                        title: '평가 항목',
                        icon: Icons.star_outline_rounded,
                        child: Column(
                          children: [
                            _buildEvaluationItem('대기 시간', '입장부터 서비스까지 시간 측정'),
                            _buildEvaluationItem('서비스 품질', '서비스 품질 평가'),
                            _buildEvaluationItem('청결도', '테이블, 바닥, 화장실'),
                            _buildEvaluationItem('직원 응대', '인사, 친절도, 불만 대응'),
                            _buildEvaluationItem('가성비', '가격 대비 만족도'),
                          ],
                        ),
                      ),

                      // 주의사항 (접기)
                      _buildExpandableSection(
                        title: '주의사항',
                        icon: Icons.warning_amber_rounded,
                        child: _buildWarningContent(),
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 하단 CTA
        _buildBottomCTA(context, ref),
      ],
    );
  }

  /// 상단 고정 헤더: 업체명 + 보상금액 + 상태 + 카테고리
  Widget _buildStickyHeader() {
    final statusInfo = _getStatusInfo();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        border: Border(
          bottom: BorderSide(color: HwahaeColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리 & 지역 & 상태
          Row(
            children: [
              _buildInfoChip(
                _getCategoryIcon(mission.category),
                mission.category ?? '기타',
              ),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.location_on, mission.region ?? '지역 미정'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusInfo.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusInfo.label,
                  style: HwahaeTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 업체명
          Text(
            mission.business?.name ?? mission.category ?? '미션',
            style: HwahaeTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // 보상 금액 (강조)
          _buildRewardCard(),
        ],
      ),
    );
  }

  /// 미션 진행 상태 수평 Stepper
  Widget _buildMissionStepper() {
    final steps = ['모집중', '배정', '진행', '심사', '완료'];
    final statusMap = {
      'recruiting': 0,
      'assigned': 1,
      'in_progress': 2,
      'review_submitted': 3,
      'completed': 4,
    };
    final currentStep = statusMap[mission.status] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // 연결선
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentStep;
            return Expanded(
              child: Container(
                height: 3,
                color: isCompleted ? HwahaeColors.success : HwahaeColors.border,
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isActive = stepIndex == currentStep;
          final isCompleted = stepIndex < currentStep;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isActive
                      ? HwahaeColors.primary
                      : isCompleted
                          ? HwahaeColors.success
                          : HwahaeColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : isActive
                          ? Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[stepIndex],
                style: HwahaeTypography.captionSmall.copyWith(
                  color: isActive
                      ? HwahaeColors.primary
                      : isCompleted
                          ? HwahaeColors.success
                          : HwahaeColors.textTertiary,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 10,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// 접기/펴기 섹션 위젯
  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required Widget child,
    bool initiallyExpanded = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
        border: Border.all(color: HwahaeColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(icon, color: HwahaeColors.primary, size: 22),
          title: Text(
            title,
            style: HwahaeTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [child],
        ),
      ),
    );
  }

  /// 주의사항 내용 (ExpansionTile 내부용)
  Widget _buildWarningContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.warningLight,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusSM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWarningItem('미션 수행 중 신분이 노출되면 미션이 무효됩니다'),
          _buildWarningItem('영수증은 반드시 보관해주세요'),
          _buildWarningItem('미션 기한 내 리뷰를 제출해야 보상이 지급됩니다'),
          _buildWarningItem('허위/부실 리뷰는 패널티 사유가 됩니다'),
        ],
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: HwahaeColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: HwahaeTypography.bodySmall.copyWith(
                color: HwahaeColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final statusInfo = _getStatusInfo();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusInfo.color.withOpacity(0.15),
            statusInfo.color.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: statusInfo.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusInfo.label,
              style: HwahaeTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            statusInfo.subtitle,
            style: HwahaeTypography.bodyMedium.copyWith(
              color: statusInfo.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  _StatusInfo _getStatusInfo() {
    switch (mission.status) {
      case 'recruiting':
        final days = mission.daysUntilDeadline ?? 0;
        return _StatusInfo(
          label: '리뷰어 모집중',
          subtitle: days > 0 ? '마감까지 $days일 남음' : '오늘 마감',
          color: HwahaeColors.primary,
        );
      case 'assigned':
        return _StatusInfo(
          label: '미션 배정됨',
          subtitle: '업체 정보가 공개되었습니다',
          color: HwahaeColors.info,
        );
      case 'in_progress':
        return _StatusInfo(
          label: '미션 진행중',
          subtitle: mission.missionType == 'visit'
              ? '방문 후 리뷰를 작성해주세요'
              : '미션 수행 후 리뷰를 작성해주세요',
          color: HwahaeColors.warning,
        );
      case 'review_submitted':
        return _StatusInfo(
          label: '리뷰 심사중',
          subtitle: '리뷰가 검토되고 있습니다',
          color: HwahaeColors.secondary,
        );
      case 'completed':
        return _StatusInfo(
          label: '미션 완료',
          subtitle: '보상이 지급되었습니다',
          color: HwahaeColors.success,
        );
      default:
        return _StatusInfo(
          label: '미션 상태',
          subtitle: '',
          color: HwahaeColors.textSecondary,
        );
    }
  }

  Widget _buildRewardCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
        border: Border.all(color: HwahaeColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: HwahaeColors.successLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payments,
              color: HwahaeColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '페이백 금액',
                style: HwahaeTypography.captionLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatCurrency(mission.reviewerFee)}원',
                style: HwahaeTypography.headlineSmall.copyWith(
                  color: HwahaeColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HwahaeColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: HwahaeColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: HwahaeTypography.labelSmall.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: HwahaeColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: HwahaeTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: HwahaeTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: HwahaeColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: HwahaeTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: HwahaeTypography.captionLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.warningLight,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: HwahaeColors.warning),
              const SizedBox(width: 8),
              Text(
                '주의사항',
                style: HwahaeTypography.titleSmall.copyWith(
                  color: HwahaeColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• 업체와 개인 연락 시 계정 정지\n'
            '• 최소 30분 이상 체류 필수\n'
            '• 미션 배정 후 3일 이내 방문\n'
            '• 영수증 미첨부 시 페이백 불가',
            style: HwahaeTypography.bodySmall.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCTA(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: _buildCTAByStatus(context, ref),
      ),
    );
  }

  Widget _buildCTAByStatus(BuildContext context, WidgetRef ref) {
    switch (mission.status) {
      case 'recruiting':
        return _buildRecruitingCTA(context, ref);
      case 'assigned':
        return _buildAssignedCTA(context, ref);
      case 'in_progress':
        return _buildInProgressCTA(context);
      case 'review_submitted':
        return _buildReviewSubmittedCTA(context);
      case 'completed':
        return _buildCompletedCTA(context);
      default:
        return _buildRecruitingCTA(context, ref);
    }
  }

  // 모집중 - 신청하기 버튼
  Widget _buildRecruitingCTA(BuildContext context, WidgetRef ref) {
    final current = mission.currentApplicants ?? 0;
    final max = mission.maxApplicants ?? 20;

    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '현재 신청자',
                style: HwahaeTypography.captionMedium,
              ),
              Text(
                '$current / $max명',
                style: HwahaeTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: HwahaePrimaryButton(
            text: '미션 신청',
            onPressed: () => _showApplyDialog(context, ref),
          ),
        ),
      ],
    );
  }

  // 배정됨 - 체크인 버튼
  Widget _buildAssignedCTA(BuildContext context, WidgetRef ref) {
    final visitDeadline = mission.visitDeadline;
    final daysUntilDeadline = mission.daysUntilVisitDeadline;
    final hoursUntilDeadline = mission.hoursUntilVisitDeadline;
    final isVisitMission = mission.missionType == 'visit';
    final needsGps = isVisitMission && mission.gpsRequired;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 업체 정보 공개 안내
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: HwahaeColors.infoLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(mission.missionTypeIcon, color: HwahaeColors.info, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${mission.business?.name ?? "업체"} - ${mission.business?.address ?? "주소 확인 필요"}',
                      style: HwahaeTypography.bodySmall.copyWith(
                        color: HwahaeColors.info,
                      ),
                    ),
                  ),
                ],
              ),
              if (visitDeadline != null && daysUntilDeadline != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event, color: HwahaeColors.info, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        daysUntilDeadline > 0
                            ? '미션 기한: ${daysUntilDeadline}일 남음 (3일 이내 수행 필수)'
                            : hoursUntilDeadline != null && hoursUntilDeadline > 0
                                ? '미션 기한: ${hoursUntilDeadline}시간 남음'
                                : '미션 기한 만료 임박!',
                        style: HwahaeTypography.bodySmall.copyWith(
                          color: HwahaeColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              // 미션 유형별 인증 요구사항 안내
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.checklist, color: HwahaeColors.info, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '인증: ${mission.verificationRequirements.join(", ")}',
                      style: HwahaeTypography.bodySmall.copyWith(
                        color: HwahaeColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // GPS 필요한 방문 미션: 위치 보기 + 체크인 버튼
        if (needsGps)
          Row(
            children: [
              Expanded(
                child: HwahaeSecondaryButton(
                  text: '위치 보기',
                  icon: Icons.map,
                  onPressed: () => _openMapLocation(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: HwahaePrimaryButton(
                  text: '체크인 하기',
                  icon: Icons.location_on,
                  onPressed: () => _showCheckInWithVerification(context, ref),
                ),
              ),
            ],
          )
        // GPS 불필요한 방문 미션: 위치 보기 (선택) + 미션 시작
        else if (isVisitMission)
          Row(
            children: [
              Expanded(
                child: HwahaeSecondaryButton(
                  text: '위치 보기',
                  icon: Icons.map,
                  onPressed: () => _openMapLocation(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: HwahaePrimaryButton(
                  text: '미션 시작',
                  icon: Icons.play_arrow,
                  onPressed: () => _startMissionWithoutGps(context, ref),
                ),
              ),
            ],
          )
        // 비방문 미션: 미션 시작 버튼만
        else
          SizedBox(
            width: double.infinity,
            child: HwahaePrimaryButton(
              text: '미션 시작',
              icon: Icons.play_arrow,
              onPressed: () => _startMissionWithoutGps(context, ref),
            ),
          ),
      ],
    );
  }

  // 진행중 - 리뷰 작성 버튼
  Widget _buildInProgressCTA(BuildContext context) {
    final stayDuration = _getStayDuration();
    final visitDeadline = mission.visitDeadline;
    final hoursUntilDeadline = mission.hoursUntilVisitDeadline;
    final daysUntilDeadline = mission.daysUntilVisitDeadline;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stay timer and deadline info
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: HwahaeColors.warningLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, color: HwahaeColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stayDuration != null
                          ? '체류 중: ${stayDuration.inMinutes}분 ${stayDuration.inSeconds % 60}초'
                          : '체크인 완료!',
                      style: HwahaeTypography.bodySmall.copyWith(
                        color: HwahaeColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (visitDeadline != null && hoursUntilDeadline != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event, color: HwahaeColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        daysUntilDeadline != null && daysUntilDeadline > 0
                            ? '방문 마감: ${daysUntilDeadline}일 남음'
                            : hoursUntilDeadline > 0
                                ? '방문 마감: ${hoursUntilDeadline}시간 남음'
                                : '방문 마감 임박!',
                        style: HwahaeTypography.bodySmall.copyWith(
                          color: HwahaeColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: HwahaeSecondaryButton(
                text: '체크아웃',
                onPressed: () => _handleCheckout(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: HwahaePrimaryButton(
                text: '리뷰 작성하기',
                icon: Icons.edit,
                onPressed: () => context.push('/write-review/${mission.id}'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 리뷰 심사중 - 상태 표시
  Widget _buildReviewSubmittedCTA(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: HwahaeColors.secondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '리뷰 심사중',
                  style: HwahaeTypography.titleSmall.copyWith(
                    color: HwahaeColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '심사 완료 시 알림으로 안내드릴게요',
                  style: HwahaeTypography.captionMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 완료 - 보상 정보 표시
  Widget _buildCompletedCTA(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.successLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: HwahaeColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '미션 완료!',
                  style: HwahaeTypography.titleSmall.copyWith(
                    color: HwahaeColors.success,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatCurrency(mission.reviewerFee)}원이 지급되었습니다',
                  style: HwahaeTypography.captionMedium,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push('/review-detail/${mission.id}'),
            child: Text(
              '내 리뷰 보기',
              style: HwahaeTypography.labelMedium.copyWith(
                color: HwahaeColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCheckout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: HwahaeColors.primary),
            const SizedBox(width: 8),
            Text('체크아웃', style: HwahaeTypography.titleMedium),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '미션을 완료하고 체크아웃 하시겠습니까?',
              style: HwahaeTypography.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HwahaeColors.infoLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: HwahaeColors.info, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '체크아웃 후 리뷰를 작성해주세요',
                      style: HwahaeTypography.bodySmall.copyWith(
                        color: HwahaeColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              '취소',
              style: HwahaeTypography.labelLarge.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // 체크아웃 API 호출
              try {
                final response = await ref
                    .read(missionActionProvider.notifier)
                    .checkOut(mission.id);
                if (!context.mounted) return;
                if (response.success) {
                  // 미션 상세 새로고침
                  ref.invalidate(missionDetailProvider(mission.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        response.stayMinutes != null
                            ? '체크아웃 완료! 체류 시간: ${response.stayMinutes}분'
                            : '체크아웃이 완료되었습니다',
                      ),
                      backgroundColor: HwahaeColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response.message ?? '체크아웃에 실패했습니다'),
                      backgroundColor: HwahaeColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('체크아웃에 실패했습니다'),
                    backgroundColor: HwahaeColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            child: Text(
              '체크아웃',
              style: HwahaeTypography.labelLarge.copyWith(
                color: HwahaeColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openMapLocation(BuildContext context) {
    final business = mission.business;
    final latitude = business?.latitude;
    final longitude = business?.longitude;

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('업체 위치 정보가 없습니다'),
          backgroundColor: HwahaeColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    MapLauncher.showMapAppPicker(
      context: context,
      latitude: latitude,
      longitude: longitude,
      name: business?.name,
      address: business?.address,
    );
  }

  void _showApplyDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => _MissionApplyDialog(
        missionId: mission.id,
        onApply: () async {
          Navigator.pop(dialogContext);

          // 로딩 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('미션 신청 중...'),
                ],
              ),
              backgroundColor: HwahaeColors.primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );

          // API 호출
          final success = await ref
              .read(availableMissionsProvider.notifier)
              .applyMission(mission.id);

          // 로딩 스낵바 제거
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          if (success) {
            // 미션 상세 새로고침
            ref.invalidate(missionDetailProvider(mission.id));

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('미션 신청이 완료되었습니다!'),
                backgroundColor: HwahaeColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('미션 신청에 실패했습니다. 다시 시도해주세요.'),
                backgroundColor: HwahaeColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  /// GPS 없이 미션 시작 (비방문 미션 또는 GPS 선택적 방문 미션)
  void _startMissionWithoutGps(BuildContext context, WidgetRef ref) async {
    try {
      final response = await ref
          .read(missionActionProvider.notifier)
          .checkIn(
            mission.id,
            latitude: 0,
            longitude: 0,
          );

      if (!context.mounted) return;

      if (response.success) {
        ref.invalidate(missionDetailProvider(mission.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? '미션이 시작되었습니다.'),
            backgroundColor: HwahaeColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? '미션 시작에 실패했습니다.'),
            backgroundColor: HwahaeColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('미션 시작에 실패했습니다.'),
          backgroundColor: HwahaeColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  /// GPS Mock Location 탐지를 포함한 체크인 프로세스 (구간별 점진적 반경 완화)
  void _showCheckInWithVerification(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CheckInVerificationSheet(
        mission: mission,
        onCheckInSuccess: () {
          Navigator.pop(sheetContext);
          // Refresh mission detail to reflect check-in
          ref.invalidate(missionDetailProvider(mission.id));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('체크인 완료! 이제 방문을 시작하세요.'),
              backgroundColor: HwahaeColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
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

class _StatusInfo {
  final String label;
  final String subtitle;
  final Color color;

  _StatusInfo({
    required this.label,
    required this.subtitle,
    required this.color,
  });
}

/// GPS Mock Location 탐지를 포함한 체크인 검증 시트
class _CheckInVerificationSheet extends ConsumerStatefulWidget {
  final MissionModel mission;
  final VoidCallback onCheckInSuccess;

  const _CheckInVerificationSheet({
    required this.mission,
    required this.onCheckInSuccess,
  });

  @override
  ConsumerState<_CheckInVerificationSheet> createState() =>
      _CheckInVerificationSheetState();
}

class _CheckInVerificationSheetState
    extends ConsumerState<_CheckInVerificationSheet> {
  _CheckInStep _currentStep = _CheckInStep.initial;
  String? _errorMessage;
  bool _isMockDetected = false;
  String? _detectedZone;
  int? _detectedDistance;
  String? _zoneMessage;
  File? _capturedPhoto;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들바
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: HwahaeColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // 제목
          Text(
            '위치 인증 체크인',
            style: HwahaeTypography.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '실제 업체 위치에서만 체크인이 가능합니다',
            style: HwahaeTypography.bodySmall.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // 상태별 UI
          _buildStepContent(),

          const SizedBox(height: 24),

          // 버튼
          _buildActionButton(),

          // 안전 영역
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    // 단순화된 3단계 사용자 경험
    switch (_currentStep) {
      case _CheckInStep.initial:
        return _buildInitialStep();
      case _CheckInStep.verifying:
      case _CheckInStep.photoUploading:
        return _buildVerifyingStep();
      case _CheckInStep.success:
      case _CheckInStep.yellowZone:
        return _buildSuccessStep();
      case _CheckInStep.orangeZone:
      case _CheckInStep.photoCapture:
        return _buildAdditionalVerificationStep();
      case _CheckInStep.mockDetected:
      case _CheckInStep.locationError:
      case _CheckInStep.outOfRange:
        return _buildFailureStep();
    }
  }

  /// 초기 화면: 간결한 위치 인증 시작
  Widget _buildInitialStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: HwahaeColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_searching,
            size: 52,
            color: HwahaeColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '업체 근처에 계신가요?',
          style: HwahaeTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '실제 업체 위치에서 체크인해주세요',
          style: HwahaeTypography.bodyMedium.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 확인 중: 통합된 로딩 화면 (토스 본인인증 UX)
  Widget _buildVerifyingStep() {
    return Column(
      children: [
        const SizedBox(
          width: 72,
          height: 72,
          child: CircularProgressIndicator(
            color: HwahaeColors.primary,
            strokeWidth: 5,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          '잠깐만 기다려주세요',
          style: HwahaeTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '위치를 확인하고 있습니다...',
          style: HwahaeTypography.bodyMedium.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 성공: 체크인 완료 (Yellow zone도 성공으로 통합)
  Widget _buildSuccessStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: HwahaeColors.successLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 52,
            color: HwahaeColors.success,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '위치 인증 완료!',
          style: HwahaeTypography.titleLarge.copyWith(
            color: HwahaeColors.success,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '체크인이 성공적으로 완료되었습니다',
          style: HwahaeTypography.bodyMedium.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 추가 인증 필요: Orange zone - 사진 촬영 (간소화)
  Widget _buildAdditionalVerificationStep() {
    return Column(
      children: [
        if (_capturedPhoto != null) ...[
          // 촬영된 사진 미리보기
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _capturedPhoto!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '업체 간판이 잘 보이는지 확인해주세요',
            style: HwahaeTypography.bodyMedium.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3E0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 52,
              color: Color(0xFFFF9800),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '추가 인증이 필요합니다',
            style: HwahaeTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE65100),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '업체 간판 사진을 촬영해 인증해주세요',
            style: HwahaeTypography.bodyMedium.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  /// 실패: 모든 오류 상태를 통합
  Widget _buildFailureStep() {
    final String title;
    final String message;
    final IconData icon;
    final Color color;

    if (_isMockDetected) {
      title = '위치 확인 실패';
      message = '위치 설정을 확인하고 실제 업체에서 다시 시도해주세요.';
      icon = Icons.gps_off;
      color = HwahaeColors.error;
    } else if (_detectedZone == 'red') {
      final distanceText = _detectedDistance != null ? '${_detectedDistance}m' : '500m 이상';
      title = '업체에서 너무 멀어요';
      message = '현재 $distanceText 떨어져 있습니다.\n업체 근처로 이동 후 다시 시도해주세요.';
      icon = Icons.wrong_location;
      color = HwahaeColors.error;
    } else {
      title = '위치 확인 실패';
      message = _errorMessage ?? 'GPS 신호를 받을 수 없습니다.\n실외에서 다시 시도해주세요.';
      icon = Icons.location_off;
      color = HwahaeColors.warning;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 52, color: color),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: HwahaeTypography.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: HwahaeTypography.bodyMedium.copyWith(
            color: HwahaeColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: HwahaeColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: HwahaeColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: HwahaeTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: HwahaeTypography.captionLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStepIndicator(
    String label,
    bool isCompleted,
    bool isActive,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (isCompleted)
            const Icon(Icons.check_circle, color: HwahaeColors.success, size: 20)
          else if (isActive)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: HwahaeColors.primary,
              ),
            )
          else
            Icon(Icons.circle_outlined,
                color: HwahaeColors.border, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: HwahaeTypography.bodyMedium.copyWith(
              color: isCompleted
                  ? HwahaeColors.success
                  : isActive
                      ? HwahaeColors.textPrimary
                      : HwahaeColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(String tip) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HwahaeColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline,
              color: HwahaeColors.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: HwahaeTypography.captionLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    switch (_currentStep) {
      case _CheckInStep.initial:
        return SizedBox(
          width: double.infinity,
          child: HwahaePrimaryButton(
            text: '내 위치 확인하기',
            icon: Icons.gps_fixed,
            onPressed: _startLocationVerification,
          ),
        );
      case _CheckInStep.verifying:
      case _CheckInStep.photoUploading:
        return const SizedBox.shrink();
      case _CheckInStep.mockDetected:
        return SizedBox(
          width: double.infinity,
          child: HwahaeSecondaryButton(
            text: '닫기',
            onPressed: () => Navigator.pop(context),
          ),
        );
      case _CheckInStep.locationError:
      case _CheckInStep.outOfRange:
        return SizedBox(
          width: double.infinity,
          child: HwahaePrimaryButton(
            text: '다시 시도',
            icon: Icons.refresh,
            onPressed: _startLocationVerification,
          ),
        );
      case _CheckInStep.yellowZone:
        // Yellow zone: check-in already succeeded, just confirm
        return SizedBox(
          width: double.infinity,
          child: HwahaePrimaryButton(
            text: '확인',
            onPressed: widget.onCheckInSuccess,
          ),
        );
      case _CheckInStep.orangeZone:
        // Orange zone: need to take a photo
        return SizedBox(
          width: double.infinity,
          child: HwahaePrimaryButton(
            text: '사진 촬영하기',
            icon: Icons.camera_alt,
            onPressed: _captureVerificationPhoto,
          ),
        );
      case _CheckInStep.photoCapture:
        return Column(
          children: [
            if (_capturedPhoto != null) ...[
              SizedBox(
                width: double.infinity,
                child: HwahaePrimaryButton(
                  text: '이 사진으로 인증',
                  icon: Icons.check,
                  onPressed: _submitPhotoVerification,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: HwahaeSecondaryButton(
                  text: '다시 촬영',
                  icon: Icons.refresh,
                  onPressed: _captureVerificationPhoto,
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: HwahaePrimaryButton(
                  text: '사진 촬영',
                  icon: Icons.camera_alt,
                  onPressed: _captureVerificationPhoto,
                ),
              ),
            ],
          ],
        );
      case _CheckInStep.success:
        return SizedBox(
          width: double.infinity,
          child: HwahaePrimaryButton(
            text: '체크인 완료',
            onPressed: widget.onCheckInSuccess,
          ),
        );
    }
  }

  Future<void> _startLocationVerification() async {
    setState(() {
      _currentStep = _CheckInStep.verifying;
      _errorMessage = null;
      _isMockDetected = false;
      _detectedZone = null;
      _detectedDistance = null;
      _zoneMessage = null;
    });

    // 위치 검증 수행
    final locationNotifier = ref.read(locationVerificationProvider.notifier);
    await locationNotifier.verifyLocationWithSampling();

    final locationState = ref.read(locationVerificationProvider);

    if (locationState.isMockDetected) {
      setState(() {
        _currentStep = _CheckInStep.mockDetected;
        _isMockDetected = true;
      });
      return;
    }

    if (!locationState.isVerified || locationState.position == null) {
      setState(() {
        _currentStep = _CheckInStep.locationError;
        _errorMessage = locationState.errorMessage;
      });
      return;
    }

    // 백엔드 API를 통해 GPS 존 판별 + 체크인 시도
    final position = locationState.position!;
    final checkInResponse = await ref
        .read(missionActionProvider.notifier)
        .checkIn(
          widget.mission.id,
          latitude: position.latitude,
          longitude: position.longitude,
        );

    _detectedZone = checkInResponse.zone;
    _detectedDistance = checkInResponse.distance;
    _zoneMessage = checkInResponse.message;

    if (checkInResponse.success) {
      // Green or Yellow zone: check-in succeeded
      if (checkInResponse.zone == 'yellow') {
        setState(() {
          _currentStep = _CheckInStep.yellowZone;
        });
      } else {
        // Green zone
        setState(() {
          _currentStep = _CheckInStep.success;
        });
      }
    } else {
      // Check-in failed — determine which zone
      if (checkInResponse.zone == 'orange' &&
          checkInResponse.requiresPhotoVerification) {
        // Orange zone: need photo verification
        setState(() {
          _currentStep = _CheckInStep.orangeZone;
        });
      } else if (checkInResponse.zone == 'red') {
        // Red zone: blocked
        setState(() {
          _currentStep = _CheckInStep.outOfRange;
        });
      } else {
        // Generic error
        setState(() {
          _currentStep = _CheckInStep.locationError;
          _errorMessage = checkInResponse.message;
        });
      }
    }
  }

  /// Capture a verification photo (orange zone)
  Future<void> _captureVerificationPhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 960,
        imageQuality: 80,
      );

      if (photo != null) {
        setState(() {
          _capturedPhoto = File(photo.path);
          _currentStep = _CheckInStep.photoCapture;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '카메라를 사용할 수 없습니다.';
        _currentStep = _CheckInStep.locationError;
      });
    }
  }

  /// Submit photo verification for orange zone check-in
  Future<void> _submitPhotoVerification() async {
    if (_capturedPhoto == null) return;

    setState(() {
      _currentStep = _CheckInStep.photoUploading;
    });

    try {
      // Read photo and encode as base64
      final bytes = await _capturedPhoto!.readAsBytes();
      final base64Photo = base64Encode(bytes);

      final locationState = ref.read(locationVerificationProvider);
      final position = locationState.position;

      if (position == null) {
        setState(() {
          _currentStep = _CheckInStep.locationError;
          _errorMessage = '위치 정보를 가져올 수 없습니다. 다시 시도해주세요.';
        });
        return;
      }

      // Re-submit check-in with photo
      final checkInResponse = await ref
          .read(missionActionProvider.notifier)
          .checkIn(
            widget.mission.id,
            latitude: position.latitude,
            longitude: position.longitude,
            verificationPhoto: base64Photo,
          );

      if (checkInResponse.success) {
        // Refresh mission detail
        ref.invalidate(missionDetailProvider(widget.mission.id));
        setState(() {
          _currentStep = _CheckInStep.success;
          _zoneMessage = checkInResponse.message;
        });
      } else {
        setState(() {
          _currentStep = _CheckInStep.locationError;
          _errorMessage = checkInResponse.message ?? '사진 인증에 실패했습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _currentStep = _CheckInStep.locationError;
        _errorMessage = '사진 인증에 실패했습니다: ${e.toString()}';
      });
    }
  }
}

enum _CheckInStep {
  initial,
  verifying,
  mockDetected,
  locationError,
  outOfRange,        // red zone (500m+)
  yellowZone,        // yellow zone (100-200m) — warning
  orangeZone,        // orange zone (200-500m) — photo required
  photoCapture,      // taking photo for orange zone verification
  photoUploading,    // uploading photo
  success,
}

/// 미션 신청 확인 다이얼로그
class _MissionApplyDialog extends StatelessWidget {
  final String missionId;
  final VoidCallback onApply;

  const _MissionApplyDialog({
    required this.missionId,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        '미션 신청',
        style: HwahaeTypography.headlineSmall,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이 미션에 신청하시겠습니까?',
            style: HwahaeTypography.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HwahaeColors.infoLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                      color: HwahaeColors.info, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '신청 안내',
                      style: HwahaeTypography.labelMedium.copyWith(
                        color: HwahaeColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• 배정 시 업체 정보가 공개됩니다\n'
                  '• 배정 후 3일 이내 방문해야 합니다\n'
                  '• 미션 포기 시 신뢰도가 하락합니다',
                  style: HwahaeTypography.captionLarge.copyWith(
                    color: HwahaeColors.info,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            '취소',
            style: HwahaeTypography.labelLarge.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: onApply,
          child: Text(
            '신청하기',
            style: HwahaeTypography.labelLarge.copyWith(
              color: HwahaeColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
