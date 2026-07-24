import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/network/api_client.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient().post('/auth/forgot-password', data: {
        'email': _emailController.text.trim(),
      });

      if (response.data['success']) {
        setState(() => _isEmailSent = true);
      } else {
        _showError(response.data['message'] ?? '이메일 전송에 실패했습니다.');
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: HwahaeColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _isEmailSent ? _buildSuccessContent() : _buildFormContent(),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // 아이콘
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: HwahaeColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lock_reset,
                size: 40,
                color: HwahaeColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 제목
          Center(
            child: Text(
              '비밀번호 찾기',
              style: HwahaeTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: HwahaeColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 설명
          Center(
            child: Text(
              '가입하신 이메일 주소를 입력해주세요.\n비밀번호 재설정 링크를 보내드립니다.',
              textAlign: TextAlign.center,
              style: HwahaeTypography.bodySmall.copyWith(
                color: HwahaeColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // 이메일 입력
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
          const SizedBox(height: 32),

          // 전송 버튼
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendResetEmail,
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
                  : Text('재설정 링크 보내기', style: HwahaeTypography.labelLarge.copyWith(
                      color: HwahaeColors.onPrimary,
                      fontWeight: FontWeight.w600,
                    )),
            ),
          ),
          const SizedBox(height: 16),

          // 로그인으로 돌아가기
          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
              ),
              child: Text(
                '로그인으로 돌아가기',
                style: HwahaeTypography.labelMedium.copyWith(
                  color: HwahaeColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 60),

        // 성공 아이콘
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: HwahaeColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read,
            size: 50,
            color: HwahaeColors.success,
          ),
        ),
        const SizedBox(height: 32),

        // 제목
        Text(
          '이메일을 확인해주세요',
          style: HwahaeTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: HwahaeColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // 설명
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '${_emailController.text}로\n비밀번호 재설정 링크를 보냈습니다.\n\n이메일이 오지 않았다면 스팸함을 확인해주세요.',
            textAlign: TextAlign.center,
            style: HwahaeTypography.bodySmall.copyWith(
              color: HwahaeColors.textSecondary,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 40),

        // 다시 보내기 버튼
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() => _isEmailSent = false);
                  },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: HwahaeColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '다른 이메일로 보내기',
              style: HwahaeTypography.labelLarge.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 로그인으로 돌아가기
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HwahaeColors.primary,
              foregroundColor: HwahaeColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('로그인으로 돌아가기', style: HwahaeTypography.labelLarge.copyWith(
              color: HwahaeColors.onPrimary,
              fontWeight: FontWeight.w600,
            )),
          ),
        ),
      ],
    );
  }
}
