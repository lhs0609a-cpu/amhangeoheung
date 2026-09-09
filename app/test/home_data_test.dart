import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:amhangeoheung_app/features/home/providers/home_provider.dart';
import 'package:amhangeoheung_app/features/review/data/repositories/review_repository.dart';
import 'package:amhangeoheung_app/features/mission/data/repositories/mission_repository.dart';
import 'package:amhangeoheung_app/features/ranking/data/repositories/ranking_repository.dart';
import 'package:amhangeoheung_app/features/ranking/data/models/ranking_model.dart';

class Reviews extends ReviewRepository {
  final Map<String?, Completer<ReviewListResponse>> pending = {};
  @override
  Future<ReviewListResponse> getReviews(
      {String? category, int page = 1, int limit = 20}) {
    return (pending[category] ??= Completer<ReviewListResponse>()).future;
  }
}

class Missions extends MissionRepository {
  int calls = 0;
  @override
  Future<MissionListResponse> getAvailableMissions(
      {String? category,
      String? city,
      String? type,
      int page = 1,
      int limit = 20}) async {
    calls++;
    return MissionListResponse(success: false, message: 'Unauthorized');
  }
}

class Rankings extends RankingRepository {
  @override
  Future<List<RegionalRankingModel>> getRegionalRanking(
          {String? region, String? category}) async =>
      [];
}

void main() {
  test('consumer home does not request private mission data', () async {
    final reviews = Reviews();
    final missions = Missions();
    final notifier = HomeDataNotifier(reviews, missions, Rankings());
    final load = notifier.loadHomeData();
    reviews.pending[null]!.complete(ReviewListResponse(success: true));
    await load;
    expect(missions.calls, 0);
    expect(notifier.state.reviewsError, isNull);
    expect(notifier.state.isLoading, false);
    notifier.dispose();
  });
  test('mission failure does not erase public reviews and is not empty success',
      () async {
    final reviews = Reviews();
    final notifier = HomeDataNotifier(reviews, Missions(), Rankings());
    final load = notifier.loadHomeData(includeMissions: true);
    reviews.pending[null]!.complete(ReviewListResponse(success: true));
    await load;
    expect(notifier.state.missionsError, isNotNull);
    expect(notifier.state.reviewsError, isNull);
    notifier.dispose();
  });
  test('category and role request generation rejects late results', () async {
    final reviews = Reviews();
    final notifier = HomeDataNotifier(reviews, Missions(), Rankings());
    final old = notifier.loadHomeData(category: '음식점');
    final latest = notifier.loadHomeData(category: '카페');
    reviews.pending['카페']!.complete(ReviewListResponse(success: true));
    await latest;
    reviews.pending['음식점']!.complete(ReviewListResponse(success: false));
    await old;
    expect(notifier.state.selectedCategory, '카페');
    expect(notifier.state.reviewsError, isNull);
    notifier.dispose();
  });
}
