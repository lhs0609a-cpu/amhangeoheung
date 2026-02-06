import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../providers/profile_provider.dart';

class BankAccountScreen extends ConsumerStatefulWidget {
  const BankAccountScreen({super.key});

  @override
  ConsumerState<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends ConsumerState<BankAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _holderController = TextEditingController();
  String? _selectedBank;
  bool _isLoading = false;

  final List<String> _banks = [
    '국민은행',
    '신한은행',
    '우리은행',
    '하나은행',
    'NH농협',
    'IBK기업은행',
    'SC제일은행',
    '씨티은행',
    '카카오뱅크',
    '토스뱅크',
    '케이뱅크',
    '새마을금고',
    '신협',
    '우체국',
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(profileProvider).user;
    _selectedBank = user?.bankName;
    _accountController.text = user?.bankAccount ?? '';
    _holderController.text = user?.bankHolder ?? '';
  }

  @override
  void dispose() {
    _accountController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  Future<void> _saveBankAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('은행을 선택해주세요'),
          backgroundColor: HwahaeColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(profileProvider.notifier).updateBankAccount(
      bankName: _selectedBank!,
      bankAccount: _accountController.text.trim(),
      bankHolder: _holderController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('계좌 정보가 저장되었습니다'),
            backgroundColor: HwahaeColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('저장에 실패했습니다'),
            backgroundColor: HwahaeColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('정산 계좌', style: HwahaeTypography.titleMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 메시지
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HwahaeColors.infoLight,
                  borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: HwahaeColors.info, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '정산금은 등록된 계좌로 입금됩니다.\n본인 명의 계좌만 등록 가능합니다.',
                        style: HwahaeTypography.bodySmall.copyWith(
                          color: HwahaeColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 은행 선택
              Text(
                '은행',
                style: HwahaeTypography.labelMedium.copyWith(
                  color: HwahaeColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: HwahaeColors.surface,
                  borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
                  border: Border.all(color: HwahaeColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedBank,
                    isExpanded: true,
                    hint: Text(
                      '은행을 선택하세요',
                      style: HwahaeTypography.bodyMedium.copyWith(
                        color: HwahaeColors.textTertiary,
                      ),
                    ),
                    items: _banks.map((bank) {
                      return DropdownMenuItem(
                        value: bank,
                        child: Text(bank),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedBank = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 계좌번호
              Text(
                '계좌번호',
                style: HwahaeTypography.labelMedium.copyWith(
                  color: HwahaeColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _accountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '- 없이 숫자만 입력',
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
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '계좌번호를 입력해주세요';
                  }
                  if (value.length < 10) {
                    return '올바른 계좌번호를 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 예금주
              Text(
                '예금주',
                style: HwahaeTypography.labelMedium.copyWith(
                  color: HwahaeColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _holderController,
                decoration: InputDecoration(
                  hintText: '예금주명을 입력하세요',
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
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '예금주명을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // 저장 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveBankAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HwahaeColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('저장하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
