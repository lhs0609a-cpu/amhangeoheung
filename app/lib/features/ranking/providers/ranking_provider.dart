import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/ranking_model.dart';
import '../data/repositories/ranking_repository.dart';

final rankingRepositoryProvider = Provider((ref) => RankingRepository());

final regionalRankingProvider = FutureProvider.family<List<RegionalRankingModel>, Map<String, String?>>((ref, params) async {
  final repository = ref.read(rankingRepositoryProvider);
  return repository.getRegionalRanking(region: params['region'], category: params['category']);
});

final reviewerRankingProvider = FutureProvider<List<ReviewerRankingModel>>((ref) async {
  final repository = ref.read(rankingRepositoryProvider);
  return repository.getReviewerRanking();
});

final availableRegionsProvider = FutureProvider<Map<String, List<String>>>((ref) async {
  final repository = ref.read(rankingRepositoryProvider);
  return repository.getAvailableRegions();
});
