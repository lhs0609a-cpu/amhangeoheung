import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/hwahae_colors.dart';
import '../../../core/theme/hwahae_theme.dart';
import '../../../core/theme/hwahae_typography.dart';

/// 입력창.
///
/// **테두리를 지우지 말 것.** 입력창 채움색(`surface`)과 페이지 배경(`background`)
/// 의 대비는 1.11:1 이다. 테두리가 없으면 입력창이 어디 있는지 보이지 않는다.
/// 그래서 `border`(1.30:1, 카드 윤곽용)가 아니라 `borderStrong`(3.12:1,
/// 조작 요소용)을 쓴다 — WCAG 1.4.11 이 요구하는 3:1 을 넘기는 쪽이다.
///
/// 화면마다 InputDecoration 을 손으로 짜다 보니 어떤 곳은 테두리가 연하고
/// 어떤 곳은 아예 없었다. 여기 한 곳에서만 정한다.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.suffixIcon,
    this.suffixText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
  });

  /// 숫자만 받는 입력창. 금액·인원처럼 자릿수만 넣는 자리에 쓴다.
  factory AppTextField.number({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? hint,
    String? helper,
    String? suffixText,
    bool enabled = true,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      label: label,
      hint: hint,
      helper: helper,
      suffixText: suffixText,
      enabled: enabled,
      onChanged: onChanged,
      validator: validator,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  final TextEditingController? controller;

  /// 입력창 위에 붙는 이름. 플레이스홀더만으로는 글자를 넣는 순간 무엇을
  /// 넣는 칸이었는지 사라진다.
  final String? label;

  final String? hint;
  final String? helper;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffix;

  /// 입력창 오른쪽 안쪽에 붙는 버튼(지우기 등). 터치 영역이 필요할 때는
  /// [suffix] 가 아니라 이쪽을 쓴다.
  final Widget? suffixIcon;

  final String? suffixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int maxLines;
  final int? minLines;
  final bool obscureText;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      obscureText: obscureText,
      autofocus: autofocus,
      enabled: enabled,
      readOnly: readOnly,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      validator: validator,
      style: HwahaeTypography.bodyMedium.copyWith(
        color: enabled ? HwahaeColors.textPrimary : HwahaeColors.textTertiary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: HwahaeTypography.bodyMedium.copyWith(
          color: HwahaeColors.textTertiary,
        ),
        helperText: helper,
        helperStyle: HwahaeTypography.captionMedium.copyWith(
          color: HwahaeColors.textSecondary,
        ),
        helperMaxLines: 3,
        errorText: errorText,
        errorStyle: HwahaeTypography.captionMedium.copyWith(
          // 인주색은 지적에만 쓰기로 했고, 입력 오류도 고쳐야 할 것이므로
          // 여기서는 맞는 쓰임이다. 다만 글자용으로 한 단계 진한 값을 쓴다.
          color: HwahaeColors.errorStrong,
        ),
        errorMaxLines: 3,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 20, color: HwahaeColors.textSecondary),
        suffix: suffix,
        suffixIcon: suffixIcon,
        suffixText: suffixText,
        suffixStyle: HwahaeTypography.bodyMedium.copyWith(
          color: HwahaeColors.textSecondary,
        ),
        filled: true,
        fillColor: enabled ? HwahaeColors.surface : HwahaeColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: _border(HwahaeColors.borderStrong),
        enabledBorder: _border(HwahaeColors.borderStrong),
        disabledBorder: _border(HwahaeColors.border),
        focusedBorder: _border(HwahaeColors.borderFocused, width: 2),
        errorBorder: _border(HwahaeColors.errorStrong),
        focusedErrorBorder: _border(HwahaeColors.errorStrong, width: 2),
      ),
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label!,
          style: HwahaeTypography.labelMedium.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
        const SizedBox(height: 7),
        field,
      ],
    );
  }
}
