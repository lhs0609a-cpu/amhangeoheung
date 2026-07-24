import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../data/repositories/mission_repository.dart';

/// 미션 등록 화면 (사장님)
/// 핵심: 보상 방식(현금 정산 / 무료체험) 선택
class CreateMissionScreen extends ConsumerStatefulWidget {
  const CreateMissionScreen({super.key});

  @override
  ConsumerState<CreateMissionScreen> createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends ConsumerState<CreateMissionScreen> {
  final _repo = MissionRepository();

  // 미션 유형
  static final List<(String, String, IconData)> _missionTypes = [
    ('visit', '방문', Icons.store_mall_directory_outlined),
    ('delivery', '배달', Icons.local_shipping_outlined),
    ('online', '온라인', Icons.language_outlined),
    ('phone', '전화', Icons.phone_outlined),
  ];
  String _missionType = 'visit';

  // 보상 방식
  String _rewardType = 'free_experience';

  final _reviewerFeeController = TextEditingController();
  final _productCostController = TextEditingController();
  final _experienceDescController = TextEditingController();
  final _experienceValueController = TextEditingController();
  final _maxApplicantsController = TextEditingController(text: '20');

  String? _businessId;
  bool _loadingBusiness = true;
  bool _submitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  @override
  void dispose() {
    _reviewerFeeController.dispose();
    _productCostController.dispose();
    _experienceDescController.dispose();
    _experienceValueController.dispose();
    _maxApplicantsController.dispose();
    super.dispose();
  }

  Future<void> _loadBusiness() async {
    final id = await _repo.getMyBusinessId();
    if (!mounted) return;
    setState(() {
      _businessId = id;
      _loadingBusiness = false;
      _loadError = id == null ? '등록된 업체가 없습니다. 먼저 업체 정보를 등록해주세요.' : null;
    });
  }

  bool get _isFreeExperience => _rewardType == 'free_experience';

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final businessId = _businessId;
    if (businessId == null) return;

    // 검증
    if (_isFreeExperience) {
      if (_experienceDescController.text.trim().isEmpty) {
        messenger.showSnackBar(const SnackBar(content: Text('무료체험 제공 내용을 입력해주세요.')));
        return;
      }
    } else {
      final fee = int.tryParse(_reviewerFeeController.text.trim()) ?? 0;
      if (fee <= 0) {
        messenger.showSnackBar(const SnackBar(content: Text('리뷰어 보상금을 입력해주세요.')));
        return;
      }
    }

    setState(() => _submitting = true);

    final result = await _repo.createMission(
      businessId: businessId,
      missionType: _missionType,
      rewardType: _rewardType,
      reviewerFee: int.tryParse(_reviewerFeeController.text.trim()) ?? 0,
      productCost: int.tryParse(_productCostController.text.trim()) ?? 0,
      experienceDescription: _experienceDescController.text.trim(),
      experienceValue: int.tryParse(_experienceValueController.text.trim()),
      maxApplicants: int.tryParse(_maxApplicantsController.text.trim()),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      messenger.showSnackBar(SnackBar(
        content: Text(result.message ?? '미션이 등록되었습니다.'),
        backgroundColor: HwahaeColors.success,
      ));
      context.pop();
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(result.message ?? '미션 등록에 실패했습니다.'),
        backgroundColor: HwahaeColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('미션 등록', style: HwahaeTypography.titleMedium),
      ),
      body: _loadingBusiness
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildErrorState()
              : _buildForm(),
      bottomNavigationBar: (_loadingBusiness || _loadError != null)
          ? null
          : _buildSubmitBar(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_outlined, size: 48, color: HwahaeColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: HwahaeTypography.bodyMedium.copyWith(color: HwahaeColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionLabel('미션 유형'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _missionTypes.map((t) {
            final selected = _missionType == t.$1;
            return ChoiceChip(
              avatar: Icon(t.$3, size: 18,
                  color: selected ? Colors.white : HwahaeColors.textSecondary),
              label: Text(t.$2),
              selected: selected,
              selectedColor: HwahaeColors.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : HwahaeColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => setState(() => _missionType = t.$1),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        _sectionLabel('보상 방식'),
        const SizedBox(height: 8),
        _rewardOption(
          value: 'free_experience',
          title: '🎁 무료체험 제공',
          desc: '현금 대신 가게 메뉴/서비스를 무료 제공. 결제 없이 바로 모집되며 구독에 포함됩니다.',
        ),
        const SizedBox(height: 8),
        _rewardOption(
          value: 'cash',
          title: '💳 현금 보상',
          desc: '리뷰어에게 현금 페이백을 지급합니다. 등록 후 결제가 필요합니다.',
        ),
        const SizedBox(height: 24),

        if (_isFreeExperience) ..._freeExperienceFields() else ..._cashFields(),

        const SizedBox(height: 8),
        _sectionLabel('최대 신청자 수'),
        const SizedBox(height: 8),
        _numberField(_maxApplicantsController, hint: '20', suffix: '명'),
        const SizedBox(height: 24),
      ],
    );
  }

  List<Widget> _freeExperienceFields() {
    return [
      _sectionLabel('제공 내용'),
      const SizedBox(height: 8),
      TextField(
        controller: _experienceDescController,
        maxLength: 100,
        decoration: _inputDecoration('예: 아메리카노 1잔 무료, 시그니처 디저트 1개'),
      ),
      const SizedBox(height: 12),
      _sectionLabel('추정 가치 (선택)'),
      const SizedBox(height: 8),
      _numberField(_experienceValueController, hint: '5000', suffix: '원'),
    ];
  }

  List<Widget> _cashFields() {
    return [
      _sectionLabel('리뷰어 보상금'),
      const SizedBox(height: 8),
      _numberField(_reviewerFeeController, hint: '10000', suffix: '원'),
      const SizedBox(height: 12),
      _sectionLabel('제품/서비스 비용 (선택)'),
      const SizedBox(height: 8),
      _numberField(_productCostController, hint: '0', suffix: '원'),
    ];
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: HwahaeTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _rewardOption({
    required String value,
    required String title,
    required String desc,
  }) {
    final selected = _rewardType == value;
    return InkWell(
      onTap: () => setState(() => _rewardType = value),
      borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? HwahaeColors.primary.withOpacity(0.06) : HwahaeColors.surface,
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          border: Border.all(
            color: selected ? HwahaeColors.primary : HwahaeColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? HwahaeColors.primary : HwahaeColors.textTertiary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: HwahaeTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(desc,
                      style: HwahaeTypography.captionLarge
                          .copyWith(color: HwahaeColors.textSecondary, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(TextEditingController controller, {required String hint, String? suffix}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: _inputDecoration(hint).copyWith(suffixText: suffix),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: HwahaeColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
        borderSide: BorderSide(color: HwahaeColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
        borderSide: BorderSide(color: HwahaeColors.border),
      ),
    );
  }

  Widget _buildSubmitBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: HwahaeColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    _isFreeExperience ? '무료체험 미션 등록' : '미션 등록 (결제 진행)',
                    style: HwahaeTypography.bodyMedium
                        .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }
}
