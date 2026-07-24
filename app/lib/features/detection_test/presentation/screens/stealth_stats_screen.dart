import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../providers/detection_test_provider.dart';

class StealthStatsScreen extends ConsumerWidget {
  const StealthStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(stealthStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('은밀성 통계')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: HwahaeColors.primary)),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (stats) => _buildContent(context, stats),
      ),
    );
  }

  Widget _buildContent(BuildContext context, stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main score card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: stats.stealthScore / 100,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation(
                              _getScoreColor(stats.stealthScore),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${stats.stealthScore.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(stats.stealthScore),
                              ),
                            ),
                            const Text('은밀성 점수', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_getGradeLabel(stats.stealthScore),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(stats.stealthScore),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats grid
          Row(
            children: [
              Expanded(child: _statCard('총 테스트', '${stats.totalTests}회')),
              const SizedBox(width: 12),
              Expanded(child: _statCard('감지 횟수', '${stats.detectedCount}회')),
              const SizedBox(width: 12),
              Expanded(child: _statCard('감지율', '${stats.detectionRate}%')),
            ],
          ),
          const SizedBox(height: 16),

          // Advice
          if (stats.advice.isNotEmpty)
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(child: Text(stats.advice)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Recent tests
          if (stats.recentTests.isNotEmpty) ...[
            const Text('최근 테스트 결과',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final test in stats.recentTests)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getScoreColor(
                        (100 - (test.detectionScore ?? 0)).toDouble())
                        .withValues(alpha: 0.2),
                    child: Icon(
                      test.status == 'expired'
                          ? Icons.visibility_off
                          : (test.detectionScore ?? 0) >= 70
                              ? Icons.visibility
                              : Icons.visibility_off,
                      color: _getScoreColor(
                          (100 - (test.detectionScore ?? 0)).toDouble()),
                    ),
                  ),
                  title: Text(
                    test.status == 'expired'
                        ? '미감지 (만료)'
                        : (test.detectionScore ?? 0) >= 70
                            ? '감지됨'
                            : '미감지',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: test.status == 'expired' || (test.detectionScore ?? 0) < 70
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  subtitle: test.createdAt != null
                      ? Text('${test.createdAt!.month}/${test.createdAt!.day}')
                      : null,
                  trailing: Text(
                    test.status == 'expired' ? '0점' : '${test.detectionScore ?? 0}점',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getGradeLabel(double score) {
    if (score >= 90) return '완벽한 은밀성';
    if (score >= 70) return '우수한 은밀성';
    if (score >= 50) return '보통';
    if (score >= 30) return '주의 필요';
    return '위험';
  }
}
