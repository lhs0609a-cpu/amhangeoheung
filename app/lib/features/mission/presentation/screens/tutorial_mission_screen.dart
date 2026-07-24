import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../providers/tutorial_provider.dart';

class TutorialMissionScreen extends ConsumerStatefulWidget {
  const TutorialMissionScreen({super.key});

  @override
  ConsumerState<TutorialMissionScreen> createState() => _TutorialMissionScreenState();
}

class _TutorialMissionScreenState extends ConsumerState<TutorialMissionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // 서약 체크박스 상태
  final List<bool> _pledgeChecks = [false, false, false];

  final List<_TutorialStep> _steps = [
    _TutorialStep(
      icon: Icons.handshake,
      title: '암행어사의 취지',
      description: '왜 솔직한 리뷰가 중요할까요?',
      detail: '',
    ),
    _TutorialStep(
      icon: Icons.verified_user_rounded,
      title: '서약서',
      description: '암행어사로서의 약속',
      detail: '',
    ),
    _TutorialStep(
      icon: Icons.school_rounded,
      title: '교육 안내',
      description: '3일간의 교육 과정을 소개합니다',
      detail: '',
    ),
    _TutorialStep(
      icon: Icons.arrow_circle_right_rounded,
      title: '다음 단계',
      description: '회원가입 후 교육을 시작하세요',
      detail: '',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _animController.reset();
    _animController.forward();
    if (step > ref.read(tutorialProvider).currentStep) {
      ref.read(tutorialProvider.notifier).nextStep();
    } else {
      ref.read(tutorialProvider.notifier).previousStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tutorialState = ref.watch(tutorialProvider);
    final currentStep = tutorialState.currentStep;
    final isCompleted = tutorialState.isCompleted;

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
              _buildProgressBar(currentStep),
              Expanded(
                child: isCompleted
                    ? _buildCompletionScreen()
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildStepContent(currentStep),
                      ),
              ),
              if (!isCompleted) _buildBottomSection(currentStep),
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
            child: const Icon(Icons.close, size: 24, color: HwahaeColors.textSecondary),
          ),
          Text(
            '리뷰어 온보딩',
            style: HwahaeTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
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

  Widget _buildProgressBar(int currentStep) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(_steps.length, (index) {
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep;
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

  Widget _buildStepContent(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return _buildPurposeStep();
      case 1:
        return _buildPledgeStep();
      case 2:
        return _buildEducationInfoStep();
      case 3:
        return _buildNextStepStep();
      default:
        return _buildPurposeStep();
    }
  }

  // Step 1: 암행어사의 취지
  Widget _buildPurposeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildStepIcon(Icons.handshake, HwahaeColors.gradientPrimary, HwahaeColors.primary),
          const SizedBox(height: 32),
          Text(
            '암행어사의 취지',
            style: HwahaeTypography.headlineMedium.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '왜 솔직한 리뷰가 중요할까요?',
            style: HwahaeTypography.bodyLarge.copyWith(
              color: HwahaeColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildInfoCard(
            icon: Icons.people_alt_rounded,
            title: '소비자를 위한 가치',
            description: '조작되지 않은 솔직한 리뷰로\n소비자가 현명한 선택을 할 수 있도록 돕습니다.',
            color: HwahaeColors.primary,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.store_rounded,
            title: '업체를 위한 가치',
            description: '객관적인 평가를 통해 업체가\n실질적으로 개선할 수 있는 인사이트를 제공합니다.',
            color: HwahaeColors.accent,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.shield_rounded,
            title: '리뷰어의 책임',
            description: '암행어사는 신분을 숨기고 객관적으로 평가하며,\n정직함과 공정함을 최우선으로 합니다.',
            color: HwahaeColors.warning,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HwahaeColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: HwahaeColors.warning.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: HwahaeColors.warning, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '리뷰 한 건이 수천 명의 소비자 선택에 영향을 줍니다.\n그만큼 책임감이 필요한 역할이에요.',
                    style: HwahaeTypography.bodyMedium.copyWith(color: HwahaeColors.warning),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // Step 2: 서약서
  Widget _buildPledgeStep() {
    final allChecked = _pledgeChecks.every((c) => c);
    final tutorialState = ref.watch(tutorialProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildStepIcon(Icons.verified_user_rounded, HwahaeColors.gradientAccent, HwahaeColors.accent),
          const SizedBox(height: 32),
          Text(
            '서약서',
            style: HwahaeTypography.headlineMedium.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '암행어사로서 다음을 약속합니다',
            style: HwahaeTypography.bodyLarge.copyWith(
              color: HwahaeColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildPledgeItem(
            index: 0,
            title: '정직한 리뷰 작성',
            description: '개인적 감정이나 외부 압력 없이, 오직 경험에 기반한 솔직하고 객관적인 리뷰를 작성합니다.',
          ),
          const SizedBox(height: 16),
          _buildPledgeItem(
            index: 1,
            title: '신분 비공개 준수',
            description: '미션 수행 중 리뷰어 신분을 절대 밝히지 않으며, 일반 소비자로서 자연스럽게 행동합니다.',
          ),
          const SizedBox(height: 16),
          _buildPledgeItem(
            index: 2,
            title: '공정성과 윤리 준수',
            description: '대가를 받고 리뷰를 조작하거나, 담합하거나, 허위 사실을 기재하지 않습니다.',
          ),
          const SizedBox(height: 24),
          // 전체 동의 버튼
          if (!tutorialState.pledgeAccepted)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    final newValue = !allChecked;
                    for (int i = 0; i < _pledgeChecks.length; i++) {
                      _pledgeChecks[i] = newValue;
                    }
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: allChecked ? HwahaeColors.accent : HwahaeColors.surfaceVariant,
                    width: 2,
                  ),
                  backgroundColor: allChecked ? HwahaeColors.accent.withOpacity(0.05) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      allChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: allChecked ? HwahaeColors.accent : HwahaeColors.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '전체 동의',
                      style: HwahaeTypography.button.copyWith(
                        color: allChecked ? HwahaeColors.accent : HwahaeColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (tutorialState.pledgeAccepted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '서약에 동의했습니다',
                    style: HwahaeTypography.button.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // Step 3: 교육 안내
  Widget _buildEducationInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildStepIcon(Icons.school_rounded, HwahaeColors.gradientCool, HwahaeColors.secondary),
          const SizedBox(height: 32),
          Text(
            '교육 안내',
            style: HwahaeTypography.headlineMedium.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '3일간의 교육 과정을 이수해야\n암행어사 자격이 부여됩니다',
            style: HwahaeTypography.bodyLarge.copyWith(
              color: HwahaeColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildDayCard(
            day: 1,
            title: '암행어흥의 철학',
            description: '왜 객관적 리뷰가 중요한지, 평가 기준을 학습합니다.',
            icon: Icons.menu_book_rounded,
            color: HwahaeColors.primary,
          ),
          const SizedBox(height: 16),
          _buildDayCard(
            day: 2,
            title: '현장 행동 수칙',
            description: '신분 노출 방지, 사진 촬영 가이드, 문제 상황 대응법을 배웁니다.',
            icon: Icons.directions_walk_rounded,
            color: HwahaeColors.accent,
          ),
          const SizedBox(height: 16),
          _buildDayCard(
            day: 3,
            title: '리뷰 작성 + 종합시험',
            description: '객관적 글쓰기 실습 후 종합 시험을 통해 자격을 인증합니다.',
            icon: Icons.edit_note_rounded,
            color: HwahaeColors.warning,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HwahaeColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: HwahaeColors.warning.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: HwahaeColors.warning, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '교육은 회원가입 후 앱에서 진행됩니다.\n하루에 한 과정씩, 3일이면 완료할 수 있어요.',
                    style: HwahaeTypography.bodyMedium.copyWith(color: HwahaeColors.warning),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // Step 4: 다음 단계
  Widget _buildNextStepStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildStepIcon(Icons.arrow_circle_right_rounded, HwahaeColors.gradientWarm, HwahaeColors.warning),
          const SizedBox(height: 32),
          Text(
            '다음 단계',
            style: HwahaeTypography.headlineMedium.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '회원가입 후 암행어사가 되는 여정을 시작하세요',
            style: HwahaeTypography.bodyLarge.copyWith(
              color: HwahaeColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildStepCard(
            number: '1',
            title: '회원가입',
            description: '이메일과 기본 정보로 계정을 만드세요.',
            icon: Icons.person_add_rounded,
          ),
          const SizedBox(height: 12),
          _buildStepCard(
            number: '2',
            title: '3일 교육 이수',
            description: '앱에서 교육 과정을 수료하세요.',
            icon: Icons.school_rounded,
          ),
          const SizedBox(height: 12),
          _buildStepCard(
            number: '3',
            title: '인증 취득',
            description: '종합시험 통과 후 암행어사 자격을 받으세요.',
            icon: Icons.workspace_premium_rounded,
          ),
          const SizedBox(height: 32),
          // 가입하기 버튼
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: HwahaeColors.gradientWarm),
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
                  ref.read(tutorialProvider.notifier).completeTutorial();
                  context.go('/register');
                },
                borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '가입하기',
                      style: HwahaeTypography.button.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text(
              '이미 계정이 있어요',
              style: HwahaeTypography.bodyMedium.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 완료 화면
  Widget _buildCompletionScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: HwahaeColors.gradientWarm),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: HwahaeColors.warning.withOpacity(0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(Icons.celebration_rounded, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Text(
            '온보딩 완료!',
            style: HwahaeTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Text(
            '회원가입 후 3일 교육을 시작하세요.\n교육을 이수하면 암행어사 자격이 부여됩니다.',
            style: HwahaeTypography.bodyLarge.copyWith(
              color: HwahaeColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: HwahaeColors.gradientWarm),
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
                onTap: () => context.go('/register'),
                borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '가입하기',
                      style: HwahaeTypography.button.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text(
              '이미 계정이 있어요',
              style: HwahaeTypography.bodyMedium.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Shared widgets --

  Widget _buildStepIcon(IconData icon, List<Color> gradient, Color shadowColor) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(icon, size: 56, color: Colors.white),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: HwahaeTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: HwahaeTypography.bodyMedium.copyWith(
                    color: HwahaeColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPledgeItem({
    required int index,
    required String title,
    required String description,
  }) {
    final tutorialState = ref.watch(tutorialProvider);
    final isAccepted = tutorialState.pledgeAccepted;

    return GestureDetector(
      onTap: isAccepted
          ? null
          : () {
              setState(() {
                _pledgeChecks[index] = !_pledgeChecks[index];
              });
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (_pledgeChecks[index] || isAccepted)
              ? HwahaeColors.accent.withOpacity(0.05)
              : HwahaeColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (_pledgeChecks[index] || isAccepted)
                ? HwahaeColors.accent.withOpacity(0.3)
                : HwahaeColors.surfaceVariant,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              (_pledgeChecks[index] || isAccepted)
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: (_pledgeChecks[index] || isAccepted)
                  ? HwahaeColors.accent
                  : HwahaeColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: HwahaeTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: HwahaeTypography.bodySmall.copyWith(
                      color: HwahaeColors.textSecondary,
                      height: 1.5,
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

  Widget _buildDayCard({
    required int day,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Day',
                  style: HwahaeTypography.captionSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
                Text(
                  '$day',
                  style: HwahaeTypography.titleMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: HwahaeTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: HwahaeTypography.bodySmall.copyWith(
                    color: HwahaeColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: color.withOpacity(0.4), size: 28),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String number,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HwahaeColors.surfaceVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: HwahaeColors.gradientWarm),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: HwahaeTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: HwahaeTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: HwahaeTypography.bodySmall.copyWith(
                    color: HwahaeColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: HwahaeColors.textSecondary.withOpacity(0.4), size: 24),
        ],
      ),
    );
  }

  Widget _buildBottomSection(int currentStep) {
    final isLastStep = currentStep == _steps.length - 1;
    final isPledgeStep = currentStep == 1;
    final tutorialState = ref.watch(tutorialProvider);
    final allPledgesChecked = _pledgeChecks.every((c) => c);

    // 서약 단계에서 아직 동의하지 않았으면 서약 동의 버튼
    final bool pledgeRequired = isPledgeStep && !tutorialState.pledgeAccepted;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          // 마지막 단계에서는 위에 가입하기 버튼이 있으므로 하단 버튼 숨김
          if (!isLastStep)
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: (pledgeRequired && !allPledgesChecked)
                      ? [HwahaeColors.surfaceVariant, HwahaeColors.surfaceVariant]
                      : HwahaeColors.gradientWarm,
                ),
                borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
                boxShadow: (pledgeRequired && !allPledgesChecked)
                    ? []
                    : [
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
                  onTap: (pledgeRequired && !allPledgesChecked)
                      ? null
                      : () async {
                          if (pledgeRequired) {
                            // 서약 동의 처리
                            await ref.read(tutorialProvider.notifier).acceptPledge();
                            _goToStep(currentStep + 1);
                          } else {
                            _goToStep(currentStep + 1);
                          }
                        },
                  borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        pledgeRequired ? '서약에 동의하고 다음으로' : '다음',
                        style: HwahaeTypography.button.copyWith(
                          color: (pledgeRequired && !allPledgesChecked)
                              ? HwahaeColors.textSecondary
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: (pledgeRequired && !allPledgesChecked)
                            ? HwahaeColors.textSecondary
                            : Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!isLastStep) const SizedBox(height: 12),
          if (currentStep > 0 && !isLastStep)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () => _goToStep(currentStep - 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_ios, size: 14, color: HwahaeColors.textSecondary),
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
