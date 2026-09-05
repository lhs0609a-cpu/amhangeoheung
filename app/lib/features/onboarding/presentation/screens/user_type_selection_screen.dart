import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_type_provider.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';

/// 회원가입 후 사용자 유형 선택 화면
class UserTypeSelectionScreen extends ConsumerStatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  ConsumerState<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

/// 유형 하나를 설명하는 데 필요한 것들.
class _TypeOption {
  const _TypeOption({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.features,
  });

  final UserType type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> features;
}

/// 인주색(secondary)은 쓰지 않는다. 감찰과 지적에만 쓰기로 한 색이라
/// 유형 선택 같은 중립적인 자리에 놓으면 그 약속이 흐려진다.
const _options = <_TypeOption>[
  _TypeOption(
    type: UserType.reviewer,
    title: '리뷰어',
    description: '미션을 수행하고 리뷰를 써서 보수를 받아요',
    icon: Icons.rate_review_rounded,
    color: HwahaeColors.primary,
    features: ['미션 수행 및 보수', '리뷰어 등급', '정산 관리'],
  ),
  _TypeOption(
    type: UserType.consumer,
    title: '소비자',
    description: '검증된 리뷰를 보고 믿을 만한 가게를 찾아요',
    icon: Icons.person_rounded,
    color: HwahaeColors.info,
    features: ['검증 리뷰 열람', '업체 검색·랭킹', '리뷰 요청'],
  ),
  _TypeOption(
    type: UserType.business,
    title: '업체',
    description: '신뢰도를 관리하고 감찰을 요청해요',
    icon: Icons.storefront_rounded,
    color: HwahaeColors.accent,
    features: ['신뢰도 분석', '미션 등록·관리', '선공개 리뷰 확인'],
  ),
];

class _UserTypeSelectionScreenState
    extends ConsumerState<UserTypeSelectionScreen> {
  UserType? _selectedType;

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      showBack: false,
      bottomBar: AppBottomActionBar(
        child: AppButton(
          label: _selectedType != null ? '시작하기' : '유형을 골라주세요',
          onPressed: _selectedType != null ? _onConfirm : null,
          size: AppButtonSize.large,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const AppMascot.eoheung(size: 84),
          const SizedBox(height: 16),
          Text(
            '어떻게 쓰실 건가요?',
            style: HwahaeTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '고른 유형에 맞게 화면이 바뀝니다.\n설정에서 언제든 바꿀 수 있어요.',
            style: HwahaeTypography.bodyMedium.copyWith(
              color: HwahaeColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          for (final option in _options) ...[
            _TypeCard(
              option: option,
              selected: _selectedType == option.type,
              onTap: () => setState(() => _selectedType = option.type),
            ),
            const SizedBox(height: AppLayout.cardGap),
          ],
          const AppBottomSpacer.plain(),
        ],
      ),
    );
  }

  void _onConfirm() async {
    if (_selectedType == null) return;

    // 사용자 유형 저장 (Riverpod + SharedPreferences)
    await ref.read(userTypeProvider.notifier).setUserType(_selectedType!);

    if (!mounted) return;

    // 유형에 따라 적절한 진입점으로 이동.
    // 업체는 가치(무료체험·선공개 보호) 슬라이드를 먼저 거친다.
    switch (_selectedType!) {
      case UserType.business:
        context.go('/business-onboarding');
        break;
      case UserType.reviewer:
      case UserType.consumer:
        context.go('/home');
        break;
    }
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _TypeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${option.title} 유형',
      selected: selected,
      button: true,
      child: AppCard(
        style: AppCardStyle.outlined,
        onTap: onTap,
        borderColor: selected ? option.color : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected
                        ? option.color
                        : HwahaeColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    option.icon,
                    size: 24,
                    // 골드 면 위의 흰 아이콘은 1.86:1 이다. 유형마다 밝기가
                    // 다르므로 색을 고정하지 않고 배경에서 고른다.
                    color: selected
                        ? HwahaeColors.onColor(option.color)
                        : HwahaeColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: HwahaeTypography.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        option.description,
                        style: HwahaeTypography.captionLarge.copyWith(
                          color: HwahaeColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 24,
                    color: option.color,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final feature in option.features)
                  AppBadge(
                    label: feature,
                    color: selected
                        ? option.color
                        : HwahaeColors.textTertiary,
                    compact: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
