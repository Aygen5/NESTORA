import 'package:flutter/material.dart';

/// Nestora Design System Colors
/// Defined according to docs/design-system.md & Stitch tokens
class AppColors {
  AppColors._();

  // === LIGHT THEME (Senaryo B: Modern Kaşmir & Doğal Taş) ===
  /// Sayfa arka planı (#F5F3EF - Sıcak, ferah kaşmir fildişi)
  static const Color lightScaffoldBackground = Color(0xFFF5F3EF);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightSecondarySurface = Color(0xFFEAE6DF); // Doğal taş bej yüzey

  /// Sıcak Fildişi ve Doğal Taş tonları
  static const Color lightNeutralPearl = Color(0xFFF5F3EF);
  static const Color lightOldLace = Color(0xFFFDF5E6);

  // Brand Palette (Vurgu & Butonlar: #1E3023 - Derin Asil Orman Yeşili)
  static const Color primary = Color(0xFF1E3023);
  static const Color primaryDark = Color(0xFF152219);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1E3023);
  static const Color onPrimaryContainer = Color(0xFFD4C3A3); // Sıcak kaşmir bej
  static const Color primaryFixed = Color(0xFFD0DDD2);
  static const Color onPrimaryFixed = Color(0xFF0D1810);

  // Secondary (Metinler: #666666 / Doğal Taş)
  static const Color secondary = Color(0xFF666666);
  static const Color secondaryContainer = Color(0xFFEAE6DF); // Doğal Taş
  static const Color onSecondaryContainer = Color(0xFF1E3023);
  static const Color secondaryFixed = Color(0xFFE2DDD5);
  static const Color onSecondaryFixed = Color(0xFF141D15);
  static const Color onSecondaryFixedVariant = Color(0xFF4A524B);

  // Tertiary (Kaşmir Rozet / Aktiflik: #D4C3A3)
  static const Color tertiary = Color(0xFFD4C3A3);
  static const Color tertiaryContainer = Color(0xFFEFE8DC);
  static const Color onTertiaryContainer = Color(0xFF2C2418);
  static const Color tertiaryFixed = Color(0xFFF2EADC);
  static const Color tertiaryFixedDim = Color(0xFFD4C3A3); // Kaşmir rozet vurgusu
  static const Color kashmirBadge = Color(0xFFD4C3A3);
  static const Color cashmereBadge = Color(0xFFD4C3A3);
  static const Color kashmirBadgeLight = Color(0xFFF0E9DF);

  // Neutrals & Surfaces (Başlıklar: #212121, Metinler: #666666)
  static const Color textPrimary = Color(0xFF212121); // Net Kömür/Siyah Başlık
  static const Color textSecondary = Color(0xFF666666); // Dengeli Gri Metin
  static const Color outline = Color(0xFF7A827B);
  static const Color outlineVariant = Color(0xFFDCD6CC);
  static const Color border = Color(0xFFE2DDD5); // Doğal Taş Zarif Kenarlık
  static const Color surfaceTint = Color(0xFF1E3023);

  // Containers
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF7F5F1);
  static const Color surfaceContainer = Color(0xFFF0ECE5);
  static const Color surfaceContainerHigh = Color(0xFFEAE6DF);
  static const Color surfaceContainerHighest = Color(0xFFE4DFD8);

  // Error & Status
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color success = Color(0xFF1E3023);

  // === DARK THEME (Ferah Grafit & Gece Zarafeti) ===
  static const Color darkScaffoldBackground = Color(0xFF131614); // Zifiri değil, ferah grafit
  static const Color darkCardBackground = Color(0xFF1B201D); // Derin antrasit kart
  static const Color darkSecondarySurface = Color(0xFF242B26);
  static const Color darkBorder = Color(0xFF2F3832);

  static const Color darkTextPrimary = Color(0xFFFFFFFF); // Saf beyaz, yüksek kontrast
  static const Color darkTextSecondary = Color(0xFFB0B7B2); // Okunabilir açık gümüş
  static const Color darkPrimary = Color(0xFFD4C3A3); // Kaşmir altın fildişi
  static const Color darkPrimaryContainer = Color(0xFF253629);
  static const Color darkOnPrimaryContainer = Color(0xFFD4C3A3);
  static const Color darkSurfaceContainer = Color(0xFF202722);
  static const Color darkSurfaceContainerLow = Color(0xFF181E1A);
  static const Color darkSurfaceContainerHigh = Color(0xFF29322B);

  // Soft Ambient Shadows
  static const List<BoxShadow> lightCardShadow = [
    BoxShadow(
      color: Color(0x0A292F29), // faint olive-moss undertone
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Color(0x05292F29),
      blurRadius: 6,
      offset: Offset(0, 2),
      spreadRadius: -1,
    ),
  ];

  static const List<BoxShadow> activeCardShadow = [
    BoxShadow(
      color: Color(0x14344638),
      blurRadius: 28,
      offset: Offset(0, 12),
      spreadRadius: -6,
    ),
  ];
  // Quick Theme Aliases
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color secondaryFixedDim = Color(0xFFC0C9BC);
  static const Color lightScaffold = lightScaffoldBackground;
  static const Color darkBackground = darkScaffoldBackground;
  static const Color lightCard = lightCardBackground;
  static const Color darkCard = darkCardBackground;
  static const Color lightCardSecondary = lightSecondarySurface;
  static const Color darkCardSecondary = darkSecondarySurface;
  static const Color lightBorder = border;
  static const Color lightTextPrimary = textPrimary;
  static const Color lightTextSecondary = textSecondary;
  static const Color warmAmber = Color(0xFFE9C9A8);
  static const List<BoxShadow> cardShadow = lightCardShadow;
  static const List<BoxShadow> subtleShadow = lightCardShadow;
}

