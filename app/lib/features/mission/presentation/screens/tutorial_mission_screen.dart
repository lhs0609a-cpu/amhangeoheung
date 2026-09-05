import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';
import '../../providers/tutorial_provider.dart';

/// 가입 전 리뷰어 온보딩. 취지 → 서약 → 교육 안내 → 다음 단계.
class TutorialMissionScreen extends ConsumerStatefulWidget {
  const TutorialMissionScreen({super.key});

  @override
  ConsumerState<TutorialMissionScreen> createState() =>
      _TutorialMissionScreenState();
}

/// 서약 항목. 여기 적힌 것이 곧 감찰관이 지켜야 할 규칙이다.
const _pledges = <({String title, String description})>[
  (
    title: '정직한 리뷰 작성',
    description: '개인적 감정이나 외부 압력 없이, 오직 경험에 기반한 솔직하고 '
        '객관적인 리뷰를 작성합니다.',
  ),
  (
    title: '신분 비공개 준수',
    description: '미션 수행 중 감찰관 신분을 절대 밝히지 않으며, 일반 손님으로서 '
        '자연스럽게 행동합니다.',
  ),
  (
    title: '공정성과 윤리 준수',
    description: '대가를 받고 리뷰를 조작하거나, 담합하거나, 허위 사실을 '
        '기재하지 않습니다.',
  ),
];

const _stepCount = 4;

