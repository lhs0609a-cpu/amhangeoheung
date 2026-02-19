import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../../../core/providers/user_type_provider.dart';

/// 회원가입 후 사용자 유형 선택 화면
class UserTypeSelectionScreen extends ConsumerStatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  ConsumerState<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState
    extends ConsumerState<UserTypeSelectionScreen> {
  UserType? _selectedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              // 헤더
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: HwahaeColors.gradientPrimary,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '어떻게 사용하실 건가요?',
                style: HwahaeTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: HwahaeColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '맞춤 경험을 위해 사용 유형을 선택해주세요.\n언제든지 설정에서 변경할 수 있습니다.',
                style: HwahaeTypography.bodyMedium.copyWith(
                  color: HwahaeColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // 유형 선택 카드
              Expanded(
                child: Column(
                  children: [
                    _buildTypeCard(
                      type: UserType.reviewer,
                      title: '리뷰어',
                      description: '미션을 수행하고 리뷰를 작성하여 보상을 받아요',
                      icon: Icons.rate_review_rounded,
                      gradient: HwahaeColors.gradientWarm,
                      features: ['미션 수행 및 보상', '리뷰어 등급 시스템', '정산 관리'],
                    ),
                    const SizedBox(height: 16),
                    _buildTypeCard(
                      type: UserType.consumer,
                      title: '소비자',
                      description: '인증된 리뷰를 보고 신뢰할 수 있는 업체를 찾아요',
                      icon: Icons.person_rounded,
                      gradient: HwahaeColors.gradientPrimary,
                      features: ['인증 리뷰 열람', '업체 검색 및 랭킹', '리뷰 요청'],
                    ),
                    const SizedBox(height: 16),
                    _buildTypeCard(
                      type: UserType.business,
                      title: '업체',
                      description: '신뢰도를 관리하고 미스터리쇼핑을 요청해요',
                      icon: Icons.storefront_rounded,
                      gradient: HwahaeColors.gradientAccent,
                      features: ['신뢰도 분석 대시보드', '미션 등록 및 관리', '선공개 리뷰 확인'],
                    ),
                  ],
                ),
              ),

              // 시작 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedType != null ? _onConfirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HwahaeColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: HwahaeColors.surfaceContainer,
                    disabledForegroundColor: HwahaeColors.textDisabled,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(HwahaeTheme.radiusMD),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _selectedType != null ? '시작하기' : '유형을 선택해주세요',
                    style: HwahaeTypography.labelLarge.copyWith(
                      color: _selectedType != null
                          ? Colors.white
                          : HwahaeColors.textDisabled,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required UserType type,
    required String title,
    required String description,
    required IconData icon,
    required List<Color> gradient,
    required List<String> features,
  }) {
    final isSelected = _selectedType == type;

    return Expanded(
      child: Semantics(
        label: '$title 유형 선택',
        selected: isSelected,
        button: true,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedType = type;
            });
          },
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? gradient[0].withOpacity(0.08)
                  : HwahaeColors.surface,
              borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
              border: Border.all(
                color: isSelected ? gradient[0] : HwahaeColors.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: gradient[0].withOpacity(0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // 아이콘
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(colors: gradient)
                        : null,
                    color: isSelected ? null : HwahaeColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : HwahaeColors.textSecondary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                // 텍스트
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: HwahaeTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? gradient[0]
                              : HwahaeColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: HwahaeTypography.captionLarge.copyWith(
                          color: HwahaeColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 체크
                if (isSelected)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onConfirm() async {
    if (_selectedType == null) return;

    // 사용자 유형 저장 (Riverpod + SharedPreferences)
    await ref
        .read(userTypeProvider.notifier)
        .setUserType(_selectedType!);

    if (!mounted) return;

    // 유형에 따라 적절한 홈으로 이동
    switch (_selectedType!) {
      case UserType.business:
        context.go('/dashboard');
        break;
      case UserType.reviewer:
      case UserType.consumer:
        context.go('/home');
        break;
    }
  }
}
