import '../../../../core/network/api_client.dart';

class TutorialRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> startTutorial(String deviceId) async {
    try {
      final response = await _apiClient.post('/tutorials/start', data: {
        'deviceId': deviceId,
      });
      return response.data['data'] ?? {};
    } catch (e) {
      throw Exception('튜토리얼 시작에 실패했습니다: $e');
    }
  }

  Future<Map<String, dynamic>> updateProgress(String sessionId, {int? step}) async {
    try {
      final response = await _apiClient.put('/tutorials/$sessionId/progress', data: {
        if (step != null) 'step': step,
      });
      return response.data['data'] ?? {};
    } catch (e) {
      throw Exception('진행 상황 업데이트에 실패했습니다: $e');
    }
  }

  Future<Map<String, dynamic>> acceptPledge(String sessionId) async {
    try {
      final response = await _apiClient.post('/tutorials/$sessionId/pledge');
      return response.data ?? {};
    } catch (e) {
      throw Exception('서약 수락에 실패했습니다: $e');
    }
  }

  Future<Map<String, dynamic>> completeTutorial(String sessionId) async {
    try {
      final response = await _apiClient.post('/tutorials/$sessionId/complete');
      return response.data ?? {};
    } catch (e) {
      throw Exception('튜토리얼 완료 처리에 실패했습니다: $e');
    }
  }
}
