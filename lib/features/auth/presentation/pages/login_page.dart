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
import '../../../../core/widgets/nestora_logo.dart';
import '../../../../core/widgets/nestora_snackbar.dart';
import '../../data/repositories/fallback_auth_repository.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Screen allowing existing users to authenticate with email & password,
/// toggle "Remember Me" preferences, or trigger Demo login.
class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onNavigateToRegister;
  final VoidCallback? onNavigateToForgotPassword;
  final AuthCubit? authCubit;

  const LoginPage({
    super.key,
    this.onLoginSuccess,
    this.onNavigateToRegister,
    this.onNavigateToForgotPassword,
    this.authCubit,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final AuthCubit _cubit;
  late final bool _ownsCubit;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _showDemoFeedback = false;

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

    _loadRememberedPreferences();
  }

  void _loadRememberedPreferences() {
    if (sl.isRegistered<SharedPreferences>()) {
      final prefs = sl<SharedPreferences>();
      final isRemembered =
          prefs.getBool(AppConstants.prefRememberMe) ?? false;
      final savedEmail =
          prefs.getString(AppConstants.prefLastUserEmail) ?? '';

      setState(() {
        _rememberMe = isRemembered;
        if (isRemembered && savedEmail.isNotEmpty) {
          _emailController.text = savedEmail;
        }
      });
    }
  }

  void _persistRememberMe() {
    if (sl.isRegistered<SharedPreferences>()) {
      final prefs = sl<SharedPreferences>();
      if (_rememberMe) {
        prefs.setBool(AppConstants.prefRememberMe, true);
        prefs.setString(
          AppConstants.prefLastUserEmail,
          _emailController.text.trim(),
        );
      } else {
        prefs.setBool(AppConstants.prefRememberMe, false);
        prefs.remove(AppConstants.prefLastUserEmail);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    if (_ownsCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

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

    if (password.isEmpty) {
      NestoraSnackbar.showError(
        context,
        message: 'Lütfen şifrenizi giriniz.',
      );
      return;
    }

    _cubit.signInWithEmail(email: email, password: password);
  }

  void _handleDemoLogin() {
    setState(() => _showDemoFeedback = true);
    _cubit.signInDemo();
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
          } else if (state is Authenticated) {
            _persistRememberMe();
            if (widget.onLoginSuccess != null) {
              widget.onLoginSuccess!.call();
            } else {
              if (context.mounted) {
                try {
                  context.go(AppRoutePaths.dashboard);
                } catch (_) {}
              }
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

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
                                  horizontal: 12,
                                  vertical: 4,
                                ),
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
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border,
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                          hintText: 'ornek@nestora.com',
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
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Remember Me & Forgot Password Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (val) {
                                      setState(
                                        () => _rememberMe = val ?? false,
                                      );
                                    },
                                    activeColor: AppColors.primaryContainer,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(
                                      () => _rememberMe = !_rememberMe,
                                    );
                                  },
                                  child: Text(
                                    'Beni Hatırla',
                                    style: AppTypography.bodySm(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                if (widget.onNavigateToForgotPassword !=
                                    null) {
                                  widget.onNavigateToForgotPassword!.call();
                                } else {
                                  try {
                                    context.go(AppRoutePaths.forgotPassword);
                                  } catch (_) {}
                                }
                              },
                              child: Text(
                                'Şifremi Unuttum?',
                                style: AppTypography.labelMd(
                                  color: isDark
                                      ? AppColors.darkPrimary
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Login Button
                        NestoraButton(
                          text: 'Giriş Yap',
                          trailingIcon: Icons.arrow_forward_rounded,
                          isLoading: isLoading,
                          onPressed: _handleLogin,
                        ),
                        const SizedBox(height: 10),

                        // Fast Demo Button
                        NestoraButton(
                          text: 'Hızlı Demo ile Giriş Yap',
                          leadingIcon: Icons.bolt_rounded,
                          variant: NestoraButtonVariant.secondary,
                          isLoading: isLoading,
                          onPressed: _handleDemoLogin,
                        ),

                        // Demo Feedback Banner
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _showDemoFeedback ? 1.0 : 0.0,
                          child: Container(
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
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
                                  'Demo profili hazırlanıyor...',
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
                              onPressed: () {
                                if (widget.onNavigateToRegister != null) {
                                  widget.onNavigateToRegister!.call();
                                } else {
                                  try {
                                    context.go(AppRoutePaths.register);
                                  } catch (_) {}
                                }
                              },
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
        },
      ),
    );
  }
}
