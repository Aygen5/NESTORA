import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/nestora_button.dart';
import '../../../../core/widgets/nestora_input.dart';
import '../../../../core/widgets/nestora_snackbar.dart';
import '../../data/repositories/fallback_auth_repository.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Screen allowing users to request a password reset email via Firebase Authentication.
class ForgotPasswordPage extends StatefulWidget {
  final VoidCallback? onBackToLogin;
  final AuthCubit? authCubit;

  const ForgotPasswordPage({
    super.key,
    this.onBackToLogin,
    this.authCubit,
  });

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final AuthCubit _cubit;
  late final bool _ownsCubit;

  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.authCubit != null) {
      _cubit = widget.authCubit!;
      _ownsCubit = false;
    } else if (sl.isRegistered<AuthCubit>()) {
      _cubit = sl<AuthCubit>();
      _ownsCubit = true;
    } else {
      _cubit = AuthCubit(authRepository: const FallbackAuthRepository());
      _ownsCubit = true;
    }

    _loadInitialEmail();
  }

  void _loadInitialEmail() {
    if (sl.isRegistered<SharedPreferences>()) {
      final prefs = sl<SharedPreferences>();
      final savedEmail = prefs.getString(AppConstants.prefLastUserEmail) ?? '';
      if (savedEmail.isNotEmpty) {
        _emailController.text = savedEmail;
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    if (_ownsCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  void _handleSendResetLink() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      NestoraSnackbar.showError(
        context,
        message: 'Lütfen e-posta adresinizi giriniz.',
      );
      return;
    }

    if (!AppConstants.emailRegex.hasMatch(email)) {
      NestoraSnackbar.showError(
        context,
        message: 'Lütfen geçerli bir e-posta adresi giriniz.',
      );
      return;
    }

    _cubit.sendPasswordReset(email: email);
  }

  void _navigateBack() {
    if (widget.onBackToLogin != null) {
      widget.onBackToLogin!.call();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      try {
        context.go(AppRoutePaths.login);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider<AuthCubit>.value(
      value: _cubit,
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            NestoraSnackbar.showError(context, message: state.message);
          } else if (state is AuthPasswordResetSent) {
            NestoraSnackbar.showSuccess(
              context,
              message:
                  'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.',
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final isSuccess = state is AuthPasswordResetSent;

          return Scaffold(
            backgroundColor: isDark
                ? AppColors.darkScaffoldBackground
                : AppColors.lightScaffoldBackground, // Pure #FFFFFF
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Bar
                        Row(
                          children: [
                            IconButton(
                              onPressed: _navigateBack,
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                              ),
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primary,
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
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border,
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
                          hintText: 'ornek@nestora.com',
                          controller: _emailController,
                          prefixIcon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 18),

                        // Action Button
                        NestoraButton(
                          text: isSuccess
                              ? 'Bağlantı İletildi'
                              : 'Sıfırlama Bağlantısı Gönder',
                          trailingIcon: isSuccess
                              ? Icons.done_rounded
                              : Icons.arrow_forward_rounded,
                          isLoading: isLoading,
                          onPressed: _handleSendResetLink,
                        ),

                        // Success Notification Card
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 300),
                          crossFadeState: isSuccess
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              : AppColors
                                                  .onSecondaryFixedVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.darkSecondarySurface
                                              : AppColors
                                                  .surfaceContainerLowest,
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                                      ? AppColors
                                                          .darkTextSecondary
                                                      : AppColors
                                                          .textSecondary,
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
                            onPressed: _navigateBack,
                            icon: const Icon(
                              Icons.keyboard_backspace_rounded,
                              size: 20,
                            ),
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
                              style: AppTypography.labelSm(
                                color: AppColors.outline,
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
        },
      ),
    );
  }
}
