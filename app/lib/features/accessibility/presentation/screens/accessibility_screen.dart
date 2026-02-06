import 'package:flutter/material.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';

class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  bool _largeText = false;
  bool _highContrast = false;
  bool _reduceMotion = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('접근성', style: HwahaeTypography.titleMedium),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSwitchTile(
            icon: Icons.text_fields,
            title: '큰 텍스트',
            subtitle: '텍스트 크기를 크게 표시합니다',
            value: _largeText,
            onChanged: (value) => setState(() => _largeText = value),
          ),
          _buildSwitchTile(
            icon: Icons.contrast,
            title: '고대비 모드',
            subtitle: '색상 대비를 높여 가독성을 향상시킵니다',
            value: _highContrast,
            onChanged: (value) => setState(() => _highContrast = value),
          ),
          _buildSwitchTile(
            icon: Icons.motion_photos_off,
            title: '모션 줄이기',
            subtitle: '애니메이션과 전환 효과를 줄입니다',
            value: _reduceMotion,
            onChanged: (value) => setState(() => _reduceMotion = value),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('도움말', style: HwahaeTypography.titleSmall),
                const SizedBox(height: 8),
                Text(
                  '접근성 기능은 시각, 청각, 운동 능력에 어려움이 있는 사용자를 위해 제공됩니다. 추가적인 도움이 필요하시면 고객센터로 문의해주세요.',
                  style: HwahaeTypography.bodySmall.copyWith(
                    color: HwahaeColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: HwahaeColors.textSecondary),
      title: Text(title, style: HwahaeTypography.bodyMedium),
      subtitle: Text(
        subtitle,
        style: HwahaeTypography.captionMedium.copyWith(
          color: HwahaeColors.textSecondary,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: HwahaeColors.primary,
    );
  }
}
