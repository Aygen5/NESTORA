import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/nestora_button.dart';
import '../../../../core/widgets/nestora_input.dart';

class ForgotPasswordPage extends StatefulWidget {
  final VoidCallback? onBackToLogin;

  const ForgotPasswordPage({super.key, this.onBackToLogin});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController(
    text: 'aygenyildirim27@gmail.com',
  );

  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendResetLink() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : AppColors.lightScaffoldBackground, // Pure #FFFFFF
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              // Top Bar
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onBackToLogin ?? () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Şifre Sıfırlama',
                    style: AppTypography.headlineSm(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Visual Accent / Natural Warm Framing Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSecondarySurface
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondaryFixed,
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_rounded,
                        size: 26,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HESAP GÜVENLİĞİ',
                            style: AppTypography.labelSm(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Erişimini Kolayca Geri Kazan',
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
              ),
              const SizedBox(height: 24),

              // Editorial Headline
              Text(
                'Şifreni mi unuttun?',
                style: AppTypography.headlineLg(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.primary,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'E-posta adresini gir. Şifreni yenilemen için sana bir bağlantı gönderelim.',
                style: AppTypography.bodyMd(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Email Input Field
              NestoraInput(
                label: 'E-posta',
                hintText: 'aygen@example.com',
                controller: _emailController,
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),

              // Action Button
              NestoraButton(
                text: _isSuccess
                    ? 'Bağlantı İletildi'
                    : 'Sıfırlama Bağlantısı Gönder',
                trailingIcon:
                    _isSuccess ? Icons.done_rounded : Icons.arrow_forward_rounded,
                isLoading: _isLoading,
                onPressed: _handleSendResetLink,
              ),

              // Success Notification Card
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _isSuccess
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(height: 0),
                secondChild: Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkPrimaryContainer
                        : AppColors.secondaryFixed,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryContainer,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'E-posta gönderildi.',
                              style: AppTypography.headlineSm(
                                color: isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gelen kutunu kontrol et. Sıfırlama talimatları ${_emailController.text} adresine iletildi.',
                              style: AppTypography.bodyMd(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.onSecondaryFixedVariant,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSecondarySurface
                                    : AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Spam ya da gereksiz klasörünü kontrol etmeyi unutma.',
                                      style: AppTypography.bodySm(
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Return Link
              Center(
                child: TextButton.icon(
                  onPressed: widget.onBackToLogin ?? () => Navigator.maybePop(context),
                  icon: const Icon(Icons.keyboard_backspace_rounded, size: 20),
                  label: Text(
                    'Giriş Ekranına Dön',
                    style: AppTypography.labelLg(
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Brand Note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.eco_rounded,
                    size: 14,
                    color: AppColors.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Nestora Akıllı Yaşam Asistanı',
                    style: AppTypography.labelSm(color: AppColors.outline),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    ),
  ),
);
}
}

