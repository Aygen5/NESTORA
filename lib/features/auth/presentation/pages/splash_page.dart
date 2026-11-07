import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/nestora_logo.dart';

/// Animated Splash Screen for Nestora.
/// Implements a 2-stage explicit animation choreography:
/// - Stage 1 (0.0 to 0.45): Circular Nestora logo slides down from the top (Y: -1.4 -> 0.0)
///   with a soft bounce ([Curves.easeOutBack]).
/// - Rest Hold (0.45 to 0.70): Logo stays centered with radiant ambient aura for clear brand visibility.
/// - Stage 2 (0.70 to 1.00): Entire screen slides upward out of the screen (Y: 0.0 -> -1.0)
///   with smooth curtain dismissal ([Curves.easeInOutCubic]).
/// Fully respects WCAG AAA Reduced-Motion standards via [MediaQuery.disableAnimations].
class SplashPage extends StatefulWidget {
  final VoidCallback? onFinish;

  const SplashPage({super.key, this.onFinish});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _screenSlideAnimation;
  late Animation<double> _glowAnimation;
  Timer? _fallbackTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // 1. Stage: Logo drops smoothly from top into center with spring/bounce
    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    // Soft fade-in during the initial downward slide
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.30, curve: Curves.easeIn),
      ),
    );

    // Radiant bloom glow pulsing during center hold
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.20, 0.65, curve: Curves.easeInOut),
      ),
    );

    // 2. Stage: Entire screen slides upward out of view
    _screenSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.0),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    // Trigger navigation immediately when choreography finishes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNext();
      }
    });

    _controller.forward();

    // Safety fallback timer ensuring navigation occurs smoothly even in delayed environments
    _fallbackTimer = Timer(const Duration(milliseconds: 2100), () {
      if (mounted && !_hasNavigated) {
        _navigateToNext();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations && !_hasNavigated) {
      _controller.value = 1.0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToNext();
      });
    }
  }

  void _navigateToNext() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    _fallbackTimer?.cancel();

    if (widget.onFinish != null) {
      widget.onFinish!.call();
    } else {
      try {
        context.go(AppRoutePaths.onboarding);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SlideTransition(
        position: _screenSlideAnimation, // Stage 2: Screen slides upward out of view
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: AppColors.darkScaffoldBackground,
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final glow = _glowAnimation.value;
                return FadeTransition(
                  opacity: _logoFadeAnimation,
                  child: SlideTransition(
                    position: _logoSlideAnimation, // Stage 1: Logo slides down from top
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer Ambient Halo Ring
                        Container(
                          width: 360,
                          height: 360,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFDCE6DD).withValues(alpha: 0.28 * glow),
                                AppColors.warmAmber.withValues(alpha: 0.16 * glow),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                          ),
                        ),

                        // Soft Core Bloom Halo
                        Container(
                          width: 270,
                          height: 270,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFB4C8B5).withValues(alpha: 0.38 * glow),
                                blurRadius: 45,
                                spreadRadius: 10,
                              ),
                              BoxShadow(
                                color: AppColors.warmAmber.withValues(alpha: 0.22 * glow),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),

                        // Prominent, Large, Center-Stage Circular Nestora Logo
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const NestoraLogo(
                            size: 220,
                            showGlow: false,
                            enableNavigation: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
