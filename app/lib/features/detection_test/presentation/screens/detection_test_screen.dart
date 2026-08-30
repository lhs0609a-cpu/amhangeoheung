import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/detection_test_provider.dart';
import '../../../../shared/widgets/ui/ui.dart';

class DetectionTestScreen extends ConsumerStatefulWidget {
  final String testId;
  const DetectionTestScreen({super.key, required this.testId});

  @override
  ConsumerState<DetectionTestScreen> createState() => _DetectionTestScreenState();
}

class _DetectionTestScreenState extends ConsumerState<DetectionTestScreen> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  int _confidence = 3;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  static const _timeSlots = [
    {'value': 'morning', 'label': '오전 (6-11시)', 'icon': Icons.wb_sunny_outlined},
    {'value': 'lunch', 'label': '점심 (11-14시)', 'icon': Icons.restaurant},
    {'value': 'afternoon', 'label': '오후 (14-17시)', 'icon': Icons.wb_sunny},
    {'value': 'evening', 'label': '저녁 (17-21시)', 'icon': Icons.nights_stay_outlined},
    {'value': 'night', 'label': '밤 (21시 이후)', 'icon': Icons.dark_mode},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('역탐지 테스트')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.psychology, size: 48, color: Colors.blue),
                    SizedBox(height: 8),
                    Text('이 리뷰어가 언제 방문했을까요?',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    SizedBox(height: 4),
                    Text('최근 2주 내 방문한 날짜와 시간대를 추측해보세요.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Date picker
            const Text('방문 날짜 추측', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: _selectedDate != null ? Colors.blue : Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        color: _selectedDate != null ? Colors.blue : Colors.grey),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate != null
                          ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                          : '날짜를 선택하세요',
                      style: TextStyle(
                          color: _selectedDate != null ? null : Colors.grey,
                          fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Time slot
            const Text('방문 시간대 추측', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeSlots.map((slot) {
                final isSelected = _selectedTimeSlot == slot['value'];
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(slot['icon'] as IconData, size: 16,
                          color: isSelected ? Colors.white : null),
                      const SizedBox(width: 4),
                      Text(slot['label'] as String),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedTimeSlot = slot['value'] as String),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Description (optional)
            const Text('특징 묘사 (선택)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '기억나는 특징이 있나요? (예: 혼자 방문, 사진을 많이 찍었음)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Confidence level
            const Text('확신도', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('확신 없음'),
                Expanded(
                  child: Slider(
                    value: _confidence.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _confidenceLabel,
                    onChanged: (val) => setState(() => _confidence = val.round()),
                  ),
                ),
                const Text('매우 확신'),
              ],
            ),
            Center(
              child: Text(_confidenceLabel,
                  style: TextStyle(color: Colors.grey[600])),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit && !_isSubmitting ? _submit : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('추측 제출', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _confidenceLabel {
    const labels = ['', '전혀 모름', '약간 추측', '보통', '꽤 확신', '매우 확신'];
    return labels[_confidence];
  }

  bool get _canSubmit => _selectedDate != null && _selectedTimeSlot != null;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 14)),
      lastDate: now,
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);

    final repo = ref.read(detectionTestRepositoryProvider);
    final result = await repo.submitTest(
      testId: widget.testId,
      guessedDate: '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
      guessedTimeSlot: _selectedTimeSlot!,
      guessedDescription: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      confidenceLevel: _confidence,
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (result.containsKey('error')) {
      AppToast.info(context, result['error'].toString());
      return;
    }

    final dateCorrect = result['dateCorrect'] == true;
    final timeCorrect = result['timeCorrect'] == true;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('결과'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _resultRow('날짜', dateCorrect),
            _resultRow('시간대', timeCorrect),
            const SizedBox(height: 12),
            Text(
              dateCorrect && timeCorrect
                  ? '정확하게 맞추셨습니다!'
                  : dateCorrect
                      ? '날짜만 맞추셨습니다.'
                      : timeCorrect
                          ? '시간대만 맞추셨습니다.'
                          : '아쉽지만 맞추지 못했습니다. 리뷰어의 은밀성이 높습니다!',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, bool correct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(correct ? Icons.check_circle : Icons.cancel,
              color: correct ? Colors.green : Colors.red, size: 20),
          const SizedBox(width: 8),
          Text('$label: ${correct ? "정답" : "오답"}'),
        ],
      ),
    );
  }
}
