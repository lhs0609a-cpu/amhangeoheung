import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../data/models/training_module_model.dart';
import '../../providers/certification_provider.dart';

class FinalExamScreen extends ConsumerStatefulWidget {
  const FinalExamScreen({super.key});

  @override
  ConsumerState<FinalExamScreen> createState() => _FinalExamScreenState();
}

class _FinalExamScreenState extends ConsumerState<FinalExamScreen>
    with WidgetsBindingObserver {
  final Map<int, int> _answers = {};
  bool _isSubmitting = false;
  int _remainingSeconds = 30 * 60; // 30분
  Timer? _timer;
  bool _examStarted = false;
  int _tabSwitchCount = 0;

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
    if (_examStarted && state == AppLifecycleState.paused) {
      _tabSwitchCount++;
      if (_tabSwitchCount >= 3) {
        _showProctorWarning();
      }
    }
  }

  void _showProctorWarning() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('주의'),
        content: Text(
            '앱을 벗어나는 행위가 $_tabSwitchCount회 감지되었습니다.\n3회 이상 시 시험이 무효 처리될 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _timer?.cancel();
          _autoSubmit();
        }
      });
    });
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_examStarted) {
      return _buildStartScreen();
    }

    // Load Day 3 quiz modules for the exam
    final modulesAsync = ref.watch(trainingModulesProvider(3));

    return Scaffold(
      appBar: AppBar(
        title: const Text('종합 시험'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Chip(
              label: Text(_formattedTime,
                  style: TextStyle(
                    color: _remainingSeconds < 300 ? Colors.red : null,
                    fontWeight: FontWeight.bold,
                  )),
              avatar: Icon(Icons.timer,
                  size: 18,
                  color: _remainingSeconds < 300 ? Colors.red : null),
            ),
          ),
        ],
      ),
      body: modulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: HwahaeColors.primary)),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (modules) {
          // Get the last quiz module (final exam)
          final examModules = modules.where((m) => m.contentType == 'quiz').toList();
          if (examModules.isEmpty) {
            return const Center(child: Text('시험 문제를 찾을 수 없습니다.'));
          }
          final examModule = examModules.last;
          return _buildExamContent(examModule);
        },
      ),
    );
  }

  Widget _buildStartScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('종합 시험')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.assignment, size: 64, color: Colors.blue),
              const SizedBox(height: 24),
              const Text('암행어흥 리뷰어 종합 시험',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text('제한시간: 30분\n합격 기준: 80점 이상',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('시험 안내', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('- 3일 과정에서 학습한 내용을 종합 평가합니다\n'
                          '- 시간 내에 모든 문항에 답해야 합니다\n'
                          '- 시작하면 중간에 나갈 수 없습니다'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _examStarted = true;
                    });
                    _startTimer();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('시험 시작', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamContent(TrainingModule examModule) {
    final questions = (examModule.contentData['questions'] as List? ?? [])
        .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
        .toList();

    return Column(
      children: [
        // Progress
        LinearProgressIndicator(
          value: _answers.length / questions.length.toDouble(),
          minHeight: 4,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('${_answers.length} / ${questions.length} 답변 완료',
              style: TextStyle(color: Colors.grey[600])),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final q = questions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Q${index + 1}. ${q.question}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      RadioGroup<int>(
                        groupValue: _answers[index],
                        onChanged: (val) => setState(() => _answers[index] = val!),
                        child: Column(
                          children: [
                            for (int j = 0; j < q.options.length; j++)
                              RadioListTile<int>(
                                title: Text(q.options[j]),
                                value: j,
                                dense: true,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _answers.length >= questions.length && !_isSubmitting
                    ? () => _submitExam()
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('제출 (${_answers.length}/${questions.length})'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitExam() async {
    _timer?.cancel();
    setState(() => _isSubmitting = true);

    final notifier = ref.read(certificationNotifierProvider.notifier);
    final result = await notifier.takeFinalExam(_answers);

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    final passed = result['passed'] == true;
    final score = result['score'] ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(passed ? Icons.celebration : Icons.sentiment_dissatisfied,
                color: passed ? Colors.green : Colors.orange),
            const SizedBox(width: 8),
            Text(passed ? '합격!' : '불합격'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('점수: $score점',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(passed
                ? '축하합니다! 암행어흥 리뷰어 인증을 완료했습니다.\n이제 미션에 지원할 수 있습니다.'
                : '80점 이상이 필요합니다. 교육을 복습한 후 다시 도전해주세요.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/certification');
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _autoSubmit() async {
    if (_answers.isNotEmpty) {
      await _submitExam();
    }
  }
}
