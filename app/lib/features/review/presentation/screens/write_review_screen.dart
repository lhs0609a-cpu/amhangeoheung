import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../../../shared/widgets/hwahae/hwahae_buttons.dart';
import '../../../mission/providers/mission_provider.dart';
import '../../providers/receipt_provider.dart';
import '../../providers/review_provider.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  final String missionId;

  const WriteReviewScreen({super.key, required this.missionId});

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reviewController = TextEditingController();
  final _consController = TextEditingController();
  final _imagePicker = ImagePicker();

  Map<String, int> _scores = {
    '대기 시간': 0,
    '서비스 품질': 0,
    '청결도': 0,
    '직원 응대': 0,
    '가성비': 0,
  };

  List<XFile> _photos = [];
  XFile? _receiptImage;
  bool _isSubmitting = false;
  bool _isLoadingMission = true;
  String? _missionError;

  // 미션 데이터
  String _businessName = '';
  String _businessCategory = '';
  String _businessAddress = '';
  DateTime _missionDate = DateTime.now();
  String _missionStatus = '';

  @override
  void initState() {
    super.initState();
    _loadMissionData();
  }

  Future<void> _loadMissionData() async {
    setState(() {
      _isLoadingMission = true;
      _missionError = null;
    });

    try {
      final missionDetail = await ref.read(
        missionDetailProvider(widget.missionId).future,
      );

      if (missionDetail.success && missionDetail.mission != null) {
        final mission = missionDetail.mission!;
        setState(() {
          _businessName = mission.businessName ?? '업체명 없음';
          _businessCategory = mission.category ?? '';
          _businessAddress = mission.region ?? '';
          _missionDate = mission.assignedAt ?? DateTime.now();
          _missionStatus = mission.status ?? '';
          _isLoadingMission = false;
        });
      } else {
        setState(() {
          _missionError = missionDetail.message ?? '미션 정보를 불러올 수 없습니다.';
          _isLoadingMission = false;
        });
      }
    } catch (e) {
      setState(() {
        _missionError = '미션 정보를 불러오는 중 오류가 발생했습니다.';
        _isLoadingMission = false;
      });
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _consController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final receiptState = ref.watch(receiptVerificationProvider);

    // 미션 데이터 로딩 중
    if (_isLoadingMission) {
      return Scaffold(
        backgroundColor: HwahaeColors.background,
        appBar: AppBar(
          backgroundColor: HwahaeColors.surface,
          title: Text('리뷰 작성', style: HwahaeTypography.titleMedium),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: HwahaeColors.primary),
        ),
      );
    }

    // 미션 데이터 로딩 실패
    if (_missionError != null) {
      return Scaffold(
        backgroundColor: HwahaeColors.background,
        appBar: AppBar(
          backgroundColor: HwahaeColors.surface,
          title: Text('리뷰 작성', style: HwahaeTypography.titleMedium),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: HwahaeColors.error),
              const SizedBox(height: 16),
              Text(_missionError!, style: HwahaeTypography.bodyMedium),
              const SizedBox(height: 24),
              HwahaePrimaryButton(
                text: '다시 시도',
                onPressed: _loadMissionData,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text(
          '리뷰 작성',
          style: HwahaeTypography.titleMedium,
        ),
        actions: [
          TextButton(
            onPressed: _saveDraft,
            child: Text(
              '임시저장',
              style: HwahaeTypography.labelMedium.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 업체 정보
            _buildBusinessInfo(),
            const SizedBox(height: 24),

            // 항목별 평가
            _buildSectionTitle('항목별 평가', '각 항목을 1~5점으로 평가해주세요'),
            const SizedBox(height: 16),
            ..._scores.keys.map((key) => _buildScoreItem(key)),
            const SizedBox(height: 24),

            // 상세 리뷰
            _buildSectionTitle('상세 리뷰', '최소 100자 이상 작성해주세요'),
            const SizedBox(height: 12),
            _buildReviewTextField(),
            const SizedBox(height: 24),

            // 개선이 필요한 점
            _buildSectionTitle(
              '개선이 필요한 점',
              '솔직한 피드백은 업체 개선에 도움이 됩니다',
              isRequired: true,
            ),
            const SizedBox(height: 12),
            _buildConsTextField(),
            const SizedBox(height: 24),

            // 사진 첨부
            _buildSectionTitle(
              '사진 첨부',
              '최소 3장 이상 첨부해주세요 (음식, 매장 내부 등)',
            ),
            const SizedBox(height: 12),
            _buildPhotoSection(),
            const SizedBox(height: 24),

            // 영수증 첨부 (중복 검사 포함)
            _buildSectionTitle(
              '영수증 첨부',
              '결제 영수증을 촬영해주세요 (필수)',
              isRequired: true,
            ),
            const SizedBox(height: 12),
            _buildReceiptSection(receiptState),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  Widget _buildBusinessInfo() {
    // 미션 상태에 따른 배지 색상 및 텍스트
    Color statusColor;
    String statusText;
    switch (_missionStatus) {
      case 'in_progress':
        statusColor = HwahaeColors.success;
        statusText = '미션 진행중';
        break;
      case 'assigned':
        statusColor = HwahaeColors.info;
        statusText = '미션 배정됨';
        break;
      case 'review_submitted':
        statusColor = HwahaeColors.warning;
        statusText = '리뷰 제출됨';
        break;
      default:
        statusColor = HwahaeColors.textSecondary;
        statusText = '미션';
    }

    // 카테고리에 따른 아이콘
    IconData categoryIcon;
    switch (_businessCategory.toLowerCase()) {
      case '음식점':
      case '한식':
      case '일식':
      case '중식':
      case '양식':
        categoryIcon = Icons.restaurant;
        break;
      case '카페':
        categoryIcon = Icons.coffee;
        break;
      case '뷰티':
      case '미용':
        categoryIcon = Icons.spa;
        break;
      case '숙박':
        categoryIcon = Icons.hotel;
        break;
      default:
        categoryIcon = Icons.store;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
        border: Border.all(color: HwahaeColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: HwahaeColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              categoryIcon,
              color: HwahaeColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _businessName,
                  style: HwahaeTypography.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_businessAddress.isNotEmpty ? _businessAddress : '주소 없음'} • ${_businessCategory.isNotEmpty ? _businessCategory : '카테고리 없음'}',
                  style: HwahaeTypography.captionLarge,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: HwahaeTypography.labelSmall.copyWith(
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle, {bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: HwahaeTypography.titleSmall),
            if (isRequired) ...[
              const SizedBox(width: 8),
              Text(
                '(필수)',
                style: HwahaeTypography.labelSmall.copyWith(
                  color: HwahaeColors.error,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: HwahaeTypography.captionLarge,
        ),
      ],
    );
  }

  Widget _buildScoreItem(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: HwahaeTypography.bodyMedium,
            ),
          ),
          Expanded(
            child: Row(
              children: List.generate(5, (index) {
                final score = index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _scores[label] = score;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      score <= (_scores[label] ?? 0)
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: score <= (_scores[label] ?? 0)
                          ? HwahaeColors.warning
                          : HwahaeColors.border,
                      size: 32,
                    ),
                  ),
                );
              }),
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: (_scores[label] ?? 0) > 0
                  ? HwahaeColors.primaryContainer
                  : HwahaeColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${_scores[label] ?? 0}',
                style: HwahaeTypography.labelLarge.copyWith(
                  color: (_scores[label] ?? 0) > 0
                      ? HwahaeColors.primary
                      : HwahaeColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTextField() {
    return TextFormField(
      controller: _reviewController,
      maxLines: 6,
      style: HwahaeTypography.bodyMedium,
      decoration: InputDecoration(
        hintText: '방문 경험을 상세히 작성해주세요...\n\n- 주문한 메뉴와 맛 평가\n- 매장 분위기와 청결 상태\n- 서비스 품질과 특이사항',
        hintStyle: HwahaeTypography.bodyMedium.copyWith(
          color: HwahaeColors.textTertiary,
        ),
        filled: true,
        fillColor: HwahaeColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          borderSide: const BorderSide(color: HwahaeColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          borderSide: const BorderSide(color: HwahaeColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          borderSide: const BorderSide(color: HwahaeColors.primary, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.length < 100) {
          return '리뷰는 100자 이상 작성해주세요 (현재 ${value?.length ?? 0}자)';
        }
        return null;
      },
    );
  }

  Widget _buildConsTextField() {
    return TextFormField(
      controller: _consController,
      maxLines: 3,
      style: HwahaeTypography.bodyMedium,
      decoration: InputDecoration(
        hintText: '개선이 필요한 점을 작성해주세요...',
        hintStyle: HwahaeTypography.bodyMedium.copyWith(
          color: HwahaeColors.textTertiary,
        ),
        filled: true,
        fillColor: HwahaeColors.errorLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          borderSide: const BorderSide(color: HwahaeColors.error),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          borderSide: BorderSide(color: HwahaeColors.error.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          borderSide: const BorderSide(color: HwahaeColors.error, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '개선점을 최소 1개 이상 작성해주세요';
        }
        return null;
      },
    );
  }

  Widget _buildPhotoSection() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 사진 추가 버튼
          _buildAddPhotoButton(),
          // 추가된 사진들
          ..._photos.asMap().entries.map((entry) {
            return _buildPhotoItem(entry.key, entry.value);
          }),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _pickPhotos,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: HwahaeColors.surfaceVariant,
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          border: Border.all(color: HwahaeColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate,
              color: HwahaeColors.primary,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              '${_photos.length}/10',
              style: HwahaeTypography.captionMedium.copyWith(
                color: HwahaeColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoItem(int index, XFile photo) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
            child: Image.file(
              File(photo.path),
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _photos.removeAt(index);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptSection(ReceiptVerificationState receiptState) {
    return Column(
      children: [
        // 영수증 업로드 영역
        GestureDetector(
          onTap: _pickReceipt,
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: HwahaeColors.surface,
              borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
              border: Border.all(
                color: receiptState.isVerified
                    ? HwahaeColors.success
                    : receiptState.isDuplicate
                        ? HwahaeColors.error
                        : HwahaeColors.border,
                width: receiptState.isVerified || receiptState.isDuplicate ? 2 : 1,
              ),
            ),
            child: _receiptImage == null
                ? _buildReceiptPlaceholder()
                : _buildReceiptPreview(receiptState),
          ),
        ),

        // 검증 상태 표시
        if (receiptState.isLoading) ...[
          const SizedBox(height: 12),
          _buildVerifyingIndicator(),
        ] else if (receiptState.isVerified) ...[
          const SizedBox(height: 12),
          _buildVerifiedBadge(receiptState),
        ] else if (receiptState.isDuplicate) ...[
          const SizedBox(height: 12),
          _buildDuplicateWarning(),
        ] else if (receiptState.errorMessage != null) ...[
          const SizedBox(height: 12),
          _buildErrorMessage(receiptState.errorMessage!),
        ],

        // 안내 문구
        const SizedBox(height: 12),
        _buildReceiptGuidelines(),
      ],
    );
  }

  Widget _buildReceiptPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            color: HwahaeColors.primary,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            '영수증 촬영하기',
            style: TextStyle(
              color: HwahaeColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '업체명, 날짜, 금액이 보이도록 촬영해주세요',
            style: TextStyle(
              color: HwahaeColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptPreview(ReceiptVerificationState state) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD - 1),
          child: Image.file(
            File(_receiptImage!.path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        // 상태 오버레이
        if (state.isVerified)
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: HwahaeColors.success.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '검증 완료',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // 다시 촬영 버튼
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _pickReceipt,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text(
                    '다시 촬영',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.infoLight,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusSM),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: HwahaeColors.info,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '영수증 검증 중...',
                  style: HwahaeTypography.labelMedium.copyWith(
                    color: HwahaeColors.info,
                  ),
                ),
                Text(
                  'OCR 분석 및 중복 여부를 확인하고 있습니다',
                  style: HwahaeTypography.captionMedium.copyWith(
                    color: HwahaeColors.info,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedBadge(ReceiptVerificationState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.successLight,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusSM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: HwahaeColors.success),
              const SizedBox(width: 8),
              Text(
                '영수증 검증 완료',
                style: HwahaeTypography.labelLarge.copyWith(
                  color: HwahaeColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (state.receiptData != null) ...[
            const SizedBox(height: 12),
            _buildReceiptDataRow('업체명', state.receiptData!.businessName ?? '-'),
            _buildReceiptDataRow(
              '결제일',
              state.receiptData!.transactionDate != null
                  ? '${state.receiptData!.transactionDate!.year}.${state.receiptData!.transactionDate!.month}.${state.receiptData!.transactionDate!.day}'
                  : '-',
            ),
            _buildReceiptDataRow(
              '금액',
              state.receiptData!.totalAmount != null
                  ? '${_formatCurrency(state.receiptData!.totalAmount!)}원'
                  : '-',
            ),
          ],
          if (state.hasWarnings) ...[
            const SizedBox(height: 8),
            ...state.warnings.map((w) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: HwahaeColors.warning,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        w,
                        style: HwahaeTypography.captionMedium.copyWith(
                          color: HwahaeColors.warning,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiptDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: HwahaeTypography.captionLarge.copyWith(
                color: HwahaeColors.success,
              ),
            ),
          ),
          Text(
            value,
            style: HwahaeTypography.bodyMedium.copyWith(
              color: HwahaeColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuplicateWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.errorLight,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusSM),
        border: Border.all(color: HwahaeColors.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: HwahaeColors.error),
              const SizedBox(width: 8),
              Text(
                '중복 영수증 감지',
                style: HwahaeTypography.labelLarge.copyWith(
                  color: HwahaeColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '이 영수증은 이미 다른 리뷰에 사용되었습니다.\n새로운 영수증을 업로드해주세요.',
            style: HwahaeTypography.bodySmall.copyWith(
              color: HwahaeColors.error,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: HwahaeColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.security, color: HwahaeColors.error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '중복 사용 시도는 기록되며, 반복 시 계정이 제한됩니다.',
                    style: HwahaeTypography.captionMedium.copyWith(
                      color: HwahaeColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.warningLight,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusSM),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: HwahaeColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: HwahaeTypography.bodySmall.copyWith(
                color: HwahaeColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptGuidelines() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HwahaeColors.surfaceVariant,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusSM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '영수증 촬영 가이드',
            style: HwahaeTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildGuidelineItem(Icons.store, '업체명이 명확히 보여야 합니다'),
          _buildGuidelineItem(Icons.calendar_today, '결제 날짜가 미션 기간 내여야 합니다'),
          _buildGuidelineItem(Icons.attach_money, '결제 금액이 보여야 합니다'),
          _buildGuidelineItem(Icons.wb_sunny, '밝은 곳에서 선명하게 촬영해주세요'),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: HwahaeColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            text,
            style: HwahaeTypography.captionLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final receiptState = ref.watch(receiptVerificationProvider);
    final canSubmit = receiptState.isVerified && !_isSubmitting;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!receiptState.isVerified && _receiptImage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '영수증 검증을 완료해주세요',
                  style: HwahaeTypography.captionLarge.copyWith(
                    color: HwahaeColors.error,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: HwahaePrimaryButton(
                text: _isSubmitting ? '제출 중...' : '리뷰 제출하기',
                onPressed: canSubmit ? _submitReview : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhotos() async {
    final List<XFile> images = await _imagePicker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (images.isNotEmpty) {
      setState(() {
        _photos.addAll(images.take(10 - _photos.length));
      });
    }
  }

  Future<void> _pickReceipt() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 90,
    );

    if (image != null) {
      setState(() {
        _receiptImage = image;
      });

      // 영수증 검증 시작
      final bytes = await File(image.path).readAsBytes();
      ref.read(receiptVerificationProvider.notifier).setImage(bytes);
      ref.read(receiptVerificationProvider.notifier).verifyReceipt(
            expectedBusinessName: _businessName,
            missionDate: _missionDate,
          );
    }
  }

  String? _draftReviewId;
  bool _isSavingDraft = false;

  Future<void> _saveDraft() async {
    if (_isSavingDraft) return;

    setState(() {
      _isSavingDraft = true;
    });

    try {
      final repository = ref.read(reviewRepositoryProvider);
      final response = await repository.saveDraft(
        missionId: widget.missionId,
        reviewId: _draftReviewId,
        scores: _scores.isNotEmpty ? _scores : null,
        pros: _reviewController.text.isNotEmpty ? [_reviewController.text] : null,
        cons: _consController.text.isNotEmpty ? [_consController.text] : null,
        detailedReview: _reviewController.text.isNotEmpty ? _reviewController.text : null,
      );

      if (response.success && response.review != null) {
        _draftReviewId = response.review!.id;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('임시 저장되었습니다'),
              backgroundColor: HwahaeColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? '임시 저장에 실패했습니다'),
              backgroundColor: HwahaeColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('임시 저장 중 오류: $e'),
            backgroundColor: HwahaeColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingDraft = false;
        });
      }
    }
  }

  Future<void> _submitReview() async {
    // 점수 체크
    final hasAllScores = _scores.values.every((score) => score > 0);
    if (!hasAllScores) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('모든 항목을 평가해주세요'),
          backgroundColor: HwahaeColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // 사진 체크
    if (_photos.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('사진을 3장 이상 첨부해주세요'),
          backgroundColor: HwahaeColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    // 영수증 체크
    final receiptState = ref.read(receiptVerificationProvider);
    if (!receiptState.isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('영수증 검증을 완료해주세요'),
          backgroundColor: HwahaeColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    // 제출 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('리뷰 제출', style: HwahaeTypography.headlineSmall),
        content: Text(
          '리뷰를 제출하시겠습니까?\n\n'
          '제출 후에는 수정이 불가능합니다.\n'
          '리뷰는 검토 후 업체에 선공개됩니다.',
          style: HwahaeTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '취소',
              style: HwahaeTypography.labelLarge.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '제출하기',
              style: HwahaeTypography.labelLarge.copyWith(
                color: HwahaeColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(reviewRepositoryProvider);

      // 1. 리뷰 초안이 없으면 먼저 생성
      if (_draftReviewId == null) {
        final createResponse = await repository.createReview(
          missionId: widget.missionId,
          scores: _scores,
          pros: [_reviewController.text],
          cons: [_consController.text],
          summary: _reviewController.text.length > 100
              ? _reviewController.text.substring(0, 100)
              : _reviewController.text,
        );

        if (!createResponse.success || createResponse.review == null) {
          throw Exception(createResponse.message ?? '리뷰 생성에 실패했습니다.');
        }

        _draftReviewId = createResponse.review!.id;
      }

      // 2. 사진 업로드
      if (_photos.isNotEmpty) {
        final photoData = _photos.map((photo) => {
          'url': photo.path, // 실제로는 Storage에 업로드 후 URL
          'caption': '',
        }).toList();

        await repository.uploadPhotos(
          reviewId: _draftReviewId!,
          photos: photoData,
        );
      }

      // 3. 영수증 사용 등록
      await ref.read(receiptVerificationProvider.notifier).registerReceiptUsage(
            'review_${widget.missionId}_${DateTime.now().millisecondsSinceEpoch}',
          );

      // 4. 영수증 업로드
      if (_receiptImage != null) {
        final receiptState = ref.read(receiptVerificationProvider);
        await repository.uploadReceipt(
          reviewId: _draftReviewId!,
          imageUrl: _receiptImage!.path,
          ocrData: receiptState.receiptData?.toJson(),
        );
      }

      // 5. 리뷰 제출 (draft → submitted)
      final submitResponse = await repository.submitReview(_draftReviewId!);

      if (!submitResponse.success) {
        throw Exception(submitResponse.message ?? '리뷰 제출에 실패했습니다.');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('리뷰가 제출되었습니다! 검토 후 업체에 선공개됩니다.'),
            backgroundColor: HwahaeColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        context.go('/missions');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('제출 중 오류가 발생했습니다: $e'),
            backgroundColor: HwahaeColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
