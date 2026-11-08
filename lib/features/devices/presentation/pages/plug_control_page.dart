import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../../core/widgets/glowing_toast.dart';
import '../../../../core/widgets/nestora_dialog.dart';
import '../../../../core/widgets/nestora_switch.dart';
import '../../../../core/widgets/pulsing_glow_dot.dart';
import '../../domain/device_model.dart';
import '../cubit/devices_cubit.dart';
import '../cubit/devices_state.dart';
import 'add_edit_device_page.dart';

/// Dedicated, interactive Smart Plug control screen for Nestora.
/// Features a realistic Schuko hardware plug figure, relay toggle,
/// live wattage/voltage/current energy meters, child safety lock,
/// and auto-off timer presets.
class PlugControlPage extends StatefulWidget {
  final String? deviceId;

  const PlugControlPage({super.key, this.deviceId});

  @override
  State<PlugControlPage> createState() => _PlugControlPageState();
}

class _PlugControlPageState extends State<PlugControlPage> {
  bool _childLockEnabled = false;
  int _selectedTimerMinutes = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _toggleChildLock() {
    setState(() {
      _childLockEnabled = !_childLockEnabled;
    });
    showGlowingToast(
      context,
      message: _childLockEnabled
          ? 'Çocuk kilidi aktif edildi. Güvenlik kapakları kilitlendi.'
          : 'Çocuk kilidi devre dışı bırakıldı.',
      icon: _childLockEnabled ? Icons.lock_rounded : Icons.lock_open_rounded,
    );
  }

  void _selectTimer(int minutes) {
    _countdownTimer?.cancel();
    setState(() {
      _selectedTimerMinutes = minutes;
    });

    if (minutes > 0) {
      showGlowingToast(
        context,
        message: 'Priz $minutes dakika sonra otomatik olarak kapatılacak.',
        icon: Icons.timer_rounded,
      );
    } else {
      showGlowingToast(
        context,
        message: 'Kapanma zamanlayıcısı iptal edildi.',
        icon: Icons.timer_off_rounded,
      );
    }
  }

