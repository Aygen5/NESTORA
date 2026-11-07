import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class NestoraInput extends StatelessWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final TextInputType keyboardType;
  final String? errorText;
  final bool isSuccess;
  final bool enabled;

  const NestoraInput({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.onChanged,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixWidget,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.isSuccess = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isSuccess
        ? (isDark ? AppColors.darkPrimaryContainer.withValues(alpha: 0.4) : AppColors.secondaryFixed.withValues(alpha: 0.35))
        : (isDark ? AppColors.darkSecondarySurface : AppColors.lightSecondarySurface);

    final borderColor = isSuccess
        ? (isDark ? AppColors.darkPrimary : AppColors.primary)
        : (errorText != null ? AppColors.error : Colors.transparent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Text(
              label!,
              style: AppTypography.labelMd(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    prefixIcon,
                    size: 20,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ] else ...[
                const SizedBox(width: 14),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  enabled: enabled,
                  style: AppTypography.bodyMd(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: hintText,
                    hintStyle: AppTypography.bodyMd(
                      color: isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.7) : AppColors.outline,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
              if (suffixWidget != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: suffixWidget!,
                ),
              ] else ...[
                const SizedBox(width: 14),
              ],
            ],
          ),
        ),
        if (errorText != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText!,
              style: AppTypography.bodySm(color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }
}

