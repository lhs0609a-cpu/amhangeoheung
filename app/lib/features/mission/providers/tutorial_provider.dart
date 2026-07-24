import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/tutorial_repository.dart';

class TutorialState {
  final int currentStep;
  final int totalSteps;
  final bool isCompleted;
  final String? sessionId;
  final bool isLoading;
  final String? error;
  final bool pledgeAccepted;

  const TutorialState({
    this.currentStep = 0,
    this.totalSteps = 4,
    this.isCompleted = false,
    this.sessionId,
    this.isLoading = false,
    this.error,
    this.pledgeAccepted = false,
  });

  TutorialState copyWith({
    int? currentStep,
    int? totalSteps,
    bool? isCompleted,
    String? sessionId,
    bool? isLoading,
    String? error,
    bool? pledgeAccepted,
  }) {
    return TutorialState(
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      isCompleted: isCompleted ?? this.isCompleted,
      sessionId: sessionId ?? this.sessionId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pledgeAccepted: pledgeAccepted ?? this.pledgeAccepted,
    );
  }
}

class TutorialNotifier extends StateNotifier<TutorialState> {
  final TutorialRepository _repository = TutorialRepository();

  TutorialNotifier() : super(const TutorialState());

  Future<void> startTutorial(String deviceId) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _repository.startTutorial(deviceId);
      state = state.copyWith(
        sessionId: data['id'],
        currentStep: data['steps_completed'] ?? 0,
        totalSteps: data['total_steps'] ?? 4,
        isCompleted: data['completed'] ?? false,
        pledgeAccepted: data['pledge_accepted'] ?? false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> nextStep() async {
    if (state.currentStep >= state.totalSteps - 1) {
      await completeTutorial();
      return;
    }

    final newStep = state.currentStep + 1;
    state = state.copyWith(currentStep: newStep);

    if (state.sessionId != null) {
      try {
        await _repository.updateProgress(state.sessionId!, step: newStep);
      } catch (_) {}
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<bool> acceptPledge() async {
    if (state.sessionId == null) {
      state = state.copyWith(pledgeAccepted: true);
      return true;
    }

    try {
      await _repository.acceptPledge(state.sessionId!);
      state = state.copyWith(pledgeAccepted: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> completeTutorial() async {
    if (state.sessionId == null) {
      state = state.copyWith(isCompleted: true);
      return;
    }

    try {
      await _repository.completeTutorial(state.sessionId!);
      state = state.copyWith(isCompleted: true);
    } catch (_) {
      state = state.copyWith(isCompleted: true);
    }
  }
}

final tutorialProvider = StateNotifierProvider<TutorialNotifier, TutorialState>((ref) {
  return TutorialNotifier();
});
