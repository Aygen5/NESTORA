import 'package:flutter/material.dart';

/// Nestora Design System Colors
/// Defined according to docs/design-system.md & Stitch tokens
class AppColors {
  AppColors._();

  // === LIGHT THEME (Default) ===
  // Primary Scaffold Background: #FDF5E6 – Old Lace (Sıcak, yumuşak inci beyazı)
  static const Color lightScaffoldBackground = Color(0xFFFDF5E6);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightSecondarySurface = Color(0xFFF4EFE6); // Warm Light Cream

  // Brand Palette
  static const Color primary = Color(0xFF344638); // Deep Forest Pine
  static const Color primaryDark = Color(0xFF1E3023);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF344638);
  static const Color onPrimaryContainer = Color(0xFF9FB3A1);
  static const Color primaryFixed = Color(0xFFD3E8D5);
  static const Color onPrimaryFixed = Color(0xFF0E1F13);

  // Secondary (Sage)
  static const Color secondary = Color(0xFF586156);
  static const Color secondaryContainer = Color(0xFFDCE5D7); // Light Sage
  static const Color onSecondaryContainer = Color(0xFF5E675C);
  static const Color secondaryFixed = Color(0xFFDCE5D7);
  static const Color onSecondaryFixed = Color(0xFF161E15);
  static const Color onSecondaryFixedVariant = Color(0xFF41493F);

  // Tertiary (Warm Amber / Clay)
  static const Color tertiary = Color(0xFF3B2811);
  static const Color tertiaryContainer = Color(0xFF533E25);
  static const Color onTertiaryContainer = Color(0xFFC7A98A);
  static const Color tertiaryFixed = Color(0xFFFEDDBB);
  static const Color tertiaryFixedDim = Color(0xFFE1C1A0); // Warm Accent

  // Neutrals & Surfaces
  static const Color textPrimary = Color(0xFF292F29); // Deep Moss Charcoal
  static const Color textSecondary = Color(0xFF777D73); // Soft Herb Gray
  static const Color outline = Color(0xFF737872);
  static const Color outlineVariant = Color(0xFFC3C8C1);
  static const Color border = Color(0xFFE8ECE6); // Soft Mineral Border
  static const Color surfaceTint = Color(0xFF506354);

  // Containers
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF5EC);
  static const Color surfaceContainer = Color(0xFFEAF0E6);
  static const Color surfaceContainerHigh = Color(0xFFE4EAE1);
  static const Color surfaceContainerHighest = Color(0xFFDEE4DB);

  // Error & Status
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color success = Color(0xFF344638);

  // === DARK THEME (Stitch Dark Reference) ===
  static const Color darkScaffoldBackground = Color(0xFF131713);
  static const Color darkCardBackground = Color(0xFF1C221D);
  static const Color darkSecondarySurface = Color(0xFF242B24);
  static const Color darkBorder = Color(0xFF2E382F);

  static const Color darkTextPrimary = Color(0xFFEDF2E9);
  static const Color darkTextSecondary = Color(0xFFA2A99E);
  static const Color darkPrimary = Color(0xFFDCE5D7);
  static const Color darkPrimaryContainer = Color(0xFF2E4032);
  static const Color darkOnPrimaryContainer = Color(0xFFB7CCB9);
  static const Color darkSurfaceContainer = Color(0xFF212822);
  static const Color darkSurfaceContainerLow = Color(0xFF191F1A);
  static const Color darkSurfaceContainerHigh = Color(0xFF2B332C);

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

