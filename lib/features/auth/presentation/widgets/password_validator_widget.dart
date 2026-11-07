import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

class PasswordValidationResult {
  final bool hasMin8Chars;
  final bool hasUppercase;
  final bool hasNumber;
  final bool hasSpecialChar;
  final bool isMatching;

  const PasswordValidationResult({
    required this.hasMin8Chars,
    required this.hasUppercase,
    required this.hasNumber,
    required this.hasSpecialChar,
    required this.isMatching,
  });

  bool get isStrong =>
      hasMin8Chars && hasUppercase && hasNumber && hasSpecialChar;

  static PasswordValidationResult evaluate(String password, [String repeat = '']) {
    final hasMin8 = password.length >= 8;
    final hasUpper = RegExp(r'[A-ZÇĞİÖŞÜ]').hasMatch(password);
    final hasNum = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\\/\[\]~`]').hasMatch(password);
    final isMatch = repeat.isNotEmpty && password == repeat;

    return PasswordValidationResult(
      hasMin8Chars: hasMin8,
      hasUppercase: hasUpper,
      hasNumber: hasNum,
      hasSpecialChar: hasSpecial,
      isMatching: isMatch,
    );
  }
}

class PasswordValidatorWidget extends StatelessWidget {
  final PasswordValidationResult result;
  final bool showIfEmpty;

  const PasswordValidatorWidget({
    super.key,
    required this.result,
    this.showIfEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.isStrong) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.secondaryFixed,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Güçlü şifre',
                  style: AppTypography.labelSm(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
        _RuleRow(
          label: 'En az 8 karakter',
          isMet: result.hasMin8Chars,
        ),
        const SizedBox(height: 4),
        _RuleRow(
          label: 'En az bir büyük harf',
          isMet: result.hasUppercase,
        ),
        const SizedBox(height: 4),
        _RuleRow(
          label: 'En az bir rakam',
          isMet: result.hasNumber,
        ),
        const SizedBox(height: 4),
        _RuleRow(
          label: 'En az bir özel karakter',
          isMet: result.hasSpecialChar,
        ),
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  final String label;
  final bool isMet;

  const _RuleRow({
    required this.label,
    required this.isMet,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final inactiveColor = AppColors.error.withValues(alpha: 0.7);

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 250),
      style: AppTypography.bodySm(
        color: isMet ? activeColor : inactiveColor,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMet
                  ? AppColors.secondaryFixed
                  : AppColors.errorContainer.withValues(alpha: 0.5),
            ),
            child: Icon(
              isMet ? Icons.check_rounded : Icons.circle,
              size: isMet ? 12 : 5,
              color: isMet ? activeColor : inactiveColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

