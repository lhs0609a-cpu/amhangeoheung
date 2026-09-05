import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../shared/widgets/ui/ui.dart';

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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(HwahaeColors.background)
      ..addJavaScriptChannel(
        'TossBridge',
        onMessageReceived: _onBridgeMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadHtmlString(_buildPaymentHtml());
  }

  void _onBridgeMessage(JavaScriptMessage message) {
    if (_resolved || !mounted) return;
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
    // JS 안으로 들어가는 값은 jsonEncode 로 감싼다(따옴표 포함). 예전에는
    // 따옴표와 역슬래시만 손으로 escape 했는데, 이름에 줄바꿈이 하나만
    // 들어가도 JS 문자열이 깨져 결제창이 아예 뜨지 않는다.
    final clientKey = jsonEncode(EnvironmentConfig.tossClientKey);
    final orderId = jsonEncode(widget.orderId);
    final orderName = jsonEncode(widget.orderName);
    final customerName = jsonEncode(widget.customerName);
    final customerEmail = jsonEncode(widget.customerEmail);
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
    /* 앱 팔레트와 같은 색을 쓴다. 결제창만 예전 보라색이면 다른 사이트로
       넘어온 것처럼 보이고, 결제 화면에서 그 인상은 그대로 불안이 된다. */
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      margin: 0; padding: 24px;
      color: #3D2E1F; background: #FDF6E9;
    }
    .summary {
      background: #FFFFFF; border: 1px solid #E8D9BC;
      padding: 18px; border-radius: 14px; margin-bottom: 24px;
    }
    .summary h2 { margin: 0 0 8px; font-size: 16px; font-weight: 600; }
    .summary .amount { font-size: 26px; font-weight: 700; color: #8A5A16; }
    button {
      width: 100%; padding: 16px;
      /* 골드 면 위의 흰 글자는 1.86:1 이다. 먹색을 쓴다. */
      background: #F2B33D; color: #3D2E1F;
      border: none; border-radius: 12px; font-size: 16px; font-weight: 700;
    }
    button:disabled { background: #F0E2C6; color: #7A6A55; }
  </style>
</head>
<body>
  <div class="summary">
    <h2>${_escapeHtml(widget.orderName)}</h2>
    <div class="amount">${_format(amount)}원</div>
  </div>
  <button id="pay-btn">결제하기</button>
  <script>
    const tossPayments = TossPayments($clientKey);
    const payBtn = document.getElementById('pay-btn');
    payBtn.addEventListener('click', function() {
      payBtn.disabled = true;
      tossPayments.requestPayment('카드', {
        amount: $amount,
        orderId: $orderId,
        orderName: $orderName,
        customerName: $customerName,
        customerEmail: $customerEmail,
        successUrl: location.href,
        failUrl: location.href,
      }).then(function() {
        // 정상 흐름에선 successUrl 로 리다이렉트되므로 여기 도달하지 않음.
      }).catch(function(err) {
        // 취소하고 다시 시도할 수 있어야 한다. 예전에는 버튼이 비활성인
        // 채로 남아서 뒤로 나갔다 들어오는 수밖에 없었다.
        payBtn.disabled = false;
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

  /// HTML 본문에 넣을 문자열. 태그로 해석될 수 있는 문자를 막는다.
  /// 예전 escape 는 따옴표와 역슬래시만 봤고 `<`, `&` 는 그대로 흘려보냈다.
  static String _escapeHtml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static String _format(int n) =>
      n.toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: '결제',
      scrollable: false,
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
          // 결제창이 뜨기 전 빈 화면에서 "멈췄나?" 싶은 순간을 없앤다.
          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: HwahaeColors.background,
                child: Center(
                  child: CircularProgressIndicator(
                    color: HwahaeColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
