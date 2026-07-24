import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../data/models/training_module_model.dart';
import '../../providers/certification_provider.dart';

class TrainingModuleScreen extends ConsumerStatefulWidget {
  final int day;
  const TrainingModuleScreen({super.key, required this.day});

  @override
  ConsumerState<TrainingModuleScreen> createState() => _TrainingModuleScreenState();
}

class _TrainingModuleScreenState extends ConsumerState<TrainingModuleScreen> {
  int _currentModuleIndex = 0;
  Map<int, int> _quizAnswers = {};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final modulesAsync = ref.watch(trainingModulesProvider(widget.day));

    return Scaffold(
      appBar: AppBar(
        title: Text('Day ${widget.day} 교육'),
      ),
      body: modulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: HwahaeColors.primary)),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (modules) {
          if (modules.isEmpty) {
            return const Center(child: Text('교육 모듈이 없습니다.'));
          }
          return _buildModuleContent(modules);
        },
      ),
    );
  }

  Widget _buildModuleContent(List<TrainingModule> modules) {
    final module = modules[_currentModuleIndex];

    return Column(
      children: [
        // Progress indicator
        LinearProgressIndicator(
          value: (_currentModuleIndex + 1) / modules.length,
          minHeight: 4,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_currentModuleIndex + 1} / ${modules.length}',
                  style: TextStyle(color: Colors.grey[600])),
              Text('약 ${module.estimatedMinutes}분',
                  style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(module.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                if (module.description != null) ...[
                  const SizedBox(height: 8),
                  Text(module.description!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
                const SizedBox(height: 20),

                if (module.contentType == 'quiz')
                  _buildQuiz(module)
                else if (module.contentType == 'interactive')
                  _buildInteractive(module)
                else
                  _buildText(module),
              ],
            ),
          ),
        ),

        // Navigation buttons
        _buildNavigationBar(modules, module),
      ],
    );
  }

  Widget _buildText(TrainingModule module) {
    final content = module.contentData['content'] as String? ?? '';
    final sections = module.contentData['sections'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content.isNotEmpty)
          Text(content, style: const TextStyle(fontSize: 16, height: 1.6)),
        for (final section in sections) ...[
          const SizedBox(height: 16),
          if (section['title'] != null)
            Text(section['title'],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (section['body'] != null) ...[
            const SizedBox(height: 8),
            Text(section['body'], style: const TextStyle(fontSize: 16, height: 1.6)),
          ],
        ],
      ],
    );
  }

  Widget _buildInteractive(TrainingModule module) {
    final scenarios = module.contentData['scenarios'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < scenarios.length; i++) ...[
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text('${i + 1}'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          scenarios[i]['title'] ?? '시나리오 ${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(scenarios[i]['description'] ?? ''),
                  if (scenarios[i]['tip'] != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.green[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(scenarios[i]['tip'],
                              style: TextStyle(color: Colors.green[700]))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuiz(TrainingModule module) {
    final questions = (module.contentData['questions'] as List? ?? [])
        .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < questions.length; i++) ...[
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Q${i + 1}. ${questions[i].question}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  for (int j = 0; j < questions[i].options.length; j++)
                    RadioListTile<int>(
                      title: Text(questions[i].options[j]),
                      value: j,
                      groupValue: _quizAnswers[i],
                      onChanged: (val) {
                        setState(() => _quizAnswers[i] = val!);
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNavigationBar(List<TrainingModule> modules, TrainingModule currentModule) {
    final isLast = _currentModuleIndex == modules.length - 1;
    final isFirst = _currentModuleIndex == 0;
    final isQuiz = currentModule.contentType == 'quiz';
    final allAnswered = isQuiz &&
        _quizAnswers.length >= (currentModule.contentData['questions'] as List? ?? []).length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (!isFirst)
              OutlinedButton(
                onPressed: () => setState(() {
                  _currentModuleIndex--;
                  _quizAnswers = {};
                }),
                child: const Text('이전'),
              ),
            const Spacer(),
            if (isQuiz)
              ElevatedButton(
                onPressed: allAnswered && !_isSubmitting ? () => _submitQuiz(currentModule) : null,
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('제출'),
              )
            else if (isLast)
              ElevatedButton(
                onPressed: () => _completeDay(),
                child: const Text('교육 완료'),
              )
            else
              ElevatedButton(
                onPressed: () async {
                  await ref.read(certificationRepositoryProvider).startModule(currentModule.id);
                  setState(() {
                    _currentModuleIndex++;
                    _quizAnswers = {};
                  });
                },
                child: const Text('다음'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitQuiz(TrainingModule module) async {
    setState(() => _isSubmitting = true);

    final notifier = ref.read(certificationNotifierProvider.notifier);
    final result = await notifier.submitQuiz(module.id, _quizAnswers);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    final passed = result['passed'] == true;
    final score = result['score'] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(passed ? '합격!' : '불합격'),
        content: Text(
          passed
              ? '점수: $score점\n축하합니다! 퀴즈를 통과했습니다.'
              : '점수: $score점\n80점 이상이 필요합니다. 다시 도전해보세요.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (passed) {
                setState(() {
                  _quizAnswers = {};
                });
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeDay() async {
    final notifier = ref.read(certificationNotifierProvider.notifier);
    final result = await notifier.completeDay(widget.day);

    if (!mounted) return;

    if (result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'].toString())),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Day ${widget.day} 교육을 완료했습니다!')),
      );
      context.pop();
    }
  }
}
