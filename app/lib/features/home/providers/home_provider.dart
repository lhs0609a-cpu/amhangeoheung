import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../mission/data/models/mission_model.dart';
import '../../mission/data/repositories/mission_repository.dart';
import '../../review/data/models/review_model.dart';
import '../../review/data/repositories/review_repository.dart';

// Home Data State
class HomeDataState {
  final bool isLoading;
  final List<ReviewModel> recentReviews;
  final List<MissionModel> availableMissions;
  final String? error;
  final String selectedCategory;

  const HomeDataState({
    this.isLoading = false,
    this.recentReviews = const [],
    this.availableMissions = const [],
    this.error,
    this.selectedCategory = '전체',
  });

  HomeDataState copyWith({
    bool? isLoading,
    List<ReviewModel>? recentReviews,
    List<MissionModel>? availableMissions,
    String? error,
    String? selectedCategory,
  }) {
    return HomeDataState(
      isLoading: isLoading ?? this.isLoading,
      recentReviews: recentReviews ?? this.recentReviews,
      availableMissions: availableMissions ?? this.availableMissions,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }

  // 카테고리로 필터링된 미션 목록
  List<MissionModel> get filteredMissions {
    if (selectedCategory == '전체') {
      return availableMissions;
    }
    return availableMissions
        .where((m) => m.category?.toLowerCase() == selectedCategory.toLowerCase())
        .toList();
  }

  // 카테고리로 필터링된 리뷰 목록
  List<ReviewModel> get filteredReviews {
    if (selectedCategory == '전체') {
      return recentReviews;
    }
    return recentReviews
        .where((r) => r.business?.category?.toLowerCase() == selectedCategory.toLowerCase())
        .toList();
  }
}

// Home Data Notifier
class HomeDataNotifier extends StateNotifier<HomeDataState> {
  final ReviewRepository _reviewRepository;
  final MissionRepository _missionRepository;

  HomeDataNotifier(this._reviewRepository, this._missionRepository)
      : super(const HomeDataState());

  Future<void> loadHomeData({String? category}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 병렬로 데이터 로드
      final results = await Future.wait([
        _reviewRepository.getRecentReviews(),
        _missionRepository.getAvailableMissions(
          limit: 10,
          category: category != '전체' ? category : null,
        ),
      ]);

      final reviewResponse = results[0] as ReviewListResponse;
      final missionResponse = results[1] as MissionListResponse;

      state = state.copyWith(
        isLoading: false,
        recentReviews: reviewResponse.success ? reviewResponse.reviews : [],
        availableMissions: missionResponse.success ? missionResponse.missions : [],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '데이터를 불러오는데 실패했습니다.',
      );
    }
  }

  void setCategory(String category) {
    if (state.selectedCategory != category) {
      state = state.copyWith(selectedCategory: category);
      // 카테고리 변경 시 데이터 다시 로드
      loadHomeData(category: category);
    }
  }

  Future<void> refresh() async {
    await loadHomeData(category: state.selectedCategory);
  }
}

// Providers
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository();
});

final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  return MissionRepository();
});

final homeDataProvider = StateNotifierProvider<HomeDataNotifier, HomeDataState>((ref) {
  final reviewRepository = ref.watch(reviewRepositoryProvider);
  final missionRepository = ref.watch(missionRepositoryProvider);
  return HomeDataNotifier(reviewRepository, missionRepository);
});

// 선택된 카테고리 프로바이더 (UI 상태 관리용)
final selectedCategoryProvider = StateProvider<String>((ref) => '전체');
