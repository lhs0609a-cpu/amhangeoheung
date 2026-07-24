import '../../../../core/network/api_client.dart';
import '../models/detection_test_model.dart';

class DetectionTestRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<DetectionTest>> getPendingTests() async {
    try {
      final response = await _apiClient.dio.get('/detection-tests/pending');
      if (response.data['success'] == true) {
        return (response.data['data']['tests'] as List)
            .map((t) => DetectionTest.fromJson(t))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> submitTest({
    required String testId,
    required String guessedDate,
    required String guessedTimeSlot,
    String? guessedDescription,
    required int confidenceLevel,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/detection-tests/$testId/submit',
        data: {
          'guessedDate': guessedDate,
          'guessedTimeSlot': guessedTimeSlot,
          'guessedDescription': guessedDescription,
          'confidenceLevel': confidenceLevel,
        },
      );
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return {'error': response.data['message']};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<StealthStats> getStealthStats() async {
    try {
      final response = await _apiClient.dio.get('/detection-tests/my-stats');
      if (response.data['success'] == true) {
        return StealthStats.fromJson(response.data['data']);
      }
      return StealthStats(
        stealthScore: 100,
        totalTests: 0,
        detectedCount: 0,
        detectionRate: 0,
        advice: '',
        recentTests: [],
      );
    } catch (e) {
      return StealthStats(
        stealthScore: 100,
        totalTests: 0,
        detectedCount: 0,
        detectionRate: 0,
        advice: '',
        recentTests: [],
      );
    }
  }
}