class _TutorialMissionScreenState
    extends ConsumerState<TutorialMissionScreen> {
  final List<bool> _pledgeChecks = List.filled(_pledges.length, false);

  bool get _allPledgesChecked => _pledgeChecks.every((c) => c);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorialProvider);

    return Scaffold(
      backgroundColor: HwahaeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _ProgressBar(current: state.currentStep, total: _stepCount),
            Expanded(
              child: state.isCompleted
                  ? _buildCompletion()
                  : FadeSlideIn(
                      // 단계가 바뀔 때마다 새로 등장하도록 키를 준다.
                      key: ValueKey(state.currentStep),
                      child: _buildStep(state),
                    ),
            ),
            if (!state.isCompleted) _buildBottom(state),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppIconButton(
            icon: Icons.close_rounded,
            tooltip: '닫기',
            onPressed: () => context.go('/login'),
          ),
          Text('감찰관 온보딩', style: HwahaeTypography.titleMedium),
          AppButton.ghost(
            label: '건너뛰기',
            size: AppButtonSize.small,
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(TutorialState state) {
    return switch (state.currentStep) {
      1 => _buildPledgeStep(state),
      2 => _buildEducationStep(),
      3 => _buildNextStep(),
      _ => _buildPurposeStep(),
    };
  }

  // Step 1: 암행어사의 취지
  Widget _buildPurposeStep() {
    return _StepScroll(
      icon: Icons.handshake_rounded,
      color: HwahaeColors.primary,
      title: '암행어사의 취지',
      subtitle: '왜 솔직한 리뷰가 중요할까요?',
      children: const [
        _InfoCard(
          icon: Icons.people_alt_rounded,
          title: '소비자를 위한 가치',
          description: '조작되지 않은 솔직한 리뷰로\n손님이 제대로 고를 수 있게 합니다.',
          color: HwahaeColors.primary,
        ),
        SizedBox(height: AppLayout.cardGap),
        _InfoCard(
          icon: Icons.store_rounded,
          title: '업체를 위한 가치',
          description: '무엇을 고쳐야 하는지 구체적으로 남겨서\n'
              '가게가 실제로 고칠 수 있게 합니다.',
          color: HwahaeColors.accent,
        ),
        SizedBox(height: AppLayout.cardGap),
        _InfoCard(
          icon: Icons.shield_rounded,
          title: '감찰관의 책임',
          description: '신분을 숨기고 본 대로 적으며,\n정직함과 공정함을 최우선으로 합니다.',
          color: HwahaeColors.primaryDark,
        ),
        SizedBox(height: 20),
        AppNotice(
          message: '리뷰 한 건이 다른 손님의 선택을 바꿉니다.\n'
              '그만큼 책임이 따르는 역할이에요.',
          icon: Icons.lightbulb_outline_rounded,
          color: HwahaeColors.primaryDark,
        ),
      ],
    );
  }

  // Step 2: 서약서
  Widget _buildPledgeStep(TutorialState state) {
    final accepted = state.pledgeAccepted;

    return _StepScroll(
      icon: Icons.verified_user_rounded,
      color: HwahaeColors.accent,
      title: '서약서',
      subtitle: '감찰관으로서 다음을 약속합니다',
      children: [
        for (var i = 0; i < _pledges.length; i++) ...[
          _PledgeItem(
            title: _pledges[i].title,
            description: _pledges[i].description,
            checked: _pledgeChecks[i] || accepted,
            onTap: accepted
                ? null
                : () => setState(
                      () => _pledgeChecks[i] = !_pledgeChecks[i],
                    ),
          ),
          const SizedBox(height: AppLayout.cardGap),
        ],
        const SizedBox(height: 6),
        if (accepted)
          const AppNotice.success(message: '서약에 동의했습니다')
        else
          AppButton.outline(
            label: '전체 동의',
            icon: _allPledgesChecked
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            onPressed: () {
              final next = !_allPledgesChecked;
              setState(() {
                for (var i = 0; i < _pledgeChecks.length; i++) {
                  _pledgeChecks[i] = next;
                }
              });
            },
          ),
      ],
    );
  }

  // Step 3: 교육 안내
  Widget _buildEducationStep() {
    return _StepScroll(
      icon: Icons.school_rounded,
      color: HwahaeColors.primaryDark,
      title: '교육 안내',
      subtitle: '3일 과정을 이수해야 감찰관 자격이 나옵니다',
      children: const [
        _DayCard(
          day: 1,
          title: '암행어흥의 철학',
          description: '왜 객관적 리뷰가 중요한지, 평가 기준을 배웁니다.',
          icon: Icons.menu_book_rounded,
          color: HwahaeColors.primary,
        ),
        SizedBox(height: AppLayout.cardGap),
        _DayCard(
          day: 2,
          title: '현장 행동 수칙',
          description: '신분 노출 방지, 사진 촬영, 문제 상황 대응을 배웁니다.',
          icon: Icons.directions_walk_rounded,
          color: HwahaeColors.accent,
        ),
        SizedBox(height: AppLayout.cardGap),
        _DayCard(
          day: 3,
          title: '리뷰 작성 + 종합시험',
          description: '객관적 글쓰기를 연습하고 종합 시험을 봅니다.',
          icon: Icons.edit_note_rounded,
          color: HwahaeColors.primaryDark,
        ),
        SizedBox(height: 20),
        AppNotice(
          message: '교육은 가입 후 앱에서 진행됩니다.\n'
              '하루 한 과정씩, 3일이면 끝납니다.',
          icon: Icons.lightbulb_outline_rounded,
          color: HwahaeColors.primaryDark,
        ),
      ],
    );
  }

  // Step 4: 다음 단계
  Widget _buildNextStep() {
    return _StepScroll(
      icon: Icons.arrow_circle_right_rounded,
      color: HwahaeColors.primary,
      title: '다음 단계',
      subtitle: '가입하고 감찰관이 되는 길을 시작하세요',
      children: [
        const _NumberedCard(
          number: '1',
          title: '회원가입',
          description: '이메일과 기본 정보로 계정을 만드세요.',
          icon: Icons.person_add_rounded,
        ),
        const SizedBox(height: 10),
        const _NumberedCard(
          number: '2',
          title: '3일 교육 이수',
          description: '앱에서 교육 과정을 수료하세요.',
          icon: Icons.school_rounded,
        ),
        const SizedBox(height: 10),
        const _NumberedCard(
          number: '3',
          title: '인증 취득',
          description: '종합시험을 통과하면 감찰관 자격을 받습니다.',
          icon: Icons.workspace_premium_rounded,
        ),
        const SizedBox(height: 26),
        AppButton(
          label: '가입하기',
          icon: Icons.arrow_forward_rounded,
          trailingIcon: true,
          size: AppButtonSize.large,
          onPressed: () async {
            await ref.read(tutorialProvider.notifier).completeTutorial();
            if (mounted) context.go('/register');
          },
        ),
        const SizedBox(height: 6),
        AppButton.ghost(
          label: '이미 계정이 있어요',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }

  Widget _buildCompletion() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const AppMascot.eoheung(size: 140),
          const SizedBox(height: 26),
          Text(
            '온보딩 완료!',
            style: HwahaeTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '가입 후 3일 교육을 시작하세요.\n이수하면 감찰관 자격이 나옵니다.',
            style: HwahaeTypography.bodyLarge.copyWith(
              color: HwahaeColors.textSecondary,
              height: 1.65,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 34),
          AppButton(
            label: '가입하기',
            icon: Icons.arrow_forward_rounded,
            trailingIcon: true,
            size: AppButtonSize.large,
            onPressed: () => context.go('/register'),
          ),
          const SizedBox(height: 6),
          AppButton.ghost(
            label: '이미 계정이 있어요',
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottom(TutorialState state) {
    final isLastStep = state.currentStep == _stepCount - 1;
    // 마지막 단계에는 본문 안에 가입 버튼이 있다.
    if (isLastStep) return const SizedBox.shrink();

    final pledgeRequired = state.currentStep == 1 && !state.pledgeAccepted;
    final blocked = pledgeRequired && !_allPledgesChecked;

    return AppStickyBar(
      info: blocked
          ? Text(
              '세 가지 약속에 모두 동의해야 다음으로 넘어갑니다',
              style: HwahaeTypography.captionMedium.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            )
          : null,
      child: Row(
        children: [
          if (state.currentStep > 0) ...[
            Expanded(
              child: AppButton.outline(
                label: '이전',
                onPressed: () =>
                    ref.read(tutorialProvider.notifier).previousStep(),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: AppButton(
              label: pledgeRequired ? '서약에 동의하고 다음으로' : '다음',
              onPressed: blocked ? null : () => _advance(pledgeRequired),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _advance(bool pledgeRequired) async {
    if (pledgeRequired) {
      final ok = await ref.read(tutorialProvider.notifier).acceptPledge();
      if (!mounted) return;
      if (!ok) {
        // 서약은 기록으로 남는 약속이다. 저장이 실패했는데 넘어가면
        // 동의한 적 없는 사람이 동의한 화면을 보게 된다.
        AppToast.error(context, '서약을 저장하지 못했습니다. 다시 시도해주세요.');
        return;
      }
    }
    await ref.read(tutorialProvider.notifier).nextStep();
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (var index = 0; index < total; index++)
            Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < total - 1 ? 4 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: index < current
                      ? HwahaeColors.primary
                      : index == current
                          ? HwahaeColors.primaryLight
                          : HwahaeColors.surfaceContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 각 단계의 공통 껍데기: 큰 아이콘 + 제목 + 부제 + 본문.
class _StepScroll extends StatelessWidget {
  const _StepScroll({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(32),
                boxShadow: AppElevation.sticker(4, color: color),
              ),
              child: Icon(
                icon,
                size: 54,
                // 단계마다 면 색이 달라서 흰색을 고정하면 골드에서 사라진다.
                color: HwahaeColors.onColor(color),
              ),
            ),
          ),
          const SizedBox(height: 26),
          Text(
            title,
            style: HwahaeTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: HwahaeTypography.bodyLarge.copyWith(
              color: HwahaeColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 26),
          ...children,
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      style: AppCardStyle.outlined,
      borderColor: color,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: HwahaeTypography.titleSmall),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: HwahaeTypography.bodySmall.copyWith(
                    color: HwahaeColors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PledgeItem extends StatelessWidget {
  const _PledgeItem({
    required this.title,
    required this.description,
    required this.checked,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool checked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      child: AppCard(
        style: AppCardStyle.outlined,
        onTap: onTap,
        borderColor: checked ? HwahaeColors.accent : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              checked
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: checked
                  ? HwahaeColors.accent
                  : HwahaeColors.textTertiary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: HwahaeTypography.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: HwahaeTypography.bodySmall.copyWith(
                      color: HwahaeColors.textSecondary,
                      height: 1.55,
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
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final int day;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      style: AppCardStyle.outlined,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Day',
                  style: HwahaeTypography.captionSmall.copyWith(color: color),
                ),
                Text(
                  '$day',
                  style: HwahaeTypography.titleMedium.copyWith(color: color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: HwahaeTypography.titleSmall),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: HwahaeTypography.bodySmall.copyWith(
                    color: HwahaeColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: color.withValues(alpha: 0.45), size: 26),
        ],
      ),
    );
  }
}

class _NumberedCard extends StatelessWidget {
  const _NumberedCard({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String number;
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      style: AppCardStyle.outlined,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: HwahaeColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: HwahaeTypography.titleSmall.copyWith(
                  color: HwahaeColors.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: HwahaeTypography.titleSmall),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: HwahaeTypography.captionLarge.copyWith(
                    color: HwahaeColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, size: 22, color: HwahaeColors.textTertiary),
        ],
      ),
    );
  }
}
