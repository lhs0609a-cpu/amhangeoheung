import 'package:flutter/material.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../data/legal_content.dart';

enum LegalType {
  terms,
  privacy,
  locationPrivacy,
  marketing,
}

class LegalScreen extends StatelessWidget {
  final LegalType type;

  const LegalScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text(_getTitle(), style: HwahaeTypography.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // TODO: 공유 기능
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 마지막 업데이트 날짜
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: HwahaeColors.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '최종 업데이트: ${LegalContent.lastUpdated}',
                style: HwahaeTypography.captionMedium.copyWith(
                  color: HwahaeColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 제목
            Text(
              _getTitle(),
              style: HwahaeTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            // 부제목
            Text(
              _getSubtitle(),
              style: HwahaeTypography.bodyMedium.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // 내용
            SelectableText(
              _getContent(),
              style: HwahaeTypography.bodyMedium.copyWith(
                height: 1.8,
                color: HwahaeColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),

            // 문의 안내
            _buildContactInfo(),
            const SizedBox(height: 100), // 하단 여백
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (type) {
      case LegalType.terms:
        return '이용약관';
      case LegalType.privacy:
        return '개인정보처리방침';
      case LegalType.locationPrivacy:
        return '위치정보 이용약관';
      case LegalType.marketing:
        return '마케팅 정보 수신 동의';
    }
  }

  String _getSubtitle() {
    switch (type) {
      case LegalType.terms:
        return '암행어흥 서비스 이용에 관한 약관입니다.';
      case LegalType.privacy:
        return '개인정보의 수집, 이용, 보호에 관한 방침입니다.';
      case LegalType.locationPrivacy:
        return '위치기반서비스 이용에 관한 약관입니다.';
      case LegalType.marketing:
        return '프로모션 및 이벤트 정보 수신에 관한 안내입니다.';
    }
  }

  String _getContent() {
    switch (type) {
      case LegalType.terms:
        return LegalContent.termsOfService;
      case LegalType.privacy:
        return LegalContent.privacyPolicy;
      case LegalType.locationPrivacy:
        return LegalContent.locationPrivacy;
      case LegalType.marketing:
        return LegalContent.marketingConsent;
    }
  }

  Widget _buildContactInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HwahaeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                size: 20,
                color: HwahaeColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '문의하기',
                style: HwahaeTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '약관에 대한 문의사항이 있으시면 고객센터로 연락해 주세요.',
            style: HwahaeTypography.bodySmall.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '이메일: support@amhangeoheung.com',
            style: HwahaeTypography.bodySmall.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
