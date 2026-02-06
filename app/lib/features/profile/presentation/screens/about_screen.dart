import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('앱 정보', style: HwahaeTypography.titleMedium),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),

            // 앱 로고 및 버전
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: HwahaeColors.gradientPrimary,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: HwahaeColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified_user,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '암행어흥',
              style: HwahaeTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '버전 1.0.0',
              style: HwahaeTypography.bodyMedium.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // 앱 소개
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: HwahaeColors.surface,
                  borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
                  border: Border.all(color: HwahaeColors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      '암행어흥은 신뢰할 수 있는 리뷰 플랫폼입니다.\n'
                      '실제 방문 경험을 바탕으로 진솔한 리뷰를 작성하고,\n'
                      '합당한 보상을 받으세요.',
                      style: HwahaeTypography.bodyMedium.copyWith(
                        color: HwahaeColors.textSecondary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 메뉴 리스트
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: HwahaeColors.surface,
                  borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
                  border: Border.all(color: HwahaeColors.border),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.description_outlined,
                      title: '이용약관',
                      onTap: () => _launchUrl('https://amhangeoheung.com/terms'),
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildMenuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: '개인정보 처리방침',
                      onTap: () => _launchUrl('https://amhangeoheung.com/privacy'),
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildMenuItem(
                      icon: Icons.gavel_outlined,
                      title: '오픈소스 라이선스',
                      onTap: () => _showLicenses(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: HwahaeColors.surface,
                  borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
                  border: Border.all(color: HwahaeColors.border),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.star_outline,
                      title: '앱 평가하기',
                      onTap: () => _launchStore(),
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildMenuItem(
                      icon: Icons.share_outlined,
                      title: '친구에게 공유하기',
                      onTap: () => _shareApp(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 회사 정보
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    '(주) 암행어흥',
                    style: HwahaeTypography.labelMedium.copyWith(
                      color: HwahaeColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '사업자등록번호: 123-45-67890\n'
                    '대표: 홍길동\n'
                    '주소: 서울특별시 강남구 테헤란로 123\n'
                    '고객센터: 1588-0000',
                    style: HwahaeTypography.captionMedium.copyWith(
                      color: HwahaeColors.textTertiary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 소셜 링크
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(
                  icon: Icons.language,
                  onTap: () => _launchUrl('https://amhangeoheung.com'),
                ),
                const SizedBox(width: 16),
                _buildSocialButton(
                  icon: Icons.chat_bubble,
                  onTap: () => _launchUrl('https://pf.kakao.com/amhangeoheung'),
                ),
                const SizedBox(width: 16),
                _buildSocialButton(
                  icon: Icons.camera_alt,
                  onTap: () => _launchUrl('https://instagram.com/amhangeoheung'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 저작권
            Text(
              '© 2024 암행어흥. All rights reserved.',
              style: HwahaeTypography.captionMedium.copyWith(
                color: HwahaeColors.textTertiary,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: HwahaeColors.textSecondary),
      title: Text(title, style: HwahaeTypography.bodyMedium),
      trailing: const Icon(
        Icons.chevron_right,
        color: HwahaeColors.textTertiary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: HwahaeColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: HwahaeColors.textSecondary,
          size: 24,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: '암행어흥',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: HwahaeColors.gradientPrimary,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.verified_user,
            size: 32,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _launchStore() async {
    // TODO: 실제 스토어 링크로 교체
    const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.amhangeoheung.app';
    const appStoreUrl = 'https://apps.apple.com/app/amhangeoheung';

    // 플랫폼에 따라 적절한 스토어로 이동
    await _launchUrl(playStoreUrl);
  }

  Future<void> _shareApp() async {
    const shareText = '''
암행어흥 - 신뢰할 수 있는 리뷰 플랫폼

실제 방문 경험을 바탕으로 진솔한 리뷰를 작성하고, 합당한 보상을 받으세요!

다운로드:
Android: https://play.google.com/store/apps/details?id=com.amhangeoheung.app
iOS: https://apps.apple.com/app/amhangeoheung

공식 웹사이트: https://amhangeoheung.com
''';

    await Share.share(
      shareText,
      subject: '암행어흥 앱을 추천합니다!',
    );
  }
}
