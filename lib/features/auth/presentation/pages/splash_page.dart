import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/nestora_logo.dart';

class SplashPage extends StatefulWidget {
  final VoidCallback? onFinish;

  const SplashPage({super.key, this.onFinish});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _glowAnim;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnim = Tween<double>(begin: 0.60, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.40, curve: Curves.easeIn),
      ),
    );

    _glowAnim = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    // Clean, short presentation (~1.8 seconds)
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        if (widget.onFinish != null) {
          widget.onFinish!.call();
        } else {
          try {
            context.go(AppRoutePaths.onboarding);
          } catch (_) {}
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dark ivory/pine background (#131713)
    return Scaffold(
      backgroundColor: AppColors.darkScaffoldBackground,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final glowVal = _glowAnim.value;
            return FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Soft Ambient Aura
                    Container(
                      width: 360,
                      height: 360,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.warmAmber.withValues(alpha: 0.28 * glowVal),
                            AppColors.primaryFixed.withValues(alpha: 0.12 * glowVal),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),

                    // Core Radiant Bloom Halo
                    Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warmAmber.withValues(alpha: 0.45 * glowVal),
                            blurRadius: 60,
                            spreadRadius: 15,
                          ),
                          BoxShadow(
                            color: const Color(0xFFD3E8D5).withValues(alpha: 0.25 * glowVal),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),

                    // Big, Prominent, Center-Stage Nestora Logo
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF19201A),
                        border: Border.all(
                          color: const Color(0xFF2E3D30),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(28),
                      child: const NestoraLogo(
                        size: 164,
                        showGlow: true,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
