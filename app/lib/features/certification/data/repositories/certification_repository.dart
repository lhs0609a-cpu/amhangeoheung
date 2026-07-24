import '../../../../core/network/api_client.dart';
import '../models/training_module_model.dart';

class CertificationRepository {
  final ApiClient _apiClient = ApiClient();

  Future<CertificationStatus> getCertificationStatus() async {
    try {
      final response = await _apiClient.dio.get('/certification/status');
      if (response.data['success'] == true) {
        return CertificationStatus.fromJson(response.data['data']);
      }
      return CertificationStatus();
    } catch (e) {
      return CertificationStatus();
    }
  }

  Future<List<TrainingModule>> getTrainingModules(int day) async {
    try {
      final response = await _apiClient.dio.get('/certification/modules/$day');
      if (response.data['success'] == true) {
        final modules = (response.data['data']['modules'] as List)
            .map((m) => TrainingModule.fromJson(m))
            .toList();
        return modules;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> startModule(String moduleId) async {
    try {
      final response = await _apiClient.dio.post('/certification/modules/$moduleId/start');
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> submitQuiz(String moduleId, Map<int, int> answers) async {
    try {
      final response = await _apiClient.dio.post(
        '/certification/modules/$moduleId/submit',
        data: {'answers': answers},
      );
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return {'passed': false, 'score': 0};
    } catch (e) {
      return {'passed': false, 'score': 0, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> completeDay(int day) async {
    try {
      final response = await _apiClient.dio.post('/certification/day/$day/complete');
      if (response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      return {'error': response.data['message']};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> takeFinalExam(Map<int, int> answers) async {
    try {
      final response = await _apiClient.dio.post(
        '/certification/final-exam',
        data: {'answers': answers},
      );
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return {'passed': false, 'score': 0};
    } catch (e) {
      return {'passed': false, 'score': 0, 'error': e.toString()};
    }
  }
}
