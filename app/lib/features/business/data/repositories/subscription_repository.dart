import '../../../../core/network/api_client.dart';
import '../models/cancel_flow_model.dart';

class SubscriptionRepository {
  final ApiClient _apiClient = ApiClient();

  Future<CancelInitiateResponse> initiateCancel(String businessId) async {
    final response = await _apiClient.post('/businesses/$businessId/cancel/initiate');
    return CancelInitiateResponse.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> submitCancelReason(String businessId, String category, String? detail) async {
    final response = await _apiClient.post('/businesses/$businessId/cancel/reason', data: {
      'reasonCategory': category,
      'reasonDetail': detail,
    });
    return response.data['data'];
  }

  Future<Map<String, dynamic>> pauseSubscription(String businessId) async {
    final response = await _apiClient.post('/businesses/$businessId/cancel/pause');
    return response.data;
  }

  Future<void> confirmCancel(String businessId) async {
    await _apiClient.post('/businesses/$businessId/cancel/confirm');
  }

  /// 업체 구독 신청. Toss 결제 위젯에서 받은 paymentKey 를 백엔드로 보내
  /// 서버 측에서 결제 승인(confirmPayment)을 수행한다.
  /// plan: 'starter' | 'growth' | 'pro' (스키마 enum과 일치)
  Future<SubscribeResult> subscribe({
    required String businessId,
    required String plan,
    required String paymentKey,
  }) async {
    try {
      final response = await _apiClient.post(
        '/businesses/$businessId/subscribe',
        data: {
          'plan': plan,
          'paymentKey': paymentKey,
        },
      );
      final data = response.data;
      if (data['success'] == true) {
        return SubscribeResult.success(
          plan: data['data']?['subscription']?['plan'] ?? plan,
          endDate: data['data']?['subscription']?['endDate'],
        );
      }
      return SubscribeResult.failure(
        message: data['message'] ?? '구독 신청에 실패했습니다.',
      );
    } catch (e) {
      return SubscribeResult.failure(
        message: ApiClient.extractErrorMessage(e) ?? '네트워크 오류가 발생했습니다.',
      );
    }
  }

  /// 내 업체 목록에서 첫 번째 업체 ID 반환. 구독은 등록된 업체가 있어야 가능하다.
  Future<String?> getMyFirstBusinessId() async {
    try {
      final response = await _apiClient.get('/businesses/my/list');
      final businesses = response.data['data']?['businesses'] as List?;
      if (businesses == null || businesses.isEmpty) return null;
      return businesses.first['id'] as String?;
    } catch (_) {
      return null;
    }
  }
}

class SubscribeResult {
  final bool success;
  final String? message;
  final String? plan;
  final String? endDate;

  SubscribeResult._({
    required this.success,
    this.message,
    this.plan,
    this.endDate,
  });

  factory SubscribeResult.success({required String plan, String? endDate}) =>
      SubscribeResult._(success: true, plan: plan, endDate: endDate);

  factory SubscribeResult.failure({required String message}) =>
      SubscribeResult._(success: false, message: message);
}
