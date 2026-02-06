import 'package:flutter/material.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _pushEnabled = true;
  bool _missionNotification = true;
  bool _reviewNotification = true;
  bool _settlementNotification = true;
  bool _marketingNotification = false;
  bool _nightNotification = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('알림 설정', style: HwahaeTypography.titleMedium),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 푸시 알림 전체 설정
            _buildSection(
              title: '알림 허용',
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications_active,
                  title: '푸시 알림',
                  subtitle: '모든 알림을 켜거나 끕니다',
                  value: _pushEnabled,
                  onChanged: (value) {
                    setState(() {
                      _pushEnabled = value;
                      if (!value) {
                        _missionNotification = false;
                        _reviewNotification = false;
                        _settlementNotification = false;
                        _marketingNotification = false;
                      }
                    });
                  },
                ),
              ],
            ),

            // 알림 종류별 설정
            _buildSection(
              title: '알림 종류',
              children: [
                _buildSwitchTile(
                  icon: Icons.flag,
                  title: '미션 알림',
                  subtitle: '새 미션, 배정, 마감 알림',
                  value: _missionNotification,
                  enabled: _pushEnabled,
                  onChanged: (value) {
                    setState(() => _missionNotification = value);
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.rate_review,
                  title: '리뷰 알림',
                  subtitle: '리뷰 승인, 반려, 수정 요청 알림',
                  value: _reviewNotification,
                  enabled: _pushEnabled,
                  onChanged: (value) {
                    setState(() => _reviewNotification = value);
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.payments,
                  title: '정산 알림',
                  subtitle: '정산 완료, 입금 알림',
                  value: _settlementNotification,
                  enabled: _pushEnabled,
                  onChanged: (value) {
                    setState(() => _settlementNotification = value);
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.campaign,
                  title: '마케팅 알림',
                  subtitle: '이벤트, 프로모션 알림',
                  value: _marketingNotification,
                  enabled: _pushEnabled,
                  onChanged: (value) {
                    setState(() => _marketingNotification = value);
                  },
                ),
              ],
            ),

            // 추가 설정
            _buildSection(
              title: '추가 설정',
              children: [
                _buildSwitchTile(
                  icon: Icons.nightlight_round,
                  title: '야간 알림',
                  subtitle: '21:00 - 08:00 알림 허용',
                  value: _nightNotification,
                  enabled: _pushEnabled,
                  onChanged: (value) {
                    setState(() => _nightNotification = value);
                  },
                ),
              ],
            ),

            // 안내 문구
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HwahaeColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: HwahaeColors.textTertiary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '기기 설정에서 알림을 차단한 경우, 앱 알림이 수신되지 않을 수 있습니다.',
                        style: HwahaeTypography.captionMedium.copyWith(
                          color: HwahaeColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
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
            children: children.asMap().entries.map((entry) {
              final index = entry.key;
              final child = entry.value;
              return Column(
                children: [
                  child,
                  if (index < children.length - 1)
                    const Divider(height: 1, indent: 72),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled
              ? HwahaeColors.primaryContainer
              : HwahaeColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: enabled ? HwahaeColors.primary : HwahaeColors.textTertiary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: HwahaeTypography.bodyMedium.copyWith(
          color: enabled ? HwahaeColors.textPrimary : HwahaeColors.textTertiary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: HwahaeTypography.captionMedium.copyWith(
          color: HwahaeColors.textTertiary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: HwahaeColors.primary,
      ),
    );
  }
}
