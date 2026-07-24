import '../../../../core/network/api_client.dart';
import '../models/review_request_model.dart';

class ReviewRequestRepository {
  final ApiClient _apiClient = ApiClient();

  Future<ReviewRequestModel> createRequest(String businessId, {String? message}) async {
    final response = await _apiClient.post('/review-requests', data: {
      'businessId': businessId,
      if (message != null) 'message': message,
    });
    return ReviewRequestModel.fromJson(response.data['data']);
  }

  Future<List<Map<String, dynamic>>> getPopularRequests() async {
    final response = await _apiClient.get('/review-requests/popular');
    return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
  }
}
