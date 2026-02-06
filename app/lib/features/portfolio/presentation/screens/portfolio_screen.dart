import 'package:flutter/material.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';

class PortfolioScreen extends StatelessWidget {
  final String userId;

  const PortfolioScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('포트폴리오', style: HwahaeTypography.titleMedium),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 프로필 헤더
            Container(
              padding: const EdgeInsets.all(24),
              color: HwahaeColors.surface,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: HwahaeColors.primaryContainer,
                    child: const Icon(Icons.person, size: 48, color: HwahaeColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text('리뷰어 닉네임', style: HwahaeTypography.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    '골드 리뷰어',
                    style: HwahaeTypography.labelMedium.copyWith(
                      color: HwahaeColors.gradeGold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 통계
            Container(
              padding: const EdgeInsets.all(16),
              color: HwahaeColors.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('완료 미션', '24'),
                  _buildStat('작성 리뷰', '24'),
                  _buildStat('신뢰도', '92%'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 리뷰 목록 placeholder
            Container(
              padding: const EdgeInsets.all(16),
              color: HwahaeColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('작성한 리뷰', style: HwahaeTypography.titleMedium),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '리뷰 목록이 여기에 표시됩니다',
                      style: HwahaeTypography.bodyMedium.copyWith(
                        color: HwahaeColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: HwahaeTypography.headlineMedium),
        const SizedBox(height: 4),
        Text(
          label,
          style: HwahaeTypography.captionMedium.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
