import '../../../../core/network/api_client.dart';
import '../models/referral_model.dart';

class ReferralRepository {
  final ApiClient _apiClient = ApiClient();

  Future<String> getMyReferralCode() async {
    final response = await _apiClient.get('/referrals/my-code');
    return response.data['data']['code'];
  }

  Future<ReferralStats> getReferralStats() async {
    final response = await _apiClient.get('/referrals/stats');
    return ReferralStats.fromJson(response.data['data']);
  }

  Future<List<RegionalDemand>> getRegionalDemand() async {
    final response = await _apiClient.get('/referrals/regional-demand');
    final List data = response.data['data'] ?? [];
    return data.map((e) => RegionalDemand.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> applyReferralCode(String code) async {
    final response = await _apiClient.post('/referrals/apply', data: {'code': code});
    return response.data;
  }
}
