import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/models/user_model.dart';
import '../data/repositories/user_repository.dart';

// User Repository Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// Profile State
class ProfileState {
  final bool isLoading;
  final UserModel? user;
  final UserStats? stats;
  final String? error;

  const ProfileState({
    this.isLoading = false,
    this.user,
    this.stats,
    this.error,
  });

  ProfileState copyWith({
    bool? isLoading,
    UserModel? user,
    UserStats? stats,
    String? error,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      stats: stats ?? this.stats,
      error: error,
    );
  }
}

// Profile Notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  final UserRepository _repository;

  ProfileNotifier(this._repository) : super(const ProfileState());

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await _repository.getMyProfile();

    if (response.success) {
      state = state.copyWith(
        isLoading: false,
        user: response.user,
        stats: response.stats,
      );
    } else {
      state = state.copyWith(isLoading: false, error: response.message);
    }
  }

  Future<bool> updateProfile({
    String? nickname,
    String? profileImage,
    List<String>? specialties,
  }) async {
    final response = await _repository.updateProfile(
      nickname: nickname,
      profileImage: profileImage,
      specialties: specialties,
    );

    if (response.success) {
      await loadProfile();
    }
    return response.success;
  }

  Future<bool> updateBankAccount({
    required String bankName,
    required String bankAccount,
    required String bankHolder,
  }) async {
    final response = await _repository.updateBankAccount(
      bankName: bankName,
      bankAccount: bankAccount,
      bankHolder: bankHolder,
    );

    if (response.success) {
      await loadProfile();
    }
    return response.success;
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return ProfileNotifier(repository);
});

// Settlements State
class SettlementsState {
  final bool isLoading;
  final List<Settlement> settlements;
  final int pendingAmount;
  final String? error;

  const SettlementsState({
    this.isLoading = false,
    this.settlements = const [],
    this.pendingAmount = 0,
    this.error,
  });

  SettlementsState copyWith({
    bool? isLoading,
    List<Settlement>? settlements,
    int? pendingAmount,
    String? error,
  }) {
    return SettlementsState(
      isLoading: isLoading ?? this.isLoading,
      settlements: settlements ?? this.settlements,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      error: error,
    );
  }
}

// Settlements Notifier
class SettlementsNotifier extends StateNotifier<SettlementsState> {
  final UserRepository _repository;

  SettlementsNotifier(this._repository) : super(const SettlementsState());

  Future<void> loadSettlements() async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await _repository.getSettlements();

    if (response.success) {
      state = state.copyWith(
        isLoading: false,
        settlements: response.settlements,
        pendingAmount: response.pendingAmount,
      );
    } else {
      state = state.copyWith(isLoading: false, error: response.message);
    }
  }

  Future<bool> requestSettlement() async {
    final response = await _repository.requestSettlement();

    if (response.success) {
      await loadSettlements();
    }
    return response.success;
  }
}

final settlementsProvider = StateNotifierProvider<SettlementsNotifier, SettlementsState>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return SettlementsNotifier(repository);
});
