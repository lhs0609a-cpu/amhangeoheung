/// 결제 요청 데이터
class PaymentRequest {
  final String orderId;
  final String orderName;
  final int amount;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final PaymentMethod method;
  final String? cardCode; // 특정 카드사 지정
  final bool isSubscription; // 정기결제 여부

  PaymentRequest({
    required this.orderId,
    required this.orderName,
    required this.amount,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    required this.method,
    this.cardCode,
    this.isSubscription = false,
  });

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'orderName': orderName,
    'amount': amount,
    'customerName': customerName,
    'customerEmail': customerEmail,
    'customerPhone': customerPhone,
    'method': method.code,
    'cardCode': cardCode,
    'isSubscription': isSubscription,
  };
}

/// 결제 결과
class PaymentResult {
  final bool success;
  final String? impUid; // 아임포트 고유 ID
  final String? merchantUid; // 가맹점 주문번호
  final String? errorCode;
  final String? errorMessage;
  final int? paidAmount;
  final String? receiptUrl;
  final PaymentMethod? method;
  final String? cardName;
  final DateTime? paidAt;

  PaymentResult({
    required this.success,
    this.impUid,
    this.merchantUid,
    this.errorCode,
    this.errorMessage,
    this.paidAmount,
    this.receiptUrl,
    this.method,
    this.cardName,
    this.paidAt,
  });

  factory PaymentResult.success({
    required String impUid,
    required String merchantUid,
    required int paidAmount,
    String? receiptUrl,
    PaymentMethod? method,
    String? cardName,
    DateTime? paidAt,
  }) {
    return PaymentResult(
      success: true,
      impUid: impUid,
      merchantUid: merchantUid,
      paidAmount: paidAmount,
      receiptUrl: receiptUrl,
      method: method,
      cardName: cardName,
      paidAt: paidAt ?? DateTime.now(),
    );
  }

  factory PaymentResult.failure({
    required String errorCode,
    required String errorMessage,
    String? merchantUid,
  }) {
    return PaymentResult(
      success: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
      merchantUid: merchantUid,
    );
  }

  factory PaymentResult.fromIamport(Map<String, dynamic> response) {
    final success = response['success'] == true || response['imp_success'] == 'true';

    if (success) {
      return PaymentResult.success(
        impUid: response['imp_uid'] ?? '',
        merchantUid: response['merchant_uid'] ?? '',
        paidAmount: response['paid_amount'] ?? 0,
        receiptUrl: response['receipt_url'],
        cardName: response['card_name'],
      );
    } else {
      return PaymentResult.failure(
        errorCode: response['error_code'] ?? 'UNKNOWN',
        errorMessage: response['error_msg'] ?? '결제에 실패했습니다',
        merchantUid: response['merchant_uid'],
      );
    }
  }
}

/// 결제 수단
enum PaymentMethod {
  card('card', '신용카드', 'creditcard'),
  kakaoPay('kakaopay', '카카오페이', 'kakaopay'),
  naverPay('naverpay', '네이버페이', 'naverpay'),
  tossPay('tosspay', '토스페이', 'tosspay'),
  samsungPay('samsungpay', '삼성페이', 'samsungpay'),
  applePay('applepay', 'Apple Pay', 'applepay'),
  phone('phone', '휴대폰 결제', 'phone'),
  vbank('vbank', '가상계좌', 'vbank'),
  trans('trans', '실시간 계좌이체', 'trans');

  final String code;
  final String displayName;
  final String pgMethod;

  const PaymentMethod(this.code, this.displayName, this.pgMethod);

  static PaymentMethod fromCode(String code) {
    return PaymentMethod.values.firstWhere(
      (m) => m.code == code,
      orElse: () => PaymentMethod.card,
    );
  }
}

/// 구독 플랜 정보
class SubscriptionPlan {
  final String id;
  final String name;
  final int monthlyPrice;
  final int yearlyPrice;
  final List<String> features;
  final bool isPopular;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    this.isPopular = false,
  });

  int getPrice(bool isYearly) => isYearly ? yearlyPrice : monthlyPrice;

  int getMonthlyEquivalent(bool isYearly) {
    if (isYearly) {
      return (yearlyPrice / 12).round();
    }
    return monthlyPrice;
  }

  int getSavingsPercent() {
    if (monthlyPrice == 0) return 0;
    final yearlyMonthly = yearlyPrice / 12;
    return (((monthlyPrice - yearlyMonthly) / monthlyPrice) * 100).round();
  }
}

/// 결제 내역
class PaymentHistory {
  final String id;
  final String orderId;
  final String orderName;
  final int amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? canceledAt;
  final String? receiptUrl;
  final String? cardName;

  PaymentHistory({
    required this.id,
    required this.orderId,
    required this.orderName,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
    this.paidAt,
    this.canceledAt,
    this.receiptUrl,
    this.cardName,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      id: json['id'],
      orderId: json['orderId'],
      orderName: json['orderName'],
      amount: json['amount'],
      method: PaymentMethod.fromCode(json['method']),
      status: PaymentStatus.fromCode(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      canceledAt: json['canceledAt'] != null ? DateTime.parse(json['canceledAt']) : null,
      receiptUrl: json['receiptUrl'],
      cardName: json['cardName'],
    );
  }
}

/// 결제 상태
enum PaymentStatus {
  pending('pending', '대기'),
  paid('paid', '결제완료'),
  canceled('canceled', '취소됨'),
  failed('failed', '실패'),
  refunded('refunded', '환불됨');

  final String code;
  final String displayName;

  const PaymentStatus(this.code, this.displayName);

  static PaymentStatus fromCode(String code) {
    return PaymentStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => PaymentStatus.pending,
    );
  }
}
