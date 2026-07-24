import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/detection_test_model.dart';
import '../data/repositories/detection_test_repository.dart';

final detectionTestRepositoryProvider = Provider((ref) => DetectionTestRepository());

final pendingTestsProvider = FutureProvider.autoDispose<List<DetectionTest>>((ref) async {
  final repo = ref.read(detectionTestRepositoryProvider);
  return repo.getPendingTests();
});

final stealthStatsProvider = FutureProvider.autoDispose<StealthStats>((ref) async {
  final repo = ref.read(detectionTestRepositoryProvider);
  return repo.getStealthStats();
});
