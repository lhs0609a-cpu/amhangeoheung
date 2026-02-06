import 'package:flutter/material.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: '미션, 업체, 리뷰 검색',
            hintStyle: HwahaeTypography.bodyMedium.copyWith(
              color: HwahaeColors.textTertiary,
            ),
            border: InputBorder.none,
            filled: false,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: HwahaeColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              '검색어를 입력해주세요',
              style: HwahaeTypography.bodyMedium.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
