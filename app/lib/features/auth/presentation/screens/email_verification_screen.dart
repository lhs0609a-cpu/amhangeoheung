import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/network/api_client.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  bool _isVerified = false;
  String? _errorMessage;

  // 30-minute countdown timer
  Timer? _countdownTimer;
  int _remainingSeconds = 30 * 60;

  // 60-second resend cooldown timer
  Timer? _resendTimer;
  int _resendCooldown = 60;

  late AnimationController _successAnimController;
  late Animation<double> _successScaleAnim;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
    _startResendCooldown();

    _successAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScaleAnim = CurvedAnimation(
      parent: _successAnimController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _resendTimer?.cancel();
    _successAnimController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdownTimer() {
    _remainingSeconds = 30 * 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        setState(() {});
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
    });
  }

  void _startResendCooldown() {
    _resendCooldown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 0) {
        timer.cancel();
        setState(() {});
        return;
      }
      setState(() {
        _resendCooldown--;
      });
    });
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get _fullCode {
    return _controllers.map((c) => c.text).join();
  }

  void _onDigitChanged(int index, String value) {
    setState(() {
      _errorMessage = null;
    });

    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    // Auto-submit when all 6 digits are entered
    if (_fullCode.length == 6) {
      _verifyCode();
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyCode() async {
    final code = _fullCode;
    if (code.length != 6) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient().post('/auth/verify-email', data: {
        'email': widget.email,
        'code': code,
      });

      if (response.data['success'] == true) {
        setState(() {
          _isVerified = true;
        });
        _successAnimController.forward();

        // Navigate to home after success animation
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          context.go('/home');
        }
      } else {
        setState(() {
          _errorMessage =
              response.data['message'] ?? '인증에 실패했습니다.';
        });
        _clearCode();
      }
    } catch (e) {
      setState(() {
        _errorMessage = '네트워크 오류가 발생했습니다.';
      });
      _clearCode();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearCode() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _resendCode() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final response =
          await ApiClient().post('/auth/resend-verification', data: {
        'email': widget.email,
      });

      if (response.data['success'] == true) {
        _startCountdownTimer();
        _startResendCooldown();
        _clearCode();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('인증 코드가 재전송되었습니다.'),
              backgroundColor: HwahaeColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = response.data['message'] ?? '재전송에 실패했습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '네트워크 오류가 발생했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('이메일 인증', style: HwahaeTypography.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _isVerified ? _buildSuccessView() : _buildVerificationView(),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _successScaleAnim,
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: HwahaeColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 56,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '인증 완료!',
            style: HwahaeTypography.headlineMedium.copyWith(
              color: HwahaeColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '이메일 인증이 성공적으로 완료되었습니다.',
            style: HwahaeTypography.bodyMedium.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationView() {
    return Column(
      children: [
        const SizedBox(height: 40),

        // Mail icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: HwahaeColors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.mark_email_unread_outlined,
            color: HwahaeColors.primary,
            size: 36,
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          '인증 코드를 입력하세요',
          style: HwahaeTypography.headlineSmall.copyWith(
            color: HwahaeColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        // Description
        Text(
          '${widget.email}으로\n6자리 인증 코드를 보냈습니다.',
          textAlign: TextAlign.center,
          style: HwahaeTypography.bodyMedium.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),

        // Timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _remainingSeconds <= 60
                ? HwahaeColors.errorLight
                : HwahaeColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 18,
                color: _remainingSeconds <= 60
                    ? HwahaeColors.error
                    : HwahaeColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                _remainingSeconds > 0 ? _formattedTime : '인증 코드가 만료되었습니다. 재전송 버튼을 눌러주세요.',
                style: HwahaeTypography.labelLarge.copyWith(
                  color: _remainingSeconds <= 60
                      ? HwahaeColors.error
                      : HwahaeColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // 6-digit input fields
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Container(
              width: 48,
              height: 56,
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 8,
                right: index == 2 ? 12 : 0,
              ),
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) => _onKeyEvent(index, event),
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: HwahaeTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: HwahaeColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: _controllers[index].text.isNotEmpty
                        ? HwahaeColors.primaryContainer
                        : HwahaeColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: HwahaeColors.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: HwahaeColors.error,
                        width: 2,
                      ),
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) => _onDigitChanged(index, value),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),

        // Error message
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: HwahaeColors.error,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _errorMessage!,
                  style: HwahaeTypography.bodySmall.copyWith(
                    color: HwahaeColors.error,
                  ),
                ),
              ],
            ),
          ),

        // Loading indicator
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: HwahaeColors.primary,
                strokeWidth: 2,
              ),
            ),
          ),

        const Spacer(),

        // Resend section
        Column(
          children: [
            Text(
              '코드를 받지 못하셨나요?',
              style: HwahaeTypography.bodySmall.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '스팸함도 확인해보세요',
              style: HwahaeTypography.bodySmall.copyWith(
                color: HwahaeColors.textTertiary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed:
                    (_resendCooldown > 0 || _isResending) ? null : _resendCode,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _resendCooldown > 0
                        ? HwahaeColors.border
                        : HwahaeColors.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isResending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: HwahaeColors.primary,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _resendCooldown > 0
                            ? '재전송 (${_resendCooldown}초)'
                            : '재전송',
                        style: HwahaeTypography.labelLarge.copyWith(
                          color: _resendCooldown > 0
                              ? HwahaeColors.textDisabled
                              : HwahaeColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
