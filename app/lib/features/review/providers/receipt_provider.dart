import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final receiptVerificationProvider =
    StateNotifierProvider<ReceiptVerificationNotifier, ReceiptVerificationState>(
        (ref) => ReceiptVerificationNotifier());

class ReceiptData {
  final String? businessName;
  final DateTime? transactionDate;
  final int? totalAmount;
  final String? receiptNumber;

  ReceiptData({
    this.businessName,
    this.transactionDate,
    this.totalAmount,
    this.receiptNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'transactionDate': transactionDate?.toIso8601String(),
      'totalAmount': totalAmount,
      'receiptNumber': receiptNumber,
    };
  }
}

class ReceiptVerificationState {
  final bool isVerifying;
  final bool isVerified;
  final bool hasError;
  final bool hasWarnings;
  final bool isDuplicate;
  final bool isManualReview;
  final String? errorMessage;
  final Uint8List? imageBytes;
  final String? receiptId;
  final DateTime? receiptDate;
  final int? receiptAmount;
  final String? storeName;
  final ReceiptData? receiptData;
  final List<String> warnings;

  ReceiptVerificationState({
    this.isVerifying = false,
    this.isVerified = false,
    this.hasError = false,
    this.hasWarnings = false,
    this.isDuplicate = false,
    this.isManualReview = false,
    this.errorMessage,
    this.imageBytes,
    this.receiptId,
    this.receiptDate,
    this.receiptAmount,
    this.storeName,
    this.receiptData,
    this.warnings = const [],
  });

  // Alias for isVerifying
  bool get isLoading => isVerifying;

  ReceiptVerificationState copyWith({
    bool? isVerifying,
    bool? isVerified,
    bool? hasError,
    bool? hasWarnings,
    bool? isDuplicate,
    bool? isManualReview,
    String? errorMessage,
    Uint8List? imageBytes,
    String? receiptId,
    DateTime? receiptDate,
    int? receiptAmount,
    String? storeName,
    ReceiptData? receiptData,
    List<String>? warnings,
  }) {
    return ReceiptVerificationState(
      isVerifying: isVerifying ?? this.isVerifying,
      isVerified: isVerified ?? this.isVerified,
      hasError: hasError ?? this.hasError,
      hasWarnings: hasWarnings ?? this.hasWarnings,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      isManualReview: isManualReview ?? this.isManualReview,
      errorMessage: errorMessage ?? this.errorMessage,
      imageBytes: imageBytes ?? this.imageBytes,
      receiptId: receiptId ?? this.receiptId,
      receiptDate: receiptDate ?? this.receiptDate,
      receiptAmount: receiptAmount ?? this.receiptAmount,
      storeName: storeName ?? this.storeName,
      receiptData: receiptData ?? this.receiptData,
      warnings: warnings ?? this.warnings,
    );
  }
}

class ReceiptVerificationNotifier extends StateNotifier<ReceiptVerificationState> {
  ReceiptVerificationNotifier() : super(ReceiptVerificationState());

  void setImage(Uint8List bytes) {
    state = state.copyWith(imageBytes: bytes);
  }

  Future<void> verifyReceipt({
    String? expectedBusinessName,
    DateTime? missionDate,
    String? reviewId,
  }) async {
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
        '/reviews/${reviewId ?? 'verify'}/evidence/receipt',
        data: {'imageBase64': imageBase64},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final ocrData = response.data['data']?['ocr'];

        if (ocrData != null) {
          final storeName = ocrData['storeName'] as String?;
          final amount = ocrData['amount'] as int?;
          final dateStr = ocrData['date'] as String?;
          final parsedDate = dateStr != null ? DateTime.tryParse(dateStr) : null;

          state = state.copyWith(
            isVerifying: false,
            isVerified: true,
            storeName: storeName ?? expectedBusinessName,
            receiptAmount: amount,
            receiptDate: parsedDate ?? missionDate,
            receiptData: ReceiptData(
              businessName: storeName ?? expectedBusinessName,
              transactionDate: parsedDate ?? missionDate,
              totalAmount: amount,
              receiptNumber: 'RCP-${DateTime.now().millisecondsSinceEpoch}',
            ),
          );
        } else {
          // OCR 실패 - 수동 검토
          state = state.copyWith(
            isVerifying: false,
            isVerified: false,
            isManualReview: true,
            errorMessage: '자동 인식에 실패했습니다. 수동 검토가 진행됩니다.',
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
      // API 실패 - 수동 검토 요청
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