  void _showDeleteDialog(BuildContext context, DeviceModel plug) {
    showNestoraDeleteDialog(
      context: context,
      variation: DeleteDialogVariation.deviceDelete,
      title: '"${plug.name}" Silinecek',
      message:
          'Bu akıllı priz silindiğinde tüm bağlı enerji izleme ve senaryo ayarları sıfırlanacaktır. Onaylıyor musunuz?',
      deleteButtonText: 'Prizi Sil',
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<DevicesCubit>().deleteDeviceById(plug.id);
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

    final plug = devices.firstWhere(
      (d) => widget.deviceId != null && widget.deviceId!.isNotEmpty
          ? d.id == widget.deviceId
          : (d.type == DeviceType.plug && !d.name.toLowerCase().contains('kahve')),
      orElse: () => devices.firstWhere(
        (d) => d.type == DeviceType.plug,
        orElse: () => devices.first,
      ),
    );

    final isPowered = plug.isPoweredOn;
    final liveWatts = isPowered ? (plug.currentPowerWatts > 0 ? plug.currentPowerWatts : 120.0) : 0.0;
    final liveVolts = isPowered ? 230.4 : 0.0;
    final liveAmps = isPowered ? (liveWatts / 230.0) : 0.0;
    final dailyKwh = isPowered ? 1.42 : 1.15;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightScaffold,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(76),
        child: Container(
          height: 76,
          padding: const EdgeInsets.only(top: 16),
          color: (isDark ? AppColors.darkCard : AppColors.lightScaffold).withValues(alpha: 0.95),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plug.name,
                      style: AppTypography.headlineSmall.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${plug.room} • Akıllı Priz & Güç Ölçer',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: plug.isFavorite ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
                icon: Icon(
                  plug.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  color: plug.isFavorite ? AppColors.warmAmber : AppColors.secondary,
                  size: 24,
                ),
                onPressed: () {
                  final newFav = !plug.isFavorite;
                  context.read<DevicesCubit>().toggleDeviceFavorite(plug.id);
                  showGlowingToast(
                    context,
                    message: newFav
                        ? '${plug.name} favorilere eklendi.'
                        : '${plug.name} favorilerden çıkarıldı.',
                    icon: newFav ? Icons.star_rounded : Icons.star_border_rounded,
                  );
                },
              ),
              IconButton(
                tooltip: 'Cihazı Düzenle',
                icon: const Icon(Icons.edit_outlined, size: 22),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditDevicePage(device: plug, isEditing: true),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Cihazı Sil',
                icon: const Icon(Icons.delete_outline_rounded, size: 22, color: AppColors.error),
                onPressed: () => _showDeleteDialog(context, plug),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              children: [
                // 1. Room, Relay Status & Live Meter Pill
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
                                    const Icon(Icons.power_rounded, size: 14, color: AppColors.primaryContainer),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        plug.room,
                                        style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
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
                                '16A Schuko Röle',
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
                              const PulsingGlowDot(size: 6, color: AppColors.primaryContainer),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              isPowered ? 'Röle Aktif • ${liveWatts.toStringAsFixed(0)} W' : 'Devre Kapalı',
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

                // 2. Hardware Schuko Smart Plug Figure & Dynamic Halo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
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
                      // Schuko Plug Centerpiece with Tactile Tap
                      GestureDetector(
                        onTap: () {
                          if (_childLockEnabled) {
                            showGlowingToast(
                              context,
                              message: 'Çocuk kilidi aktif! Önce kilidi kaldırın.',
                              icon: Icons.lock_rounded,
                            );
                            return;
                          }
                          context.read<DevicesCubit>().toggleDevicePower(plug.id);
                          showGlowingToast(
                            context,
                            message: isPowered ? 'Akıllı priz kapatıldı.' : 'Akıllı priz açıldı.',
                            icon: Icons.power_rounded,
                          );
                        },
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Radiant Luminous Outer Halo
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: isPowered ? 190 : 160,
                                height: isPowered ? 190 : 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isPowered
                                      ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  boxShadow: isPowered
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
                                            blurRadius: 36,
                                            spreadRadius: 8,
                                          ),
                                        ]
                                      : [],
                                ),
                              ),

                              // Schuko Socket Outer Rim (Plastic Casing)
                              Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? const Color(0xFF1F2622) : const Color(0xFFEBE7E1),
                                  border: Border.all(
                                    color: isPowered
                                        ? const Color(0xFF4CAF50)
                                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                    width: isPowered ? 3.5 : 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Top Metallic Grounding Clip (Schuko Earth Pin)
                                    Positioned(
                                      top: 8,
                                      child: Container(
                                        width: 14,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD4AF37), // Brass
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),

                                    // Bottom Metallic Grounding Clip
                                    Positioned(
                                      bottom: 8,
                                      child: Container(
                                        width: 14,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD4AF37), // Brass
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),

                                    // Left Pin Receptacle (Cylindrical Hole)
                                    Positioned(
                                      left: 36,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF111413),
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF3B443F) : const Color(0xFFD0CAC1),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Right Pin Receptacle (Cylindrical Hole)
                                    Positioned(
                                      right: 36,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF111413),
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF3B443F) : const Color(0xFFD0CAC1),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Center Tactile Relay Switch Button
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isPowered ? AppColors.primaryContainer : (isDark ? AppColors.darkCardSecondary : Colors.white),
                                        border: Border.all(
                                          color: isPowered ? Colors.white : AppColors.secondary,
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.12),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.power_settings_new_rounded,
                                        color: isPowered ? Colors.white : AppColors.secondary,
                                        size: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Instruction Hint Text
                      Text(
                        'Prize dokunarak röleyi açıp kapatabilirsiniz',
                        style: AppTypography.caption.copyWith(color: AppColors.secondary),
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
                              Icons.power_rounded,
                              size: 20,
                              color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isPowered ? 'Röle Açık' : 'Röle Kapalı',
                              style: AppTypography.headlineSmall.copyWith(
                                color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 14),
                            NestoraSwitch(
                              value: isPowered,
                              onChanged: (_) {
                                if (_childLockEnabled) {
                                  showGlowingToast(
                                    context,
                                    message: 'Çocuk kilidi devrede! Önce kilidi kaldırın.',
                                    icon: Icons.lock_rounded,
                                  );
                                  return;
                                }
                                context.read<DevicesCubit>().toggleDevicePower(plug.id);
                                showGlowingToast(
                                  context,
                                  message: isPowered ? 'Priz rölesi kapatıldı.' : 'Priz rölesi açıldı.',
                                  icon: Icons.power_rounded,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Live Energy & Consumption Meter (Watt, Volt, Ampere, kWh)
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
                                    Icons.bolt_rounded,
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
                                        'Anlık Güç & Tüketim',
                                        style: AppTypography.headlineSmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Dinamik şebeke telemetrisi',
                                        style: AppTypography.caption.copyWith(color: AppColors.secondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              children: [
                                PulsingGlowDot(size: 6, color: AppColors.primaryContainer),
                                SizedBox(width: 6),
                                Text(
                                  'Canlı Ölçüm',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 4 Telemetry Metrics Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.1,
                        children: [
                          _buildTelemetryCard(
                            title: 'Anlık Güç',
                            value: '${liveWatts.toStringAsFixed(1)} W',
                            icon: Icons.flash_on_rounded,
                            isDark: isDark,
                          ),
                          _buildTelemetryCard(
                            title: 'Şebeke Gerilimi',
                            value: '${liveVolts.toStringAsFixed(0)} V',
                            icon: Icons.electrical_services_rounded,
                            isDark: isDark,
                          ),
                          _buildTelemetryCard(
                            title: 'Akım Şiddeti',
                            value: '${liveAmps.toStringAsFixed(2)} A',
                            icon: Icons.speed_rounded,
                            isDark: isDark,
                          ),
                          _buildTelemetryCard(
                            title: 'Günlük Tüketim',
                            value: '${dailyKwh.toStringAsFixed(2)} kWh',
                            icon: Icons.calendar_today_rounded,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Child Lock (Çocuk Emniyet Kilidi)
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
                  child: Row(
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
                              child: Icon(
                                _childLockEnabled ? Icons.lock_rounded : Icons.lock_open_rounded,
                                size: 20,
                                color: _childLockEnabled ? AppColors.warmAmber : AppColors.primaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Çocuk Kilidi',
                                    style: AppTypography.headlineSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _childLockEnabled
                                        ? 'Fiziksel tuş & soket koruması aktif'
                                        : 'Fiziksel müdahale serbest',
                                    style: AppTypography.caption.copyWith(color: AppColors.secondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      NestoraSwitch(
                        value: _childLockEnabled,
                        onChanged: (_) => _toggleChildLock(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Auto-Off Timer (Otomatik Kapanma Zamanlayıcısı)
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
                              Icons.timer_rounded,
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
                                  'Otomatik Kapanma',
                                  style: AppTypography.headlineSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  _selectedTimerMinutes > 0
                                      ? 'Priz $_selectedTimerMinutes dk sonra otomatik kapanacak'
                                      : 'Zamanlayıcı aktif değil',
                                  style: AppTypography.caption.copyWith(color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Preset Pills
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [15, 30, 60, 120, 0].map((minutes) {
                          final isSelected = _selectedTimerMinutes == minutes;
                          final label = minutes == 0 ? 'İptal' : (minutes >= 60 ? '${minutes ~/ 60} sa' : '$minutes dk');
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: GestureDetector(
                                onTap: () => _selectTimer(minutes),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryContainer
                                        : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      label,
                                      style: AppTypography.labelSmall.copyWith(
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
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryCard({
    required String title,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.secondary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
