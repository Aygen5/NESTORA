import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/nestora_button.dart';
import '../../../../core/widgets/nestora_input.dart';
import '../../../../core/widgets/nestora_logo.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onNavigateToRegister;
  final VoidCallback? onNavigateToForgotPassword;

  const LoginPage({
    super.key,
    this.onLoginSuccess,
    this.onNavigateToRegister,
    this.onNavigateToForgotPassword,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController(
    text: 'aygenyildirim27@gmail.com',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'Nestora2026*',
  );

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showDemoFeedback = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onLoginSuccess?.call();
      }
    });
  }

  void _fillDemo() {
    setState(() {
      _emailController.text = 'aygenyildirim27@gmail.com';
      _passwordController.text = 'Nestora2026*';
      _showDemoFeedback = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showDemoFeedback = false);
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
              const SizedBox(height: 12),
              // Brand Emblem and Welcoming Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSecondarySurface
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const NestoraLogo(size: 48),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPrimaryContainer
                            : AppColors.secondaryFixed,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.eco_rounded,
                            size: 14,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Akıllı ve Huzurlu Yaşam',
                            style: AppTypography.labelSm(
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.onSecondaryFixed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tekrar hoş geldin!',
                      style: AppTypography.headlineLg(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.primary,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Evinin kontrolü ve dengesi seni bekliyor.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMd(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Ambient Micro Insight Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSecondarySurface
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCardBackground
                            : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.schedule_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Durum Özeti',
                            style: AppTypography.labelSm(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Salon ve 3 cihaz bekleme modunda',
                            style: AppTypography.bodySm(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Email Input
              NestoraInput(
                label: 'E-posta',
                hintText: 'aygen@example.com',
                controller: _emailController,
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              // Password Input
              NestoraInput(
                label: 'Şifre',
                hintText: '••••••••',
                controller: _passwordController,
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixWidget: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              const SizedBox(height: 6),

              // Forgot Password Link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onNavigateToForgotPassword,
                  child: Text(
                    'Şifremi Unuttum?',
                    style: AppTypography.labelMd(
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Login Button
              NestoraButton(
                text: 'Giriş Yap',
                trailingIcon: Icons.arrow_forward_rounded,
                isLoading: _isLoading,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 10),

              // Fast Demo Button
              NestoraButton(
                text: 'Hızlı Demo ile Giriş Yap',
                leadingIcon: Icons.bolt_rounded,
                variant: NestoraButtonVariant.secondary,
                onPressed: _fillDemo,
              ),

              // Demo Feedback Banner
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showDemoFeedback ? 1.0 : 0.0,
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryFixed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aygen Yıldırım profili yüklendi (Aygen\'in Evi)',
                        style: AppTypography.labelSm(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Peaceful Natural Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSecondarySurface
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.eco_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'DOĞA DOSTU OTOMASYON',
                          style: AppTypography.labelSm(
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nestora, evinizdeki iklimi ve enerjiyi günün döngüsüne göre hassasiyetle ayarlar.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySm(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Footer Link: Register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hesabın yok mu?',
                    style: AppTypography.bodyMd(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.secondary,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onNavigateToRegister,
                    child: Text(
                      'Kayıt Ol',
                      style: AppTypography.labelLg(
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
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

