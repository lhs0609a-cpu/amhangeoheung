import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/mission_model.dart';
import '../data/repositories/mission_repository.dart';

// Mission Repository Provider
final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  return MissionRepository();
});

// Available Missions State
class AvailableMissionsState {
  final bool isLoading;
  final List<MissionModel> missions;
  final String? error;

  const AvailableMissionsState({
    this.isLoading = false,
    this.missions = const [],
    this.error,
  });

  AvailableMissionsState copyWith({
    bool? isLoading,
    List<MissionModel>? missions,
    String? error,
  }) {
    return AvailableMissionsState(
      isLoading: isLoading ?? this.isLoading,
      missions: missions ?? this.missions,
      error: error,
    );
  }
}

// Available Missions Notifier
class AvailableMissionsNotifier extends StateNotifier<AvailableMissionsState> {
  final MissionRepository _repository;

  AvailableMissionsNotifier(this._repository)
      : super(const AvailableMissionsState());

  Future<void> loadMissions({String? category, String? city}) async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await _repository.getAvailableMissions(
      category: category,
      city: city,
    );

    if (response.success) {
      state = state.copyWith(isLoading: false, missions: response.missions);
    } else {
      state = state.copyWith(isLoading: false, error: response.message);
    }
  }

  Future<bool> applyMission(String missionId) async {
    final response = await _repository.applyMission(missionId);
    if (response.success) {
      // 목록 새로고침
      await loadMissions();
    }
    return response.success;
  }
}

final availableMissionsProvider =
    StateNotifierProvider<AvailableMissionsNotifier, AvailableMissionsState>(
        (ref) {
  final repository = ref.watch(missionRepositoryProvider);
  return AvailableMissionsNotifier(repository);
});

// My Missions State
class MyMissionsState {
  final bool isLoading;
  final List<MissionModel> missions;
  final String? error;

  const MyMissionsState({
    this.isLoading = false,
    this.missions = const [],
    this.error,
  });

  MyMissionsState copyWith({
    bool? isLoading,
    List<MissionModel>? missions,
    String? error,
  }) {
    return MyMissionsState(
      isLoading: isLoading ?? this.isLoading,
      missions: missions ?? this.missions,
      error: error,
    );
  }

  List<MissionModel> get availableMissions =>
      missions.where((m) => m.status == 'recruiting').toList();

  List<MissionModel> get ongoingMissions => missions
      .where((m) => ['assigned', 'in_progress'].contains(m.status))
      .toList();

  List<MissionModel> get completedMissions => missions
      .where((m) => ['completed', 'review_submitted'].contains(m.status))
      .toList();
}

// My Missions Notifier
class MyMissionsNotifier extends StateNotifier<MyMissionsState> {
  final MissionRepository _repository;

  MyMissionsNotifier(this._repository) : super(const MyMissionsState());

  Future<void> loadMissions({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await _repository.getMyMissions(status: status);

    if (response.success) {
      state = state.copyWith(isLoading: false, missions: response.missions);
    } else {
      state = state.copyWith(isLoading: false, error: response.message);
    }
  }

  Future<bool> cancelApplication(String missionId) async {
    final response = await _repository.cancelApplication(missionId);
    if (response.success) {
      await loadMissions();
    }
    return response.success;
  }
}

final myMissionsProvider =
    StateNotifierProvider<MyMissionsNotifier, MyMissionsState>((ref) {
  final repository = ref.watch(missionRepositoryProvider);
  return MyMissionsNotifier(repository);
});

// Mission Detail Provider
final missionDetailProvider =
    FutureProvider.family<MissionDetailResponse, String>((ref, missionId) async {
  final repository = ref.watch(missionRepositoryProvider);
  return repository.getMissionDetail(missionId);
});

// Check-in/Check-out Provider
class MissionActionNotifier extends StateNotifier<AsyncValue<void>> {
  final MissionRepository _repository;

  MissionActionNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<CheckInResponse> checkIn(
    String missionId, {
    required double latitude,
    required double longitude,
  }) async {
    state = const AsyncValue.loading();
    final response = await _repository.checkIn(
      missionId,
      latitude: latitude,
      longitude: longitude,
    );
    state = const AsyncValue.data(null);
    return response;
  }

  Future<CheckOutResponse> checkOut(String missionId) async {
    state = const AsyncValue.loading();
    final response = await _repository.checkOut(missionId);
    state = const AsyncValue.data(null);
    return response;
  }
}

final missionActionProvider =
    StateNotifierProvider<MissionActionNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(missionRepositoryProvider);
  return MissionActionNotifier(repository);
});
