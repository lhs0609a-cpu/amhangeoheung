import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/hwahae/hwahae_cards.dart';
import '../../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // 프로필 및 정산 정보 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).loadProfile();
      ref.read(settlementsProvider.notifier).loadSettlements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final settlementsState = ref.watch(settlementsProvider);

    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('마이페이지', style: HwahaeTypography.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: profileState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: HwahaeColors.primary),
            )
          : profileState.error != null
              ? _buildErrorView(profileState.error!)
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(profileProvider.notifier).loadProfile();
                    await ref.read(settlementsProvider.notifier).loadSettlements();
                  },
                  color: HwahaeColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // 프로필 카드
                        _buildProfileCard(profileState),
                        const SizedBox(height: 16),

                        // 정산 정보
                        _buildSettlementCard(settlementsState),
                        const SizedBox(height: 24),

                        // 메뉴 리스트
                        _buildMenuSection(
                          title: '활동 관리',
                          items: [
                            _MenuItem(
                              icon: Icons.assignment,
                              title: '내 미션',
                              subtitle: '진행중 ${profileState.stats?.ongoingMissions ?? 0}개',
                              onTap: () => context.go('/missions'),
                            ),
                            _MenuItem(
                              icon: Icons.rate_review,
                              title: '작성한 리뷰',
                              subtitle: '${profileState.stats?.completedMissions ?? 0}개',
                              onTap: () => context.push('/my-reviews'),
                            ),
                            _MenuItem(
                              icon: Icons.history,
                              title: '정산 내역',
                              onTap: () => context.push('/settlements'),
                            ),
                          ],
                        ),
                        _buildMenuSection(
                          title: '리뷰어 설정',
                          items: [
                            _MenuItem(
                              icon: Icons.category,
                              title: '전문 카테고리',
                              subtitle: profileState.user?.reviewerInfo?.specialties?.join(', ') ?? '설정 안됨',
                              onTap: () => context.push('/specialties'),
                            ),
                            _MenuItem(
                              icon: Icons.account_balance,
                              title: '정산 계좌',
                              subtitle: profileState.user?.bankAccount != null
                                  ? '${profileState.user?.bankName ?? ''} ****${profileState.user?.bankAccount?.substring(profileState.user!.bankAccount!.length - 4)}'
                                  : '계좌 미등록',
                              onTap: () => context.push('/bank-account'),
                            ),
                            _MenuItem(
                              icon: Icons.notifications,
                              title: '알림 설정',
                              onTap: () => context.push('/notifications-settings'),
                            ),
                          ],
                        ),
                        _buildMenuSection(
                          title: '기타',
                          items: [
                            _MenuItem(
                              icon: Icons.workspace_premium,
                              title: '요금제',
                              subtitle: profileState.user?.premiumInfo?.planName ?? '무료',
                              onTap: () => context.push('/pricing'),
                            ),
                            _MenuItem(
                              icon: Icons.help_outline,
                              title: '고객센터',
                              onTap: () => context.push('/support'),
                            ),
                            _MenuItem(
                              icon: Icons.description,
                              title: '이용약관',
                              onTap: () => context.push('/terms'),
                            ),
                            _MenuItem(
                              icon: Icons.info_outline,
                              title: '앱 정보',
                              subtitle: 'v1.0.0',
                              onTap: () => context.push('/about'),
                            ),
                          ],
                        ),

                        // 로그아웃
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: OutlinedButton(
                            onPressed: () => _showLogoutDialog(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: HwahaeColors.error,
                              side: const BorderSide(color: HwahaeColors.error),
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
                              ),
                            ),
                            child: const Text('로그아웃'),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: HwahaeColors.error),
          const SizedBox(height: 16),
          Text(
            '프로필을 불러올 수 없습니다',
            style: HwahaeTypography.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: HwahaeTypography.bodySmall.copyWith(
              color: HwahaeColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(profileProvider.notifier).loadProfile();
            },
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(ProfileState profileState) {
    final user = profileState.user;
    final stats = profileState.stats;
    final grade = user?.reviewerInfo?.grade ?? 'rookie';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
        border: Border.all(color: HwahaeColors.border),
        boxShadow: HwahaeTheme.shadowSM,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 프로필 이미지
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: HwahaeColors.getGradeGradient(grade),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: user?.profileImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          user!.profileImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 32,
                        color: Colors.white,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user?.nickname ?? '암행어흥 리뷰어',
                          style: HwahaeTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        HwahaeGradeBadge(grade: grade, showLabel: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          user?.isVerified == true
                              ? Icons.verified
                              : Icons.verified_outlined,
                          size: 14,
                          color: user?.isVerified == true
                              ? HwahaeColors.success
                              : HwahaeColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user?.isVerified == true ? '본인인증 완료' : '본인인증 필요',
                          style: HwahaeTypography.captionMedium.copyWith(
                            color: user?.isVerified == true
                                ? HwahaeColors.success
                                : HwahaeColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: HwahaeColors.textSecondary),
                onPressed: () => context.push('/edit-profile'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '완료 미션',
                  '${stats?.completedMissions ?? 0}',
                  Icons.check_circle_outline,
                  HwahaeColors.success,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: HwahaeColors.divider,
              ),
              Expanded(
                child: _buildStatItem(
                  '신뢰도',
                  (stats?.trustScore ?? 0.0).toStringAsFixed(1),
                  Icons.star_rounded,
                  HwahaeColors.warning,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: HwahaeColors.divider,
              ),
              Expanded(
                child: _buildStatItem(
                  '총 수익',
                  _formatCurrency(stats?.totalEarnings ?? 0),
                  Icons.payments_outlined,
                  HwahaeColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: HwahaeTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: HwahaeTypography.captionSmall.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSettlementCard(SettlementsState settlementsState) {
    final pendingAmount = settlementsState.pendingAmount;
    final isLoading = settlementsState.isLoading;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '정산 대기 금액',
                  style: HwahaeTypography.captionMedium.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                isLoading
                    ? const SizedBox(
                        width: 100,
                        height: 24,
                        child: LinearProgressIndicator(
                          color: Colors.white,
                          backgroundColor: Colors.white24,
                        ),
                      )
                    : Text(
                        '${_formatCurrency(pendingAmount)}원',
                        style: HwahaeTypography.headlineSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: pendingAmount > 0
                ? () => _showSettlementDialog(context, pendingAmount)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: HwahaeColors.primary,
              disabledBackgroundColor: Colors.white.withOpacity(0.5),
              disabledForegroundColor: HwahaeColors.textTertiary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('정산하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: HwahaeTypography.labelMedium.copyWith(
              color: HwahaeColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: HwahaeColors.surface,
            borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
            border: Border.all(color: HwahaeColors.border),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: HwahaeColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.icon,
                        color: HwahaeColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: HwahaeTypography.bodyMedium,
                    ),
                    subtitle: item.subtitle != null
                        ? Text(
                            item.subtitle!,
                            style: HwahaeTypography.captionMedium,
                          )
                        : null,
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: HwahaeColors.textTertiary,
                    ),
                    onTap: item.onTap,
                  ),
                  if (index < items.length - 1)
                    const Divider(height: 1, indent: 72),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showSettlementDialog(BuildContext context, int amount) {
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
              '정산 신청을 하시겠습니까?\n등록된 계좌로 입금됩니다.',
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
                      success ? '정산 신청이 완료되었습니다!' : '정산 신청에 실패했습니다.',
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
        ),
        title: Text('로그아웃', style: HwahaeTypography.headlineSmall),
        content: Text(
          '정말 로그아웃 하시겠습니까?',
          style: HwahaeTypography.bodyMedium,
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
          ElevatedButton(
            onPressed: () async {
              await ApiClient().clearToken();
              if (context.mounted) {
                Navigator.pop(context);
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HwahaeColors.error,
            ),
            child: const Text('로그아웃'),
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

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}
