import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
import '../widgets/password_validator_widget.dart';

/// Screen allowing new users to create an account with full-name, email,
/// password complexity verification, and automatic Firestore profile setup.
class RegisterPage extends StatefulWidget {
  final VoidCallback? onRegisterSuccess;
  final VoidCallback? onNavigateToLogin;
  final AuthCubit? authCubit;

  const RegisterPage({
    super.key,
    this.onRegisterSuccess,
    this.onNavigateToLogin,
    this.authCubit,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final AuthCubit _cubit;
  late final bool _ownsCubit;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = true;

  PasswordValidationResult _validationResult =
      PasswordValidationResult.evaluate('');

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

    _passwordController.addListener(_onPasswordChanged);
    _passwordConfirmController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {
      _validationResult = PasswordValidationResult.evaluate(
        _passwordController.text,
        _passwordConfirmController.text,
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    if (_ownsCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  void _handleRegister() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final passwordConfirm = _passwordConfirmController.text;

    if (name.isEmpty) {
      NestoraSnackbar.showError(
        context,
        message: 'Lütfen adınızı ve soyadınızı giriniz.',
      );
      return;
    }

    if (email.isEmpty || !AppConstants.emailRegex.hasMatch(email)) {
      NestoraSnackbar.showError(
        context,
        message: 'Lütfen geçerli bir e-posta adresi giriniz.',
      );
      return;
    }

    if (!_validationResult.hasMin8Chars) {
      NestoraSnackbar.showError(
        context,
        message: 'Şifreniz en az 8 karakter uzunluğunda olmalıdır.',
      );
      return;
    }

    if (!_validationResult.hasUppercase) {
      NestoraSnackbar.showError(
        context,
        message: 'Şifreniz en az bir büyük harf içermelidir.',
      );
      return;
    }

    if (!_validationResult.hasNumber) {
      NestoraSnackbar.showError(
        context,
        message: 'Şifreniz en az bir rakam içermelidir.',
      );
      return;
    }

    if (!_validationResult.hasSpecialChar) {
      NestoraSnackbar.showError(
        context,
        message: 'Şifreniz en az bir özel karakter (!@#\$% vb.) içermelidir.',
      );
      return;
    }

    if (!_validationResult.isMatching) {
      NestoraSnackbar.showError(
        context,
        message: 'Girdiğiniz şifreler eşleşmiyor.',
      );
      return;
    }

    if (!_termsAccepted) {
      NestoraSnackbar.showError(
        context,
        message: 'Lütfen Kullanım Koşulları\'nı onaylayınız.',
      );
      return;
    }

    _cubit.signUpWithEmail(
      email: email,
      password: password,
      passwordConfirm: passwordConfirm,
      displayName: name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasEnteredPassword = _passwordController.text.isNotEmpty;
    final passwordsMatch = _passwordController.text.isNotEmpty &&
        _passwordController.text == _passwordConfirmController.text;

    return BlocProvider<AuthCubit>.value(
      value: _cubit,
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            NestoraSnackbar.showError(context, message: state.message);
          } else if (state is Authenticated) {
            NestoraSnackbar.showSuccess(
              context,
              message: 'Hesabınız oluşturuldu. Hoş geldiniz!',
            );
            if (widget.onRegisterSuccess != null) {
              widget.onRegisterSuccess!.call();
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
            resizeToAvoidBottomInset: true,
            backgroundColor: isDark
                ? AppColors.darkScaffoldBackground
                : AppColors.lightScaffoldBackground,
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () {
                                if (widget.onNavigateToLogin != null) {
                                  widget.onNavigateToLogin!.call();
                                } else if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                } else {
                                  try {
                                    context.go(AppRoutePaths.login);
                                  } catch (_) {}
                                }
                              },
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                              ),
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primary,
                            ),
                            Row(
                              children: [
                                const NestoraLogo(size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  'Nestora',
                                  style: AppTypography.headlineSm(
                                    color: isDark
                                        ? AppColors.darkPrimary
                                        : AppColors.primary,
                                  ).copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Editorial Headline Section
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Container(
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
                                  'DOĞAL AKILLI YAŞAM',
                                  style: AppTypography.labelSm(
                                    color: isDark
                                        ? AppColors.darkPrimary
                                        : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Aramıza Katıl',
                          style: AppTypography.headlineLg(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.primary,
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nestora ile evini yönetmeye başla.',
                          style: AppTypography.bodyMd(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Full Name Field
                        NestoraInput(
                          label: 'Ad Soyad',
                          hintText: 'Adınız Soyadınız',
                          controller: _nameController,
                          prefixIcon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 14),

                        // Email Field
                        NestoraInput(
                          label: 'E-posta',
                          hintText: 'ornek@nestora.com',
                          controller: _emailController,
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),

                        // Password Field
                        NestoraInput(
                          label: 'Şifre',
                          hintText: '••••••••',
                          controller: _passwordController,
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          isSuccess: _validationResult.isStrong,
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

                        // Live Password Validation Rules
                        if (hasEnteredPassword) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSecondarySurface
                                  : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: PasswordValidatorWidget(
                              result: _validationResult,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // Password Repeat Field
                        NestoraInput(
                          label: 'Şifre Tekrar',
                          hintText: '••••••••',
                          controller: _passwordConfirmController,
                          prefixIcon: Icons.verified_user_outlined,
                          obscureText: _obscureConfirmPassword,
                          isSuccess: passwordsMatch,
                          suffixWidget: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              );
                            },
                          ),
                        ),

                        if (_passwordConfirmController.text.isNotEmpty &&
                            !passwordsMatch) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              'Şifreler eşleşmiyor',
                              style:
                                  AppTypography.bodySm(color: AppColors.error),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Terms and Eco Commitment Note
                        GestureDetector(
                          onTap: () =>
                              setState(() => _termsAccepted = !_termsAccepted),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _termsAccepted,
                                  onChanged: (val) => setState(
                                    () => _termsAccepted = val ?? false,
                                  ),
                                  activeColor: AppColors.primaryContainer,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Kullanım Koşulları\'nı ve Sürdürülebilir Ev Politikası\'nı onaylıyorum.',
                                  style: AppTypography.bodySm(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Submit Primary Button
                        NestoraButton(
                          text: 'Hesap Oluştur',
                          trailingIcon: Icons.arrow_forward_rounded,
                          isLoading: isLoading,
                          onPressed: _handleRegister,
                        ),
                        const SizedBox(height: 20),

                        // Ambient Micro-feature Pill
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSecondarySurface
                                : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.secondaryFixed,
                                ),
                                child: const Icon(
                                  Icons.energy_savings_leaf_rounded,
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
                                      'Daha Yeşil Bir Ev',
                                      style: AppTypography.labelMd(
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      'Kurulum sonrası %28\'e varan enerji tasarrufu.',
                                      style: AppTypography.bodySm(
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Footer Account Switch Prompt
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Zaten hesabın var mı?',
                              style: AppTypography.bodyMd(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.secondary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                if (widget.onNavigateToLogin != null) {
                                  widget.onNavigateToLogin!.call();
                                } else {
                                  try {
                                    context.go(AppRoutePaths.login);
                                  } catch (_) {}
                                }
                              },
                              child: Text(
                                'Giriş Yap',
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
