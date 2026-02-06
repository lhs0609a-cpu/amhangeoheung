import 'package:flutter/material.dart';
import 'package:iamport_flutter/iamport_flutter.dart';
import 'package:iamport_flutter/model/payment_data.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../data/models/payment_models.dart';
import '../../data/services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final PaymentRequest request;
  final Function(PaymentResult) onComplete;

  const PaymentScreen({
    super.key,
    required this.request,
    required this.onComplete,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isVerifying = false;

  @override
  Widget build(BuildContext context) {
    if (_isVerifying) {
      return Scaffold(
        backgroundColor: HwahaeColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: HwahaeColors.primary),
              const SizedBox(height: 24),
              Text(
                '결제를 확인하고 있습니다...',
                style: HwahaeTypography.bodyMedium.copyWith(
                  color: HwahaeColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return IamportPayment(
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('결제하기', style: HwahaeTypography.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _handleCancel(),
        ),
      ),
      initialChild: _buildLoadingWidget(),
      userCode: PaymentService.merchantId,
      data: _createPaymentData(),
      callback: _handlePaymentCallback,
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: HwahaeColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: HwahaeColors.gradientPrimary,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.payment,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '결제 페이지를 준비하고 있습니다',
              style: HwahaeTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '잠시만 기다려주세요...',
              style: HwahaeTypography.bodySmall.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: HwahaeColors.primary),
          ],
        ),
      ),
    );
  }

  PaymentData _createPaymentData() {
    final request = widget.request;
    final paymentData = _paymentService.createPaymentData(
      request: request,
      appScheme: 'amhangeoheung',
    );

    return PaymentData(
      pg: paymentData['pg'],
      payMethod: paymentData['pay_method'],
      merchantUid: paymentData['merchant_uid'],
      name: paymentData['name'],
      amount: paymentData['amount'],
      buyerName: paymentData['buyer_name'],
      buyerEmail: paymentData['buyer_email'],
      buyerTel: paymentData['buyer_tel'],
      appScheme: paymentData['app_scheme'],
    );
  }

  Future<void> _handlePaymentCallback(Map<String, String> result) async {
    setState(() => _isVerifying = true);

    // 아임포트 결과 파싱
    final impSuccess = result['imp_success'] == 'true';
    final impUid = result['imp_uid'] ?? '';
    final merchantUid = result['merchant_uid'] ?? '';
    final errorMsg = result['error_msg'];

    if (!impSuccess || impUid.isEmpty) {
      // 결제 실패
      final paymentResult = PaymentResult.failure(
        errorCode: result['error_code'] ?? 'PAYMENT_FAILED',
        errorMessage: errorMsg ?? '결제가 취소되었습니다',
        merchantUid: merchantUid,
      );

      if (mounted) {
        widget.onComplete(paymentResult);
        Navigator.of(context).pop();
      }
      return;
    }

    // 서버에서 결제 검증
    final verifyResult = await _paymentService.verifyPayment(
      impUid: impUid,
      merchantUid: merchantUid,
    );

    if (mounted) {
      widget.onComplete(verifyResult);
      Navigator.of(context).pop();
    }
  }

  void _handleCancel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
        ),
        title: Text('결제 취소', style: HwahaeTypography.headlineSmall),
        content: Text(
          '결제를 취소하시겠습니까?',
          style: HwahaeTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '계속 결제',
              style: HwahaeTypography.labelLarge.copyWith(
                color: HwahaeColors.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫기
              final cancelResult = PaymentResult.failure(
                errorCode: 'USER_CANCEL',
                errorMessage: '사용자가 결제를 취소했습니다',
                merchantUid: widget.request.orderId,
              );
              widget.onComplete(cancelResult);
              Navigator.of(context).pop(); // 결제 화면 닫기
            },
            child: Text(
              '취소',
              style: HwahaeTypography.labelLarge.copyWith(
                color: HwahaeColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 결제 화면 띄우기 헬퍼
Future<PaymentResult?> showPaymentScreen({
  required BuildContext context,
  required PaymentRequest request,
}) async {
  PaymentResult? result;

  await Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => PaymentScreen(
        request: request,
        onComplete: (r) => result = r,
      ),
    ),
  );

  return result;
}
