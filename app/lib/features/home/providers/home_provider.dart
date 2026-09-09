import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../mission/data/models/mission_model.dart';
import '../../mission/data/repositories/mission_repository.dart';
import '../../review/data/models/review_model.dart';
import '../../review/data/repositories/review_repository.dart';
import '../../ranking/data/models/ranking_model.dart';
import '../../ranking/data/repositories/ranking_repository.dart';

class HomeDataState {
  final bool isLoading;
  final List<ReviewModel> recentReviews;
  final List<MissionModel> availableMissions;
  final List<RegionalRankingModel> topBusinesses;
  final List<ReviewerRankingModel> topReviewers;
  final String? error;
  final String? reviewsError;
  final String? rankingsError;
  final String? missionsError;
  final String selectedCategory;

  const HomeDataState({
    this.isLoading = true,
    this.recentReviews = const [],
    this.availableMissions = const [],
    this.topBusinesses = const [],
    this.topReviewers = const [],
    this.error,
    this.reviewsError,
    this.rankingsError,
    this.missionsError,
    this.selectedCategory = '전체',
  });

  List<MissionModel> get filteredMissions => availableMissions;
  List<ReviewModel> get filteredReviews => recentReviews;
}

class HomeDataNotifier extends StateNotifier<HomeDataState> {
  final ReviewRepository _reviewRepository;
  final MissionRepository _missionRepository;
  final RankingRepository _rankingRepository;
  int _request = 0;
  bool _includeMissions = false;

  HomeDataNotifier(
      this._reviewRepository, this._missionRepository, this._rankingRepository)
      : super(const HomeDataState());

  Future<void> loadHomeData({String? category, bool? includeMissions}) async {
    final request = ++_request;
    final selected = category ?? state.selectedCategory;
    final filter = selected == '전체' ? null : selected;
    _includeMissions = includeMissions ?? _includeMissions;
    final loadMissions = _includeMissions;
    state = HomeDataState(selectedCategory: selected);
    List<ReviewModel> reviews = [];
    List<MissionModel> missions = [];
    List<RegionalRankingModel> businesses = [];
    String? reviewsError;
    String? rankingsError;
    String? missionsError;

    // 섹션별 실패 분리. 로그인 전 미션 접근 실패가 공개 리뷰를 가리지 않는다.
    await Future.wait([
      () async {
        try {
          final result =
              await _reviewRepository.getReviews(category: filter, limit: 6);
          if (!result.success) throw StateError('reviews unavailable');
          reviews = result.reviews;
        } catch (_) {
          reviewsError = '감찰 목록을 불러오지 못했어요.';
        }
      }(),
      () async {
        try {
          businesses =
              await _rankingRepository.getRegionalRanking(category: filter);
        } catch (_) {
          rankingsError = '랭킹을 불러오지 못했어요.';
        }
      }(),
      if (loadMissions)
        () async {
          try {
            final result = await _missionRepository.getAvailableMissions(
                limit: 5, category: filter);
            if (!result.success) throw StateError('missions unavailable');
            missions = result.missions;
          } catch (_) {
            missionsError = '모집 중인 감찰을 불러오지 못했어요.';
          }
        }(),
    ]);
    if (!mounted || request != _request) return;
    state = HomeDataState(
      isLoading: false,
      selectedCategory: selected,
      recentReviews: reviews,
      availableMissions: missions,
      topBusinesses: businesses.take(5).toList(),
      reviewsError: reviewsError,
      rankingsError: rankingsError,
      missionsError: missionsError,
    );
  }

  void setCategory(String category) {
    if (category != state.selectedCategory) loadHomeData(category: category);
  }

  Future<void> refresh() => loadHomeData();
}

final reviewRepositoryProvider =
    Provider<ReviewRepository>((ref) => ReviewRepository());
final missionRepositoryProvider =
    Provider<MissionRepository>((ref) => MissionRepository());
final rankingRepositoryProvider =
    Provider<RankingRepository>((ref) => RankingRepository());
final homeDataProvider =
    StateNotifierProvider<HomeDataNotifier, HomeDataState>((ref) {
  return HomeDataNotifier(
      ref.watch(reviewRepositoryProvider),
      ref.watch(missionRepositoryProvider),
      ref.watch(rankingRepositoryProvider));
});
final selectedCategoryProvider = StateProvider<String>((ref) => '전체');
