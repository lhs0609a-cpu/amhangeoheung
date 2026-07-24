import '../../../../core/network/api_client.dart';
import '../models/season_model.dart';

class SeasonRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<SeasonModel>> getActiveSeasons() async {
    final response = await _apiClient.get('/seasons');
    final List data = response.data['data'] ?? [];
    return data.map((e) => SeasonModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getSeasonDetail(String id) async {
    final response = await _apiClient.get('/seasons/$id');
    return response.data['data'];
  }
}
