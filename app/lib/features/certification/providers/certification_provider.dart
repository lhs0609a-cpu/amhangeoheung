import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/training_module_model.dart';
import '../data/repositories/certification_repository.dart';

final certificationRepositoryProvider = Provider((ref) => CertificationRepository());

final certificationStatusProvider = FutureProvider.autoDispose<CertificationStatus>((ref) async {
  final repo = ref.read(certificationRepositoryProvider);
  return repo.getCertificationStatus();
});

final trainingModulesProvider = FutureProvider.autoDispose.family<List<TrainingModule>, int>((ref, day) async {
  final repo = ref.read(certificationRepositoryProvider);
  return repo.getTrainingModules(day);
});

class CertificationNotifier extends StateNotifier<AsyncValue<CertificationStatus>> {
  final CertificationRepository _repository;

  CertificationNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadStatus();
  }

  Future<void> loadStatus() async {
    state = const AsyncValue.loading();
    try {
      final status = await _repository.getCertificationStatus();
      state = AsyncValue.data(status);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Map<String, dynamic>> submitQuiz(String moduleId, Map<int, int> answers) async {
    final result = await _repository.submitQuiz(moduleId, answers);
    await loadStatus(); // Refresh status after submission
    return result;
  }

  Future<Map<String, dynamic>> completeDay(int day) async {
    final result = await _repository.completeDay(day);
    await loadStatus();
    return result;
  }

  Future<Map<String, dynamic>> takeFinalExam(Map<int, int> answers) async {
    final result = await _repository.takeFinalExam(answers);
    await loadStatus();
    return result;
  }
}

final certificationNotifierProvider =
    StateNotifierProvider.autoDispose<CertificationNotifier, AsyncValue<CertificationStatus>>((ref) {
  return CertificationNotifier(ref.read(certificationRepositoryProvider));
});
