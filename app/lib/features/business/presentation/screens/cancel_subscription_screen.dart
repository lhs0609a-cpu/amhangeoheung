import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../data/models/cancel_flow_model.dart';
import '../../providers/cancel_flow_provider.dart';
import '../../../../shared/widgets/ui/ui.dart';

class CancelSubscriptionScreen extends ConsumerStatefulWidget {
  final String businessId;
  const CancelSubscriptionScreen({super.key, required this.businessId});

  @override
  ConsumerState<CancelSubscriptionScreen> createState() => _CancelSubscriptionScreenState();
}

class _CancelSubscriptionScreenState extends ConsumerState<CancelSubscriptionScreen> {
  late PageController _pageController;
  final _detailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cancelFlowProvider(widget.businessId).notifier).loadInitiateData();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cancelFlowProvider(widget.businessId));

    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('구독 해지', style: HwahaeTypography.titleMedium),
      ),
      body: state.isLoading && state.initiateData == null
          ? const Center(child: CircularProgressIndicator(color: HwahaeColors.primary))
          : state.isCancelled
              ? _buildCancelledView()
              : PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildLossPage(state),
                    _buildReasonPage(state),
                    _buildRetentionPage(state),
                    _buildConfirmPage(state),
                  ],
                ),
    );
  }

  Widget _buildLossPage(CancelFlowState state) {
    final data = state.initiateData;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: HwahaeColors.error.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
              border: Border.all(color: HwahaeColors.error.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.warning_rounded, size: 48, color: HwahaeColors.error),
                const SizedBox(height: 16),
                Text('떠나면 잃는 것들', style: HwahaeTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                )),
                const SizedBox(height: 20),
                if (data != null) ...[
                  _buildLossItem(Icons.reviews_rounded, '누적 리뷰', '${data.totalReviews}개가 만료됩니다'),
                  _buildLossItem(Icons.star_rounded, '평균 평점', '${data.avgRating.toStringAsFixed(1)}점'),
                  if (data.badgeLossWarning != null)
                    _buildLossItem(Icons.shield_rounded, '배지', data.badgeLossWarning!),
                  _buildLossItem(Icons.trending_down, '예상 매출 감소', '${_formatCurrency(data.estimatedRevenueLoss)}원'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () { _goToPage(1); ref.read(cancelFlowProvider(widget.businessId).notifier).nextPage(); },
              style: ElevatedButton.styleFrom(
                backgroundColor: HwahaeColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD)),
              ),
              child: const Text('그래도 해지하기', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('구독 유지하기'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLossItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: HwahaeColors.error),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: HwahaeTypography.bodyMedium)),
          Text(value, style: HwahaeTypography.labelMedium.copyWith(
            color: HwahaeColors.error, fontWeight: FontWeight.w600,
          )),
        ],
      ),
    );
  }

  Widget _buildReasonPage(CancelFlowState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('해지 이유를 알려주세요', style: HwahaeTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          ...CancelReason.categories.map((cat) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => ref.read(cancelFlowProvider(widget.businessId).notifier).setReason(cat['key']!),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: state.selectedReason == cat['key'] ? HwahaeColors.primaryContainer : HwahaeColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.selectedReason == cat['key'] ? HwahaeColors.primary : HwahaeColors.border,
                    width: state.selectedReason == cat['key'] ? 2 : 1,
                  ),
                ),
                child: Text(cat['label']!, style: HwahaeTypography.bodyMedium),
              ),
            ),
          )),
          const SizedBox(height: 16),
          TextField(
            controller: _detailController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '추가 의견 (선택)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => ref.read(cancelFlowProvider(widget.businessId).notifier).setReasonDetail(v),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: state.selectedReason != null ? () {
                ref.read(cancelFlowProvider(widget.businessId).notifier).submitReason();
                _goToPage(2);
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: HwahaeColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD)),
              ),
              child: const Text('다음'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetentionPage(CancelFlowState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.lightbulb_rounded, size: 48, color: HwahaeColors.warning),
          const SizedBox(height: 16),
          Text('잠깐! 이 대안은 어떠세요?', style: HwahaeTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          // 일시정지 옵션
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [HwahaeColors.primary.withValues(alpha: 0.05), HwahaeColors.primary.withValues(alpha: 0.02)]),
              borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
              border: Border.all(color: HwahaeColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.pause_circle_rounded, size: 40, color: HwahaeColors.primary),
                const SizedBox(height: 12),
                Text('1개월 일시정지', style: HwahaeTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('데이터와 배지를 유지하면서 비용 부담 없이 쉴 수 있어요 (연 2회)',
                  style: HwahaeTypography.bodySmall.copyWith(color: HwahaeColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final success = await ref.read(cancelFlowProvider(widget.businessId).notifier).pauseSubscription();
                      if (success && mounted) {
                        AppToast.info(context, '구독이 일시정지되었습니다');
                        context.pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: HwahaeColors.primary),
                    child: const Text('일시정지하기'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () { _goToPage(3); ref.read(cancelFlowProvider(widget.businessId).notifier).nextPage(); },
              style: OutlinedButton.styleFrom(foregroundColor: HwahaeColors.error),
              child: const Text('그래도 해지할게요'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPage(CancelFlowState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.sentiment_dissatisfied_rounded, size: 48, color: HwahaeColors.textSecondary),
          const SizedBox(height: 16),
          Text('정말 해지하시겠습니까?', style: HwahaeTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(
            '해지 후에는 누적 데이터와 배지가 초기화되며,\n복구할 수 없습니다.',
            style: HwahaeTypography.bodyMedium.copyWith(color: HwahaeColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : () async {
                try {
                  final success = await ref.read(cancelFlowProvider(widget.businessId).notifier).confirmCancel();
                  if (success && mounted) {
                    AppToast.info(context, '구독이 해지되었습니다.');
                  } else if (mounted) {
                    AppToast.info(context, '해지 처리에 실패했습니다. 다시 시도해주세요.');
                  }
                } catch (e) {
                  if (mounted) {
                    AppToast.info(context, '해지 처리 중 문제가 발생했습니다. 다시 시도해주세요.');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: HwahaeColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD)),
              ),
              child: state.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('최종 해지 확인', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('역시 유지할게요!'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: HwahaeColors.textSecondary),
          const SizedBox(height: 16),
          Text('구독이 해지되었습니다', style: HwahaeTypography.titleMedium),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('홈으로'),
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
}
