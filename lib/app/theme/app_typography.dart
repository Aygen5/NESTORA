import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Nestora Typography System
/// Powered exclusively by Manrope as requested by User & updated in docs/design-system.md
/// Modern, premium, balanced and controlled scale.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Manrope';

  // 1. Sayfa Başlığı (24–28 px, Bold 700)
  static TextStyle pageTitle({Color? color}) => GoogleFonts.manrope(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.02 * 26,
        color: color,
      );

  // 2. Bölüm Başlığı (18–20 px, SemiBold 600)
  static TextStyle sectionTitle({Color? color}) => GoogleFonts.manrope(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        height: 1.30,
        letterSpacing: -0.01 * 19,
        color: color,
      );

  // 3. Kart Başlığı (15–16 px, SemiBold 600)
  static TextStyle cardTitle({Color? color}) => GoogleFonts.manrope(
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: color,
      );

  // 4. Normal Metin (14 px, Regular 400)
  static TextStyle bodyText({Color? color}) => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: color,
      );

  // 5. Açıklama (12–13 px, Regular 400)
  static TextStyle description({Color? color}) => GoogleFonts.manrope(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        height: 1.40,
        color: color,
      );

  // 6. Küçük Etiket / Rozet (11–12 px, Medium 500)
  static TextStyle badge({Color? color}) => GoogleFonts.manrope(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        height: 1.30,
        letterSpacing: 0.02 * 11.5,
        color: color,
      );

  // 7. Buton Metni (14–15 px, SemiBold 600)
  static TextStyle buttonText({Color? color}) => GoogleFonts.manrope(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        height: 1.20,
        letterSpacing: 0.01 * 14.5,
        color: color,
      );

  // === Backward-compatible Method Signatures ===
  static TextStyle headlineXl({Color? color}) => GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.02 * 28,
        color: color,
      );

  static TextStyle headlineLg({Color? color}) => pageTitle(color: color);

  static TextStyle headlineMd({Color? color}) => sectionTitle(color: color);

  static TextStyle headlineSm({Color? color}) => cardTitle(color: color);

  static TextStyle bodyLg({Color? color}) => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: color,
      );

  static TextStyle bodyMd({Color? color}) => bodyText(color: color);

  static TextStyle bodySm({Color? color}) => description(color: color);

  static TextStyle labelLg({Color? color}) => buttonText(color: color);

  static TextStyle labelMd({Color? color}) => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.30,
        color: color,
      );

  static TextStyle labelSm({Color? color}) => badge(color: color);

  // === Static Getters ===
  static TextStyle get displayLarge => GoogleFonts.manrope(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 38,
      );
  static TextStyle get headlineLarge => pageTitle();
  static TextStyle get headlineMedium => sectionTitle();
  static TextStyle get headlineSmall => cardTitle();
  static TextStyle get bodyLarge => bodyLg();
  static TextStyle get bodyMedium => bodyText();
  static TextStyle get bodySmall => description();
  static TextStyle get labelLarge => buttonText();
  static TextStyle get labelMedium => labelMd();
  static TextStyle get labelSmall => badge();
  static TextStyle get caption => badge();
}
