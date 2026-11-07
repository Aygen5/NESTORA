import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class NestoraSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const NestoraSwitch({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeTrackColor =
        isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer;
    final inactiveTrackColor =
        isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHighest;

    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOut,
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9999),
          color: value ? activeTrackColor : inactiveTrackColor,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark && value
                  ? AppColors.darkPrimary
                  : AppColors.surfaceContainerLowest,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 4,
                  offset: Offset(0, 1.5),
                ),
              ],
            ),
            child: value
                ? Center(
                    child: Icon(
                      Icons.check,
                      size: 13,
                      color: isDark ? AppColors.primaryDark : AppColors.primary,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

