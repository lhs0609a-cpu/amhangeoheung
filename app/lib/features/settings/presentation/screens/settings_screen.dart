import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/providers/user_type_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userType = ref.watch(userTypeProvider);
    final userTypeLabel = switch (userType) {
      UserType.reviewer => '리뷰어',
      UserType.consumer => '소비자',
      UserType.business => '업체',
    };

    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('설정', style: HwahaeTypography.titleMedium),
      ),
      body: ListView(
        children: [
          _buildSection('계정', [
            _buildListTile(
              context,
              Icons.person_outline,
              '프로필 수정',
              onTap: () => context.push('/edit-profile'),
            ),
            _buildListTile(
              context,
              Icons.lock_outline,
              '비밀번호 변경',
              onTap: () => context.push('/forgot-password'),
            ),
            _buildListTile(
              context,
              Icons.notifications_outlined,
              '알림 설정',
              onTap: () => context.push('/notifications-settings'),
            ),
            _buildListTile(
              context,
              Icons.swap_horiz_rounded,
              '사용자 유형 변경',
              subtitle: '현재: $userTypeLabel',
              onTap: () => context.push('/select-user-type'),
            ),
          ]),
          _buildSection('정보', [
            _buildListTile(
              context,
              Icons.description_outlined,
              '이용약관',
              onTap: () => context.push('/terms'),
            ),
            _buildListTile(
              context,
              Icons.privacy_tip_outlined,
              '개인정보처리방침',
              onTap: () => context.push('/privacy'),
            ),
            _buildListTile(
              context,
              Icons.info_outline,
              '앱 정보',
              onTap: () => context.push('/about'),
            ),
          ]),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: () => _showLogoutDialog(context),
              child: Text(
                '로그아웃',
                style: HwahaeTypography.labelLarge.copyWith(
                  color: HwahaeColors.error,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextButton(
              onPressed: () => _showDeleteAccountDialog(context),
              child: Text(
                '회원 탈퇴',
                style: HwahaeTypography.labelSmall.copyWith(
                  color: HwahaeColors.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: HwahaeTypography.labelMedium.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context,
    IconData icon,
    String title, {
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: HwahaeColors.textSecondary),
      title: Text(title, style: HwahaeTypography.bodyMedium),
      subtitle: subtitle != null
          ? Text(subtitle, style: HwahaeTypography.captionMedium.copyWith(
              color: HwahaeColors.textTertiary,
            ))
          : null,
      trailing: const Icon(Icons.chevron_right, color: HwahaeColors.textTertiary),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              const storage = FlutterSecureStorage();
              await storage.delete(key: 'auth_token');
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: Text(
              '로그아웃',
              style: TextStyle(color: HwahaeColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text('탈퇴 시 모든 데이터가 삭제되며 복구할 수 없습니다.\n정말 탈퇴하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // TODO: 회원탈퇴 API 연동 후 로그인 화면으로 이동
              const storage = FlutterSecureStorage();
              await storage.delete(key: 'auth_token');
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: Text(
              '탈퇴하기',
              style: TextStyle(color: HwahaeColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
