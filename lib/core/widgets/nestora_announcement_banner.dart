import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../services/remote_config_service.dart';

/// Reusable announcement banner widget displaying dynamic broadcasts
/// configured via Firebase Remote Config.
class NestoraAnnouncementBanner extends StatelessWidget {
  final AppAnnouncement announcement;
  final VoidCallback? onDismiss;
  final EdgeInsetsGeometry? margin;

  const NestoraAnnouncementBanner({
    super.key,
    required this.announcement,
    this.onDismiss,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    if (!announcement.hasContent) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color iconColor;
    IconData iconData;
    Color bgColor;
    Color borderColor;

    switch (announcement.type.toLowerCase()) {
      case 'warning':
        iconColor = AppColors.warmAmber;
        iconData = Icons.warning_amber_rounded;
        bgColor = isDark ? const Color(0xFF2B2519) : const Color(0xFFFFF8E7);
        borderColor = AppColors.warmAmber.withValues(alpha: 0.35);
        break;
      case 'update':
        iconColor = isDark ? AppColors.darkPrimary : AppColors.primaryContainer;
        iconData = Icons.system_update_rounded;
        bgColor = isDark ? const Color(0xFF1E2820) : const Color(0xFFEDF5EF);
        borderColor = iconColor.withValues(alpha: 0.30);
        break;
      case 'success':
        iconColor = AppColors.secondary;
        iconData = Icons.check_circle_outline_rounded;
        bgColor = isDark ? const Color(0xFF18261B) : const Color(0xFFEAF5EC);
        borderColor = AppColors.secondary.withValues(alpha: 0.30);
        break;
      case 'info':
      default:
        iconColor = isDark ? AppColors.darkPrimary : AppColors.primaryContainer;
        iconData = Icons.info_outline_rounded;
        bgColor = isDark ? const Color(0xFF1A241C) : const Color(0xFFF1F6F2);
        borderColor = iconColor.withValues(alpha: 0.25);
    }

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(iconData, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (announcement.title.isNotEmpty)
                  Text(
                    announcement.title,
                    style: AppTypography.cardTitle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ).copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                if (announcement.title.isNotEmpty && announcement.message.isNotEmpty)
                  const SizedBox(height: 3),
                if (announcement.message.isNotEmpty)
                  Text(
                    announcement.message,
                    style: AppTypography.description(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ).copyWith(fontSize: 12, height: 1.35),
                  ),
              ],
            ),
          ),
          if (announcement.isDismissible && onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                      .withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
