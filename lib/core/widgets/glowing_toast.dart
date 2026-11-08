import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Interactive glowing floating toast card for Nestora.
/// Enters with a soft luminous radiance (bright glow & border aura),
/// gently settles and dims into an elegant deep card, then smoothly dismisses.
class GlowingToastWidget extends StatefulWidget {
  final String message;
  final IconData? icon;
  final bool isError;
  final String? actionLabel;
  final VoidCallback? onAction;

  const GlowingToastWidget({
    super.key,
    required this.message,
    this.icon,
    this.isError = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<GlowingToastWidget> createState() => _GlowingToastWidgetState();
}

class _GlowingToastWidgetState extends State<GlowingToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Subtle natural pop-in scale
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.94, end: 1.02)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.02, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 70,
      ),
    ]).animate(_controller);

    // Initial bright radiance that smoothly dims into a deep elegant card:
    // 0-15%: Spikes to 1.0 (bright luminous flare)
    // 15-70%: Softly dims down to 0.0 ("karararak gitsin")
    // 70-100%: Stays at elegant dark resting state
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 30,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glowColor = widget.isError
        ? const Color(0xFFFF6E6E)
        : (isDark ? AppColors.cashmereBadge : const Color(0xFFD4C3A3));

    final baseBgColor = widget.isError
        ? const Color(0xFF8C1D18)
        : (isDark ? const Color(0xFF1B201D) : const Color(0xFF1E3023));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glow = _glowAnimation.value;
        final scale = _scaleAnimation.value;

        return Transform.scale(
          scale: scale,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: baseBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color.lerp(
                  const Color(0x33FFFFFF),
                  glowColor,
                  glow * 0.9,
                )!,
                width: 1.0 + (1.2 * glow),
              ),
              boxShadow: [
                // Soft deep ambient shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                // Glowing bloom: bright at first, smoothly dimming out
                if (glow > 0.01)
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.45 * glow),
                    blurRadius: 22 * glow + 4,
                    spreadRadius: 2.5 * glow,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glow-wrapped icon badge
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isError
                        ? const Color(0x33FFFFFF)
                        : (glow > 0.3
                            ? glowColor.withValues(alpha: 0.25)
                            : const Color(0x22FFFFFF)),
                    boxShadow: [
                      if (glow > 0.2)
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.4 * glow),
                          blurRadius: 10 * glow,
                          spreadRadius: 1 * glow,
                        ),
                    ],
                  ),
                  child: Icon(
                    widget.icon ??
                        (widget.isError
                            ? Icons.error_outline_rounded
                            : Icons.check_rounded),
                    color: Colors.white,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 12),
                // Message text
                Flexible(
                  child: Text(
                    widget.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (widget.actionLabel != null && widget.onAction != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      widget.onAction!();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        widget.actionLabel!,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.cashmereBadge,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Helper function to display the Nestora Glowing Toast notification.
void showGlowingToast(
  BuildContext context, {
  required String message,
  IconData? icon,
  bool isError = false,
  String? actionLabel,
  VoidCallback? onAction,
  Duration? duration,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: EdgeInsets.zero,
      duration: duration ?? const Duration(milliseconds: 2800),
      content: Center(
        child: GlowingToastWidget(
          message: message,
          icon: icon,
          isError: isError,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ),
    ),
  );
}
