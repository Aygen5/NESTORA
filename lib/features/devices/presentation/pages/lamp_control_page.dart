import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../../core/widgets/glowing_toast.dart';
import '../../../../core/widgets/nestora_button.dart';
import '../../../../core/widgets/nestora_dialog.dart';
import '../../../../core/widgets/nestora_switch.dart';
import '../../domain/device_model.dart';
import '../cubit/devices_cubit.dart';
import '../cubit/devices_state.dart';
import 'add_edit_device_page.dart';

/// Predefined atmosphere lighting modes for quick ambient switching.
class LampAtmosphereMode {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final int brightness;
  final String colorHex;
  final String colorName;

  const LampAtmosphereMode({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.brightness,
    required this.colorHex,
    required this.colorName,
  });
}

class LampControlPage extends StatefulWidget {
  final String? deviceId;

  const LampControlPage({super.key, this.deviceId});

  @override
  State<LampControlPage> createState() => _LampControlPageState();
}

class _LampControlPageState extends State<LampControlPage> {
  int _selectedTimerMinutes = 0; // 0 = off

  static const List<LampAtmosphereMode> _atmosphereModes = [
    LampAtmosphereMode(
      key: 'reading',
      title: 'Okuma',
      subtitle: 'Dengeli odak ışığı',
      icon: Icons.menu_book_rounded,
      brightness: 80,
      colorHex: '#EAF0E6',
      colorName: 'Doğal Beyaz (4000K)',
    ),
    LampAtmosphereMode(
      key: 'relaxing',
      title: 'Dinlenme',
      subtitle: 'Sıcak akşam tonu',
      icon: Icons.self_improvement_rounded,
      brightness: 40,
      colorHex: '#E1C1A0',
      colorName: 'Sıcak Günışığı (2700K)',
    ),
    LampAtmosphereMode(
      key: 'focus',
      title: 'Konsantrasyon',
      subtitle: 'Net çalışma ışığı',
      icon: Icons.psychology_rounded,
      brightness: 100,
      colorHex: '#D3E8D5',
      colorName: 'Soğuk Beyaz (6500K)',
    ),
    LampAtmosphereMode(
      key: 'night',
      title: 'Gece Lambası',
      subtitle: 'Göz almayan loş ışık',
      icon: Icons.nightlight_round,
      brightness: 15,
      colorHex: '#533E25',
      colorName: 'Gece Modu (Köz)',
    ),
  ];

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
      'glow': const Color(0xFFFFFFFF),
    },
    {
      'name': 'Sıcak Sarı (3000K)',
      'hex': '#FFD54F',
      'color': const Color(0xFFFFD54F),
      'glow': const Color(0xFFFFF9C4),
    },
    {
      'name': 'Yumuşak Yeşil',
      'hex': '#81C784',
      'color': const Color(0xFF81C784),
      'glow': const Color(0xFFC8E6C9),
    },
    {
      'name': 'Gece Mavisi',
      'hex': '#64B5F6',
      'color': const Color(0xFF64B5F6),
      'glow': const Color(0xFFBBDEFB),
    },
  ];

  void _applyAtmosphereMode(DeviceModel lamp, LampAtmosphereMode mode) {
    final cubit = context.read<DevicesCubit>();
    if (!lamp.isPoweredOn) {
      cubit.toggleDevicePower(lamp.id);
    }
    cubit.setLampBrightness(lamp.id, mode.brightness);
    cubit.setLampColor(
      lamp.id,
      name: mode.colorName,
      hex: mode.colorHex,
    );

    showGlowingToast(
      context,
      message: '${mode.title} modu uygulandı (%${mode.brightness})',
      icon: mode.icon,
    );
  }

  void _selectTimer(int minutes) {
    setState(() => _selectedTimerMinutes = minutes);
    final message = minutes > 0
        ? 'Lamba $minutes dakika sonra otomatik olarak kapatılacak.'
        : 'Zamanlayıcı iptal edildi.';

    showGlowingToast(
      context,
      message: message,
      icon: minutes > 0 ? Icons.timer_rounded : Icons.timer_off_rounded,
    );
  }

  void _showDeleteDialog(BuildContext context, DeviceModel lamp) {
    showNestoraDeleteDialog(
      context: context,
      variation: DeleteDialogVariation.deviceDelete,
      title: '"${lamp.name}" Silinecek',
      message:
          'Bu aydınlatma cihazı silindiğinde mevcut tüm senaryo ve rutinlerden kaldırılacaktır. Onaylıyor musunuz?',
      deleteButtonText: 'Cihazı Sil',
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<DevicesCubit>().deleteDeviceById(lamp.id);
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final devicesCubit = context.watch<DevicesCubit>();
    final devicesState = devicesCubit.state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final devices = (devicesState is DevicesLoaded)
        ? devicesState.devices.map(SeedData.deviceToModel).toList()
        : SeedData.defaultDeviceModels;

    final lamp = devices.firstWhere(
      (d) => widget.deviceId != null && widget.deviceId!.isNotEmpty
          ? d.id == widget.deviceId
          : d.type == DeviceType.bulb,
      orElse: () => devices.firstWhere(
        (d) => d.type == DeviceType.bulb,
        orElse: () => devices.first,
      ),
    );

    final brightness = lamp.brightness;
    final isPowered = lamp.isPoweredOn;

    // Active color swatch
    final activeSwatch = _colorSwatches.firstWhere(
      (swatch) => swatch['hex'] == lamp.colorHex,
      orElse: () {
        if (lamp.colorHex == '#533E25') {
          return {
            'name': 'Gece Modu (Köz)',
            'hex': '#533E25',
            'color': const Color(0xFF533E25),
            'glow': const Color(0xFFFAF3EB),
          };
        }
        return _colorSwatches.first;
      },
    );
    final bulbColor = activeSwatch['color'] as Color;
    final glowColor = activeSwatch['glow'] as Color;
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final glowDuration = disableAnimations ? Duration.zero : const Duration(milliseconds: 250);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightScaffold,
      appBar: AppBar(
        backgroundColor: (isDark ? AppColors.darkCard : AppColors.lightScaffold).withValues(alpha: 0.92),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          lamp.name,
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: lamp.isFavorite ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
            icon: Icon(
              lamp.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: lamp.isFavorite ? AppColors.warmAmber : AppColors.secondary,
              size: 22,
            ),
            onPressed: () {
              final newFav = !lamp.isFavorite;
              context.read<DevicesCubit>().toggleDeviceFavorite(lamp.id);
              showGlowingToast(
                context,
                message: newFav
                    ? '${lamp.name} favorilere eklendi.'
                    : '${lamp.name} favorilerden çıkarıldı.',
                icon: newFav ? Icons.star_rounded : Icons.star_border_rounded,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditDevicePage(device: lamp, isEditing: true),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 22, color: AppColors.error),
            onPressed: () => _showDeleteDialog(context, lamp),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              children: [
                // 1. Room & Power Metadata Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.chair_rounded,
                                      size: 14,
                                      color: AppColors.primaryContainer,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        lamp.room,
                                        style: AppTypography.labelSmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Akıllı Ampul',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.secondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
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
                                decoration: const BoxDecoration(
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

                // 2. Radiant Bulb Centerpiece & Dynamic Glow
                AnimatedContainer(
                  duration: glowDuration,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isPowered && brightness > 0
                        ? Color.alphaBlend(
                            bulbColor.withValues(alpha: 0.08 + (brightness / 100) * 0.16),
                            isDark ? AppColors.darkCard : AppColors.lightCard,
                          )
                        : (isDark ? AppColors.darkCard : AppColors.lightCard),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isPowered && brightness > 0
                          ? bulbColor.withValues(alpha: 0.35 + (brightness / 100) * 0.45)
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: isPowered && brightness > 0 ? 2.0 : 1.0,
                    ),
                    boxShadow: isPowered && brightness > 0
                        ? [
                            BoxShadow(
                              color: bulbColor.withValues(
                                alpha: (brightness / 100) * 0.4,
                              ),
                              blurRadius: 28 + (brightness * 0.35),
                              spreadRadius: 2 + (brightness * 0.1),
                            ),
                          ]
                        : AppColors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      // Ambient Glow and Bulb Canvas
                      SizedBox(
                        height: 220,
                        width: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Dynamic Glow Halo (Turns off completely when unpowered)
                            AnimatedContainer(
                              duration: glowDuration,
                              curve: Curves.easeOutCubic,
                              width: isPowered ? (100 + brightness * 1.2) : 0,
                              height: isPowered ? (100 + brightness * 1.2) : 0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: glowColor.withValues(
                                  alpha: isPowered ? (0.2 + (brightness / 100) * 0.5) : 0,
                                ),
                                boxShadow: isPowered && brightness > 0
                                    ? [
                                        BoxShadow(
                                          color: bulbColor.withValues(
                                            alpha: (brightness / 100) * 0.7,
                                          ),
                                          blurRadius: 36 + (brightness * 0.55),
                                          spreadRadius: 10 + (brightness * 0.3),
                                        ),
                                      ]
                                    : [],
                              ),
                            ),

                            // Modern Bulb Custom Painter
                            CustomPaint(
                              size: const Size(120, 160),
                              painter: ModernBulbPainter(
                                isPowered: isPowered && brightness > 0,
                                brightness: brightness,
                                bulbColor: bulbColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Master Power Switch Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            const SizedBox(width: 14),
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

                // 3. Brightness Slider Control Card (%0 - %100)
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
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.brightness_medium_rounded,
                                    size: 20,
                                    color: AppColors.primaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Parlaklık',
                                        style: AppTypography.headlineSmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Aydınlatma şiddeti (%0 - %100)',
                                        style: AppTypography.caption.copyWith(color: AppColors.secondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
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
                          value: brightness.clamp(0, 100).toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 100,
                          onChanged: (val) {
                            context.read<DevicesCubit>().setLampBrightness(lamp.id, val.round());
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Quick Preset Pills (%25, %50, %75, %100)
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

                // 4. Color Temperature & Tone Palette Swatches
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
                            child: const Icon(
                              Icons.palette_rounded,
                              size: 20,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
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
                              showGlowingToast(
                                context,
                                message: '${swatch['name']} tonuna geçildi.',
                                icon: Icons.palette_rounded,
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
                const SizedBox(height: 20),

                // 5. Hazır Atmosfer Modları (Okuma, Dinlenme, Konsantrasyon, Gece Lambası)
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
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 20,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hazır Atmosfer Modları',
                                  style: AppTypography.headlineSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  'Tek dokunuşla ışık ve renk ambiyansı',
                                  style: AppTypography.caption.copyWith(color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 2x2 Grid of Preset Atmosphere Modes
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.6,
                        ),
                        itemCount: _atmosphereModes.length,
                        itemBuilder: (context, index) {
                          final mode = _atmosphereModes[index];
                          final isActive = lamp.colorHex == mode.colorHex && lamp.brightness == mode.brightness;

                          return GestureDetector(
                            onTap: () => _applyAtmosphereMode(lamp, mode),
                            child: AnimatedContainer(
                              duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.secondaryContainer.withValues(alpha: 0.5)
                                    : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isActive
                                      ? AppColors.primaryContainer
                                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  width: isActive ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppColors.primaryContainer
                                          : (isDark ? AppColors.darkCard : Colors.white),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      mode.icon,
                                      size: 18,
                                      color: isActive ? Colors.white : AppColors.primaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          mode.title,
                                          style: AppTypography.labelMedium.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '%${mode.brightness}',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Otomatik Kapanma Zamanlayıcısı (Timer Interface)
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
                            child: const Icon(
                              Icons.timer_outlined,
                              size: 20,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kapanma Zamanlayıcısı',
                                  style: AppTypography.headlineSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  _selectedTimerMinutes > 0
                                      ? '$_selectedTimerMinutes dk sonra kapanacak'
                                      : 'Zamanlayıcı aktif değil',
                                  style: AppTypography.caption.copyWith(
                                    color: _selectedTimerMinutes > 0
                                        ? AppColors.primaryContainer
                                        : AppColors.secondary,
                                    fontWeight: _selectedTimerMinutes > 0 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Timer quick selection chips
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          {'label': 'Kapalı', 'val': 0},
                          {'label': '15 dk', 'val': 15},
                          {'label': '30 dk', 'val': 30},
                          {'label': '45 dk', 'val': 45},
                          {'label': '60 dk', 'val': 60},
                        ].map((item) {
                          final val = item['val'] as int;
                          final label = item['label'] as String;
                          final isSelected = _selectedTimerMinutes == val;

                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: GestureDetector(
                                onTap: () => _selectTimer(val),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryContainer
                                        : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryContainer
                                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      label,
                                      style: AppTypography.caption.copyWith(
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
                const SizedBox(height: 24),

                // 7. Management Action Buttons
                NestoraButton(
                  text: 'Cihazı Yapılandır',
                  icon: Icons.tune_rounded,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditDevicePage(device: lamp, isEditing: true),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                NestoraButton(
                  text: 'Cihazı Kaldır',
                  variant: ButtonVariant.ghost,
                  icon: Icons.delete_outline_rounded,
                  onPressed: () => _showDeleteDialog(context, lamp),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
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
    glassPath.moveTo(cx + 12, 28);
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
