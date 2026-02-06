import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('고객센터', style: HwahaeTypography.titleMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상담 안내
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: HwahaeColors.gradientPrimary,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
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
                          Icons.headset_mic,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '암행어흥 고객센터',
                            style: HwahaeTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '평일 09:00 - 18:00',
                            style: HwahaeTypography.captionMedium.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildContactButton(
                          icon: Icons.phone,
                          label: '전화 상담',
                          onTap: () => _launchPhone('1588-0000'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildContactButton(
                          icon: Icons.chat_bubble_outline,
                          label: '카카오톡',
                          onTap: () => _launchUrl('https://pf.kakao.com/amhangeoheung'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 자주 묻는 질문
            Text(
              '자주 묻는 질문',
              style: HwahaeTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            _buildFaqItem(
              question: '미션은 어떻게 신청하나요?',
              answer: '홈 화면 또는 미션 탭에서 원하는 미션을 선택한 후 "미션 신청" 버튼을 누르면 됩니다. 배정되면 업체 정보가 공개되며, 3일 이내에 방문해야 합니다.',
            ),
            _buildFaqItem(
              question: '정산은 언제 되나요?',
              answer: '리뷰가 승인되면 정산 대기 금액에 추가됩니다. 정산 신청 후 영업일 기준 3-5일 이내에 등록된 계좌로 입금됩니다.',
            ),
            _buildFaqItem(
              question: '리뷰가 반려되면 어떻게 되나요?',
              answer: '반려 사유를 확인하고 수정하여 다시 제출할 수 있습니다. 수정 기한 내에 제출하지 않으면 미션이 취소됩니다.',
            ),
            _buildFaqItem(
              question: '미션을 취소할 수 있나요?',
              answer: '배정 후 방문 전에는 취소가 가능합니다. 다만, 잦은 취소는 신뢰도에 영향을 줄 수 있습니다.',
            ),
            _buildFaqItem(
              question: '등급은 어떻게 올릴 수 있나요?',
              answer: '미션 완료 횟수, 리뷰 품질, 신뢰도 점수에 따라 등급이 결정됩니다. 양질의 리뷰를 꾸준히 작성하면 등급이 올라갑니다.',
            ),

            const SizedBox(height: 24),

            // 문의하기
            Text(
              '1:1 문의',
              style: HwahaeTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            _buildInquiryItem(
              icon: Icons.email_outlined,
              title: '이메일 문의',
              subtitle: 'support@amhangeoheung.com',
              onTap: () => _launchEmail('support@amhangeoheung.com'),
            ),
            _buildInquiryItem(
              icon: Icons.report_problem_outlined,
              title: '신고하기',
              subtitle: '부적절한 콘텐츠 또는 이용자 신고',
              onTap: () {},
            ),
            _buildInquiryItem(
              icon: Icons.feedback_outlined,
              title: '서비스 개선 제안',
              subtitle: '암행어흥을 더 좋게 만들어주세요',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: HwahaeTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem({
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
        border: Border.all(color: HwahaeColors.border),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            question,
            style: HwahaeTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          children: [
            Text(
              answer,
              style: HwahaeTypography.bodySmall.copyWith(
                color: HwahaeColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInquiryItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
        border: Border.all(color: HwahaeColors.border),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: HwahaeColors.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: HwahaeColors.primary, size: 20),
        ),
        title: Text(title, style: HwahaeTypography.bodyMedium),
        subtitle: Text(
          subtitle,
          style: HwahaeTypography.captionMedium.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: HwahaeColors.textTertiary,
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
