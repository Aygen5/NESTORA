import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback? onStart;
  final VoidCallback? onBack;

  const OnboardingPage({
    super.key,
    this.onStart,
    this.onBack,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  double _dragPosition = 0.0;
  bool _isUnlocked = false;

  void _triggerStart() {
    if (_isUnlocked) return;
    setState(() {
      _isUnlocked = true;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        if (widget.onStart != null) {
          widget.onStart!.call();
        } else {
          try {
            context.go(AppRoutePaths.welcome);
          } catch (_) {}
        }
      }
    });
  }

  void _handleDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_isUnlocked) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _handleDragEnd(DragEndDetails details, double maxDrag) {
    if (_isUnlocked) return;
    if (_dragPosition >= maxDrag * 0.65) {
      setState(() {
        _dragPosition = maxDrag;
      });
      _triggerStart();
    } else {
      setState(() {
        _dragPosition = 0.0;
      });
    }
  }

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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // Floating 3D Smart House Visual Card (Matching User Image 2 & 5)
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 280,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Soft Ambient Background Halo Glow
                          Positioned(
                            top: 20,
                            child: Container(
                              width: 280,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    (isDark ? AppColors.darkPrimary : AppColors.primaryFixed)
                                        .withValues(alpha: 0.35),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Layered Sage Offset Accent Frame
                          Positioned(
                            top: 8,
                            left: 14,
                            right: 0,
                            bottom: 6,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF2E3E31)
                                      : const Color(0xFFC7DBC9),
                                  width: 2.0,
                                ),
                              ),
                            ),
                          ),

                          // Main Floating House Image Card
                          Container(
                            width: double.infinity,
                            height: 260,
                            margin: const EdgeInsets.only(right: 12, bottom: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1B231D) : Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 26,
                                  offset: const Offset(0, 10),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  'assets/screens/modern_smart_house.jpg',
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: isDark ? const Color(0xFF1B231D) : Colors.white,
                                      child: const Center(
                                        child: Icon(
                                          Icons.home_work_rounded,
                                          size: 72,
                                          color: AppColors.primaryContainer,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Soft gradient vignette along the bottom of the photo
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  height: 50,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          (isDark ? const Color(0xFF1B231D) : Colors.white)
                                              .withValues(alpha: 0.35),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Tag: Manage your home / Evinizi Yönetin
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPrimaryContainer.withValues(alpha: 0.5)
                          : const Color(0xFFE4EDE3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Evinizi Yönetin',
                      style: AppTypography.badge(
                        color: isDark ? AppColors.darkOnPrimaryContainer : AppColors.primaryDark,
                      ).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Big Headline: "Evinizi Kolayca\nYönetin"
                  Text(
                    'Evinizi Kolayca\nYönetin',
                    style: AppTypography.pageTitle(
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A261D),
                    ).copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.16,
                      letterSpacing: -0.6,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Highly Legible Description Subtitle
                  Text(
                    'Akıllı evinizin iklim, aydınlatma ve cihaz kontrolü artık parmaklarınızın ucunda çok daha huzurlu.',
                    style: AppTypography.bodyText(
                      color: isDark ? const Color(0xFFBAC2B7) : const Color(0xFF4A554A),
                    ).copyWith(
                      fontSize: 14.5,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Active Pagination Dots (Image 2 standard)
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkPrimary : AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 10,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2E3D30) : const Color(0xFFD4E0D2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 10,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2E3D30) : const Color(0xFFD4E0D2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),

                  // Interactive "Slide to Start" Slider Capsule (Image 2 bottom control)
                  Row(
                    children: [
                      // Circular Back / Reset Button
                      InkWell(
                        onTap: () {
                          if (widget.onBack != null) {
                            widget.onBack!();
                          } else {
                            setState(() {
                              _dragPosition = 0.0;
                              _isUnlocked = false;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF242C25) : Colors.white,
                            border: Border.all(
                              color: isDark ? const Color(0xFF333E34) : const Color(0xFFE2E6DF),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            size: 28,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E3023),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Slide-to-Start Drag Capsule
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            const trackHeight = 56.0;
                            const thumbSize = 48.0;
                            const thumbPadding = 4.0;
                            final maxDrag = constraints.maxWidth - thumbSize - (thumbPadding * 2);

                            return InkWell(
                              onTap: _triggerStart,
                              borderRadius: BorderRadius.circular(trackHeight / 2),
                              child: Container(
                                height: trackHeight,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1D2820)
                                      : const Color(0xFF1E2E22), // Deep Forest Pine
                                  borderRadius: BorderRadius.circular(trackHeight / 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1E2E22).withValues(alpha: 0.28),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    // Centered Track Text
                                    Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Başla',
                                            style: AppTypography.buttonText(
                                              color: Colors.white,
                                            ).copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            '>>>',
                                            style: TextStyle(
                                              color: Color(0xFFB7CCB9),
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Draggable Round Thumb Button
                                    Positioned(
                                      left: thumbPadding + _dragPosition,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onHorizontalDragUpdate: (details) =>
                                            _handleDragUpdate(details, maxDrag),
                                        onHorizontalDragEnd: (details) =>
                                            _handleDragEnd(details, maxDrag),
                                        onTap: _triggerStart,
                                        child: Container(
                                          width: thumbSize,
                                          height: thumbSize,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isDark ? const Color(0xFFDCE5D7) : Colors.white,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.22),
                                                blurRadius: 8,
                                                offset: const Offset(2, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.chevron_right_rounded,
                                            size: 28,
                                            color: const Color(0xFF1E2E22),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
