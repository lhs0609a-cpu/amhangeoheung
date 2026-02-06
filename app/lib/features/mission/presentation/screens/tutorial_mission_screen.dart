import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';

/// 튜토리얼 미션 화면
/// 리뷰어로 처음 시작하는 사용자를 위한 가이드 미션
class TutorialMissionScreen extends StatefulWidget {
  const TutorialMissionScreen({super.key});

  @override
  State<TutorialMissionScreen> createState() => _TutorialMissionScreenState();
}

class _TutorialMissionScreenState extends State<TutorialMissionScreen> {
  int _currentStep = 0;

  final List<_TutorialStep> _steps = [
    _TutorialStep(
      icon: Icons.location_on_rounded,
      title: '위치 인증',
      description: '미션 장소에 도착하면 GPS로 위치를 인증해요',
      detail: '건물 내부에서는 Wi-Fi를 켜면 더 정확해요',
    ),
    _TutorialStep(
      icon: Icons.receipt_long_rounded,
      title: '영수증 인증',
      description: '결제 후 영수증을 촬영해 인증해요',
      detail: '날짜와 금액이 잘 보이도록 촬영해주세요',
    ),
    _TutorialStep(
      icon: Icons.timer_rounded,
      title: '체류 시간',
      description: '미션에 맞는 최소 체류 시간을 지켜요',
      detail: '음식점은 보통 30분, 카페는 20분 정도예요',
    ),
    _TutorialStep(
      icon: Icons.rate_review_rounded,
      title: '솔직한 리뷰',
      description: '장점과 단점을 솔직하게 작성해요',
      detail: '단점도 꼭 작성해야 신뢰도가 올라가요',
    ),
    _TutorialStep(
      icon: Icons.payments_rounded,
      title: '보상 지급',
      description: '리뷰 승인 후 보상이 지급돼요',
      detail: '등급이 높아지면 더 많은 보상을 받아요',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              HwahaeColors.background,
              HwahaeColors.warning.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressBar(),
              Expanded(
                child: _buildStepContent(),
              ),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.go('/login'),
            child: Row(
              children: [
                Icon(
                  Icons.close,
                  size: 24,
                  color: HwahaeColors.textSecondary,
                ),
              ],
            ),
          ),
          Text(
            '리뷰어 튜토리얼',
            style: HwahaeTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: () => context.go('/login'),
            style: TextButton.styleFrom(
              foregroundColor: HwahaeColors.textSecondary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(60, 36),
            ),
            child: const Text('건너뛰기'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(_steps.length, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < _steps.length - 1 ? 4 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isCompleted
                    ? HwahaeColors.warning
                    : isCurrent
                        ? HwahaeColors.warning.withOpacity(0.5)
                        : HwahaeColors.surfaceVariant,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    final step = _steps[_currentStep];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        key: ValueKey(_currentStep),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 스텝 번호
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: HwahaeColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${_currentStep + 1}',
                  style: HwahaeTypography.titleMedium.copyWith(
                    color: HwahaeColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 아이콘
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: HwahaeColors.gradientWarm,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: HwahaeColors.warning.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(
                step.icon,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            // 제목
            Text(
              step.title,
              style: HwahaeTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // 설명
            Text(
              step.description,
              style: HwahaeTypography.bodyLarge.copyWith(
                color: HwahaeColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // 팁 박스
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HwahaeColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: HwahaeColors.warning.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: HwahaeColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step.detail,
                      style: HwahaeTypography.bodyMedium.copyWith(
                        color: HwahaeColors.warning,
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

  Widget _buildBottomSection() {
    final isLastStep = _currentStep == _steps.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          // 메인 버튼
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: HwahaeColors.gradientWarm,
              ),
              borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
              boxShadow: [
                BoxShadow(
                  color: HwahaeColors.warning.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (isLastStep) {
                    // 튜토리얼 완료 → 회원가입으로
                    context.go('/register');
                  } else {
                    setState(() {
                      _currentStep++;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastStep ? '회원가입하고 시작하기' : '다음',
                      style: HwahaeTypography.button.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLastStep ? Icons.arrow_forward : Icons.arrow_forward_ios,
                      size: 18,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 이전 버튼
          if (_currentStep > 0)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      size: 14,
                      color: HwahaeColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '이전',
                      style: HwahaeTypography.bodyMedium.copyWith(
                        color: HwahaeColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TutorialStep {
  final IconData icon;
  final String title;
  final String description;
  final String detail;

  _TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.detail,
  });
}
