import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/mission_model.dart';

class MissionRepository {
  final ApiClient _apiClient = ApiClient();

  // 참여 가능한 미션 목록 조회
  Future<MissionListResponse> getAvailableMissions({
    String? category,
    String? city,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/missions/available',
        queryParameters: {
          if (category != null) 'category': category,
          if (city != null) 'city': city,
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['success']) {
        final missions = (response.data['data']['missions'] as List)
            .map((m) => MissionModel.fromJson(m))
            .toList();
        return MissionListResponse(success: true, missions: missions);
      }

      return MissionListResponse(
        success: false,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return MissionListResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // 내 미션 목록 조회
  Future<MissionListResponse> getMyMissions({String? status}) async {
    try {
      final response = await _apiClient.get(
        '/missions/my',
        queryParameters: {
          if (status != null) 'status': status,
        },
      );

      if (response.data['success']) {
        final missions = (response.data['data']['missions'] as List)
            .map((m) => MissionModel.fromJson(m))
            .toList();
        return MissionListResponse(success: true, missions: missions);
      }

      return MissionListResponse(
        success: false,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return MissionListResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // 미션 상세 조회
  Future<MissionDetailResponse> getMissionDetail(String missionId) async {
    try {
      final response = await _apiClient.get('/missions/$missionId/reviewer');

      if (response.data['success']) {
        return MissionDetailResponse(
          success: true,
          mission: MissionModel.fromJson(response.data['data']['mission']),
          isAssigned: response.data['data']['isAssigned'] ?? false,
        );
      }

      return MissionDetailResponse(
        success: false,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return MissionDetailResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // 미션 신청
  Future<ApiResponse> applyMission(String missionId) async {
    try {
      final response = await _apiClient.post('/missions/$missionId/apply');

      return ApiResponse(
        success: response.data['success'],
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // 미션 신청 취소
  Future<ApiResponse> cancelApplication(String missionId) async {
    try {
      final response = await _apiClient.delete('/missions/$missionId/apply');

      return ApiResponse(
        success: response.data['success'],
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // 체크인
  Future<CheckInResponse> checkIn(
    String missionId, {
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiClient.post(
        '/missions/$missionId/check-in',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      if (response.data['success']) {
        return CheckInResponse(
          success: true,
          message: response.data['message'],
          businessName: response.data['data']?['businessName'],
          address: response.data['data']?['address'],
        );
      }

      return CheckInResponse(
        success: false,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return CheckInResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // 체크아웃
  Future<CheckOutResponse> checkOut(String missionId) async {
    try {
      final response = await _apiClient.post('/missions/$missionId/check-out');

      if (response.data['success']) {
        return CheckOutResponse(
          success: true,
          message: response.data['message'],
          stayMinutes: response.data['data']?['stayMinutes'],
        );
      }

      return CheckOutResponse(
        success: false,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return CheckOutResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // 미션 검색
  Future<MissionListResponse> searchMissions(String query) async {
    try {
      final response = await _apiClient.get(
        '/missions/available',
        queryParameters: {
          'search': query,
          'limit': 20,
        },
      );

      if (response.data['success']) {
        final missions = (response.data['data']['missions'] as List)
            .map((m) => MissionModel.fromJson(m))
            .toList();
        return MissionListResponse(success: true, missions: missions);
      }

      return MissionListResponse(
        success: false,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return MissionListResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  String _getErrorMessage(DioException e) {
    if (e.response != null) {
      return e.response!.data['message'] ?? '오류가 발생했습니다.';
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '서버 연결 시간이 초과되었습니다.';
      case DioExceptionType.connectionError:
        return '네트워크 연결을 확인해주세요.';
      default:
        return '서버 오류가 발생했습니다.';
    }
  }
}

// Response Classes
class ApiResponse {
  final bool success;
  final String? message;

  ApiResponse({required this.success, this.message});
}

class MissionListResponse {
  final bool success;
  final String? message;
  final List<MissionModel> missions;

  MissionListResponse({
    required this.success,
    this.message,
    this.missions = const [],
  });
}

class MissionDetailResponse {
  final bool success;
  final String? message;
  final MissionModel? mission;
  final bool isAssigned;

  MissionDetailResponse({
    required this.success,
    this.message,
    this.mission,
    this.isAssigned = false,
  });
}

class CheckInResponse {
  final bool success;
  final String? message;
  final String? businessName;
  final String? address;

  CheckInResponse({
    required this.success,
    this.message,
    this.businessName,
    this.address,
  });
}

class CheckOutResponse {
  final bool success;
  final String? message;
  final int? stayMinutes;

  CheckOutResponse({
    required this.success,
    this.message,
    this.stayMinutes,
  });
}
