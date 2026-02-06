import 'package:flutter/material.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('설정', style: HwahaeTypography.titleMedium),
      ),
      body: ListView(
        children: [
          _buildSection('계정', [
            _buildListTile(Icons.person_outline, '프로필 수정'),
            _buildListTile(Icons.lock_outline, '비밀번호 변경'),
            _buildListTile(Icons.notifications_outlined, '알림 설정'),
          ]),
          _buildSection('앱 설정', [
            _buildListTile(Icons.dark_mode_outlined, '다크 모드'),
            _buildListTile(Icons.language, '언어'),
          ]),
          _buildSection('정보', [
            _buildListTile(Icons.description_outlined, '이용약관'),
            _buildListTile(Icons.privacy_tip_outlined, '개인정보처리방침'),
            _buildListTile(Icons.info_outline, '앱 버전 1.0.0'),
          ]),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: () {},
              child: Text(
                '로그아웃',
                style: HwahaeTypography.labelLarge.copyWith(
                  color: HwahaeColors.error,
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

  Widget _buildListTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: HwahaeColors.textSecondary),
      title: Text(title, style: HwahaeTypography.bodyMedium),
      trailing: const Icon(Icons.chevron_right, color: HwahaeColors.textTertiary),
      onTap: () {},
    );
  }
}
