import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'nestora_button.dart';

enum DeleteDialogVariation {
  deviceDelete, // Variation A: simple irreversible delete
  roomDeleteWithDevices, // Variation B: room has active devices, manage/delete
}

class DialogVariation {
  static const DeleteDialogVariation variationA = DeleteDialogVariation.deviceDelete;
  static const DeleteDialogVariation variationB = DeleteDialogVariation.roomDeleteWithDevices;
}

Future<void> showNestoraDialog({
  required BuildContext context,
  DeleteDialogVariation variation = DeleteDialogVariation.deviceDelete,
  required String title,
  required String description,
  String? confirmText,
  VoidCallback? onConfirm,
}) async {
  final result = await showNestoraDeleteDialog(
    context: context,
    title: title,
    message: description,
    variation: variation,
    deleteButtonText: confirmText ?? 'Sil',
  );
  if (result == true) {
    onConfirm?.call();
  }
}

Future<bool?> showNestoraDeleteDialog({
  required BuildContext context,
  required String title,
  required String message,
  DeleteDialogVariation variation = DeleteDialogVariation.deviceDelete,
  String deleteButtonText = 'Sil',
  VoidCallback? onManageDevices,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showDialog<bool>(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: isDark
            ? AppColors.darkCardBackground
            : AppColors.lightCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with red or warning badge
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: variation == DeleteDialogVariation.deviceDelete
                          ? AppColors.errorContainer
                          : AppColors.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      variation == DeleteDialogVariation.deviceDelete
                          ? Icons.delete_forever_rounded
                          : Icons.sensor_door_outlined,
                      color: variation == DeleteDialogVariation.deviceDelete
                          ? AppColors.error
                          : AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variation == DeleteDialogVariation.deviceDelete
                              ? 'CİHAZ SİLME'
                              : 'ODA SİLME UYARISI',
                          style: AppTypography.labelSm(
                            color: variation == DeleteDialogVariation.deviceDelete
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          title,
                          style: AppTypography.headlineSm(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: AppTypography.bodyMd(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              // Action buttons
              if (variation == DeleteDialogVariation.deviceDelete) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Vazgeç',
                        style: AppTypography.labelLg(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    NestoraButton(
                      text: deleteButtonText,
                      variant: NestoraButtonVariant.destructive,
                      height: 44,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              ] else ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (onManageDevices != null) ...[
                      NestoraButton(
                        text: 'Cihazları Yönet',
                        variant: NestoraButtonVariant.secondary,
                        height: 44,
                        onPressed: () {
                          Navigator.of(context).pop(false);
                          onManageDevices();
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(
                            'Vazgeç',
                            style: AppTypography.labelLg(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        NestoraButton(
                          text: deleteButtonText,
                          variant: NestoraButtonVariant.destructive,
                          height: 44,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

