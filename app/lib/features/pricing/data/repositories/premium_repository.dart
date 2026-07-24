import '../../../../core/network/api_client.dart';

/// 소비자 프리미엄 구독 리포지토리.
/// Toss 결제 위젯에서 받은 paymentKey 를 백엔드 `/users/premium/subscribe` 로
/// 보내 서버 측에서 결제 승인(confirmPayment)을 수행한다.
class PremiumRepository {
  final ApiClient _apiClient = ApiClient();

  /// 프리미엄 구독 신청.
  /// billing: 'monthly'(9,900원) | 'yearly'(99,000원) — 백엔드 가격과 일치해야 한다.
  Future<PremiumSubscribeResult> subscribe({
    required String billing,
    required String paymentKey,
  }) async {
    try {
      final response = await _apiClient.post(
        '/users/premium/subscribe',
        data: {
          'plan': billing,
          'paymentKey': paymentKey,
        },
      );
      final data = response.data;
      if (data['success'] == true) {
        return PremiumSubscribeResult.success(
          plan: data['data']?['premium_plan'] ?? billing,
          expiresAt: data['data']?['premium_expires_at'],
        );
      }
      return PremiumSubscribeResult.failure(
        message: data['message'] ??
            data['error']?['message'] ??
            '구독 신청에 실패했습니다.',
      );
    } catch (e) {
      return PremiumSubscribeResult.failure(
        message: ApiClient.extractErrorMessage(e) ?? '네트워크 오류가 발생했습니다.',
      );
    }
  }

  /// 프리미엄 구독 해지.
  Future<bool> cancel() async {
    try {
      final response = await _apiClient.post('/users/premium/cancel');
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }
}

class PremiumSubscribeResult {
  final bool success;
  final String? message;
  final String? plan;
  final String? expiresAt;

  PremiumSubscribeResult._({
    required this.success,
    this.message,
    this.plan,
    this.expiresAt,
  });

  factory PremiumSubscribeResult.success({required String plan, String? expiresAt}) =>
      PremiumSubscribeResult._(success: true, plan: plan, expiresAt: expiresAt);

  factory PremiumSubscribeResult.failure({required String message}) =>
      PremiumSubscribeResult._(success: false, message: message);
}
