import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';
import '../../data/models/training_module_model.dart';
import '../../providers/certification_provider.dart';

class FinalExamScreen extends ConsumerStatefulWidget {
  const FinalExamScreen({super.key});

  @override
  ConsumerState<FinalExamScreen> createState() => _FinalExamScreenState();
}

class _FinalExamScreenState extends ConsumerState<FinalExamScreen>
    with WidgetsBindingObserver {
  static const int _totalSeconds = 30 * 60;

  /// 남은 시간이 이보다 적으면 인주색으로 바꾼다.
  static const int _hurryThreshold = 5 * 60;

  final Map<int, int> _answers = {};
  bool _isSubmitting = false;
  int _remainingSeconds = _totalSeconds;
  Timer? _timer;
  bool _examStarted = false;
  bool _timeUp = false;
  int _leaveCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_examStarted && !_timeUp && state == AppLifecycleState.paused) {
      _leaveCount++;
      if (_leaveCount >= 3) _warnAboutLeaving();
    }
  }

  Future<void> _warnAboutLeaving() async {
    if (!mounted) return;
    await showAppConfirm(
      context: context,
      title: '시계는 계속 갑니다',
      // 예전 문구는 "3회 이상 시 시험이 무효 처리될 수 있습니다" 였는데,
      // 이 횟수는 어디에도 전송되지 않고 무효 처리하는 코드도 없다.
      // 지키지 않을 경고를 하느니 실제로 일어나는 일을 말한다.
      message: '앱을 벗어난 것이 $_leaveCount회 감지됐습니다. '
          '자리를 비운 동안에도 제한시간은 줄어듭니다.',
      confirmLabel: '알겠습니다',
      cancelLabel: '',
      icon: Icons.timer_outlined,
    );
  }

  void _startTimer() {
    setState(() => _examStarted = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _timeUp = true;
        });
        // 시간이 다 되면 답이 없어도 제출한다. 예전에는 답이 하나도 없으면
        // 아무 일도 일어나지 않아서, 00:00 화면에 갇힌 채 제출 버튼도
        // 비활성인 상태로 남았다.
        _submitExam(auto: true);
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_examStarted) return _buildStartScreen();

    final modulesAsync = ref.watch(trainingModulesProvider(3));
    final hurrying = _remainingSeconds < _hurryThreshold;

    return PopScope(
      // "시작하면 중간에 나갈 수 없습니다"라고 안내해놓고 뒤로가기를 막지
      // 않고 있었다. 말한 대로 막되, 왜 막는지 알려주고 나갈 길도 준다.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _isSubmitting) return;
        final leave = await showAppConfirm(
          context: context,
          title: '시험을 그만둘까요?',
          message: '지금 나가면 답안이 저장되지 않고 응시 횟수만 늘어납니다.',
          confirmLabel: '그만두기',
          cancelLabel: '계속 풀기',
          destructive: true,
        );
        if (leave && context.mounted) context.go('/certification');
      },
      child: AppScreen(
        title: '종합 시험',
        showBack: false,
        scrollable: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: AppBadge(
                label: _formattedTime,
                color: hurrying
                    ? HwahaeColors.secondary
                    : HwahaeColors.textSecondary,
                icon: Icons.timer_outlined,
                filled: hurrying,
              ),
            ),
          ),
        ],
        child: modulesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: HwahaeColors.primary),
          ),
          error: (e, _) => SingleChildScrollView(
            child: AppErrorState.fromMessage(
              '$e',
              onRetry: () => ref.invalidate(trainingModulesProvider(3)),
            ),
          ),
          data: (modules) {
            final examModules =
                modules.where((m) => m.contentType == 'quiz').toList();
            if (examModules.isEmpty) {
              return const SingleChildScrollView(
                child: AppEmptyState(
                  icon: Icons.help_outline_rounded,
                  title: '시험 문제를 찾을 수 없습니다',
                  message: '잠시 후 다시 시도해주세요',
                ),
              );
            }
            return _buildExamContent(examModules.last);
          },
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return AppScreen(
      title: '종합 시험',
      bottomBar: AppBottomActionBar(
        child: AppButton(
          label: '시험 시작',
          size: AppButtonSize.large,
          onPressed: _startTimer,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Center(child: AppMascot.sato(size: 96)),
          const SizedBox(height: 20),
          Text(
            '암행어흥 리뷰어 종합 시험',
            textAlign: TextAlign.center,
            style: HwahaeTypography.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '제한시간 30분 · 합격 기준 80점',
            textAlign: TextAlign.center,
            style: HwahaeTypography.bodyMedium.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          AppCard(
            style: AppCardStyle.outlined,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('시험 안내', style: HwahaeTypography.titleSmall),
                const SizedBox(height: 10),
                for (final line in const [
                  '3일 과정에서 배운 내용을 종합해서 묻습니다.',
                  '모든 문항에 답해야 제출할 수 있습니다.',
                  '시간이 끝나면 푼 만큼 자동으로 제출됩니다.',
                  '시작하면 중간에 나갈 수 없습니다.',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 5, right: 8),
                          child: Icon(
                            Icons.circle,
                            size: 5,
                            color: HwahaeColors.textTertiary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            line,
                            style: HwahaeTypography.bodySmall.copyWith(
                              color: HwahaeColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const AppBottomSpacer.plain(),
        ],
      ),
    );
  }

  Widget _buildExamContent(TrainingModule examModule) {
    final questions = (examModule.contentData['questions'] as List? ?? [])
        .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
        .toList();

    if (questions.isEmpty) {
      return const SingleChildScrollView(
        child: AppEmptyState(
          icon: Icons.help_outline_rounded,
          title: '출제된 문항이 없습니다',
          message: '잠시 후 다시 시도해주세요',
        ),
      );
    }

    final gutter = AppLayout.gutterOf(context);
    final answered = _answers.length;

    return Column(
      children: [
        // 문항이 0개면 0으로 나눠 NaN 이 된다. 위에서 이미 걸렀지만
        // 진행률 계산은 그 자체로 안전해야 한다.
        AppProgressBar(
          value: questions.isEmpty ? 0 : answered / questions.length,
          height: 5,
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, 10, gutter, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$answered / ${questions.length} 답변 완료',
              style: HwahaeTypography.captionMedium.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 16),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            itemCount: questions.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: AppLayout.cardGap),
              child: _QuestionCard(
                index: index,
                question: questions[index],
                selected: _answers[index],
                onSelected: (value) =>
                    setState(() => _answers[index] = value),
              ),
            ),
          ),
        ),
        AppStickyBar(
          child: AppButton(
            label: '제출 ($answered/${questions.length})',
            isLoading: _isSubmitting,
            onPressed: answered >= questions.length && !_isSubmitting
                ? _submitExam
                : null,
          ),
        ),
      ],
    );
  }

  Future<void> _submitExam({bool auto = false}) async {
    if (_isSubmitting) return;
    _timer?.cancel();
    setState(() => _isSubmitting = true);

    final notifier = ref.read(certificationNotifierProvider.notifier);
    final result = await notifier.takeFinalExam(_answers);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // 저장소는 네트워크 오류도 {passed:false, score:0} 으로 돌려준다.
    // 그대로 보여주면 통신이 끊긴 사람에게 "0점 불합격"이라고 말하게 된다.
    if (result['error'] != null) {
      final retry = await showAppConfirm(
        context: context,
        title: '답안을 보내지 못했습니다',
        message: '네트워크를 확인하고 다시 제출해주세요. 답안은 그대로 남아 있습니다.',
        confirmLabel: '다시 제출',
        cancelLabel: '나가기',
        destructive: false,
        icon: Icons.wifi_off_rounded,
      );
      if (!mounted) return;
      if (retry) {
        await _submitExam(auto: auto);
      } else {
        context.go('/certification');
      }
      return;
    }

    final passed = result['passed'] == true;
    final score = result['score'] ?? 0;

    await showAppConfirm(
      context: context,
      title: passed ? '합격!' : '불합격',
      message: [
        '점수 $score점',
        if (auto) '시간이 끝나 자동으로 제출됐습니다.',
        if (passed)
          '축하합니다. 이제 미션에 지원할 수 있습니다.'
        else
          '80점 이상이 필요합니다. 교육을 복습한 뒤 다시 도전해주세요.',
      ].join('\n'),
      confirmLabel: '확인',
      cancelLabel: '',
      icon: passed ? Icons.celebration_rounded : Icons.replay_rounded,
    );

    if (mounted) context.go('/certification');
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.selected,
    required this.onSelected,
  });

  final int index;
  final QuizQuestion question;
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q${index + 1}. ${question.question}',
            style: HwahaeTypography.titleSmall.copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),
          RadioGroup<int>(
            groupValue: selected,
            onChanged: (value) {
              if (value != null) onSelected(value);
            },
            child: Column(
              children: [
                for (var j = 0; j < question.options.length; j++)
                  RadioListTile<int>(
                    title: Text(
                      question.options[j],
                      style: HwahaeTypography.bodyMedium,
                    ),
                    value: j,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: HwahaeColors.primaryDark,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
