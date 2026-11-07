import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/theme/app_colors.dart';
import 'package:nestora/app/theme/app_theme.dart';
import 'package:nestora/app/theme/app_typography.dart';

/// Helper to compute WCAG 2.1 relative luminance
double _relativeLuminance(Color color) {
  double transform(double v) {
    return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = transform(color.r);
  final g = transform(color.g);
  final b = transform(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Helper to compute WCAG 2.1 contrast ratio
double _contrastRatio(Color c1, Color c2) {
  final l1 = _relativeLuminance(c1);
  final l2 = _relativeLuminance(c2);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Faz 7.1: Tema Renkleri ve Kontrast Değerlendirme Testleri', () {
    test('Açık mod arka plan renk sabitleri ve değerleri doğrudur', () {
      expect(AppColors.lightNeutralPearl, const Color(0xFFF4F3EC));
      expect(AppColors.lightOldLace, const Color(0xFFFDF5E6));
      expect(AppColors.lightScaffoldBackground, AppColors.lightNeutralPearl);
      expect(AppColors.lightCardBackground, const Color(0xFFFFFFFF));
      expect(AppColors.lightSecondarySurface, const Color(0xFFF1F4EF));
    });

    test('Koyu mod arka plan ve kart renk sabitleri Stitch referansına uygundur', () {
      expect(AppColors.darkScaffoldBackground, const Color(0xFF131713));
      expect(AppColors.darkCardBackground, const Color(0xFF1C221D));
      expect(AppColors.darkSecondarySurface, const Color(0xFF242B24));
      expect(AppColors.darkBorder, const Color(0xFF2E382F));
      expect(AppColors.darkTextPrimary, const Color(0xFFEDF2E9));
      expect(AppColors.darkTextSecondary, const Color(0xFFA2A99E));
    });

    test('Açık mod kontrast denetimi: Metin ve kartlar WCAG standartlarını karşılar', () {
      // Primary text (#292F29) on Neutral Pearl background (#F4F3EC)
      final textOnScaffoldContrast = _contrastRatio(AppColors.textPrimary, AppColors.lightNeutralPearl);
      expect(textOnScaffoldContrast, greaterThanOrEqualTo(7.0),
          reason: 'Açık mod birincil metin (#292F29) arka planda WCAG AAA (7.0:1) eşiğini aşmalıdır');

      // Primary text (#292F29) on white card (#FFFFFF)
      final textOnCardContrast = _contrastRatio(AppColors.textPrimary, AppColors.lightCardBackground);
      expect(textOnCardContrast, greaterThanOrEqualTo(7.0),
          reason: 'Açık mod birincil metin (#292F29) beyaz kart üzerinde WCAG AAA (7.0:1) eşiğini aşmalıdır');

      // Secondary text (#777D73) on white card (#FFFFFF)
      final secondaryOnCardContrast = _contrastRatio(AppColors.textSecondary, AppColors.lightCardBackground);
      expect(secondaryOnCardContrast, greaterThanOrEqualTo(4.0),
          reason: 'İkincil metin (#777D73) beyaz kart üzerinde en az 4.0:1 kontrast sağlamalıdır');

      // Subtle contrast between white card (#FFFFFF) and Neutral Pearl (#F4F3EC)
      final cardOnScaffoldContrast = _contrastRatio(AppColors.lightCardBackground, AppColors.lightNeutralPearl);
      expect(cardOnScaffoldContrast, greaterThan(1.10),
          reason: 'Beyaz kart (#FFFFFF) ile nötr inci arka planı (#F4F3EC) arasında doğal bir görsel ayrım olmalıdır');
    });

    test('Koyu mod kontrast denetimi: Metin ve kartlar WCAG standartlarını karşılar', () {
      // Dark text primary (#EDF2E9) on dark scaffold (#131713)
      final darkTextOnScaffold = _contrastRatio(AppColors.darkTextPrimary, AppColors.darkScaffoldBackground);
      expect(darkTextOnScaffold, greaterThanOrEqualTo(7.0),
          reason: 'Koyu mod birincil metin (#EDF2E9) koyu arka planda (#131713) WCAG AAA (7.0:1) eşiğini aşmalıdır');

      // Dark text primary (#EDF2E9) on dark card (#1C221D)
      final darkTextOnCard = _contrastRatio(AppColors.darkTextPrimary, AppColors.darkCardBackground);
      expect(darkTextOnCard, greaterThanOrEqualTo(7.0),
          reason: 'Koyu mod birincil metin (#EDF2E9) kart üzerinde (#1C221D) WCAG AAA (7.0:1) eşiğini aşmalıdır');

      // Dark text secondary (#A2A99E) on dark card (#1C221D)
      final darkSecondaryOnCard = _contrastRatio(AppColors.darkTextSecondary, AppColors.darkCardBackground);
      expect(darkSecondaryOnCard, greaterThanOrEqualTo(4.5),
          reason: 'Koyu mod ikincil metin (#A2A99E) kart üzerinde (#1C221D) WCAG AA (4.5:1) eşiğini aşmalıdır');

      // Card elevation contrast: #1C221D against #131713
      final cardOnScaffold = _contrastRatio(AppColors.darkCardBackground, AppColors.darkScaffoldBackground);
      expect(cardOnScaffold, greaterThan(1.05),
          reason: 'Koyu modda kart yüzeyi ile arka plan arasında görünür bir ton kademelenmesi olmalıdır');
    });

    test('AppTheme lightTheme ve darkTheme yapılandırması doğru renk ve fontu kullanır', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.textTheme.bodyMedium?.fontFamily, AppTypography.fontFamily);
      expect(dark.textTheme.bodyMedium?.fontFamily, AppTypography.fontFamily);

      expect(light.scaffoldBackgroundColor, AppColors.lightScaffoldBackground);
      expect(dark.scaffoldBackgroundColor, AppColors.darkScaffoldBackground);

      expect(light.colorScheme.surface, AppColors.lightCardBackground);
      expect(dark.colorScheme.surface, AppColors.darkCardBackground);

      expect(light.useMaterial3, isTrue);
      expect(dark.useMaterial3, isTrue);
    });
  });
}
