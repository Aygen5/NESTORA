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

/// Predefined TV channel item model.
class TvChannelItem {
  final String id;
  final String name;
  final String number;
  final String program;
  final IconData icon;
  final Color themeColor;
  final Color ambilightColor;
  final bool isApp;

  const TvChannelItem({
    required this.id,
    required this.name,
    required this.number,
    required this.program,
    required this.icon,
    required this.themeColor,
    required this.ambilightColor,
    this.isApp = false,
  });
}

/// Dedicated, interactive television control screen for Nestora.
/// Features a realistic TV screen figure with ambilight, remote D-Pad,
/// volume slider, input selection, and live energy display.
class TvControlPage extends StatefulWidget {
  final String? deviceId;

  const TvControlPage({super.key, this.deviceId});

  @override
  State<TvControlPage> createState() => _TvControlPageState();
}

class _TvControlPageState extends State<TvControlPage> {
  int _volume = 32;
  bool _isMuted = false;
  int _preMuteVolume = 32;
  String _selectedChannelId = 'ch-1';
  String _selectedInput = 'TV';
  int _sleepTimerMinutes = 0;
  Timer? _sleepCountdownTimer;

  static const List<TvChannelItem> _channels = [
    TvChannelItem(
      id: 'ch-1',
      name: 'TRT Belgesel',
      number: '1',
      program: 'Doğanın Ritmi • 4K HDR',
      icon: Icons.forest_rounded,
      themeColor: Color(0xFF2E7D32),
      ambilightColor: Color(0xFF81C784),
    ),
    TvChannelItem(
      id: 'ch-2',
      name: 'BBC Earth',
      number: '2',
      program: 'Gezegenimiz 2 • Belgesel',
      icon: Icons.public_rounded,
      themeColor: Color(0xFF0277BD),
      ambilightColor: Color(0xFF4FC3F7),
    ),
    TvChannelItem(
      id: 'ch-3',
      name: 'National Geographic',
      number: '3',
      program: 'Vahşi Yaşam Gizemleri',
      icon: Icons.explore_rounded,
      themeColor: Color(0xFFF57F17),
      ambilightColor: Color(0xFFFFD54F),
    ),
    TvChannelItem(
      id: 'ch-4',
      name: 'S Sport',
      number: '4',
      program: 'Canlı: Premier Lig Karşılaşması',
      icon: Icons.sports_soccer_rounded,
      themeColor: Color(0xFFC62828),
      ambilightColor: Color(0xFFEF5350),
    ),
    TvChannelItem(
      id: 'app-netflix',
      name: 'Netflix',
      number: 'App',
      program: 'Stranger Things • Sezon 5',
      icon: Icons.movie_filter_rounded,
      themeColor: Color(0xFF880E4F),
      ambilightColor: Color(0xFFE53935),
      isApp: true,
    ),
    TvChannelItem(
      id: 'app-youtube',
      name: 'YouTube',
      number: 'App',
      program: 'Nestora Smart Home 4K Tanıtım',
      icon: Icons.smart_display_rounded,
      themeColor: Color(0xFFAD1457),
      ambilightColor: Color(0xFFFF4081),
      isApp: true,
    ),
  ];

  static const List<String> _inputs = [
    'TV',
    'HDMI 1 (Konsol)',
    'HDMI 2 (Apple TV)',
    'USB Medya',
  ];

  @override
  void dispose() {
    _sleepCountdownTimer?.cancel();
    super.dispose();
  }

  TvChannelItem get _activeChannel => _channels.firstWhere(
        (c) => c.id == _selectedChannelId,
        orElse: () => _channels.first,
      );

  void _toggleMute() {
    setState(() {
      if (_isMuted) {
        _isMuted = false;
        _volume = _preMuteVolume > 0 ? _preMuteVolume : 25;
        showGlowingToast(
          context,
          message: 'Ses açıldı: %$_volume',
          icon: Icons.volume_up_rounded,
        );
      } else {
        _isMuted = true;
        _preMuteVolume = _volume;
        _volume = 0;
        showGlowingToast(
          context,
          message: 'Ses kapatıldı (Sessiz mod)',
          icon: Icons.volume_off_rounded,
        );
      }
    });
  }

  void _adjustVolume(int delta) {
    setState(() {
      _isMuted = false;
      _volume = (_volume + delta).clamp(0, 100);
    });
    showGlowingToast(
      context,
      message: 'Ses Seviyesi: %$_volume',
      icon: _volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
    );
  }

  void _setVolume(int newVol) {
    setState(() {
      _isMuted = newVol == 0;
      _volume = newVol.clamp(0, 100);
    });
  }

