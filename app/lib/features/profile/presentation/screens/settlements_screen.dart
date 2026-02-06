import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../providers/profile_provider.dart';
import '../../data/repositories/user_repository.dart';

class SettlementsScreen extends ConsumerStatefulWidget {
  const SettlementsScreen({super.key});

  @override
  ConsumerState<SettlementsScreen> createState() => _SettlementsScreenState();
}

class _SettlementsScreenState extends ConsumerState<SettlementsScreen> {
  String? _expandedSettlementId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settlementsProvider.notifier).loadSettlements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settlementsState = ref.watch(settlementsProvider);

    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('정산 내역', style: HwahaeTypography.titleMedium),
      ),
      body: settlementsState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: HwahaeColors.primary),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(settlementsProvider.notifier).loadSettlements(),
              color: HwahaeColors.primary,
              child: CustomScrollView(
                slivers: [
                  // 정산 대기 금액 카드
                  SliverToBoxAdapter(
                    child: _buildPendingCard(settlementsState.pendingAmount),
                  ),

                  // 정산 내역 리스트
                  if (settlementsState.settlements.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final settlement = settlementsState.settlements[index];
                            return _buildSettlementCard(settlement);
                          },
                          childCount: settlementsState.settlements.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildPendingCard(int amount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: HwahaeColors.gradientPrimary,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: HwahaeColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '정산 대기 금액',
                style: HwahaeTypography.titleSmall.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${_formatCurrency(amount)}원',
            style: HwahaeTypography.displaySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: amount > 0
                  ? () => _requestSettlement(amount)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: HwahaeColors.primary,
                disabledBackgroundColor: Colors.white.withOpacity(0.5),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('정산 신청하기'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: HwahaeColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            '정산 내역이 없습니다',
            style: HwahaeTypography.titleMedium.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '미션을 완료하면 정산 내역이 표시됩니다',
            style: HwahaeTypography.bodySmall.copyWith(
              color: HwahaeColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementCard(Settlement settlement) {
    final isExpanded = _expandedSettlementId == settlement.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
        border: Border.all(
          color: isExpanded ? _getStatusColor(settlement.status).withOpacity(0.3) : HwahaeColors.border,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: _getStatusColor(settlement.status).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // 메인 카드 (클릭 가능)
          InkWell(
            onTap: () {
              setState(() {
                _expandedSettlementId = isExpanded ? null : settlement.id;
              });
            },
            borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getStatusColor(settlement.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(settlement.status),
                      color: _getStatusColor(settlement.status),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(settlement.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                settlement.statusDisplayName,
                                style: HwahaeTypography.labelSmall.copyWith(
                                  color: _getStatusColor(settlement.status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_formatCurrency(settlement.amount)}원',
                              style: HwahaeTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (settlement.missionTitle != null) ...[
                              Expanded(
                                child: Text(
                                  settlement.missionTitle!,
                                  style: HwahaeTypography.bodySmall.copyWith(
                                    color: HwahaeColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ] else ...[
                              Text(
                                '신청일: ${_formatDate(settlement.requestedAt)}',
                                style: HwahaeTypography.captionMedium.copyWith(
                                  color: HwahaeColors.textTertiary,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: HwahaeColors.textTertiary,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 타임라인 (확장 시)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildSettlementTimeline(settlement),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  /// 정산 타임라인 위젯
  Widget _buildSettlementTimeline(Settlement settlement) {
    final events = settlement.timelineEvents;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text(
            '정산 진행 상황',
            style: HwahaeTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // 타임라인 이벤트들
          ...events.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            final isLast = index == events.length - 1;

            return _buildTimelineEvent(event, isLast);
          }),
          // 실패 시 재시도 버튼
          if (settlement.status == 'failed' && (settlement.retryCount ?? 0) < 3) ...[
            const SizedBox(height: 12),
            _buildRetryButton(settlement),
          ],
          // 예상 지급일 안내
          if (settlement.estimatedPayoutDate != null && settlement.status != 'completed') ...[
            const SizedBox(height: 12),
            _buildEstimatedPayoutInfo(settlement.estimatedPayoutDate!),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineEvent(SettlementTimelineEvent event, bool isLast) {
    final Color statusColor;
    final IconData statusIcon;

    if (event.isFailed) {
      statusColor = HwahaeColors.error;
      statusIcon = Icons.error_outline;
    } else if (event.isCompleted) {
      statusColor = HwahaeColors.success;
      statusIcon = Icons.check_circle;
    } else if (event.isInProgress) {
      statusColor = HwahaeColors.warning;
      statusIcon = Icons.hourglass_top;
    } else {
      statusColor = HwahaeColors.textTertiary;
      statusIcon = Icons.circle_outlined;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타임라인 아이콘과 선
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Icon(
                statusIcon,
                size: 20,
                color: statusColor,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: event.isCompleted
                      ? HwahaeColors.success.withOpacity(0.3)
                      : HwahaeColors.border,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // 내용
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      event.title,
                      style: HwahaeTypography.labelMedium.copyWith(
                        color: event.isCompleted || event.isInProgress
                            ? HwahaeColors.textPrimary
                            : HwahaeColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (event.isInProgress) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: HwahaeColors.warning,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  event.description,
                  style: HwahaeTypography.captionMedium.copyWith(
                    color: HwahaeColors.textTertiary,
                  ),
                ),
                if (event.completedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDateTime(event.completedAt!),
                    style: HwahaeTypography.captionSmall.copyWith(
                      color: HwahaeColors.textTertiary,
                    ),
                  ),
                ],
                if (event.isFailed && event.errorMessage != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: HwahaeColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: HwahaeColors.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.errorMessage!,
                            style: HwahaeTypography.captionMedium.copyWith(
                              color: HwahaeColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRetryButton(Settlement settlement) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _retrySettlement(settlement),
        icon: const Icon(Icons.refresh, size: 18),
        label: Text('재시도 (${3 - (settlement.retryCount ?? 0)}회 남음)'),
        style: OutlinedButton.styleFrom(
          foregroundColor: HwahaeColors.primary,
          side: const BorderSide(color: HwahaeColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildEstimatedPayoutInfo(DateTime estimatedDate) {
    final daysLeft = estimatedDate.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HwahaeColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HwahaeColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: 18,
            color: HwahaeColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '예상 지급일',
                  style: HwahaeTypography.captionMedium.copyWith(
                    color: HwahaeColors.textSecondary,
                  ),
                ),
                Text(
                  '${_formatDate(estimatedDate)} ${daysLeft > 0 ? '(${daysLeft}일 후)' : '(오늘)'}',
                  style: HwahaeTypography.labelMedium.copyWith(
                    color: HwahaeColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _retrySettlement(Settlement settlement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
        ),
        title: Text('정산 재시도', style: HwahaeTypography.headlineSmall),
        content: Text(
          '정산을 다시 시도하시겠습니까?\n등록된 계좌 정보가 올바른지 확인해주세요.',
          style: HwahaeTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '취소',
              style: HwahaeTypography.labelLarge.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '재시도',
              style: HwahaeTypography.labelLarge.copyWith(
                color: HwahaeColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 정산 재시도 API 호출
      try {
        // API 호출 시뮬레이션 - 실제로는 ApiClient를 통해 호출
        await Future.delayed(const Duration(milliseconds: 500));
        await ref.read(settlementsProvider.notifier).loadSettlements();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('정산 재시도를 요청했습니다'),
            backgroundColor: HwahaeColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('정산 재시도에 실패했습니다'),
              backgroundColor: HwahaeColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return HwahaeColors.success;
      case 'processing':
        return HwahaeColors.warning;
      case 'failed':
        return HwahaeColors.error;
      default:
        return HwahaeColors.primary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'processing':
        return Icons.hourglass_top;
      case 'failed':
        return Icons.error;
      default:
        return Icons.pending;
    }
  }

  void _requestSettlement(int amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
        ),
        title: Text('정산 신청', style: HwahaeTypography.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HwahaeColors.successLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payments, color: HwahaeColors.success),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatCurrency(amount)}원',
                    style: HwahaeTypography.headlineMedium.copyWith(
                      color: HwahaeColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '등록된 계좌로 정산됩니다.\n영업일 기준 3-5일 소요됩니다.',
              style: HwahaeTypography.bodyMedium,
              textAlign: TextAlign.center,
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
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(settlementsProvider.notifier)
                  .requestSettlement();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? '정산 신청이 완료되었습니다' : '정산 신청에 실패했습니다',
                    ),
                    backgroundColor:
                        success ? HwahaeColors.success : HwahaeColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            child: Text(
              '신청하기',
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

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
