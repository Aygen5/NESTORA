import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class NestoraCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool isActive;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;

  const NestoraCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.isActive = false,
    this.borderRadius = 16,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBg = isDark
        ? AppColors.darkCardBackground
        : AppColors.lightCardBackground;

    final defaultBorder = isDark
        ? (isActive ? AppColors.darkPrimary : AppColors.darkBorder)
        : (isActive ? AppColors.secondaryFixed : AppColors.border);

    final bg = backgroundColor ?? defaultBg;
    final bColor = borderColor ?? defaultBorder;
    final shadows = isActive
        ? AppColors.activeCardShadow
        : (isDark ? <BoxShadow>[] : AppColors.lightCardShadow);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: bColor, width: 1),
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

