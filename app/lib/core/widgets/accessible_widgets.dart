import 'package:flutter/material.dart';
import '../utils/accessibility_utils.dart';
import '../theme/hwahae_colors.dart';
import '../theme/hwahae_typography.dart';

/// 접근성이 적용된 공통 위젯 모음

/// 접근성 친화적 아이콘 버튼
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final bool showTooltip;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.hint,
    this.onPressed,
    this.color,
    this.size = 24.0,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = SemanticButton(
      label: label,
      hint: hint,
      isEnabled: onPressed != null,
      onTap: onPressed,
      child: AccessibleTouchTarget(
        onTap: onPressed,
        child: Icon(
          icon,
          size: size,
          color: onPressed != null
              ? (color ?? HwahaeColors.textPrimary)
              : HwahaeColors.textDisabled,
        ),
      ),
    );

    if (showTooltip) {
      return Tooltip(
        message: label,
        child: button,
      );
    }

    return button;
  }
}

/// 접근성 친화적 카드
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final String? label;
  final String? hint;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final double borderRadius;

  const AccessibleCard({
    super.key,
    required this.child,
    this.label,
    this.hint,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return SemanticButton(
        label: label ?? '',
        hint: hint ?? '탭하여 열기',
        onTap: onTap,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    if (label != null) {
      return SemanticContainer(
        label: label,
        child: card,
      );
    }

    return card;
  }
}

/// 접근성 친화적 별점 표시
class AccessibleRatingStars extends StatelessWidget {
  final double rating;
  final double maxRating;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final String? label;
  final bool showValue;

  const AccessibleRatingStars({
    super.key,
    required this.rating,
    this.maxRating = 5.0,
    this.size = 20.0,
    this.activeColor,
    this.inactiveColor,
    this.label,
    this.showValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final stars = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating.toInt(), (index) {
        final starValue = index + 1;
        IconData iconData;
        Color color;

        if (rating >= starValue) {
          iconData = Icons.star_rounded;
          color = activeColor ?? HwahaeColors.ratingStar;
        } else if (rating >= starValue - 0.5) {
          iconData = Icons.star_half_rounded;
          color = activeColor ?? HwahaeColors.ratingStar;
        } else {
          iconData = Icons.star_outline_rounded;
          color = inactiveColor ?? HwahaeColors.ratingStarEmpty;
        }

        return Icon(iconData, size: size, color: color);
      }),
    );

    final content = showValue
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              stars,
              const SizedBox(width: 8),
              Text(
                rating.toStringAsFixed(1),
                style: HwahaeTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        : stars;

    return SemanticRating(
      rating: rating,
      maxRating: maxRating,
      label: label,
      child: ExcludeSemantics(child: content),
    );
  }
}

/// 접근성 친화적 가격 표시
class AccessiblePrice extends StatelessWidget {
  final int amount;
  final int? originalAmount;
  final String? label;
  final TextStyle? style;
  final TextStyle? originalStyle;
  final bool showCurrency;

  const AccessiblePrice({
    super.key,
    required this.amount,
    this.originalAmount,
    this.label,
    this.style,
    this.originalStyle,
    this.showCurrency = true,
  });

  @override
  Widget build(BuildContext context) {
    final formattedAmount = _formatCurrency(amount);
    final isDiscounted = originalAmount != null && originalAmount! > amount;

    Widget priceWidget;

    if (isDiscounted) {
      priceWidget = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatCurrency(originalAmount!),
            style: (originalStyle ?? HwahaeTypography.bodySmall).copyWith(
              decoration: TextDecoration.lineThrough,
              color: HwahaeColors.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            showCurrency ? '$formattedAmount원' : formattedAmount,
            style: (style ?? HwahaeTypography.titleMedium).copyWith(
              color: HwahaeColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else {
      priceWidget = Text(
        showCurrency ? '$formattedAmount원' : formattedAmount,
        style: style ?? HwahaeTypography.titleMedium.copyWith(
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return SemanticPrice(
      amount: amount,
      originalAmount: originalAmount,
      label: label,
      isDiscounted: isDiscounted,
      child: ExcludeSemantics(child: priceWidget),
    );
  }

  String _formatCurrency(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}

/// 접근성 친화적 상태 배지
class AccessibleStatusBadge extends StatelessWidget {
  final String status;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final String? label;

  const AccessibleStatusBadge({
    super.key,
    required this.status,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? HwahaeColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor ?? HwahaeColors.primary),
            const SizedBox(width: 4),
          ],
          Text(
            status,
            style: HwahaeTypography.labelSmall.copyWith(
              color: textColor ?? HwahaeColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return SemanticStatus(
      status: status,
      label: label,
      child: ExcludeSemantics(child: badge),
    );
  }
}

/// 접근성 친화적 진행률 표시
class AccessibleProgressBar extends StatelessWidget {
  final double value;
  final String label;
  final String? valueLabel;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;

  const AccessibleProgressBar({
    super.key,
    required this.value,
    required this.label,
    this.valueLabel,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final progressBar = ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        backgroundColor: backgroundColor ?? HwahaeColors.surfaceVariant,
        valueColor: AlwaysStoppedAnimation(
          foregroundColor ?? HwahaeColors.primary,
        ),
        minHeight: height,
      ),
    );

    return SemanticProgress(
      label: label,
      value: value,
      valueLabel: valueLabel,
      child: ExcludeSemantics(child: progressBar),
    );
  }
}

/// 접근성 친화적 알림 배지 (아이콘 위)
class AccessibleNotificationBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final String label;
  final Color? badgeColor;
  final Color? textColor;

  const AccessibleNotificationBadge({
    super.key,
    required this.child,
    required this.count,
    required this.label,
    this.badgeColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor ?? HwahaeColors.error,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: HwahaeTypography.labelSmall.copyWith(
                    color: textColor ?? Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    return SemanticBadge(
      label: label,
      count: count,
      child: ExcludeSemantics(child: badge),
    );
  }
}

/// 접근성 친화적 날짜 표시
class AccessibleDateDisplay extends StatelessWidget {
  final DateTime dateTime;
  final String? label;
  final bool showTime;
  final TextStyle? style;
  final String? format;

  const AccessibleDateDisplay({
    super.key,
    required this.dateTime,
    this.label,
    this.showTime = false,
    this.style,
    this.format,
  });

  @override
  Widget build(BuildContext context) {
    String displayText;
    if (format != null) {
      displayText = format!;
    } else {
      displayText = '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
      if (showTime) {
        displayText += ' ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    }

    return SemanticDateTime(
      dateTime: dateTime,
      label: label,
      includeTime: showTime,
      child: ExcludeSemantics(
        child: Text(
          displayText,
          style: style ?? HwahaeTypography.bodySmall,
        ),
      ),
    );
  }
}

/// 접근성 친화적 섹션 헤더
class AccessibleSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const AccessibleSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: HwahaeTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: HwahaeTypography.bodySmall.copyWith(
                      color: HwahaeColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    if (onTap != null) {
      return SemanticHeader(
        label: subtitle != null ? '$title, $subtitle' : title,
        child: InkWell(
          onTap: onTap,
          child: content,
        ),
      );
    }

    return SemanticHeader(
      label: subtitle != null ? '$title, $subtitle' : title,
      child: content,
    );
  }
}

/// 접근성 친화적 리스트 타일
class AccessibleListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticHint;
  final EdgeInsets? contentPadding;

  const AccessibleListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    this.semanticHint,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
      contentPadding: contentPadding,
    );

    final label = semanticLabel ?? (subtitle != null ? '$title, $subtitle' : title);

    if (onTap != null) {
      return SemanticButton(
        label: label,
        hint: semanticHint ?? '탭하여 열기',
        onTap: onTap,
        child: ExcludeSemantics(child: tile),
      );
    }

    return Semantics(
      label: label,
      child: ExcludeSemantics(child: tile),
    );
  }
}

/// 접근성 친화적 텍스트 입력 필드
class AccessibleTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final bool readOnly;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const AccessibleTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SemanticHeader(
          label: label,
          child: Text(
            label,
            style: HwahaeTypography.labelMedium.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SemanticTextField(
          label: label,
          hint: hint,
          value: controller?.text,
          isObscured: obscureText,
          isMultiline: maxLines > 1,
          isReadOnly: readOnly,
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            readOnly: readOnly,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              errorText: errorText,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}

/// 접근성 친화적 체크박스 타일
class AccessibleCheckboxTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final Widget? secondary;

  const AccessibleCheckboxTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return SemanticCheckbox(
      label: subtitle != null ? '$title, $subtitle' : title,
      isChecked: value,
      onChanged: onChanged != null ? (v) => onChanged!(v) : null,
      child: CheckboxListTile(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        value: value,
        onChanged: onChanged,
        secondary: secondary,
      ),
    );
  }
}

/// 접근성 친화적 스위치 타일
class AccessibleSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? secondary;

  const AccessibleSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = subtitle != null
        ? '$title, $subtitle, ${value ? '켜짐' : '꺼짐'}'
        : '$title, ${value ? '켜짐' : '꺼짐'}';

    return Semantics(
      toggled: value,
      label: semanticLabel,
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: SwitchListTile(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        value: value,
        onChanged: onChanged,
        secondary: secondary,
      ),
    );
  }
}

/// 접근성 친화적 빈 상태 표시
class AccessibleEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AccessibleEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = description != null
        ? '$title. $description'
        : title;

    return Semantics(
      label: semanticLabel,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 64,
                color: HwahaeColors.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: HwahaeTypography.titleMedium.copyWith(
                  color: HwahaeColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (description != null) ...[
                const SizedBox(height: 8),
                Text(
                  description!,
                  style: HwahaeTypography.bodyMedium.copyWith(
                    color: HwahaeColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                SemanticButton(
                  label: actionLabel!,
                  onTap: onAction,
                  child: ElevatedButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 접근성 친화적 로딩 표시
class AccessibleLoadingIndicator extends StatelessWidget {
  final String? label;
  final double size;
  final Color? color;

  const AccessibleLoadingIndicator({
    super.key,
    this.label,
    this.size = 40.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SemanticProgress(
      label: label ?? '로딩 중',
      child: Center(
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(
              color ?? HwahaeColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 접근성 친화적 에러 표시
class AccessibleErrorState extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onRetry;
  final IconData? icon;

  const AccessibleErrorState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SemanticLiveRegion(
      label: '오류: $message',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon ?? Icons.error_outline_rounded,
                size: 48,
                color: HwahaeColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: HwahaeTypography.bodyMedium.copyWith(
                  color: HwahaeColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onRetry != null) ...[
                const SizedBox(height: 24),
                SemanticButton(
                  label: actionLabel!,
                  hint: '탭하여 다시 시도',
                  onTap: onRetry,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(actionLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
