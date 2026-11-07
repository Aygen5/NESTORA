import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/nestora_button.dart';
import '../../../../core/widgets/nestora_logo.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback? onGetStarted;
  final VoidCallback? onLogin;

  const WelcomePage({
    super.key,
    this.onGetStarted,
    this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : AppColors.lightScaffoldBackground, // #F4F3EC Neutral Pearl
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Minimal Top Bar / Brand Identifier
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSecondarySurface
                                  : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0C000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: NestoraLogo(size: 32),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Nestora',
                            style: AppTypography.pageTitle(
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primaryDark,
                            ).copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkPrimaryContainer
                              : AppColors.secondaryContainer.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.eco_rounded,
                              size: 16,
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'YAŞAM ALANI',
                              style: AppTypography.badge(
                                color: isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.primary,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Visual Hero Container (Exact Stitch Watercolor Villa + Micro Ambience Pill)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: isDark
                          ? AppColors.darkCardBackground
                          : Colors.white,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : const Color(0xFFE6EAE4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 10,
                          child: Image.asset(
                            'assets/screens/watercolor_villa.png',
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: isDark
                                    ? AppColors.darkSecondarySurface
                                    : const Color(0xFFEAF0E6),
                                child: const Center(
                                  child: Icon(
                                    Icons.villa_rounded,
                                    size: 64,
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Soft organic gradient blend
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.25),
                                ],
                                stops: const [0.65, 1.0],
                              ),
                            ),
                          ),
                        ),

                        // Micro Ambience Indicator Badge (Pinned at bottom of card)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xE61C221D)
                                  : const Color(0xF2FFFFFF),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x18000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 9,
                                      height: 9,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF344638),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Bağlı Ekosistem',
                                      style: AppTypography.badge(
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.textPrimary,
                                      ).copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.other_houses_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '24°C • Dengeli',
                                      style: AppTypography.badge(
                                        color: isDark
                                            ? AppColors.darkPrimary
                                            : AppColors.primary,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Headline & Description
                  Text(
                    'Evinin dijital dünyasına hoş geldin.',
                    style: AppTypography.pageTitle(
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E3023),
                    ).copyWith(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      height: 1.22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Evinin odalarını ve akıllı cihazlarını tek bir yerden kolayca yönet. Huzurlu, sürdürülebilir ve kesintisiz akıllı ev deneyimi.',
                    style: AppTypography.bodyText(
                      color: isDark ? AppColors.darkTextSecondary : const Color(0xFF586156),
                    ).copyWith(
                      fontSize: 14.5,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Key Benefit Mini Pills (2 columns)
                  Row(
                    children: [
                      // Benefit 1: Doğal Uyum
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSecondarySurface
                                : const Color(0xFFEFF5EC),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkCardBackground
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(
                                  Icons.energy_savings_leaf_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Doğal Uyum',
                                      style: AppTypography.badge(
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.textPrimary,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      '%28 Tasarruf',
                                      style: AppTypography.description(
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.textSecondary,
                                      ).copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Benefit 2: Güvenli Alan
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSecondarySurface
                                : const Color(0xFFEFF5EC),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkCardBackground
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(
                                  Icons.verified_user_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Güvenli Alan',
                                      style: AppTypography.badge(
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.textPrimary,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      'Aktif Koruma',
                                      style: AppTypography.description(
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.textSecondary,
                                      ).copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Action Controls
                  NestoraButton(
                    text: 'Hemen Başla',
                    trailingIcon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      if (onGetStarted != null) {
                        onGetStarted!.call();
                      } else {
                        try {
                          context.go(AppRoutePaths.dashboard);
                        } catch (_) {}
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  NestoraButton(
                    text: 'Zaten hesabın var mı? Giriş Yap',
                    variant: NestoraButtonVariant.secondary,
                    onPressed: () {
                      if (onLogin != null) {
                        onLogin!.call();
                      } else {
                        try {
                          context.go(AppRoutePaths.login);
                        } catch (_) {}
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
