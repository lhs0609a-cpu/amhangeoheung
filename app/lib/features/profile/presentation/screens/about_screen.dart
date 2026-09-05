import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/company_info.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _site = 'https://amhangeoheung.com';
  static const String _kakao = 'https://pf.kakao.com/amhangeoheung';
  static const String _instagram = 'https://instagram.com/amhangeoheung';

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: '앱 정보',
      child: Column(
        children: [
          const SizedBox(height: 20),
          const AppMascot.eoheung(size: 116),
          const SizedBox(height: 12),
          Text('암행어흥', style: HwahaeTypography.headlineMedium),
          const SizedBox(height: 4),
          Text(
            '버전 ${CompanyInfo.appVersion}',
            style: HwahaeTypography.bodyMedium.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          AppCard(
            style: AppCardStyle.outlined,
            padding: const EdgeInsets.all(20),
            child: Text(
              '업체가 돈을 내지만, 업체가 결과를 못 바꿉니다.\n'
              '실제로 다녀온 감찰관이 본 대로 적고, 지적한 것이 고쳐졌는지까지 '
              '따라갑니다.',
              style: HwahaeTypography.bodyMedium.copyWith(
                color: HwahaeColors.textSecondary,
                height: 1.7,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppLayout.sectionGap),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                AppListRow(
                  icon: Icons.description_outlined,
                  title: '이용약관',
                  // 앱 안에 약관 화면이 있는데 브라우저로 내보내고 있었다.
                  onTap: () => context.push('/terms'),
                ),
                const AppDivider(indent: 56),
                AppListRow(
                  icon: Icons.privacy_tip_outlined,
                  title: '개인정보 처리방침',
                  onTap: () => context.push('/privacy'),
                ),
                const AppDivider(indent: 56),
                AppListRow(
                  icon: Icons.gavel_outlined,
                  title: '오픈소스 라이선스',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: '암행어흥',
                    applicationVersion: CompanyInfo.appVersion,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppLayout.cardGap),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                AppListRow(
                  icon: Icons.star_outline_rounded,
                  title: '앱 평가하기',
                  onTap: () => _launchStore(context),
                ),
                const AppDivider(indent: 56),
                AppListRow(
                  icon: Icons.share_outlined,
                  title: '친구에게 공유하기',
                  onTap: _shareApp,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppLayout.sectionGap),
          Text(
            CompanyInfo.companyName,
            style: HwahaeTypography.labelMedium.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '사업자등록번호: ${CompanyInfo.businessRegistrationNumber}\n'
            '대표: ${CompanyInfo.ceoName}\n'
            '주소: ${CompanyInfo.address}\n'
            '고객센터: ${CompanyInfo.customerServicePhone}',
            style: HwahaeTypography.captionMedium.copyWith(
              color: HwahaeColors.textTertiary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialButton(
                icon: Icons.language_rounded,
                tooltip: '공식 웹사이트',
                onTap: () => _launch(context, _site),
              ),
              const SizedBox(width: 14),
              _SocialButton(
                icon: Icons.chat_bubble_outline_rounded,
                tooltip: '카카오톡 채널',
                onTap: () => _launch(context, _kakao),
              ),
              const SizedBox(width: 14),
              _SocialButton(
                icon: Icons.camera_alt_outlined,
                tooltip: '인스타그램',
                onTap: () => _launch(context, _instagram),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            // 연도를 손으로 적어두면 해가 바뀔 때마다 낡는다.
            '© ${DateTime.now().year} ${CompanyInfo.companyName}. '
            'All rights reserved.',
            style: HwahaeTypography.captionMedium.copyWith(
              color: HwahaeColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const AppBottomSpacer.plain(extra: 12),
        ],
      ),
    );
  }

  Future<void> _launch(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final opened = await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && context.mounted) {
      AppToast.error(context, '링크를 열 수 없습니다');
    }
  }

  Future<void> _launchStore(BuildContext context) {
    final url = !kIsWeb && Platform.isIOS
        ? 'https://apps.apple.com/app/${CompanyInfo.iosAppId}'
        : 'https://play.google.com/store/apps/details'
            '?id=${CompanyInfo.androidPackageId}';
    return _launch(context, url);
  }

  Future<void> _shareApp() async {
    // 스토어 주소를 손으로 또 적지 않는다. 예전에는 패키지 ID 가 여기에만
    // 하드코딩돼 있어서 CompanyInfo 를 바꿔도 공유 문구는 옛 주소를 가리켰다.
    final text = '''
암행어흥 — 업체가 돈을 내지만, 업체가 결과를 못 바꾸는 리뷰 플랫폼

Android: https://play.google.com/store/apps/details?id=${CompanyInfo.androidPackageId}
iOS: https://apps.apple.com/app/${CompanyInfo.iosAppId}

공식 웹사이트: $_site
''';

    await Share.share(text, subject: '암행어흥 앱을 추천합니다!');
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onTap,
      background: HwahaeColors.surfaceVariant,
      color: HwahaeColors.textSecondary,
    );
  }
}
