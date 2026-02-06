import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/review_model.dart';
import '../data/repositories/review_repository.dart';

// Review Repository Provider
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository();
});

// Reviews State
class ReviewsState {
  final bool isLoading;
  final List<ReviewModel> reviews;
  final String? error;
  final String? selectedCategory;

  const ReviewsState({
    this.isLoading = false,
    this.reviews = const [],
    this.error,
    this.selectedCategory,
  });

  ReviewsState copyWith({
    bool? isLoading,
    List<ReviewModel>? reviews,
    String? error,
    String? selectedCategory,
  }) {
    return ReviewsState(
      isLoading: isLoading ?? this.isLoading,
      reviews: reviews ?? this.reviews,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

// Reviews Notifier
class ReviewsNotifier extends StateNotifier<ReviewsState> {
  final ReviewRepository _repository;

  ReviewsNotifier(this._repository) : super(const ReviewsState());

  Future<void> loadReviews({String? category}) async {
    state = state.copyWith(isLoading: true, error: null, selectedCategory: category);

    final response = await _repository.getReviews(category: category);

    if (response.success) {
      state = state.copyWith(isLoading: false, reviews: response.reviews);
    } else {
      state = state.copyWith(isLoading: false, error: response.message);
    }
  }

  void setCategory(String? category) {
    loadReviews(category: category);
  }

  Future<bool> markHelpful(String reviewId) async {
    final response = await _repository.markHelpful(reviewId);
    if (response.success) {
      // 리뷰 목록 새로고침
      await loadReviews(category: state.selectedCategory);
    }
    return response.success;
  }
}

final reviewsProvider = StateNotifierProvider<ReviewsNotifier, ReviewsState>((ref) {
  final repository = ref.watch(reviewRepositoryProvider);
  return ReviewsNotifier(repository);
});

// Trending Reviews Provider
final trendingReviewsProvider = FutureProvider<List<ReviewModel>>((ref) async {
  final repository = ref.watch(reviewRepositoryProvider);
  final response = await repository.getTrendingReviews();
  if (response.success) {
    return response.reviews;
  }
  throw Exception(response.message);
});

// Recent Reviews Provider
final recentReviewsProvider = FutureProvider<List<ReviewModel>>((ref) async {
  final repository = ref.watch(reviewRepositoryProvider);
  final response = await repository.getRecentReviews();
  if (response.success) {
    return response.reviews;
  }
  throw Exception(response.message);
});

// Review Detail Provider
final reviewDetailProvider = FutureProvider.family<ReviewModel?, String>((ref, reviewId) async {
  final repository = ref.watch(reviewRepositoryProvider);
  final response = await repository.getReviewDetail(reviewId);
  if (response.success) {
    return response.review;
  }
  throw Exception(response.message);
});

// My Reviews Provider
final myReviewsProvider = FutureProvider<List<ReviewModel>>((ref) async {
  final repository = ref.watch(reviewRepositoryProvider);
  final response = await repository.getMyReviews();
  if (response.success) {
    return response.reviews;
  }
  throw Exception(response.message);
});

// Write Review State
class WriteReviewState {
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final Map<String, int> scores;
  final List<String> pros;
  final List<String> cons;
  final String? summary;

  const WriteReviewState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.scores = const {},
    this.pros = const [],
    this.cons = const [],
    this.summary,
  });

  WriteReviewState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    Map<String, int>? scores,
    List<String>? pros,
    List<String>? cons,
    String? summary,
  }) {
    return WriteReviewState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      scores: scores ?? this.scores,
      pros: pros ?? this.pros,
      cons: cons ?? this.cons,
      summary: summary ?? this.summary,
    );
  }

  bool get isValid => scores.isNotEmpty && cons.isNotEmpty;
}

// Write Review Notifier
class WriteReviewNotifier extends StateNotifier<WriteReviewState> {
  final ReviewRepository _repository;

  WriteReviewNotifier(this._repository) : super(const WriteReviewState());

  void updateScore(String category, int score) {
    final newScores = Map<String, int>.from(state.scores);
    newScores[category] = score;
    state = state.copyWith(scores: newScores);
  }

  void updatePros(List<String> pros) {
    state = state.copyWith(pros: pros);
  }

  void updateCons(List<String> cons) {
    state = state.copyWith(cons: cons);
  }

  void updateSummary(String summary) {
    state = state.copyWith(summary: summary);
  }

  Future<ReviewModel?> submitReview(String missionId) async {
    if (!state.isValid) {
      state = state.copyWith(error: '점수와 개선점을 입력해주세요.');
      return null;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    final response = await _repository.createReview(
      missionId: missionId,
      scores: state.scores,
      pros: state.pros,
      cons: state.cons,
      summary: state.summary,
    );

    if (response.success && response.review != null) {
      state = state.copyWith(isSubmitting: false);
      return response.review;
    } else {
      state = state.copyWith(isSubmitting: false, error: response.message);
      return null;
    }
  }

  void reset() {
    state = const WriteReviewState();
  }
}

final writeReviewProvider = StateNotifierProvider<WriteReviewNotifier, WriteReviewState>((ref) {
  final repository = ref.watch(reviewRepositoryProvider);
  return WriteReviewNotifier(repository);
});
