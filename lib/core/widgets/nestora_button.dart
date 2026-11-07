import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

enum NestoraButtonVariant {
  primary,
  secondary,
  ghost,
  destructive,
}

typedef ButtonVariant = NestoraButtonVariant;

class NestoraButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final NestoraButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final double? width;
  final double height;
  final double borderRadius;

  const NestoraButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = NestoraButtonVariant.primary,
    IconData? leadingIcon,
    this.trailingIcon,
    IconData? icon,
    this.isLoading = false,
    this.width,
    this.height = 52,
    this.borderRadius = 9999, // Pill by default
  }) : leadingIcon = leadingIcon ?? icon;

  @override
  State<NestoraButton> createState() => _NestoraButtonState();
}

class _NestoraButtonState extends State<NestoraButton>
    with SingleTickerTransitionPainterMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    Border? border;

    switch (widget.variant) {
      case NestoraButtonVariant.primary:
        bg = isDark ? AppColors.darkPrimary : AppColors.primary;
        fg = isDark ? AppColors.primaryDark : AppColors.onPrimary;
        break;
      case NestoraButtonVariant.secondary:
        bg = isDark ? AppColors.darkSecondarySurface : AppColors.lightSecondarySurface;
        fg = isDark ? AppColors.darkTextPrimary : AppColors.primary;
        border = Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1,
        );
        break;
      case NestoraButtonVariant.ghost:
        bg = Colors.transparent;
        fg = isDark ? AppColors.darkPrimary : AppColors.primary;
        break;
      case NestoraButtonVariant.destructive:
        bg = AppColors.errorContainer;
        fg = AppColors.error;
        break;
    }

    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final scaleDuration = disableAnimations ? Duration.zero : const Duration(milliseconds: 150);

    return AnimatedScale(
      scale: (_isPressed && !disableAnimations) ? 0.98 : 1.0,
      duration: scaleDuration,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Material(
          color: isEnabled ? bg : bg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: InkWell(
            onTap: isEnabled ? widget.onPressed : null,
            onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
            onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
            onTapCancel: () => setState(() => _isPressed = false),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: border,
              ),
              alignment: Alignment.center,
              child: widget.isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.leadingIcon != null) ...[
                          Icon(widget.leadingIcon, size: 20, color: fg),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            widget.text,
                            style: AppTypography.labelLg(color: fg),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.trailingIcon != null) ...[
                          const SizedBox(width: 8),
                          Icon(widget.trailingIcon, size: 20, color: fg),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

mixin SingleTickerTransitionPainterMixin {}
