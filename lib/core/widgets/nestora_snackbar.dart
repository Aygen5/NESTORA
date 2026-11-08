import 'package:flutter/material.dart';
import 'glowing_toast.dart';

/// Legacy adapter for backward compatibility.
/// All toasts in Nestora now render the elegant, compact, glowing toast card.
class NestoraSnackbar {
  NestoraSnackbar._();

  static void showSuccess(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    showGlowingToast(
      context,
      message: message,
      isError: false,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    showGlowingToast(
      context,
      message: message,
      isError: true,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

/// Global convenience function to show glowing feedback toast.
void showNestoraSnackbar(
  BuildContext context, {
  required String message,
  bool isError = false,
  IconData? icon,
}) {
  showGlowingToast(
    context,
    message: message,
    isError: isError,
    icon: icon,
  );
}
