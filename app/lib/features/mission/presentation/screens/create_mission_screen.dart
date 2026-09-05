import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';
import '../../data/repositories/mission_repository.dart';

/// 미션 등록 화면 (사장님)
/// 핵심: 보상 방식(현금 정산 / 무료체험) 선택
class CreateMissionScreen extends ConsumerStatefulWidget {
  const CreateMissionScreen({super.key});

  @override
  ConsumerState<CreateMissionScreen> createState() =>
      _CreateMissionScreenState();
}

class _CreateMissionScreenState extends ConsumerState<CreateMissionScreen> {
  final _repo = MissionRepository();

  static const List<(String, String, IconData)> _missionTypes = [
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
    setState(() => _loadingBusiness = true);
    final id = await _repo.getMyBusinessId();
    if (!mounted) return;
    setState(() {
      _businessId = id;
      _loadingBusiness = false;
      _loadError =
          id == null ? '등록된 업체가 없습니다. 먼저 업체 정보를 등록해주세요.' : null;
    });
  }

  bool get _isFreeExperience => _rewardType == 'free_experience';

  Future<void> _submit() async {
    final businessId = _businessId;
    if (businessId == null) return;

    // 검증
    if (_isFreeExperience) {
      if (_experienceDescController.text.trim().isEmpty) {
        AppToast.warning(context, '무료체험 제공 내용을 입력해주세요.');
        return;
      }
    } else {
      final fee = int.tryParse(_reviewerFeeController.text.trim()) ?? 0;
      if (fee <= 0) {
        AppToast.warning(context, '리뷰어 보상금을 입력해주세요.');
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
      AppToast.success(context, result.message ?? '미션이 등록되었습니다.');
      context.pop();
    } else {
      AppToast.error(context, result.message ?? '미션 등록에 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingBusiness) {
      return const AppScreen(
        title: '미션 등록',
        child: Padding(
          padding: EdgeInsets.only(top: 120),
          child: Center(
            child: CircularProgressIndicator(color: HwahaeColors.primary),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return AppScreen(
        title: '미션 등록',
        child: AppEmptyState(
          icon: Icons.storefront_outlined,
          title: '등록된 업체가 없네',
          message: _loadError,
          actionLabel: '다시 확인',
          onAction: _loadBusiness,
        ),
      );
    }

    return AppScreen(
      title: '미션 등록',
      bottomBar: AppBottomActionBar(
        info: Text(
          _isFreeExperience
              ? '무료체험 미션은 구독에 포함되어 결제 없이 바로 모집됩니다.'
              : '등록 후 보상금 결제를 진행합니다.',
          style: HwahaeTypography.captionMedium.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
        child: AppButton(
          label: _isFreeExperience ? '무료체험 미션 등록' : '미션 등록하고 결제',
          size: AppButtonSize.large,
          isLoading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          AppSection(
            title: '미션 유형',
            topGap: 0,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (value, label, icon) in _missionTypes)
                  AppChip(
                    label: label,
                    icon: icon,
                    selected: _missionType == value,
                    onTap: () => setState(() => _missionType = value),
                  ),
              ],
            ),
          ),
          AppSection(
            title: '보상 방식',
            child: Column(
              children: [
                _RewardOption(
                  selected: _isFreeExperience,
                  emoji: '🎁',
                  title: '무료체험 제공',
                  description: '현금 대신 가게 메뉴·서비스를 무료로 제공합니다. '
                      '결제 없이 바로 모집되며 구독에 포함됩니다.',
                  onTap: () =>
                      setState(() => _rewardType = 'free_experience'),
                ),
                const SizedBox(height: 10),
                _RewardOption(
                  selected: !_isFreeExperience,
                  emoji: '💳',
                  title: '현금 보상',
                  description: '리뷰어에게 현금을 지급합니다. 등록 후 결제가 필요합니다.',
                  onTap: () => setState(() => _rewardType = 'cash'),
                ),
              ],
            ),
          ),
          if (_isFreeExperience) ...[
            AppSection(
              title: '제공 내용',
              child: AppTextField(
                controller: _experienceDescController,
                maxLength: 100,
                hint: '예: 아메리카노 1잔 무료, 시그니처 디저트 1개',
              ),
            ),
            AppSection(
              title: '추정 가치',
              subtitle: '선택',
              topGap: 12,
              child: AppTextField.number(
                controller: _experienceValueController,
                hint: '5000',
                suffixText: '원',
              ),
            ),
          ] else ...[
            AppSection(
              title: '리뷰어 보상금',
              child: AppTextField.number(
                controller: _reviewerFeeController,
                hint: '10000',
                suffixText: '원',
              ),
            ),
            AppSection(
              title: '제품·서비스 비용',
              subtitle: '선택',
              topGap: 12,
              child: AppTextField.number(
                controller: _productCostController,
                hint: '0',
                suffixText: '원',
              ),
            ),
          ],
          AppSection(
            title: '최대 신청자 수',
            child: AppTextField.number(
              controller: _maxApplicantsController,
              hint: '20',
              suffixText: '명',
            ),
          ),
          const AppBottomSpacer.plain(),
        ],
      ),
    );
  }
}

class _RewardOption extends StatelessWidget {
  const _RewardOption({
    required this.selected,
    required this.emoji,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final bool selected;
  final String emoji;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: AppCard(
        style: AppCardStyle.outlined,
        onTap: onTap,
        borderColor: selected ? HwahaeColors.primary : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color:
                  selected ? HwahaeColors.primaryDark : HwahaeColors.textTertiary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$emoji $title',
                    style: HwahaeTypography.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: HwahaeTypography.captionLarge.copyWith(
                      color: HwahaeColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
