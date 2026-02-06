import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final receiptVerificationProvider =
    StateNotifierProvider<ReceiptVerificationNotifier, ReceiptVerificationState>(
        (ref) => ReceiptVerificationNotifier());

class ReceiptVerificationState {
  final bool isVerifying;
  final bool isVerified;
  final bool hasError;
  final bool isManualReview;
  final String? errorMessage;
  final Uint8List? imageBytes;
  final String? receiptId;
  final DateTime? receiptDate;
  final int? receiptAmount;
  final String? storeName;

  ReceiptVerificationState({
    this.isVerifying = false,
    this.isVerified = false,
    this.hasError = false,
    this.isManualReview = false,
    this.errorMessage,
    this.imageBytes,
    this.receiptId,
    this.receiptDate,
    this.receiptAmount,
    this.storeName,
  });

  ReceiptVerificationState copyWith({
    bool? isVerifying,
    bool? isVerified,
    bool? hasError,
    bool? isManualReview,
    String? errorMessage,
    Uint8List? imageBytes,
    String? receiptId,
    DateTime? receiptDate,
    int? receiptAmount,
    String? storeName,
  }) {
    return ReceiptVerificationState(
      isVerifying: isVerifying ?? this.isVerifying,
      isVerified: isVerified ?? this.isVerified,
      hasError: hasError ?? this.hasError,
      isManualReview: isManualReview ?? this.isManualReview,
      errorMessage: errorMessage ?? this.errorMessage,
      imageBytes: imageBytes ?? this.imageBytes,
      receiptId: receiptId ?? this.receiptId,
      receiptDate: receiptDate ?? this.receiptDate,
      receiptAmount: receiptAmount ?? this.receiptAmount,
      storeName: storeName ?? this.storeName,
    );
  }
}

class ReceiptVerificationNotifier extends StateNotifier<ReceiptVerificationState> {
  ReceiptVerificationNotifier() : super(ReceiptVerificationState());

  void setImage(Uint8List bytes) {
    state = state.copyWith(imageBytes: bytes);
  }

  Future<void> verifyReceipt(String reviewId) async {
    if (state.imageBytes == null) {
      state = state.copyWith(
        hasError: true,
        errorMessage: '영수증 이미지를 선택해주세요',
      );
      return;
    }

    state = state.copyWith(isVerifying: true, hasError: false, errorMessage: null);

    try {
      final apiClient = ApiClient();
      final imageBase64 = base64Encode(state.imageBytes!);

      final response = await apiClient.post(
        '/reviews/$reviewId/evidence/receipt',
        data: {'imageBase64': imageBase64},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final ocrData = response.data['data']?['ocr'];

        if (ocrData != null) {
          state = state.copyWith(
            isVerifying: false,
            isVerified: true,
            storeName: ocrData['storeName'],
            receiptAmount: ocrData['amount'],
            receiptDate: ocrData['date'] != null
                ? DateTime.tryParse(ocrData['date'])
                : null,
          );
        } else {
          // OCR 실패 - 수동 검토 상태
          state = state.copyWith(
            isVerifying: false,
            isVerified: false,
            isManualReview: true,
          );
        }
      } else {
        state = state.copyWith(
          isVerifying: false,
          hasError: true,
          errorMessage: response.data['message'] ?? '영수증 검증에 실패했습니다',
        );
      }
    } catch (e) {
      // API 실패 - 수동 검토 요청 상태로 전환
      state = state.copyWith(
        isVerifying: false,
        isManualReview: true,
        errorMessage: '자동 검증에 실패했습니다. 수동 검토가 요청됩니다.',
      );
    }
  }

  Future<void> registerReceiptUsage(String missionId) async {
    try {
      final apiClient = ApiClient();
      await apiClient.post('/reviews/$missionId/receipt-usage');
    } catch (_) {}
  }

  void reset() {
    state = ReceiptVerificationState();
  }
}