  void _selectChannel(DeviceModel tv, TvChannelItem channel) {
    setState(() {
      _selectedChannelId = channel.id;
    });
    // If TV is off, power it on automatically
    if (!tv.isPoweredOn) {
      context.read<DevicesCubit>().toggleDevicePower(tv.id);
    }
    showGlowingToast(
      context,
      message: '${channel.name} yayınına geçildi.',
      icon: channel.icon,
    );
  }

  void _selectInput(DeviceModel tv, String input) {
    setState(() {
      _selectedInput = input;
    });
    if (!tv.isPoweredOn) {
      context.read<DevicesCubit>().toggleDevicePower(tv.id);
    }
    showGlowingToast(
      context,
      message: 'Giriş kaynağı değiştirildi: $input',
      icon: Icons.input_rounded,
    );
  }

  void _onRemoteAction(String action) {
    showGlowingToast(
      context,
      message: 'Kumanda Komutu: $action',
      icon: Icons.settings_remote_rounded,
    );
  }

  void _selectSleepTimer(int minutes) {
    _sleepCountdownTimer?.cancel();
    setState(() {
      _sleepTimerMinutes = minutes;
    });
    if (minutes > 0) {
      showGlowingToast(
        context,
        message: 'Televizyon $minutes dakika sonra otomatik kapanacak.',
        icon: Icons.timer_rounded,
      );
    } else {
      showGlowingToast(
        context,
        message: 'Uyku zamanlayıcısı iptal edildi.',
        icon: Icons.timer_off_rounded,
      );
    }
  }

