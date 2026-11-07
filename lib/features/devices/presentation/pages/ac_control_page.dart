import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../../core/widgets/nestora_button.dart';
import '../../../../core/widgets/nestora_dialog.dart';
import '../../../../core/widgets/nestora_switch.dart';
import '../../../rooms/presentation/cubit/rooms_cubit.dart';
import '../../../rooms/presentation/cubit/rooms_state.dart';
import '../../domain/device_model.dart';
import '../cubit/devices_cubit.dart';
import '../cubit/devices_state.dart';
import 'add_edit_device_page.dart';

class AcControlPage extends StatefulWidget {
  final String? deviceId;

  const AcControlPage({super.key, this.deviceId});

  @override
  State<AcControlPage> createState() => _AcControlPageState();
}

class _AcControlPageState extends State<AcControlPage> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  FanSpeed? _lastSpeed;
  bool? _lastPowered;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  void _syncAnimation(bool isPowered, FanSpeed speed) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations || !isPowered) {
      if (_waveController.isAnimating) {
        _waveController.stop();
      }
      _lastPowered = isPowered;
      return;
    }

    if (_lastPowered != true || _lastSpeed != speed) {
      _lastPowered = true;
      _lastSpeed = speed;

      Duration duration;
      switch (speed) {
        case FanSpeed.low:
          duration = const Duration(milliseconds: 2200);
          break;
        case FanSpeed.mid:
          duration = const Duration(milliseconds: 1400);
          break;
        case FanSpeed.high:
          duration = const Duration(milliseconds: 700);
          break;
        case FanSpeed.auto:
          duration = const Duration(milliseconds: 1200);
          break;
      }

      _waveController.duration = duration;
      if (!_waveController.isAnimating) {
        _waveController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _adjustTemp(DeviceModel ac, double delta) {
    final next = (ac.targetTemp + delta).clamp(16.0, 30.0);
    final clean = ((next * 2).round() / 2.0);
    context.read<DevicesCubit>().setAcTemp(ac.id, clean);
  }

  String _formatTemp(double temp) {
    if (temp == temp.truncateToDouble()) {
      return temp.toInt().toString();
    }
    return temp.toStringAsFixed(1);
  }

  void _showDeleteDialog(BuildContext context, DeviceModel ac) {
    showNestoraDeleteDialog(
      context: context,
      variation: DeleteDialogVariation.deviceDelete,
      title: '"${ac.name}" Silinecek',
      message:
          'Bu klima cihazı silindiğinde tüm iklimlendirme otomasyonlarından ve odasından kaldırılacaktır. Onaylıyor musunuz?',
      deleteButtonText: 'Klimayı Sil',
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<DevicesCubit>().deleteDeviceById(ac.id);
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

    final ac = devices.firstWhere(
      (d) => d.id == widget.deviceId || d.id == 'dev-5',
      orElse: () => devices.firstWhere(
        (d) => d.type == DeviceType.ac,
        orElse: () => devices.first,
      ),
    );

    final isPowered = ac.isPoweredOn;
    final currentTemp = ac.targetTemp;

    // Synchronize fan animation based on power state and fan speed
    _syncAnimation(isPowered, ac.fanSpeed);

    // Look up ambient room temperature and humidity if available
    double ambientTemp = 25.4;
    int ambientHumidity = 48;
    try {
      final roomsState = context.read<RoomsCubit>().state;
      if (roomsState is RoomsLoaded) {
        final room = roomsState.rooms.where((r) => r.id == ac.roomId).firstOrNull;
        if (room != null) {
          ambientTemp = room.targetTemperature;
          ambientHumidity = room.humidity;
        }
      }
    } catch (_) {}

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
          ac.name,
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              ac.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: ac.isFavorite ? AppColors.warmAmber : AppColors.secondary,
              size: 22,
            ),
            onPressed: () => context.read<DevicesCubit>().toggleDeviceFavorite(ac.id),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditDevicePage(device: ac, isEditing: true),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 22, color: AppColors.error),
            onPressed: () => _showDeleteDialog(context, ac),
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
                // 1. Room & Power Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.bed_rounded,
                                  size: 16,
                                  color: AppColors.primaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ac.room,
                                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'İklimlendirme',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.secondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isPowered ? 'Açık' : 'Kapalı',
                          style: AppTypography.labelMedium.copyWith(
                            color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        NestoraSwitch(
                          value: isPowered,
                          onChanged: (_) => context.read<DevicesCubit>().toggleDevicePower(ac.id),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. AC Hardware Graphic & Dynamic Breeze Animation
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppColors.cardShadow,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'NESTORA CLIMATE PRO',
                                style: AppTypography.caption.copyWith(
                                  letterSpacing: 1.1,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isPowered ? 'Aktif • ${_formatTemp(currentTemp)}°C' : 'Standby',
                              style: AppTypography.caption.copyWith(
                                color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // AC Body Representation
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  height: 4,
                                  width: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isPowered ? '${_formatTemp(currentTemp)}°C' : '--°C',
                                    style: AppTypography.labelMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Louver Air-Vent Blade
                            Container(
                              height: 5,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: isPowered ? 0.85 : 0.25,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Dynamic Airflow Animation (Runs when powered on, stops when off)
                      if (isPowered) ...[
                        const SizedBox(height: 10),
                        AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: (0.35 + (_waveController.value * 0.65)).clamp(0.0, 1.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.air_rounded,
                                    color: AppColors.primaryContainer,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${ac.fanSpeed.name.toUpperCase()} Hızda Hava Akışı',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.primaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Circular Thermostat Dial & Controls (0.5°C Steps)
                Container(
                  padding: const EdgeInsets.all(20),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hedef Ayar',
                            style: AppTypography.labelMedium.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '16.0°C - 30.0°C',
                              style: AppTypography.caption.copyWith(color: AppColors.secondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Circular Arc Dial Stack
                      SizedBox(
                        height: 220,
                        width: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Custom painted circular arc
                            CustomPaint(
                              size: const Size(220, 220),
                              painter: TemperatureArcPainter(
                                temperature: currentTemp,
                                minTemp: 16.0,
                                maxTemp: 30.0,
                                isPowered: isPowered,
                                mode: ac.acMode,
                              ),
                            ),

                            // Center Target Temperature Display
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatTemp(currentTemp),
                                        style: AppTypography.displayLarge.copyWith(
                                          color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 48,
                                          height: 1.0,
                                        ),
                                      ),
                                      Text(
                                        '°C',
                                        style: AppTypography.headlineMedium.copyWith(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hedef Sıcaklık',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Distinct Ambient Environment Readings
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.thermostat_rounded, size: 12, color: AppColors.secondary),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Oda: ${_formatTemp(ambientTemp)}°C',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.water_drop_outlined, size: 12, color: AppColors.secondary),
                                      const SizedBox(width: 2),
                                      Text(
                                        '%$ambientHumidity',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Floating '-' Step Button (0.5°C decrease)
                            Positioned(
                              left: 0,
                              child: GestureDetector(
                                onTap: () => _adjustTemp(ac, -0.5),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                                    boxShadow: AppColors.subtleShadow,
                                    border: Border.all(
                                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.remove_rounded,
                                    size: 22,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                            ),

                            // Floating '+' Step Button (0.5°C increase)
                            Positioned(
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _adjustTemp(ac, 0.5),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                                    boxShadow: AppColors.subtleShadow,
                                    border: Border.all(
                                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    size: 22,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Quick Preset Buttons (20°C, 22°C, 24°C, 26°C)
                      Row(
                        children: [
                          _buildPresetButton(
                            label: '20°C Serin',
                            temp: 20.0,
                            currentTemp: currentTemp,
                            onTap: () => context.read<DevicesCubit>().setAcTemp(ac.id, 20.0),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          _buildPresetButton(
                            label: '22°C Dengeli',
                            temp: 22.0,
                            currentTemp: currentTemp,
                            onTap: () => context.read<DevicesCubit>().setAcTemp(ac.id, 22.0),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          _buildPresetButton(
                            label: '24°C Konfor',
                            temp: 24.0,
                            currentTemp: currentTemp,
                            onTap: () => context.read<DevicesCubit>().setAcTemp(ac.id, 24.0),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          _buildPresetButton(
                            label: '26°C Eko',
                            temp: 26.0,
                            currentTemp: currentTemp,
                            onTap: () => context.read<DevicesCubit>().setAcTemp(ac.id, 26.0),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Operational Modes: Soğutma, Isıtma, Otomatik, Fan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Çalışma Modu',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      '${ac.acMode.name.toUpperCase()} Seçili',
                      style: AppTypography.caption.copyWith(color: AppColors.secondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildModeCard(
                        title: 'Soğutma',
                        subtitle: 'Serin Esinti',
                        icon: Icons.ac_unit_rounded,
                        isSelected: ac.acMode == AcMode.cool,
                        onTap: () => context.read<DevicesCubit>().setAcModeChoice(ac.id, AcMode.cool),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildModeCard(
                        title: 'Isıtma',
                        subtitle: 'Dengeli Ilık',
                        icon: Icons.local_fire_department_rounded,
                        isSelected: ac.acMode == AcMode.heat,
                        onTap: () => context.read<DevicesCubit>().setAcModeChoice(ac.id, AcMode.heat),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildModeCard(
                        title: 'Otomatik',
                        subtitle: 'Akıllı Ayar',
                        icon: Icons.autorenew_rounded,
                        isSelected: ac.acMode == AcMode.auto,
                        onTap: () => context.read<DevicesCubit>().setAcModeChoice(ac.id, AcMode.auto),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildModeCard(
                        title: 'Fan',
                        subtitle: 'Hava Akışı',
                        icon: Icons.air_rounded,
                        isSelected: ac.acMode == AcMode.fanOnly,
                        onTap: () => context.read<DevicesCubit>().setAcModeChoice(ac.id, AcMode.fanOnly),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 5. Fan Speed Level Pills (Düşük, Orta, Yüksek, Otomatik)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fan Hızı',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.air_rounded, size: 14, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(
                          '${ac.fanSpeed.name.toUpperCase()} Kademesi',
                          style: AppTypography.caption.copyWith(color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFanPill(
                      'Düşük',
                      FanSpeed.low,
                      ac.fanSpeed,
                      () => context.read<DevicesCubit>().setAcFanSpeedChoice(ac.id, FanSpeed.low),
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildFanPill(
                      'Orta',
                      FanSpeed.mid,
                      ac.fanSpeed,
                      () => context.read<DevicesCubit>().setAcFanSpeedChoice(ac.id, FanSpeed.mid),
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildFanPill(
                      'Yüksek',
                      FanSpeed.high,
                      ac.fanSpeed,
                      () => context.read<DevicesCubit>().setAcFanSpeedChoice(ac.id, FanSpeed.high),
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildFanPill(
                      'Otomatik',
                      FanSpeed.auto,
                      ac.fanSpeed,
                      () => context.read<DevicesCubit>().setAcFanSpeedChoice(ac.id, FanSpeed.auto),
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 6. Eco Energy Insight Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
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
                              'Enerji Tasarrufu',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              '24°C ve üzeri hedef sıcaklık %18 daha az enerji harcar',
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
                const SizedBox(height: 24),

                // 7. Action Buttons
                NestoraButton(
                  text: 'Cihazı Düzenle',
                  icon: Icons.tune_rounded,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditDevicePage(device: ac, isEditing: true),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                NestoraButton(
                  text: 'Cihazı Sil',
                  variant: ButtonVariant.ghost,
                  icon: Icons.delete_outline_rounded,
                  onPressed: () => _showDeleteDialog(context, ac),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton({
    required String label,
    required double temp,
    required double currentTemp,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final isSelected = temp == currentTemp;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryContainer
                : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
            borderRadius: BorderRadius.circular(12),
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryContainer
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.22)
                    : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.primaryContainer,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                color: isSelected ? Colors.white70 : AppColors.secondary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFanPill(
    String label,
    FanSpeed speed,
    FanSpeed currentSpeed,
    VoidCallback onTap,
    bool isDark,
  ) {
    final isSelected = speed == currentSpeed;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.secondaryContainer
                : (isDark ? AppColors.darkCard : AppColors.lightCard),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryContainer
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? AppColors.primaryContainer
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

class TemperatureArcPainter extends CustomPainter {
  final double temperature;
  final double minTemp;
  final double maxTemp;
  final bool isPowered;
  final AcMode mode;

  TemperatureArcPainter({
    required this.temperature,
    required this.minTemp,
    required this.maxTemp,
    required this.isPowered,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 24;

    // Background track arc
    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.18)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const startAngle = 0.75 * math.pi;
    const sweepAngle = 1.5 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Active progress arc
    if (isPowered) {
      final ratio = ((temperature - minTemp) / (maxTemp - minTemp)).clamp(0.0, 1.0);
      Color arcColor = AppColors.primaryContainer;
      if (mode == AcMode.cool) {
        arcColor = const Color(0xFF2B78E4);
      } else if (mode == AcMode.heat) {
        arcColor = const Color(0xFFE67E22);
      } else if (mode == AcMode.fanOnly) {
        arcColor = const Color(0xFF4A7C59);
      }

      final activePaint = Paint()
        ..color = arcColor
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * ratio,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TemperatureArcPainter oldDelegate) {
    return oldDelegate.temperature != temperature ||
        oldDelegate.isPowered != isPowered ||
        oldDelegate.mode != mode;
  }
}
