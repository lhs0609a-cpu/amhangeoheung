import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/social_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();

  bool _isLoading = false;
  bool _isSocialLoading = false;
  String? _loadingProvider;
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _authRepository.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.success) {
        if (mounted) {
          context.go('/home');
        }
      } else {
        _showError(response.errorMessage);
      }
    } catch (e) {
      _showError('네트워크 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _socialLogin(SocialProvider provider) async {
    if (_isSocialLoading) return;

    setState(() {
      _isSocialLoading = true;
      _loadingProvider = provider.name;
    });

    try {
      final response = await _authRepository.socialLogin(provider);

      if (response.success) {
        if (mounted) {
          // 신규 사용자인 경우 추가 정보 입력 화면으로 이동할 수도 있음
          context.go('/home');
        }
      } else {
        _showError(response.errorMessage);
      }
    } catch (e) {
      _showError('소셜 로그인 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isSocialLoading = false;
          _loadingProvider = null;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: HwahaeColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: HwahaeColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),

                    // 로고 & 타이틀
                    Center(child: _buildLogo()),
                    const SizedBox(height: 48),

                    // 환영 메시지
                    _buildWelcomeText(),
                    const SizedBox(height: 40),

                    // 입력 필드들
                    _buildEmailField(),
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                    const SizedBox(height: 12),

                    // 비밀번호 찾기
                    _buildForgotPassword(),
                    const SizedBox(height: 32),

                    // 로그인 버튼
                    _buildLoginButton(),
                    const SizedBox(height: 24),

                    // 소셜 로그인
                    _buildSocialLogin(),
                    const SizedBox(height: 32),

                    // 회원가입 링크
                    _buildSignUpLink(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: HwahaeColors.gradientPrimary,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: HwahaeColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.verified_user_rounded,
            size: 44,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: HwahaeColors.gradientPrimary,
          ).createShader(bounds),
          child: Text(
            '암행어흥',
            style: HwahaeTypography.displaySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '다시 만나서 반가워요',
          style: HwahaeTypography.headlineMedium.copyWith(
            color: HwahaeColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '신뢰할 수 있는 리뷰 플랫폼에 로그인하세요',
          style: HwahaeTypography.bodyMedium.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '이메일',
          style: HwahaeTypography.labelMedium.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: HwahaeTypography.bodyMedium,
          enabled: !_isLoading && !_isSocialLoading,
          decoration: InputDecoration(
            hintText: 'example@email.com',
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: HwahaeColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.email_outlined,
                size: 20,
                color: HwahaeColors.primary,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '이메일을 입력해주세요';
            }
            if (!value.contains('@')) {
              return '올바른 이메일 형식이 아닙니다';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '비밀번호',
          style: HwahaeTypography.labelMedium.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: HwahaeTypography.bodyMedium,
          enabled: !_isLoading && !_isSocialLoading,
          decoration: InputDecoration(
            hintText: '비밀번호를 입력하세요',
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: HwahaeColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 20,
                color: HwahaeColors.primary,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: HwahaeColors.textTertiary,
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
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: (_isLoading || _isSocialLoading)
            ? null
            : () => context.push('/forgot-password'),
        style: TextButton.styleFrom(
          foregroundColor: HwahaeColors.primary,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          '비밀번호를 잊으셨나요?',
          style: HwahaeTypography.labelMedium.copyWith(
            color: HwahaeColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    final isDisabled = _isLoading || _isSocialLoading;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isDisabled
            ? null
            : const LinearGradient(
                colors: HwahaeColors.gradientPrimary,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: isDisabled ? HwahaeColors.surfaceVariant : null,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: HwahaeColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : _login,
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: HwahaeColors.primary,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    '로그인',
                    style: HwahaeTypography.button.copyWith(
                      color: isDisabled ? HwahaeColors.textTertiary : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: HwahaeColors.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '간편 로그인',
                style: HwahaeTypography.captionMedium.copyWith(
                  color: HwahaeColors.textTertiary,
                ),
              ),
            ),
            const Expanded(child: Divider(color: HwahaeColors.divider)),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google 로그인
            _SocialLoginButton(
              provider: SocialProvider.google,
              isLoading: _loadingProvider == 'google',
              isDisabled: _isLoading || _isSocialLoading,
              onTap: () => _socialLogin(SocialProvider.google),
            ),
            const SizedBox(width: 16),
            // Apple 로그인 (iOS만)
            if (Platform.isIOS)
              _SocialLoginButton(
                provider: SocialProvider.apple,
                isLoading: _loadingProvider == 'apple',
                isDisabled: _isLoading || _isSocialLoading,
                onTap: () => _socialLogin(SocialProvider.apple),
              ),
            if (Platform.isIOS) const SizedBox(width: 16),
            // 카카오 로그인
            _SocialLoginButton(
              provider: SocialProvider.kakao,
              isLoading: _loadingProvider == 'kakao',
              isDisabled: _isLoading || _isSocialLoading,
              onTap: () => _socialLogin(SocialProvider.kakao),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '소셜 로그인 시 서비스 이용약관에 동의하게 됩니다.',
          style: HwahaeTypography.captionSmall.copyWith(
            color: HwahaeColors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '계정이 없으신가요?',
          style: HwahaeTypography.bodySmall.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: (_isLoading || _isSocialLoading)
              ? null
              : () => context.push('/register'),
          style: TextButton.styleFrom(
            foregroundColor: HwahaeColors.primary,
            padding: const EdgeInsets.only(left: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            '회원가입',
            style: HwahaeTypography.labelLarge.copyWith(
              color: HwahaeColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// 소셜 로그인 버튼 위젯
class _SocialLoginButton extends StatelessWidget {
  final SocialProvider provider;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;

  const _SocialLoginButton({
    required this.provider,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDisabled
                ? HwahaeColors.border.withOpacity(0.5)
                : HwahaeColors.border,
          ),
          boxShadow: isLoading
              ? [
                  BoxShadow(
                    color: _getBrandColor().withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: _getBrandColor(),
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : Center(
                child: _buildIcon(),
              ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (provider == SocialProvider.kakao) {
      return isDisabled
          ? const Color(0xFFFEE500).withOpacity(0.5)
          : const Color(0xFFFEE500);
    }
    return HwahaeColors.surface;
  }

  Color _getBrandColor() {
    switch (provider) {
      case SocialProvider.google:
        return const Color(0xFFEA4335);
      case SocialProvider.apple:
        return HwahaeColors.textPrimary;
      case SocialProvider.kakao:
        return const Color(0xFF3C1E1E);
    }
  }

  Widget _buildIcon() {
    final opacity = isDisabled ? 0.5 : 1.0;

    switch (provider) {
      case SocialProvider.google:
        return Opacity(
          opacity: opacity,
          child: _buildGoogleIcon(),
        );
      case SocialProvider.apple:
        return Opacity(
          opacity: opacity,
          child: const Icon(
            Icons.apple_rounded,
            size: 32,
            color: Colors.black,
          ),
        );
      case SocialProvider.kakao:
        return Opacity(
          opacity: opacity,
          child: const Icon(
            Icons.chat_bubble_rounded,
            size: 28,
            color: Color(0xFF3C1E1E),
          ),
        );
    }
  }

  Widget _buildGoogleIcon() {
    // Google 공식 컬러 아이콘
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFFEA4335),
          ),
        ),
      ),
    );
  }
}
