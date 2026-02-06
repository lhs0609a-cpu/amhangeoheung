import 'package:flutter/foundation.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/network/api_client.dart';
import '../models/payment_models.dart';

/// 결제 서비스 - 아임포트 (PortOne) 연동
class PaymentService {
  // 아임포트 설정
  static String get merchantId => EnvironmentConfig.iamportMerchantId;
  static const String pgProvider = 'html5_inicis'; // PG사 (이니시스, KG이니시스, 토스페이먼츠 등)

  final ApiClient _apiClient;

  PaymentService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// 주문번호 생성
  String generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'ORD_$timestamp';
  }

  /// 결제 요청 데이터 생성 (아임포트용)
  Map<String, dynamic> createPaymentData({
    required PaymentRequest request,
    required String appScheme,
  }) {
    return {
      'pg': _getPgCode(request.method),
      'pay_method': request.method.pgMethod,
      'merchant_uid': request.orderId,
      'name': request.orderName,
      'amount': request.amount,
      'buyer_name': request.customerName,
      'buyer_email': request.customerEmail,
      'buyer_tel': request.customerPhone ?? '',
      'app_scheme': appScheme,
      // 정기결제 설정
      if (request.isSubscription) ...{
        'customer_uid': 'customer_${request.customerEmail.hashCode}',
        'period': {
          'from': DateTime.now().toIso8601String().split('T')[0],
          'to': DateTime.now().add(const Duration(days: 365)).toIso8601String().split('T')[0],
        },
      },
    };
  }

  /// PG사 코드 반환
  String _getPgCode(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.kakaoPay:
        return 'kakaopay';
      case PaymentMethod.naverPay:
        return 'naverpay';
      case PaymentMethod.tossPay:
        return 'tosspay';
      case PaymentMethod.samsungPay:
        return 'html5_inicis';
      case PaymentMethod.applePay:
        return 'tosspay'; // 토스페이먼츠 통해 Apple Pay 지원
      default:
        return pgProvider;
    }
  }

  /// 결제 완료 후 서버 검증
  Future<PaymentResult> verifyPayment({
    required String impUid,
    required String merchantUid,
  }) async {
    try {
      final response = await _apiClient.post(
        '/payments/verify',
        data: {
          'imp_uid': impUid,
          'merchant_uid': merchantUid,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return PaymentResult.success(
          impUid: impUid,
          merchantUid: merchantUid,
          paidAmount: response.data['data']['amount'],
          receiptUrl: response.data['data']['receipt_url'],
          cardName: response.data['data']['card_name'],
        );
      } else {
        return PaymentResult.failure(
          errorCode: 'VERIFY_FAILED',
          errorMessage: response.data['message'] ?? '결제 검증에 실패했습니다',
          merchantUid: merchantUid,
        );
      }
    } catch (e) {
      debugPrint('Payment verification error: $e');
      return PaymentResult.failure(
        errorCode: 'NETWORK_ERROR',
        errorMessage: '네트워크 오류가 발생했습니다',
        merchantUid: merchantUid,
      );
    }
  }

  /// 구독 결제 처리
  Future<PaymentResult> processSubscription({
    required String planId,
    required bool isYearly,
    required String customerUid,
  }) async {
    try {
      final response = await _apiClient.post(
        '/subscriptions/create',
        data: {
          'plan_id': planId,
          'is_yearly': isYearly,
          'customer_uid': customerUid,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return PaymentResult.success(
          impUid: response.data['data']['imp_uid'] ?? '',
          merchantUid: response.data['data']['merchant_uid'] ?? '',
          paidAmount: response.data['data']['amount'] ?? 0,
        );
      } else {
        return PaymentResult.failure(
          errorCode: 'SUBSCRIPTION_FAILED',
          errorMessage: response.data['message'] ?? '구독 처리에 실패했습니다',
        );
      }
    } catch (e) {
      debugPrint('Subscription error: $e');
      return PaymentResult.failure(
        errorCode: 'NETWORK_ERROR',
        errorMessage: '네트워크 오류가 발생했습니다',
      );
    }
  }

  /// 결제 취소
  Future<bool> cancelPayment({
    required String impUid,
    required String reason,
    int? amount, // 부분 취소 시 금액
  }) async {
    try {
      final response = await _apiClient.post(
        '/payments/cancel',
        data: {
          'imp_uid': impUid,
          'reason': reason,
          if (amount != null) 'amount': amount,
        },
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('Payment cancel error: $e');
      return false;
    }
  }

  /// 결제 내역 조회
  Future<List<PaymentHistory>> getPaymentHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/payments/history',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => PaymentHistory.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Get payment history error: $e');
      return [];
    }
  }

  /// 현재 구독 정보 조회
  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    try {
      final response = await _apiClient.get('/subscriptions/current');

      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Get subscription error: $e');
      return null;
    }
  }

  /// 구독 취소
  Future<bool> cancelSubscription({required String reason}) async {
    try {
      final response = await _apiClient.post(
        '/subscriptions/cancel',
        data: {'reason': reason},
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('Cancel subscription error: $e');
      return false;
    }
  }
}
