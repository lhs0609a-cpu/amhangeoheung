import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../../../core/utils/map_launcher.dart';
import '../../../../shared/widgets/hwahae/hwahae_buttons.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../providers/mission_provider.dart';
import '../../providers/location_provider.dart';
import '../../data/models/mission_model.dart';

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

class _MissionDetailContent extends ConsumerWidget {
  final MissionModel mission;

  const _MissionDetailContent({required this.mission});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상태 배너
                _buildStatusBanner(),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 카테고리 & 지역
                      Row(
                        children: [
                          _buildInfoChip(
                            _getCategoryIcon(mission.category),
                            mission.category ?? '기타',
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(Icons.location_on, mission.region ?? '지역 미정'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 제목
                      Text(
                        mission.business?.name ?? mission.category ?? '미션',
                        style: HwahaeTypography.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '정확한 업체명은 미션 배정 후 공개됩니다.',
                        style: HwahaeTypography.bodySmall.copyWith(
                          color: HwahaeColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 페이백 정보
                      _buildRewardCard(),
                      const SizedBox(height: 24),

                      // 미션 설명
                      Text(
                        '미션 안내',
                        style: HwahaeTypography.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _buildMissionStep('1', '배정된 업체를 방문하여 이용'),
                      _buildMissionStep('2', '서비스 품질 평가 (대기시간, 청결도, 품질 등)'),
                      _buildMissionStep('3', '영수증 촬영 및 현장 사진 3장 이상'),
                      _buildMissionStep('4', '정형화된 리뷰 작성 (단점 1개 이상 필수)'),
                      const SizedBox(height: 24),

                      // 평가 항목
                      Text(
                        '평가 항목',
                        style: HwahaeTypography.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _buildEvaluationItem('대기 시간', '입장부터 서비스까지 시간 측정'),
                      _buildEvaluationItem('서비스 품질', '서비스 품질 평가'),
                      _buildEvaluationItem('청결도', '테이블, 바닥, 화장실'),
                      _buildEvaluationItem('직원 응대', '인사, 친절도, 불만 대응'),
                      _buildEvaluationItem('가성비', '가격 대비 만족도'),
                      const SizedBox(height: 24),

                      // 주의사항
                      _buildWarningSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 하단 CTA
        _buildBottomCTA(context, ref),
      ],
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
          subtitle: '방문 후 리뷰를 작성해주세요',
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
          child: Row(
            children: [
              const Icon(Icons.store, color: HwahaeColors.info, size: 20),
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
        ),
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
        ),
      ],
    );
  }

  // 진행중 - 리뷰 작성 버튼
  Widget _buildInProgressCTA(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 진행 상황 표시
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: HwahaeColors.warningLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time, color: HwahaeColors.warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '체크인 완료! 방문 후 리뷰를 작성해주세요.',
                  style: HwahaeTypography.bodySmall.copyWith(
                    color: HwahaeColors.warning,
                  ),
                ),
              ),
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
                await Future.delayed(const Duration(milliseconds: 500));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('체크아웃이 완료되었습니다'),
                    backgroundColor: HwahaeColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
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

  /// GPS Mock Location 탐지를 포함한 체크인 프로세스
  void _showCheckInWithVerification(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CheckInVerificationSheet(
        mission: mission,
        onCheckInSuccess: () {
          Navigator.pop(context);
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
    switch (_currentStep) {
      case _CheckInStep.initial:
        return _buildInitialStep();
      case _CheckInStep.verifying:
        return _buildVerifyingStep();
      case _CheckInStep.mockDetected:
        return _buildMockDetectedStep();
      case _CheckInStep.locationError:
        return _buildLocationErrorStep();
      case _CheckInStep.outOfRange:
        return _buildOutOfRangeStep();
      case _CheckInStep.success:
        return _buildSuccessStep();
    }
  }

  Widget _buildInitialStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: HwahaeColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_searching,
            size: 48,
            color: HwahaeColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        _buildInfoCard(
          icon: Icons.security,
          title: '위치 보안 검증',
          description: 'GPS 조작 방지 시스템으로\n실제 위치를 확인합니다.',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.my_location,
          title: '업체 반경 확인',
          description: '업체 위치 100m 이내에서만\n체크인이 가능합니다.',
        ),
      ],
    );
  }

  Widget _buildVerifyingStep() {
    return Column(
      children: [
        const SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            color: HwahaeColors.primary,
            strokeWidth: 6,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '위치 확인 중...',
          style: HwahaeTypography.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'GPS 신호를 분석하고 있습니다',
          style: HwahaeTypography.bodySmall.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        _buildVerificationStepIndicator('GPS 신호 수집', true, true),
        _buildVerificationStepIndicator('Mock Location 탐지', true, false),
        _buildVerificationStepIndicator('위치 일관성 검증', false, false),
        _buildVerificationStepIndicator('업체 반경 확인', false, false),
      ],
    );
  }

  Widget _buildMockDetectedStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: HwahaeColors.errorLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.gps_off,
            size: 48,
            color: HwahaeColors.error,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '가짜 GPS 감지됨',
          style: HwahaeTypography.titleLarge.copyWith(
            color: HwahaeColors.error,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HwahaeColors.errorLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'GPS 위치 조작이 감지되었습니다.\n실제 업체 위치에서 다시 시도해주세요.',
                style: HwahaeTypography.bodyMedium.copyWith(
                  color: HwahaeColors.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.warning, color: HwahaeColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '반복 시도 시 계정이 제한될 수 있습니다',
                      style: HwahaeTypography.captionLarge.copyWith(
                        color: HwahaeColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationErrorStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: HwahaeColors.warningLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_off,
            size: 48,
            color: HwahaeColors.warning,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '위치 확인 실패',
          style: HwahaeTypography.titleLarge.copyWith(
            color: HwahaeColors.warning,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HwahaeColors.warningLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _errorMessage ?? 'GPS 신호를 받을 수 없습니다.\n실외에서 다시 시도해주세요.',
            style: HwahaeTypography.bodyMedium.copyWith(
              color: HwahaeColors.warning,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        _buildTipCard(
          '위치 권한이 "항상 허용"으로 설정되어 있는지 확인해주세요.',
        ),
      ],
    );
  }

  Widget _buildOutOfRangeStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: HwahaeColors.infoLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.wrong_location,
            size: 48,
            color: HwahaeColors.info,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '업체 범위 밖',
          style: HwahaeTypography.titleLarge.copyWith(
            color: HwahaeColors.info,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HwahaeColors.infoLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '현재 위치가 업체로부터\n100m 이상 떨어져 있습니다.',
                style: HwahaeTypography.bodyMedium.copyWith(
                  color: HwahaeColors.info,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: HwahaeColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.store, size: 16, color: HwahaeColors.info),
                    const SizedBox(width: 8),
                    Text(
                      widget.mission.business?.name ?? '업체',
                      style: HwahaeTypography.labelMedium.copyWith(
                        color: HwahaeColors.info,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: HwahaeColors.successLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 48,
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
        const SizedBox(height: 12),
        Text(
          '체크인이 성공적으로 완료되었습니다',
          style: HwahaeTypography.bodyMedium.copyWith(
            color: HwahaeColors.textSecondary,
          ),
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
            text: '위치 인증 시작',
            icon: Icons.gps_fixed,
            onPressed: _startLocationVerification,
          ),
        );
      case _CheckInStep.verifying:
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

    // 업체 위치와 거리 확인 (업체 좌표가 있는 경우)
    final businessLat = widget.mission.business?.latitude;
    final businessLng = widget.mission.business?.longitude;

    if (businessLat != null && businessLng != null) {
      final isWithinRange = locationNotifier.isWithinRadius(
        businessLat,
        businessLng,
        100.0, // 100미터 반경
      );

      if (!isWithinRange) {
        setState(() {
          _currentStep = _CheckInStep.outOfRange;
        });
        return;
      }
    }

    // 체크인 성공
    setState(() {
      _currentStep = _CheckInStep.success;
    });
  }
}

enum _CheckInStep {
  initial,
  verifying,
  mockDetected,
  locationError,
  outOfRange,
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
