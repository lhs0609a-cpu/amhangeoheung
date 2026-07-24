import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedUserType = AppConstants.userTypeConsumer;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _agreeToPrivacy = false;
  double _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final savedType = prefs.getString('selected_user_type');
      if (savedType != null && mounted) {
        setState(() {
          _selectedUserType = savedType;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength(String password) {
    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.2;
    setState(() => _passwordStrength = strength.clamp(0.0, 1.0));
  }

  Color _getStrengthColor() {
    if (_passwordStrength < 0.3) return HwahaeColors.error;
    if (_passwordStrength < 0.6) return HwahaeColors.warning;
    if (_passwordStrength < 0.8) return HwahaeColors.info;
    return HwahaeColors.success;
  }

  String _getStrengthLabel() {
    if (_passwordStrength == 0) return '';
    if (_passwordStrength < 0.3) return '약함';
    if (_passwordStrength < 0.6) return '보통';
    if (_passwordStrength < 0.8) return '강함';
    return '매우 강함';
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return '휴대폰 번호를 입력해주세요';
    }
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (!RegExp(r'^01[0-9]{8,9}$').hasMatch(cleaned)) {
      return '올바른 휴대폰 번호 형식이 아닙니다 (예: 010-1234-5678)';
    }
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms || !_agreeToPrivacy) {
      _showError('이용약관과 개인정보처리방침에 모두 동의해주세요');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient().post('/auth/register', data: {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        'password': _passwordController.text,
        'userType': _selectedUserType,
      });

      if (response.data['success']) {
        await ApiClient().setToken(response.data['data']['token']);
        if (mounted) {
          context.go('/verify-email?email=${Uri.encodeComponent(_emailController.text.trim())}');
        }
      } else {
        _showError(response.data['message'] ?? '회원가입에 실패했습니다.');
      }
    } catch (e) {
      _showError('네트워크 오류가 발생했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: HwahaeColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('회원가입', style: HwahaeTypography.titleMedium),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 사용자 유형 선택
                Text(
                  '가입 유형',
                  style: HwahaeTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: HwahaeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildUserTypeChip(
                      '일반 소비자',
                      '리뷰 열람',
                      AppConstants.userTypeConsumer,
                      Icons.person_outline,
                    ),
                    const SizedBox(width: 12),
                    _buildUserTypeChip(
                      '리뷰어',
                      '미션 수행',
                      AppConstants.userTypeReviewer,
                      Icons.rate_review_outlined,
                    ),
                    const SizedBox(width: 12),
                    _buildUserTypeChip(
                      '업체',
                      '리뷰 의뢰',
                      AppConstants.userTypeBusiness,
                      Icons.store_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 이름
                Text(
                  '이름',
                  style: HwahaeTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: HwahaeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: '이름을 입력하세요',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이름을 입력해주세요';
                    }
                    if (value.length < 2) {
                      return '이름은 2글자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 이메일
                Text(
                  '이메일',
                  style: HwahaeTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: HwahaeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'example@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return '올바른 이메일 형식이 아닙니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 휴대폰 번호
                Text(
                  '휴대폰 번호',
                  style: HwahaeTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: HwahaeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _PhoneNumberFormatter(),
                  ],
                  decoration: const InputDecoration(
                    hintText: '010-0000-0000',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: _validatePhone,
                ),
                const SizedBox(height: 20),

                // 비밀번호
                Text(
                  '비밀번호',
                  style: HwahaeTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: HwahaeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: _updatePasswordStrength,
                  decoration: InputDecoration(
                    hintText: '8자 이상, 대문자/숫자/특수문자 포함',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    if (value.length < 8) {
                      return '비밀번호는 8자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                // 비밀번호 강도 표시
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _passwordStrength,
                            backgroundColor: HwahaeColors.border,
                            valueColor: AlwaysStoppedAnimation(_getStrengthColor()),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getStrengthLabel(),
                        style: HwahaeTypography.labelSmall.copyWith(
                          color: _getStrengthColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),

                // 비밀번호 확인
                Text(
                  '비밀번호 확인',
                  style: HwahaeTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: HwahaeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: '비밀번호를 다시 입력하세요',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return '비밀번호가 일치하지 않습니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 약관 동의
                _buildAgreementRow(
                  value: _agreeToTerms,
                  onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
                  label: '이용약관에 동의합니다',
                  linkText: '보기',
                  onLinkTap: () => context.push('/terms'),
                ),
                const SizedBox(height: 8),
                _buildAgreementRow(
                  value: _agreeToPrivacy,
                  onChanged: (v) => setState(() => _agreeToPrivacy = v ?? false),
                  label: '개인정보처리방침에 동의합니다',
                  linkText: '보기',
                  onLinkTap: () => context.push('/privacy'),
                ),
                const SizedBox(height: 24),

                // 회원가입 버튼
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HwahaeColors.primary,
                      foregroundColor: HwahaeColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                        : Text('회원가입', style: HwahaeTypography.labelLarge.copyWith(
                            color: HwahaeColors.onPrimary,
                            fontWeight: FontWeight.w600,
                          )),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgreementRow({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
    String? linkText,
    VoidCallback? onLinkTap,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: HwahaeColors.primary,
              ),
            ),
            Expanded(
              child: Text(
                label,
                style: HwahaeTypography.bodySmall.copyWith(
                  color: HwahaeColors.textPrimary,
                ),
              ),
            ),
            if (linkText != null)
              TextButton(
                onPressed: onLinkTap,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                child: Text(
                  linkText,
                  style: HwahaeTypography.labelSmall.copyWith(
                    color: HwahaeColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeChip(String label, String description, String value, IconData icon) {
    final isSelected = _selectedUserType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedUserType = value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? HwahaeColors.primary : HwahaeColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? HwahaeColors.primary : HwahaeColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : HwahaeColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: HwahaeTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : HwahaeColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : HwahaeColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 전화번호 자동 하이픈 포맷터
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 3 || i == 7) buffer.write('-');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
