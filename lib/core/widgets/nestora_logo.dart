import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/app_router.dart';
import '../../app/theme/app_colors.dart';

/// Custom, unique Nestora Logo Emblem & Brand Widget.
/// Displays the official circular Nestora Logo asset with transparent corners,
/// guaranteed circular clipping ([ClipOval]), ambient aura glow, and optional
/// interactive navigation to the home dashboard on tap.
class NestoraLogo extends StatelessWidget {
  final double size;
  final double glowProgress; // 0.0 to 1.0
  final bool showGlow;
  final Color? primaryColor;
  final Color? glowColor;
  final bool enableNavigation;
  final VoidCallback? onTap;
  final String? tooltip;

  const NestoraLogo({
    super.key,
    this.size = 48,
    this.glowProgress = 0.0,
    this.showGlow = false,
    this.primaryColor,
    this.glowColor,
    this.enableNavigation = false,
    this.onTap,
    this.tooltip,
  });

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    if (enableNavigation) {
      try {
        context.goToDashboard();
      } catch (_) {
        try {
          context.go(AppRoutePaths.dashboard);
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final houseColor = primaryColor ??
        (isDark ? AppColors.darkPrimary : AppColors.primaryContainer);
    final lightColor = glowColor ?? AppColors.tertiaryFixedDim;
    final isClickable = enableNavigation || onTap != null;

    final Widget emblem = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient Halo Glow
          if (showGlow || glowProgress > 0.05)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: (showGlow ? 0.85 : glowProgress).clamp(0.0, 1.0),
              child: Container(
                width: size * (1.2 + 0.3 * glowProgress),
                height: size * (1.2 + 0.3 * glowProgress),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      lightColor.withValues(
                        alpha: 0.60 * (showGlow ? 1.0 : glowProgress),
                      ),
                      lightColor.withValues(
                        alpha: 0.20 * (showGlow ? 1.0 : glowProgress),
                      ),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

          // Official Circular Nestora Logo with strict ClipOval and vector fallback
          ClipOval(
            child: Image.asset(
              'assets/screens/nestora_logo.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => CustomPaint(
                size: Size(size, size),
                painter: _NestoraEmblemPainter(
                  houseColor: houseColor,
                  lightColor: lightColor,
                  glowIntensity: glowProgress,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isClickable) {
      final effectiveTooltip = tooltip ?? 'Ana Sayfa';
      return Semantics(
        button: true,
        label: effectiveTooltip,
        child: Tooltip(
          message: effectiveTooltip,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _handleTap(context),
              child: emblem,
            ),
          ),
        ),
      );
    }

    return emblem;
  }
}

class _NestoraEmblemPainter extends CustomPainter {
  final Color houseColor;
  final Color lightColor;
  final double glowIntensity;

  _NestoraEmblemPainter({
    required this.houseColor,
    required this.lightColor,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw circular light sage emblem background
    final bgPaint = Paint()
      ..color = const Color(0xFFDCE6DD)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(w / 2, h / 2), w / 2, bgPaint);

    // Draw circular ring
    final ringPaint = Paint()
      ..color = const Color(0xFFC0D2C2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, w * 0.03)
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.46, ringPaint);

    // Draw Modern Rounded Architectural House Silhouette
    final housePaint = Paint()
      ..color = houseColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();
    final left = w * 0.22;
    final right = w * 0.78;
    final bottom = h * 0.78;
    final eavesY = h * 0.44;
    final peakX = w * 0.50;
    final peakY = h * 0.20;
    final r = w * 0.05;

    path.moveTo(left, bottom - r);
    path.quadraticBezierTo(left, bottom, left + r, bottom);
    path.lineTo(right - r, bottom);
    path.quadraticBezierTo(right, bottom, right, bottom - r);
    path.lineTo(right, eavesY + r);
    path.quadraticBezierTo(right, eavesY, right - r * 0.5, eavesY - r * 0.3);
    path.lineTo(peakX + r * 0.7, peakY + r * 0.5);
    path.quadraticBezierTo(peakX, peakY, peakX - r * 0.7, peakY + r * 0.5);
    path.lineTo(left + r * 0.5, eavesY - r * 0.3);
    path.quadraticBezierTo(left, eavesY, left, eavesY + r);
    path.close();

    canvas.drawPath(path, housePaint);

    // Eco Leaf Accent on the Roof Slope
    final leafPaint = Paint()
      ..color = AppColors.secondaryFixed
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final leafPath = Path();
    leafPath.moveTo(peakX + w * 0.06, peakY + h * 0.02);
    leafPath.cubicTo(
      peakX + w * 0.24,
      peakY - h * 0.06,
      peakX + w * 0.28,
      peakY + h * 0.10,
      peakX + w * 0.10,
      peakY + h * 0.08,
    );
    leafPath.cubicTo(
      peakX + w * 0.07,
      peakY + h * 0.05,
      peakX + w * 0.06,
      peakY + h * 0.03,
      peakX + w * 0.06,
      peakY + h * 0.02,
    );
    leafPath.close();
    canvas.drawPath(leafPath, leafPaint);

    // Center Radiant Light Beacon
    final beaconCenter = Offset(w * 0.50, h * 0.56);
    final beaconRadius = w * 0.13;

    final beaconGlowPaint = Paint()
      ..color = lightColor.withValues(alpha: 0.35 + 0.45 * glowIntensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.06);
    canvas.drawCircle(beaconCenter, beaconRadius * 1.3, beaconGlowPaint);

    final portalPaint = Paint()
      ..color = lightColor
      ..style = PaintingStyle.fill;

    final portalPath = Path();
    final pLeft = beaconCenter.dx - beaconRadius * 0.85;
    final pRight = beaconCenter.dx + beaconRadius * 0.85;
    final pBottom = beaconCenter.dy + beaconRadius * 1.1;
    final pTop = beaconCenter.dy - beaconRadius * 0.85;
    final pR = beaconRadius * 0.85;

    portalPath.moveTo(pLeft, pBottom);
    portalPath.lineTo(pLeft, pTop + pR);
    portalPath.arcToPoint(
      Offset(pRight, pTop + pR),
      radius: Radius.circular(pR),
      clockwise: true,
    );
    portalPath.lineTo(pRight, pBottom);
    portalPath.close();

    canvas.drawPath(portalPath, portalPaint);

    final rayPaint = Paint()
      ..color = houseColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * 0.025)
      ..strokeCap = StrokeCap.round;

    final rayLen = beaconRadius * 0.55;
    canvas.drawLine(
      Offset(beaconCenter.dx - rayLen, beaconCenter.dy + w * 0.02),
      Offset(beaconCenter.dx + rayLen, beaconCenter.dy + w * 0.02),
      rayPaint,
    );
    canvas.drawLine(
      Offset(beaconCenter.dx, beaconCenter.dy - rayLen * 0.8 + w * 0.02),
      Offset(beaconCenter.dx, beaconCenter.dy + rayLen * 0.8 + w * 0.02),
      rayPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _NestoraEmblemPainter oldDelegate) {
    return oldDelegate.houseColor != houseColor ||
        oldDelegate.lightColor != lightColor ||
        oldDelegate.glowIntensity != glowIntensity;
  }
}
