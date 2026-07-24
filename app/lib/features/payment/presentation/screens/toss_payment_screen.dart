import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';

/// Toss Payments 결제 결과.
class TossPaymentResult {
  final bool success;
  final String? paymentKey;
  final String? orderId;
  final int? amount;
  final String? errorMessage;
  final String? errorCode;

  TossPaymentResult._({
    required this.success,
    this.paymentKey,
    this.orderId,
    this.amount,
    this.errorMessage,
    this.errorCode,
  });

  factory TossPaymentResult.success({
    required String paymentKey,
    required String orderId,
    required int amount,
  }) =>
      TossPaymentResult._(
        success: true,
        paymentKey: paymentKey,
        orderId: orderId,
        amount: amount,
      );

  factory TossPaymentResult.failure({
    required String message,
    String? code,
  }) =>
      TossPaymentResult._(
        success: false,
        errorMessage: message,
        errorCode: code,
      );
}

/// Toss Payments 결제 위젯을 webview 로 띄우는 화면.
///
/// 결제 자체는 Toss 클라이언트 SDK 가 처리하고, 성공/실패 시 webview 안의
/// JS 가 `TossBridge.postMessage(...)` 로 결과를 Flutter 에 넘긴다.
/// Flutter 는 paymentKey 를 받아서 백엔드 `/businesses/:id/subscribe` 로 보내
/// 서버에서 최종 결제 승인(`confirmPayment`)을 수행한다.
class TossPaymentScreen extends StatefulWidget {
  final String orderId;
  final String orderName;
  final int amount;
  final String customerName;
  final String customerEmail;

  const TossPaymentScreen({
    super.key,
    required this.orderId,
    required this.orderName,
    required this.amount,
    required this.customerName,
    required this.customerEmail,
  });

  @override
  State<TossPaymentScreen> createState() => _TossPaymentScreenState();
}

class _TossPaymentScreenState extends State<TossPaymentScreen> {
  late final WebViewController _controller;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'TossBridge',
        onMessageReceived: _onBridgeMessage,
      )
      ..loadHtmlString(_buildPaymentHtml());
  }

  void _onBridgeMessage(JavaScriptMessage message) {
    if (_resolved) return;
    try {
      final payload = jsonDecode(message.message) as Map<String, dynamic>;
      final type = payload['type'] as String?;
      if (type == 'success') {
        _resolved = true;
        Navigator.of(context).pop(
          TossPaymentResult.success(
            paymentKey: payload['paymentKey'] as String,
            orderId: payload['orderId'] as String,
            amount: (payload['amount'] as num).toInt(),
          ),
        );
      } else if (type == 'fail') {
        _resolved = true;
        Navigator.of(context).pop(
          TossPaymentResult.failure(
            message: payload['message'] as String? ?? '결제에 실패했습니다.',
            code: payload['code'] as String?,
          ),
        );
      }
    } catch (_) {
      // 메시지 파싱 실패는 무시 — 사용자가 백 버튼으로 취소 가능
    }
  }

  /// Toss Payments 위젯 SDK 를 로드하고 결제를 요청하는 HTML.
  /// successUrl/failUrl 대신 JS bridge 로 결과를 받는다(앱 내 처리).
  String _buildPaymentHtml() {
    final clientKey = EnvironmentConfig.tossClientKey;
    final orderId = _escape(widget.orderId);
    final orderName = _escape(widget.orderName);
    final customerName = _escape(widget.customerName);
    final customerEmail = _escape(widget.customerEmail);
    final amount = widget.amount;

    return '''
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>결제</title>
  <script src="https://js.tosspayments.com/v1/payment"></script>
  <style>
    body { font-family: -apple-system, sans-serif; padding: 24px; color: #1a1a1a; }
    .summary { background: #F5F3FF; padding: 16px; border-radius: 12px; margin-bottom: 24px; }
    .summary h2 { margin: 0 0 8px; font-size: 16px; }
    .summary .amount { font-size: 24px; font-weight: 700; color: #6C5CE7; }
    button {
      width: 100%; padding: 16px; background: #6C5CE7; color: #fff;
      border: none; border-radius: 12px; font-size: 16px; font-weight: 600;
    }
    button:disabled { background: #aaa; }
  </style>
</head>
<body>
  <div class="summary">
    <h2>$orderName</h2>
    <div class="amount">${_format(amount)}원</div>
  </div>
  <button id="pay-btn">결제하기</button>
  <script>
    const tossPayments = TossPayments('$clientKey');
    const payBtn = document.getElementById('pay-btn');
    payBtn.addEventListener('click', function() {
      payBtn.disabled = true;
      tossPayments.requestPayment('카드', {
        amount: $amount,
        orderId: '$orderId',
        orderName: '$orderName',
        customerName: '$customerName',
        customerEmail: '$customerEmail',
        successUrl: location.href,
        failUrl: location.href,
      }).then(function() {
        // 정상 흐름에선 successUrl 로 리다이렉트되므로 여기 도달하지 않음.
      }).catch(function(err) {
        TossBridge.postMessage(JSON.stringify({
          type: 'fail',
          code: err.code || 'UNKNOWN',
          message: err.message || '결제가 취소되었습니다',
        }));
      });
    });

    // 결제창 성공 리다이렉트(successUrl)에서 paymentKey, orderId, amount 쿼리가 붙어 돌아옴
    (function() {
      const params = new URLSearchParams(location.search);
      const paymentKey = params.get('paymentKey');
      const orderId = params.get('orderId');
      const amount = params.get('amount');
      if (paymentKey && orderId && amount) {
        TossBridge.postMessage(JSON.stringify({
          type: 'success',
          paymentKey: paymentKey,
          orderId: orderId,
          amount: Number(amount),
        }));
      }
      const code = params.get('code');
      const message = params.get('message');
      if (code) {
        TossBridge.postMessage(JSON.stringify({
          type: 'fail',
          code: code,
          message: message || '결제에 실패했습니다',
        }));
      }
    })();
  </script>
</body>
</html>
''';
  }

  static String _escape(String s) =>
      s.replaceAll('\\', '\\\\').replaceAll("'", "\\'");

  static String _format(int n) =>
      n.toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('결제', style: HwahaeTypography.titleMedium),
        backgroundColor: Colors.white,
        foregroundColor: HwahaeColors.textPrimary,
        elevation: 0,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
