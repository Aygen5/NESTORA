import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/seed_data.dart';
import '../cubit/devices_cubit.dart';
import '../cubit/devices_state.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/nestora_button.dart';
import '../../../../core/widgets/nestora_dialog.dart';
import '../../../../core/widgets/nestora_switch.dart';
import 'add_edit_device_page.dart';

class LampControlPage extends StatefulWidget {
  const LampControlPage({super.key});

  @override
  State<LampControlPage> createState() => _LampControlPageState();
}

class _LampControlPageState extends State<LampControlPage> {
  final List<Map<String, dynamic>> _colorSwatches = [
    {
      'name': 'Sıcak Günışığı (2700K)',
      'hex': '#E1C1A0',
      'color': const Color(0xFFE1C1A0),
      'glow': const Color(0xFFFEDDBB),
    },
    {
      'name': 'Doğal Beyaz (4000K)',
      'hex': '#EAF0E6',
      'color': const Color(0xFFEAF0E6),
      'glow': const Color(0xFFF5FBF2),
    },
    {
      'name': 'Soğuk Beyaz (6500K)',
      'hex': '#D3E8D5',
      'color': const Color(0xFFD3E8D5),
      'glow': const Color(0xFFE8F5E9),
    },
    {
      'name': 'Soft Adaçayı Yeşili',
      'hex': '#506354',
      'color': const Color(0xFF506354),
      'glow': const Color(0xFFDCE5D7),
    },
    {
      'name': 'Gece Modu (Köz)',
      'hex': '#533E25',
      'color': const Color(0xFF533E25),
      'glow': const Color(0xFFFAF3EB),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final devicesCubit = context.watch<DevicesCubit>();
    final devicesState = devicesCubit.state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final devices = (devicesState is DevicesLoaded)
        ? devicesState.devices.map(SeedData.deviceToModel).toList()
        : SeedData.defaultDeviceModels;
    final lamp = devices.firstWhere((d) => d.id == 'dev-1', orElse: () => devices.first);

    final brightness = lamp.brightness;
    final isPowered = lamp.isPoweredOn;

    // Active color
    final activeSwatch = _colorSwatches.firstWhere(
      (swatch) => swatch['hex'] == lamp.colorHex,
      orElse: () => _colorSwatches.first,
    );
    final bulbColor = activeSwatch['color'] as Color;
    final glowColor = activeSwatch['glow'] as Color;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightScaffold,
      appBar: AppBar(
        backgroundColor: (isDark ? AppColors.darkCard : AppColors.lightScaffold).withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Aydınlatma Kontrolü',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              lamp.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: lamp.isFavorite ? AppColors.warmAmber : AppColors.secondary,
              size: 22,
            ),
            onPressed: () => context.read<DevicesCubit>().toggleDeviceFavorite(lamp.id),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditDevicePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 22, color: AppColors.error),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
            // Room & Status Metadata Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.chair_rounded, size: 14, color: AppColors.primaryContainer),
                            const SizedBox(width: 4),
                            Text(
                              lamp.room,
                              style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Akıllı Ampul',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.secondary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPowered
                          ? AppColors.secondaryContainer
                          : (isDark ? AppColors.darkCard : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        if (isPowered) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          isPowered ? 'Açık • %$brightness' : 'Kapalı',
                          style: AppTypography.labelSmall.copyWith(
                            color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Radiant Bulb Hero Centerpiece
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  // Ambient Glow and Bulb
                  SizedBox(
                    height: 220,
                    width: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated Glow Halo
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isPowered ? (100 + brightness * 1.1) : 0,
                          height: isPowered ? (100 + brightness * 1.1) : 0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: glowColor.withValues(
                              alpha: isPowered ? (0.2 + (brightness / 100) * 0.5) : 0,
                            ),
                            boxShadow: isPowered
                                ? [
                                    BoxShadow(
                                      color: bulbColor.withValues(alpha: (brightness / 100) * 0.6),
                                      blurRadius: 40 + (brightness * 0.4),
                                      spreadRadius: 10 + (brightness * 0.2),
                                    ),
                                  ]
                                : [],
                          ),
                        ),

                        // Custom Painted Modern Bulb
                        CustomPaint(
                          size: const Size(120, 160),
                          painter: ModernBulbPainter(
                            isPowered: isPowered,
                            brightness: brightness,
                            bulbColor: bulbColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Integrated Primary Master Switch
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lightbulb_rounded,
                          size: 20,
                          color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPowered ? 'Açık' : 'Kapalı',
                          style: AppTypography.headlineSmall.copyWith(
                            color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        NestoraSwitch(
                          value: isPowered,
                          onChanged: (_) {
                            context.read<DevicesCubit>().toggleDevicePower(lamp.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Brightness Slider Control Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.brightness_medium_rounded, size: 20, color: AppColors.primaryContainer),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Parlaklık',
                                style: AppTypography.headlineSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              Text(
                                'Aydınlatma şiddeti',
                                style: AppTypography.caption.copyWith(color: AppColors.secondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        '%$brightness',
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.primaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Interactive Slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primaryContainer,
                      inactiveTrackColor: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                      thumbColor: AppColors.primaryContainer,
                      overlayColor: AppColors.primaryContainer.withValues(alpha: 0.2),
                      trackHeight: 10,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                    ),
                    child: Slider(
                      value: brightness.toDouble(),
                      min: 1,
                      max: 100,
                      onChanged: (val) {
                        context.read<DevicesCubit>().setLampBrightness(lamp.id, val.round());
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick Preset Pills
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [25, 50, 75, 100].map((preset) {
                      final isSelected = brightness == preset;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () {
                              context.read<DevicesCubit>().setLampBrightness(lamp.id, preset);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryContainer
                                    : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  '%$preset',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Color Temperature & Tone Swatches
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.palette_rounded, size: 20, color: AppColors.primaryContainer),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Renk Sıcaklığı & Ton',
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            activeSwatch['name'] as String,
                            style: AppTypography.caption.copyWith(color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Swatches Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _colorSwatches.map((swatch) {
                      final isSelected = swatch['hex'] == lamp.colorHex;
                      final col = swatch['color'] as Color;

                      return GestureDetector(
                        onTap: () {
                          context.read<DevicesCubit>().setLampColor(
                            lamp.id,
                            name: swatch['name'] as String,
                            hex: swatch['hex'] as String,
                          );
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: col,
                            border: Border.all(
                              color: isSelected ? AppColors.primaryContainer : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 20,
                                  color: col.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Management Action Buttons
            NestoraButton(
              text: 'Cihazı Yapılandır',
              icon: Icons.tune_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditDevicePage()),
                );
              },
            ),
            const SizedBox(height: 10),
            NestoraButton(
              text: 'Cihazı Kaldır',
              variant: ButtonVariant.ghost,
              icon: Icons.delete_outline_rounded,
              onPressed: () => _showDeleteDialog(context),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  ),
);
}

  void _showDeleteDialog(BuildContext context) {
    showNestoraDialog(
      context: context,
      variation: DialogVariation.variationA,
      title: 'Cihazı Sil',
      description:
          'Bu cihazı silmek istediğine emin misin? Bu işlem geri alınamaz ve cihazın bağlı olduğu tüm rutinler devre dışı bırakılır.',
      onConfirm: () {
        context.read<DevicesCubit>().deleteDeviceById('dev-1');
        Navigator.pop(context);
      },
    );
  }
}

class ModernBulbPainter extends CustomPainter {
  final bool isPowered;
  final int brightness;
  final Color bulbColor;

  ModernBulbPainter({
    required this.isPowered,
    required this.brightness,
    required this.bulbColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // 1. Pendant cord
    final cordPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, 0), Offset(cx, 16), cordPaint);

    // 2. Base / Socket
    final socketPaint = Paint()..color = const Color(0xFF737872);
    final socketRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 22), width: 28, height: 12),
      const Radius.circular(3),
    );
    canvas.drawRRect(socketRect, socketPaint);

    // 3. Bulb Outer Glass Shape
    final glassPath = Path();
    // Start at socket base right
    glassPath.moveTo(cx + 12, 28);
    // Expand to bulb sphere
    glassPath.cubicTo(cx + 45, 45, cx + 55, 80, cx + 45, 110);
    glassPath.cubicTo(cx + 35, 135, cx + 18, 145, cx, 145);
    glassPath.cubicTo(cx - 18, 145, cx - 35, 135, cx - 45, 110);
    glassPath.cubicTo(cx - 55, 80, cx - 45, 45, cx - 12, 28);
    glassPath.close();

    final glassFillPaint = Paint()
      ..color = isPowered
          ? bulbColor.withValues(alpha: 0.15 + (brightness / 100) * 0.35)
          : Colors.grey.shade200
      ..style = PaintingStyle.fill;
    canvas.drawPath(glassPath, glassFillPaint);

    final glassOutlinePaint = Paint()
      ..color = isPowered ? bulbColor.withValues(alpha: 0.8) : Colors.grey.shade400
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(glassPath, glassOutlinePaint);

    if (isPowered) {
      // 4. Radiant Filament
      final filamentPaint = Paint()
        ..color = bulbColor
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final filamentPath = Path();
      filamentPath.moveTo(cx - 16, 75);
      filamentPath.cubicTo(cx - 16, 50, cx + 16, 50, cx + 16, 75);
      filamentPath.cubicTo(cx + 16, 95, cx - 16, 95, cx - 16, 115);
      canvas.drawPath(filamentPath, filamentPaint);

      // Core Glowing Node
      final nodePaint = Paint()..color = bulbColor;
      canvas.drawCircle(Offset(cx, 75), 6, nodePaint);

      // Inner intense core glow
      final coreGlow = Paint()
        ..color = Colors.white.withValues(alpha: (brightness / 100) * 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(cx, 75), 4, coreGlow);
    }
  }

  @override
  bool shouldRepaint(covariant ModernBulbPainter oldDelegate) {
    return oldDelegate.isPowered != isPowered ||
        oldDelegate.brightness != brightness ||
        oldDelegate.bulbColor != bulbColor;
  }
}
