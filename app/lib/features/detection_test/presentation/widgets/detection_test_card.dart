import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/detection_test_model.dart';

class DetectionTestCard extends StatelessWidget {
  final DetectionTest test;

  const DetectionTestCard({super.key, required this.test});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: test.isPending ? () => context.push('/detection-test/${test.id}') : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: test.isPending ? Colors.orange[100] : Colors.grey[100],
                child: Icon(
                  Icons.psychology,
                  color: test.isPending ? Colors.orange : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('역탐지 테스트',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      test.isPending
                          ? '리뷰어가 언제 방문했는지 맞춰보세요'
                          : '테스트 완료',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (test.isPending)
                      Text('남은 시간: ${test.remainingTime}',
                          style: TextStyle(fontSize: 12, color: Colors.orange[700])),
                  ],
                ),
              ),
              if (test.isPending)
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
