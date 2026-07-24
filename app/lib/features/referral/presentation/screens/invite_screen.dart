import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../providers/referral_provider.dart';

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(referralProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(referralProvider);

    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('친구 초대', style: HwahaeTypography.titleMedium),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: HwahaeColors.primary))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // 추천 코드 카드
                  _buildReferralCodeCard(state.code),
                  // 통계
                  if (state.stats != null) _buildStatsSection(state.stats!),
                  // 지역 수요
                  if (state.demand.isNotEmpty) _buildDemandSection(state.demand),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildReferralCodeCard(String? code) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: HwahaeColors.gradientPrimary),
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: HwahaeColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.card_giftcard_rounded, size: 48, color: Colors.white),
          const SizedBox(height: 16),
          Text(
            '친구를 초대하고\n10,000원씩 받으세요!',
            style: HwahaeTypography.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  code ?? '...',
                  style: HwahaeTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    if (code != null) {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('추천 코드가 복사되었습니다!')),
                      );
                    }
                  },
                  child: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildShareButton(Icons.chat_bubble_rounded, '카카오톡'),
              const SizedBox(width: 12),
              _buildShareButton(Icons.sms_rounded, 'SMS'),
              const SizedBox(width: 12),
              _buildShareButton(Icons.link_rounded, '링크복사'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        if (label == '링크복사') {
          final code = ref.read(referralProvider).code;
          if (code != null) {
            Clipboard.setData(ClipboardData(text: '암행어흥에서 함께 리뷰어로 활동해요! 추천코드: $code'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('공유 링크가 복사되었습니다!')),
            );
          }
        }
      },
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: HwahaeTypography.captionSmall.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
        border: Border.all(color: HwahaeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('추천 현황', style: HwahaeTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('초대', '${stats.total}명', HwahaeColors.primary),
              _buildStatItem('가입', '${stats.registered}명', HwahaeColors.warning),
              _buildStatItem('완료', '${stats.rewarded}명', HwahaeColors.success),
              _buildStatItem('수익', '${_formatCurrency(stats.totalEarnings)}원', HwahaeColors.accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: HwahaeTypography.titleSmall.copyWith(
            color: color, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 4),
          Text(label, style: HwahaeTypography.captionSmall.copyWith(
            color: HwahaeColors.textSecondary,
          )),
        ],
      ),
    );
  }

  Widget _buildDemandSection(List demand) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
        border: Border.all(color: HwahaeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: HwahaeColors.warning, size: 20),
              const SizedBox(width: 8),
              Text('우리 동네 리뷰어 부족!', style: HwahaeTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          ...demand.take(5).map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: Text(d.region, style: HwahaeTypography.bodySmall)),
                Text(
                  '리뷰어 ${d.activeReviewers}명 / 미션 ${d.pendingMissions}개',
                  style: HwahaeTypography.captionMedium.copyWith(color: HwahaeColors.textSecondary),
                ),
              ],
            ),
          )),
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
