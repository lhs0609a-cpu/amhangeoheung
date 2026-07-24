import '../../../../core/network/api_client.dart';
import '../models/ranking_model.dart';

class RankingRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<RegionalRankingModel>> getRegionalRanking({String? region, String? category}) async {
    final params = <String, dynamic>{};
    if (region != null) params['region'] = region;
    if (category != null) params['category'] = category;
    final response = await _apiClient.get('/rankings/regional', queryParameters: params);
    final List data = response.data['data'] ?? [];
    return data.map((e) => RegionalRankingModel.fromJson(e)).toList();
  }

  Future<List<ReviewerRankingModel>> getReviewerRanking({int limit = 20}) async {
    final response = await _apiClient.get('/rankings/reviewers', queryParameters: {'limit': limit});
    final List data = response.data['data'] ?? [];
    return data.map((e) => ReviewerRankingModel.fromJson(e)).toList();
  }

  Future<Map<String, List<String>>> getAvailableRegions() async {
    final response = await _apiClient.get('/rankings/regions');
    final data = response.data['data'];
    return {
      'regions': List<String>.from(data['regions'] ?? []),
      'categories': List<String>.from(data['categories'] ?? []),
    };
  }
}
