import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nestora/app/theme/app_colors.dart';
import 'package:nestora/app/theme/app_theme.dart';
import 'package:nestora/app/theme/app_typography.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Faz 7.2: Manrope Tipografi Skalası Kontrolü Testleri', () {
    test('Font ailesi Manrope olarak tanımlıdır', () {
      expect(AppTypography.fontFamily, 'Manrope');
    });

    test('Sayfa başlığı (pageTitle) 24–28 px aralığında ve Bold (w700) olmalıdır', () {
      final style = AppTypography.pageTitle();
      expect(style.fontSize, inInclusiveRange(24.0, 28.0));
      expect(style.fontWeight, FontWeight.w700);
    });

    test('Bölüm başlığı (sectionTitle) 18–20 px aralığında ve SemiBold (w600) olmalıdır', () {
      final style = AppTypography.sectionTitle();
      expect(style.fontSize, inInclusiveRange(18.0, 20.0));
      expect(style.fontWeight, FontWeight.w600);
    });

    test('Kart başlığı (cardTitle) 15–16 px aralığında ve SemiBold (w600) olmalıdır', () {
      final style = AppTypography.cardTitle();
      expect(style.fontSize, inInclusiveRange(15.0, 16.0));
      expect(style.fontWeight, FontWeight.w600);
    });

    test('Normal metin (bodyText) 14 px ve Regular (w400) olmalıdır', () {
      final style = AppTypography.bodyText();
      expect(style.fontSize, 14.0);
      expect(style.fontWeight, FontWeight.w400);
    });

    test('Açıklama metni (description) 12–13 px aralığında ve Regular (w400) olmalıdır', () {
      final style = AppTypography.description();
      expect(style.fontSize, inInclusiveRange(12.0, 13.0));
      expect(style.fontWeight, FontWeight.w400);
    });

    test('Küçük etiket/rozet (badge) 11–12 px aralığında ve Medium (w500) olmalıdır', () {
      final style = AppTypography.badge();
      expect(style.fontSize, inInclusiveRange(11.0, 12.0));
      expect(style.fontWeight, FontWeight.w500);
    });

    test('Buton metni (buttonText) 14–15 px aralığında ve SemiBold (w600) olmalıdır', () {
      final style = AppTypography.buttonText();
      expect(style.fontSize, inInclusiveRange(14.0, 15.0));
      expect(style.fontWeight, FontWeight.w600);
    });

    test('buildTextTheme eksiksiz TextTheme üretir ve temaya uygulanır', () {
      final textTheme = AppTypography.buildTextTheme(
        textPrimary: AppColors.textPrimary,
        textSecondary: AppColors.textSecondary,
      );

      expect(textTheme.headlineLarge?.fontSize, inInclusiveRange(24.0, 28.0));
      expect(textTheme.headlineMedium?.fontSize, inInclusiveRange(18.0, 20.0));
      expect(textTheme.headlineSmall?.fontSize, inInclusiveRange(15.0, 16.0));
      expect(textTheme.bodyMedium?.fontSize, 14.0);
      expect(textTheme.bodySmall?.fontSize, inInclusiveRange(12.0, 13.0));
      expect(textTheme.labelSmall?.fontSize, inInclusiveRange(11.0, 12.0));

      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.textTheme.headlineLarge?.fontSize, inInclusiveRange(24.0, 28.0));
      expect(dark.textTheme.headlineLarge?.fontSize, inInclusiveRange(24.0, 28.0));
      expect(light.textTheme.bodyMedium?.fontSize, 14.0);
      expect(dark.textTheme.bodyMedium?.fontSize, 14.0);
    });
  });
}
