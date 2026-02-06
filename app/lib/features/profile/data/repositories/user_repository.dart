import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/models/user_model.dart';

class UserRepository {
  final ApiClient _apiClient = ApiClient();

  // 내 프로필 조회
  Future<UserProfileResponse> getMyProfile() async {
    try {
      final response = await _apiClient.get('/users/me');

      if (response.data['success']) {
        return UserProfileResponse(
          success: true,
          user: UserModel.fromJson(response.data['data']['user']),
          stats: response.data['data']['stats'] != null
              ? UserStats.fromJson(response.data['data']['stats'])
              : null,
        );
      }

      return UserProfileResponse(
        success: false,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return UserProfileResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // 프로필 업데이트
  Future<ApiResponse> updateProfile({
    String? nickname,
    String? profileImage,
    List<String>? specialties,
  }) async {
    try {
      final response = await _apiClient.put('/users/me', data: {
        if (nickname != null) 'nickname': nickname,
        if (profileImage != null) 'profileImage': profileImage,
        if (specialties != null) 'specialties': specialties,
      });

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

  // 정산 계좌 업데이트
  Future<ApiResponse> updateBankAccount({
    required String bankName,
    required String bankAccount,
    required String bankHolder,
  }) async {
    try {
      final response = await _apiClient.put('/users/me/bank', data: {
        'bankName': bankName,
        'bankAccount': bankAccount,
        'bankHolder': bankHolder,
      });

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

  // 정산 내역 조회
  Future<SettlementListResponse> getSettlements({int page = 1}) async {
    try {
      final response = await _apiClient.get(
        '/users/me/settlements',
        queryParameters: {'page': page},
      );

      if (response.data['success']) {
        final settlements = (response.data['data']['settlements'] as List)
            .map((s) => Settlement.fromJson(s))
            .toList();
        return SettlementListResponse(
          success: true,
          settlements: settlements,
          pendingAmount: response.data['data']['pendingAmount'] ?? 0,
        );
      }

      return SettlementListResponse(
        success: false,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return SettlementListResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // 정산 요청
  Future<ApiResponse> requestSettlement() async {
    try {
      final response = await _apiClient.post('/users/me/settlements/request');

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

  // 비밀번호 변경
  Future<ApiResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.put('/users/me/password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

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

class UserProfileResponse {
  final bool success;
  final String? message;
  final UserModel? user;
  final UserStats? stats;

  UserProfileResponse({
    required this.success,
    this.message,
    this.user,
    this.stats,
  });
}

class UserStats {
  final int completedMissions;
  final int ongoingMissions;
  final double trustScore;
  final int totalEarnings;
  final int pendingSettlement;

  UserStats({
    required this.completedMissions,
    this.ongoingMissions = 0,
    required this.trustScore,
    required this.totalEarnings,
    required this.pendingSettlement,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      completedMissions: json['completedMissions'] ?? json['completed_missions'] ?? 0,
      ongoingMissions: json['ongoingMissions'] ?? json['ongoing_missions'] ?? 0,
      trustScore: (json['trustScore'] ?? json['trust_score'] ?? 0).toDouble(),
      totalEarnings: json['totalEarnings'] ?? json['total_earnings'] ?? 0,
      pendingSettlement: json['pendingSettlement'] ?? json['pending_settlement'] ?? 0,
    );
  }
}

class SettlementListResponse {
  final bool success;
  final String? message;
  final List<Settlement> settlements;
  final int pendingAmount;

  SettlementListResponse({
    required this.success,
    this.message,
    this.settlements = const [],
    this.pendingAmount = 0,
  });
}

class Settlement {
  final String id;
  final int amount;
  final String status;
  final DateTime requestedAt;
  final DateTime? processedAt;
  // 타임라인 데이터
  final DateTime? missionCompletedAt;
  final DateTime? reviewApprovedAt;
  final DateTime? payoutStartedAt;
  final DateTime? payoutCompletedAt;
  // 추가 정보
  final String? missionTitle;
  final String? bankName;
  final String? bankAccountLast4;
  final int? retryCount;
  final String? errorMessage;
  final DateTime? estimatedPayoutDate;

  Settlement({
    required this.id,
    required this.amount,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.missionCompletedAt,
    this.reviewApprovedAt,
    this.payoutStartedAt,
    this.payoutCompletedAt,
    this.missionTitle,
    this.bankName,
    this.bankAccountLast4,
    this.retryCount,
    this.errorMessage,
    this.estimatedPayoutDate,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      id: json['id'] ?? '',
      amount: json['amount'] ?? 0,
      status: json['status'] ?? 'pending',
      requestedAt: json['requested_at'] != null
          ? DateTime.parse(json['requested_at'])
          : DateTime.now(),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'])
          : null,
      // 타임라인 데이터
      missionCompletedAt: json['mission_completed_at'] != null
          ? DateTime.parse(json['mission_completed_at'])
          : null,
      reviewApprovedAt: json['review_approved_at'] != null
          ? DateTime.parse(json['review_approved_at'])
          : null,
      payoutStartedAt: json['payout_started_at'] != null
          ? DateTime.parse(json['payout_started_at'])
          : null,
      payoutCompletedAt: json['payout_completed_at'] != null
          ? DateTime.parse(json['payout_completed_at'])
          : null,
      // 추가 정보
      missionTitle: json['mission_title'],
      bankName: json['bank_name'],
      bankAccountLast4: json['bank_account_last4'],
      retryCount: json['retry_count'],
      errorMessage: json['error_message'],
      estimatedPayoutDate: json['estimated_payout_date'] != null
          ? DateTime.parse(json['estimated_payout_date'])
          : null,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return '대기중';
      case 'processing':
        return '처리중';
      case 'completed':
        return '완료';
      case 'failed':
        return '실패';
      case 'hold':
        return '보류';
      case 'releasing':
        return '지급중';
      default:
        return status;
    }
  }

  /// 타임라인 이벤트 목록 반환
  List<SettlementTimelineEvent> get timelineEvents {
    final events = <SettlementTimelineEvent>[];

    // 1. 미션 완료
    events.add(SettlementTimelineEvent(
      step: SettlementStep.missionCompleted,
      title: '미션 완료',
      description: missionTitle ?? '미션을 완료했습니다',
      completedAt: missionCompletedAt,
      isCompleted: missionCompletedAt != null,
    ));

    // 2. 리뷰 승인
    events.add(SettlementTimelineEvent(
      step: SettlementStep.reviewApproved,
      title: '리뷰 승인',
      description: '리뷰가 승인되었습니다',
      completedAt: reviewApprovedAt,
      isCompleted: reviewApprovedAt != null,
    ));

    // 3. 정산 신청
    events.add(SettlementTimelineEvent(
      step: SettlementStep.requested,
      title: '정산 신청',
      description: '정산을 신청했습니다',
      completedAt: requestedAt,
      isCompleted: true, // 정산 목록에 있으면 항상 완료
    ));

    // 4. 정산 처리중
    final isProcessing = status == 'processing' || status == 'releasing';
    events.add(SettlementTimelineEvent(
      step: SettlementStep.processing,
      title: '정산 처리중',
      description: _getProcessingDescription(),
      completedAt: payoutStartedAt,
      isCompleted: payoutStartedAt != null || status == 'completed',
      isInProgress: isProcessing,
    ));

    // 5. 정산 완료
    events.add(SettlementTimelineEvent(
      step: SettlementStep.completed,
      title: '정산 완료',
      description: _getCompletedDescription(),
      completedAt: payoutCompletedAt ?? processedAt,
      isCompleted: status == 'completed',
      isFailed: status == 'failed',
      errorMessage: status == 'failed' ? errorMessage : null,
    ));

    return events;
  }

  String _getProcessingDescription() {
    if (retryCount != null && retryCount! > 0) {
      return '재시도 중 ($retryCount회)';
    }
    if (bankName != null && bankAccountLast4 != null) {
      return '$bankName ****$bankAccountLast4';
    }
    return '계좌로 이체 중입니다';
  }

  String _getCompletedDescription() {
    if (status == 'failed') {
      return errorMessage ?? '정산 실패';
    }
    if (status == 'completed') {
      return '정산이 완료되었습니다';
    }
    if (estimatedPayoutDate != null) {
      return '예정일: ${_formatDate(estimatedPayoutDate!)}';
    }
    return '영업일 기준 3-5일 소요';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}

/// 정산 타임라인 단계
enum SettlementStep {
  missionCompleted,
  reviewApproved,
  requested,
  processing,
  completed,
}

/// 정산 타임라인 이벤트
class SettlementTimelineEvent {
  final SettlementStep step;
  final String title;
  final String description;
  final DateTime? completedAt;
  final bool isCompleted;
  final bool isInProgress;
  final bool isFailed;
  final String? errorMessage;

  SettlementTimelineEvent({
    required this.step,
    required this.title,
    required this.description,
    this.completedAt,
    this.isCompleted = false,
    this.isInProgress = false,
    this.isFailed = false,
    this.errorMessage,
  });
}
