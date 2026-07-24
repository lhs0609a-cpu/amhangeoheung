import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/cancel_flow_model.dart';
import '../data/repositories/subscription_repository.dart';

class CancelFlowState {
  final int currentPage;
  final bool isLoading;
  final String? error;
  final CancelInitiateResponse? initiateData;
  final String? selectedReason;
  final String? reasonDetail;
  final Map<String, dynamic>? retentionOffer;
  final bool isCancelled;

  const CancelFlowState({
    this.currentPage = 0,
    this.isLoading = false,
    this.error,
    this.initiateData,
    this.selectedReason,
    this.reasonDetail,
    this.retentionOffer,
    this.isCancelled = false,
  });

  CancelFlowState copyWith({
    int? currentPage,
    bool? isLoading,
    String? error,
    CancelInitiateResponse? initiateData,
    String? selectedReason,
    String? reasonDetail,
    Map<String, dynamic>? retentionOffer,
    bool? isCancelled,
  }) {
    return CancelFlowState(
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      initiateData: initiateData ?? this.initiateData,
      selectedReason: selectedReason ?? this.selectedReason,
      reasonDetail: reasonDetail ?? this.reasonDetail,
      retentionOffer: retentionOffer ?? this.retentionOffer,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }
}

class CancelFlowNotifier extends StateNotifier<CancelFlowState> {
  final SubscriptionRepository _repository = SubscriptionRepository();
  final String businessId;

  CancelFlowNotifier(this.businessId) : super(const CancelFlowState());

  Future<void> loadInitiateData() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _repository.initiateCancel(businessId);
      state = state.copyWith(initiateData: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void nextPage() => state = state.copyWith(currentPage: state.currentPage + 1);
  void previousPage() {
    if (state.currentPage > 0) state = state.copyWith(currentPage: state.currentPage - 1);
  }

  void setReason(String reason) => state = state.copyWith(selectedReason: reason);
  void setReasonDetail(String detail) => state = state.copyWith(reasonDetail: detail);

  Future<void> submitReason() async {
    if (state.selectedReason == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final data = await _repository.submitCancelReason(
        businessId, state.selectedReason!, state.reasonDetail,
      );
      state = state.copyWith(
        retentionOffer: data['retentionOffer'],
        isLoading: false,
      );
      nextPage();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> pauseSubscription() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.pauseSubscription(businessId);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> confirmCancel() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.confirmCancel(businessId);
      state = state.copyWith(isLoading: false, isCancelled: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final cancelFlowProvider = StateNotifierProvider.autoDispose.family<CancelFlowNotifier, CancelFlowState, String>(
  (ref, businessId) => CancelFlowNotifier(businessId),
);