  void _showDeleteDialog(BuildContext context, DeviceModel tv) {
    showNestoraDeleteDialog(
      context: context,
      variation: DeleteDialogVariation.deviceDelete,
      title: '"${tv.name}" Silinecek',
      message:
          'Bu televizyon silindiğinde tüm senaryo ve oda bağlantılarından kaldırılacaktır. Onaylıyor musunuz?',
      deleteButtonText: 'Cihazı Sil',
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<DevicesCubit>().deleteDeviceById(tv.id);
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

    final tv = devices.firstWhere(
      (d) => widget.deviceId != null && widget.deviceId!.isNotEmpty
          ? d.id == widget.deviceId
          : (d.type == DeviceType.tv || d.name.toLowerCase().contains('televizyon') || d.name.toLowerCase().contains('tv')),
      orElse: () => devices.firstWhere(
        (d) => d.type == DeviceType.tv,
        orElse: () => devices.first,
      ),
    );

    final isPowered = tv.isPoweredOn;
    final activeChan = _activeChannel;
    final liveWatts = isPowered ? (95.0 + (_volume * 0.15)).toStringAsFixed(1) : '0.0';

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
                      tv.name,
                      style: AppTypography.headlineSmall.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${tv.room} • Akıllı Televizyon',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: tv.isFavorite ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
                icon: Icon(
                  tv.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  color: tv.isFavorite ? AppColors.warmAmber : AppColors.secondary,
                  size: 24,
                ),
                onPressed: () {
                  final newFav = !tv.isFavorite;
                  context.read<DevicesCubit>().toggleDeviceFavorite(tv.id);
                  showGlowingToast(
                    context,
                    message: newFav
                        ? '${tv.name} favorilere eklendi.'
                        : '${tv.name} favorilerden çıkarıldı.',
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
                      builder: (_) => AddEditDevicePage(device: tv, isEditing: true),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Cihazı Sil',
                icon: const Icon(Icons.delete_outline_rounded, size: 22, color: AppColors.error),
                onPressed: () => _showDeleteDialog(context, tv),
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
                // 1. Room, Status & Energy Header Pill
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
                                    const Icon(Icons.tv_rounded, size: 14, color: AppColors.primaryContainer),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        tv.room,
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
                                '4K OLED Smart TV',
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
                              isPowered ? 'Açık • $liveWatts W' : 'Kapalı • 0.0 W',
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

                // 2. Realistic TV Figure with Dynamic Ambilight & Screen Display
                Container(
                  width: double.infinity,
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
                      // Ambient Backlight / TV Physical Screen Stack
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isPowered
                              ? [
                                  BoxShadow(
                                    color: activeChan.ambilightColor.withValues(alpha: 0.45),
                                    blurRadius: 40,
                                    spreadRadius: 6,
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                  ),
                                ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF101413),
                              border: Border.all(
                                color: const Color(0xFF2C3530),
                                width: 5,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: isPowered
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // Active Channel Cinematic Background Gradient
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              activeChan.themeColor.withValues(alpha: 0.85),
                                              const Color(0xFF0F1512),
                                              activeChan.ambilightColor.withValues(alpha: 0.4),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Screen Top Header Bar
                                      Positioned(
                                        top: 10,
                                        left: 12,
                                        right: 12,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.6),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    activeChan.isApp ? Icons.apps_rounded : Icons.live_tv_rounded,
                                                    size: 12,
                                                    color: Colors.white70,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Giriş: $_selectedInput',
                                                    style: AppTypography.caption.copyWith(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primaryContainer.withValues(alpha: 0.8),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '4K HDR',
                                                    style: AppTypography.caption.copyWith(
                                                      color: Colors.white,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _isMuted ? '🔇 Sessiz' : '🔊 %$_volume',
                                                  style: AppTypography.caption.copyWith(
                                                    color: Colors.white70,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Center Channel Banner & Visual
                                      Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 54,
                                              height: 54,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.black.withValues(alpha: 0.4),
                                                border: Border.all(
                                                  color: Colors.white.withValues(alpha: 0.3),
                                                  width: 2,
                                                ),
                                              ),
                                              child: Icon(
                                                activeChan.icon,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              activeChan.name,
                                              style: AppTypography.headlineSmall.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              activeChan.program,
                                              style: AppTypography.caption.copyWith(
                                                color: Colors.white.withValues(alpha: 0.85),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Screen Bottom Live Progress Bar
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          color: Colors.black.withValues(alpha: 0.5),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Kanal No: ${activeChan.number}',
                                                style: AppTypography.caption.copyWith(
                                                  color: Colors.white70,
                                                  fontSize: 10,
                                                ),
                                              ),
                                              Text(
                                                'Canlı Yayın',
                                                style: AppTypography.caption.copyWith(
                                                  color: const Color(0xFF81C784),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Deep Matte Black Off-State
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.tv_off_rounded,
                                            size: 40,
                                            color: Colors.white.withValues(alpha: 0.2),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Televizyon Kapalı',
                                            style: AppTypography.bodySmall.copyWith(
                                              color: Colors.white38,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Bekleme Modu (Standby) • 0.0 W',
                                            style: AppTypography.caption.copyWith(
                                              color: Colors.white24,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),

                      // TV Bezel Bottom Stand & Standby / Active LED
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // LED Dot Indicator
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isPowered ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                                boxShadow: [
                                  BoxShadow(
                                    color: isPowered
                                        ? const Color(0xFF4CAF50).withValues(alpha: 0.8)
                                        : const Color(0xFFE53935).withValues(alpha: 0.6),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isPowered ? 'Aktif (LED Yeşil)' : 'Standby (LED Kırmızı)',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.secondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Metallic TV Stand Legs
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 140,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C3530) : const Color(0xFFB0B7B2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
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
                              Icons.power_settings_new_rounded,
                              size: 20,
                              color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isPowered ? 'Güç Açık' : 'Güç Kapalı',
                              style: AppTypography.headlineSmall.copyWith(
                                color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 14),
                            NestoraSwitch(
                              value: isPowered,
                              onChanged: (_) {
                                context.read<DevicesCubit>().toggleDevicePower(tv.id);
                                showGlowingToast(
                                  context,
                                  message: isPowered ? 'Televizyon kapatıldı.' : 'Televizyon açıldı.',
                                  icon: Icons.tv_rounded,
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

                // 3. Volume & Audio Control Card
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
                                child: Icon(
                                  _isMuted
                                      ? Icons.volume_off_rounded
                                      : (_volume > 50 ? Icons.volume_up_rounded : Icons.volume_down_rounded),
                                  size: 20,
                                  color: _isMuted ? AppColors.error : AppColors.primaryContainer,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ses Seviyesi',
                                    style: AppTypography.headlineSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    _isMuted ? 'Sessiz mod etkin' : 'Hoparlör: %$_volume',
                                    style: AppTypography.caption.copyWith(color: AppColors.secondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Mute Toggle Button
                          GestureDetector(
                            onTap: _toggleMute,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _isMuted
                                    ? AppColors.error.withValues(alpha: 0.15)
                                    : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isMuted ? AppColors.error : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isMuted ? Icons.volume_off_rounded : Icons.volume_mute_rounded,
                                    size: 16,
                                    color: _isMuted ? AppColors.error : AppColors.primaryContainer,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isMuted ? 'Sessiz' : 'Sustur',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: _isMuted ? AppColors.error : AppColors.primaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Interactive Volume Slider
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded),
                            color: AppColors.primaryContainer,
                            onPressed: () => _adjustVolume(-5),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.primaryContainer,
                                inactiveTrackColor:
                                    isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                                thumbColor: AppColors.primaryContainer,
                                overlayColor: AppColors.primaryContainer.withValues(alpha: 0.2),
                                trackHeight: 8,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                              ),
                              child: Slider(
                                value: _volume.toDouble(),
                                min: 0,
                                max: 100,
                                divisions: 100,
                                onChanged: (val) => _setVolume(val.round()),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            color: AppColors.primaryContainer,
                            onPressed: () => _adjustVolume(5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Interactive Channel & Streaming App Grid
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
                              Icons.grid_view_rounded,
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
                                  'Kanal & Uygulama Seçimi',
                                  style: AppTypography.headlineSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  'Dokunarak anında yayını başlatın',
                                  style: AppTypography.caption.copyWith(color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 2-Column Channel Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 2.1,
                        ),
                        itemCount: _channels.length,
                        itemBuilder: (context, index) {
                          final chan = _channels[index];
                          final isSelected = chan.id == _selectedChannelId;

                          return GestureDetector(
                            onTap: () => _selectChannel(tv, chan),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.secondaryContainer.withValues(alpha: 0.6)
                                    : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryContainer
                                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isSelected ? chan.themeColor : Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      chan.icon,
                                      size: 16,
                                      color: isSelected ? Colors.white : AppColors.primaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          chan.name,
                                          style: AppTypography.labelMedium.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          chan.isApp ? 'Uygulama' : 'Kanal ${chan.number}',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.secondary,
                                            fontSize: 10,
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

                // 5. HDMI & Input Source Selector
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
                              Icons.settings_input_hdmi_rounded,
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
                                  'Giriş & Kaynak (HDMI)',
                                  style: AppTypography.headlineSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  'Aktif giriş: $_selectedInput',
                                  style: AppTypography.caption.copyWith(color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Input Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _inputs.map((input) {
                          final isSelected = input == _selectedInput;
                          return ChoiceChip(
                            label: Text(input),
                            selected: isSelected,
                            onSelected: (_) => _selectInput(tv, input),
                            selectedColor: AppColors.primaryContainer,
                            backgroundColor: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Virtual Remote Control D-Pad & Navigation
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
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.settings_remote_rounded,
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
                                  'Sanal Uzaktan Kumanda',
                                  style: AppTypography.headlineSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  'D-Pad menü ve kanal navigasyonu',
                                  style: AppTypography.caption.copyWith(color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Circular D-Pad Controller
                      Container(
                        width: 210,
                        height: 210,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Up Arrow
                            Positioned(
                              top: 8,
                              child: IconButton(
                                icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 36),
                                color: AppColors.primaryContainer,
                                onPressed: () => _onRemoteAction('Yukarı'),
                              ),
                            ),
                            // Down Arrow
                            Positioned(
                              bottom: 8,
                              child: IconButton(
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 36),
                                color: AppColors.primaryContainer,
                                onPressed: () => _onRemoteAction('Aşağı'),
                              ),
                            ),
                            // Left Arrow
                            Positioned(
                              left: 8,
                              child: IconButton(
                                icon: const Icon(Icons.keyboard_arrow_left_rounded, size: 36),
                                color: AppColors.primaryContainer,
                                onPressed: () => _onRemoteAction('Sol'),
                              ),
                            ),
                            // Right Arrow
                            Positioned(
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.keyboard_arrow_right_rounded, size: 36),
                                color: AppColors.primaryContainer,
                                onPressed: () => _onRemoteAction('Sağ'),
                              ),
                            ),
                            // OK / Select Center Button
                            GestureDetector(
                              onTap: () => _onRemoteAction('OK / Seç'),
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryContainer,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryContainer.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'OK',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Secondary Remote Buttons (Back, Home, Menu, Info)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildRemoteActionButton(
                            icon: Icons.arrow_back_rounded,
                            label: 'Geri',
                            onTap: () => _onRemoteAction('Geri'),
                            isDark: isDark,
                          ),
                          _buildRemoteActionButton(
                            icon: Icons.home_rounded,
                            label: 'Ana Menü',
                            onTap: () => _onRemoteAction('Ana Sayfa'),
                            isDark: isDark,
                          ),
                          _buildRemoteActionButton(
                            icon: Icons.menu_rounded,
                            label: 'Menü',
                            onTap: () => _onRemoteAction('Menü'),
                            isDark: isDark,
                          ),
                          _buildRemoteActionButton(
                            icon: Icons.info_outline_rounded,
                            label: 'Bilgi',
                            onTap: () => _onRemoteAction('Bilgi'),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 7. Auto-Off / Sleep Timer
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
                              Icons.snooze_rounded,
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
                                  'Uyku Zamanlayıcısı',
                                  style: AppTypography.headlineSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  _sleepTimerMinutes > 0
                                      ? '$_sleepTimerMinutes dk sonra televizyon kapanacak'
                                      : 'Zamanlayıcı aktif değil',
                                  style: AppTypography.caption.copyWith(color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Timer Presets
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [15, 30, 60, 120, 0].map((minutes) {
                          final isSelected = _sleepTimerMinutes == minutes;
                          final label = minutes == 0 ? 'İptal' : '$minutes dk';
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: GestureDetector(
                                onTap: () => _selectSleepTimer(minutes),
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

  Widget _buildRemoteActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryContainer),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontSize: 10,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
