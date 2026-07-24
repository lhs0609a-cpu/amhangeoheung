import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/referral_model.dart';
import '../data/repositories/referral_repository.dart';

class ReferralState {
  final String? code;
  final ReferralStats? stats;
  final List<RegionalDemand> demand;
  final bool isLoading;
  final String? error;

  const ReferralState({
    this.code,
    this.stats,
    this.demand = const [],
    this.isLoading = false,
    this.error,
  });

  ReferralState copyWith({
    String? code,
    ReferralStats? stats,
    List<RegionalDemand>? demand,
    bool? isLoading,
    String? error,
  }) {
    return ReferralState(
      code: code ?? this.code,
      stats: stats ?? this.stats,
      demand: demand ?? this.demand,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ReferralNotifier extends StateNotifier<ReferralState> {
  final ReferralRepository _repository = ReferralRepository();

  ReferralNotifier() : super(const ReferralState());

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    try {
      final code = await _repository.getMyReferralCode();
      final stats = await _repository.getReferralStats();
      final demand = await _repository.getRegionalDemand();
      state = state.copyWith(
        code: code, stats: stats, demand: demand, isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final referralProvider = StateNotifierProvider<ReferralNotifier, ReferralState>((ref) {
  return ReferralNotifier();
});
