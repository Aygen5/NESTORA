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
import '../../../notifications/domain/entities/app_notification.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../domain/device_model.dart';
import '../cubit/devices_cubit.dart';
import '../cubit/devices_state.dart';
import 'add_edit_device_page.dart';

/// Dedicated, interactive Security Camera (Giriş Güvenlik Kamerası) control screen for Nestora.
/// Features a realistic CCTV camera simulation, live stream viewport with HUD, Night Vision (IR),
/// Motion Detection, Two-Way Audio, PTZ Pan/Tilt controls, Alarm Siren, and Snapshot capture.
class SecurityCameraControlPage extends StatefulWidget {
  final String? deviceId;

  const SecurityCameraControlPage({super.key, this.deviceId});

  @override
  State<SecurityCameraControlPage> createState() => _SecurityCameraControlPageState();
}

class _SecurityCameraControlPageState extends State<SecurityCameraControlPage>
    with SingleTickerProviderStateMixin {
  bool _nightVisionEnabled = false;
  bool _motionDetectionEnabled = true;
  bool _sirenActive = false;
  bool _isIntercomActive = false;
  final bool _showReticleGrid = true;
  int _panAngle = 0; // -90 to +90 degrees
  int _tiltAngle = 15; // -30 to +60 degrees

  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _triggerSnapshot(BuildContext context, String cameraName) {
    showGlowingToast(
      context,
      message: 'Fotoğraf yakalandı ve güvenlik galerisine kaydedildi.',
      icon: Icons.camera_alt_rounded,
    );

    // Also register an in-app notification if Cubit is available
    final notifCubit = context.read<NotificationsCubit>();
    notifCubit.addNotification(
      AppNotification(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        title: '$cameraName Anlık Görüntü',
        message: 'Manuel kamera fotoğrafı saat ${_formatTime(_currentTime)} itibarıyla kaydedildi.',
        type: NotificationType.security,
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  void _toggleSiren(BuildContext context) {
    setState(() {
      _sirenActive = !_sirenActive;
    });
    showGlowingToast(
      context,
      message: _sirenActive
          ? 'UYARI: Caydırıcı alarm sireni çalıyor!'
          : 'Alarm sireni kapatıldı.',
      icon: _sirenActive ? Icons.warning_rounded : Icons.notifications_off_rounded,
    );
  }

  void _toggleIntercom() {
    setState(() {
      _isIntercomActive = !_isIntercomActive;
    });
    showGlowingToast(
      context,
      message: _isIntercomActive
          ? 'İki yönlü telsiz / mikrofon açıldı. Konuşabilirsiniz.'
          : 'Mikrofon kapatıldı.',
      icon: _isIntercomActive ? Icons.mic_rounded : Icons.mic_off_rounded,
    );
  }

  void _adjustPan(int delta) {
    setState(() {
      _panAngle = (_panAngle + delta).clamp(-90, 90);
    });
    showGlowingToast(
      context,
      message: 'Yatay Açı (Pan): $_panAngle°',
      icon: Icons.swap_horiz_rounded,
    );
  }

  void _adjustTilt(int delta) {
    setState(() {
      _tiltAngle = (_tiltAngle + delta).clamp(-30, 60);
    });
    showGlowingToast(
      context,
      message: 'Dikey Açı (Tilt): $_tiltAngle°',
      icon: Icons.swap_vert_rounded,
    );
  }

  void _resetPtz() {
    setState(() {
      _panAngle = 0;
      _tiltAngle = 15;
    });
    showGlowingToast(
      context,
      message: 'Kamera merkez odak noktasına sıfırlandı.',
      icon: Icons.filter_center_focus_rounded,
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _showDeleteDialog(BuildContext context, DeviceModel camera) async {
    final confirmed = await showNestoraDeleteDialog(
      context: context,
      title: '"${camera.name}" Silinecek',
      message:
          'Bu güvenlik kamerası sistemden silindiğinde canlı yayın ve tüm hareket bildirimleri durdurulacaktır. Onaylıyor musunuz?',
      deleteButtonText: 'Kamerayı Sil',
    );
    if (confirmed == true && context.mounted) {
      context.read<DevicesCubit>().deleteDeviceById(camera.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final devicesCubit = context.watch<DevicesCubit>();
    final devicesState = devicesCubit.state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final devices = (devicesState is DevicesLoaded)
        ? devicesState.devices.map(SeedData.deviceToModel).toList()
        : SeedData.defaultDeviceModels;

    final camera = devices.firstWhere(
      (d) => widget.deviceId != null && widget.deviceId!.isNotEmpty
          ? d.id == widget.deviceId
          : (d.type == DeviceType.security || d.name.toLowerCase().contains('kamera')),
      orElse: () => devices.firstWhere(
        (d) => d.type == DeviceType.security,
        orElse: () => devices.first,
      ),
    );

    final isStreaming = camera.isPoweredOn;

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
                      camera.name,
                      style: AppTypography.headlineSmall.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${camera.room} • Akıllı Güvenlik Kamerası',
                      style: AppTypography.caption.copyWith(color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: camera.isPoweredOn ? 'Kamerayı Kapat' : 'Kamerayı Aç',
                icon: Icon(
                  Icons.power_settings_new_rounded,
                  color: camera.isPoweredOn
                      ? (isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer)
                      : AppColors.secondary,
                ),
                onPressed: () => context.read<DevicesCubit>().toggleDevicePower(camera.id),
              ),
              IconButton(
                tooltip: camera.isFavorite ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
                icon: Icon(
                  camera.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  color: camera.isFavorite ? AppColors.warmAmber : AppColors.secondary,
                ),
                onPressed: () {
                  context.read<DevicesCubit>().toggleDeviceFavorite(camera.id);
                  showGlowingToast(
                    context,
                    message: camera.isFavorite ? 'Favorilerden çıkarıldı.' : 'Favorilere eklendi.',
                    icon: Icons.star_rounded,
                  );
                },
              ),
              IconButton(
                tooltip: 'Düzenle',
                icon: const Icon(Icons.tune_rounded, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditDevicePage(device: camera, isEditing: true),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Sil',
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                onPressed: () => _showDeleteDialog(context, camera),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // 1. Live Camera Stream Viewport Container
              _buildLiveStreamViewport(context, camera, isStreaming, isDark),
              const SizedBox(height: 20),

              // 2. Stream Power & Master Relay Switch
              _buildMasterPowerCard(context, camera, isStreaming, isDark),
              const SizedBox(height: 20),

              // 3. Quick Security Action Toolbar (Snapshot, Siren, Night Vision, Reticle)
              _buildActionToolbar(context, camera, isStreaming, isDark),
              const SizedBox(height: 20),

              // 4. PTZ Directional Pan/Tilt D-Pad Controller
              _buildPtzController(context, isStreaming, isDark),
              const SizedBox(height: 20),

              // 5. Environmental & Connectivity Telemetry
              _buildTelemetryCard(context, camera, isStreaming, isDark),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. LIVE STREAM VIEWPORT
  // -------------------------------------------------------------
  Widget _buildLiveStreamViewport(
    BuildContext context,
    DeviceModel camera,
    bool isStreaming,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isStreaming
              ? (_sirenActive ? AppColors.error : AppColors.primaryContainer)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isStreaming ? 2.0 : 1.0,
        ),
        boxShadow: [
          if (isStreaming)
            BoxShadow(
              color: (_sirenActive ? AppColors.error : AppColors.primaryContainer)
                  .withValues(alpha: 0.25),
              blurRadius: 24,
              spreadRadius: 2,
            )
          else
            ...AppColors.cardShadow,
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background simulation (Night vision or Daylight Entrance)
          if (isStreaming)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _nightVisionEnabled
                      ? [
                          const Color(0xFF0F2618),
                          const Color(0xFF041208),
                        ]
                      : [
                          const Color(0xFF1E2836),
                          const Color(0xFF111720),
                        ],
                ),
              ),
              child: CustomPaint(
                painter: _CameraFeedPainter(
                  nightVision: _nightVisionEnabled,
                  showReticle: _showReticleGrid,
                  pan: _panAngle,
                  tilt: _tiltAngle,
                ),
              ),
            )
          else
            // Standby Privacy State
            Container(
              color: const Color(0xFF121417),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.videocam_off_rounded,
                        color: Colors.white54,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kamera Gizlilik Modunda',
                      style: AppTypography.cardTitle(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Canlı akış ve hareket sensörü şu anda kapalı.',
                      style: AppTypography.caption.copyWith(color: Colors.white60),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      icon: const Icon(Icons.power_settings_new_rounded, size: 16),
                      label: const Text('Akışı Başlat'),
                      onPressed: () {
                        context.read<DevicesCubit>().toggleDevicePower(camera.id);
                        showGlowingToast(
                          context,
                          message: 'Kamera canlı yayını başlatılıyor...',
                          icon: Icons.videocam_rounded,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

          // HUD Live Overlays
          if (isStreaming) ...[
            // Top HUD Bar: Live Badge, Name, Timestamp, Signal
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // REC & LIVE Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PulsingGlowDot(size: 7, color: Colors.white),
                            SizedBox(width: 5),
                            Text(
                              'CANLI',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatTime(_currentTime),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Resolution & Wi-Fi Quality
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_rounded, size: 13, color: Color(0xFF8FD8A0)),
                        SizedBox(width: 4),
                        Text(
                          '1080p • 30fps',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom HUD Bar: Mode indicators (IR, Motion, Siren)
            Positioned(
              bottom: 14,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (_nightVisionEnabled)
                          _buildHudBadge(
                            icon: Icons.nightlight_round,
                            label: 'GECE GÖRÜŞÜ',
                            color: const Color(0xFF8FD8A0),
                          ),
                        if (_motionDetectionEnabled)
                          _buildHudBadge(
                            icon: Icons.motion_photos_on_rounded,
                            label: 'HAREKET ALGILAMA',
                            color: AppColors.warmAmber,
                          ),
                        if (_sirenActive)
                          _buildHudBadge(
                            icon: Icons.warning_amber_rounded,
                            label: 'SİREN AKTİF',
                            color: Colors.redAccent,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'P: $_panAngle° / T: $_tiltAngle°',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHudBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. MASTER POWER & RELAY CARD
  // -------------------------------------------------------------
  Widget _buildMasterPowerCard(
    BuildContext context,
    DeviceModel camera,
    bool isStreaming,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isStreaming
                  ? (isDark ? const Color(0xFF283B2C) : AppColors.primaryContainer.withValues(alpha: 0.14))
                  : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isStreaming ? Icons.videocam_rounded : Icons.videocam_off_rounded,
              color: isStreaming
                  ? (isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer)
                  : AppColors.secondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isStreaming ? 'Kamera Yayını Aktif' : 'Kamera Kapalı (Gizlilik Modu)',
                  style: AppTypography.cardTitle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isStreaming
                      ? 'Görüntü aktarımı ve sensörler kesintisiz çalışıyor.'
                      : 'Kamera lensi bekleme modunda; elektrik tüketimi 0.4W.',
                  style: AppTypography.caption.copyWith(color: AppColors.secondary),
                ),
              ],
            ),
          ),
          NestoraSwitch(
            value: isStreaming,
            onChanged: (_) {
              context.read<DevicesCubit>().toggleDevicePower(camera.id);
              showGlowingToast(
                context,
                message: isStreaming
                    ? '${camera.name} kapatıldı (Gizlilik modu).'
                    : '${camera.name} canlı akışı başlatıldı.',
                icon: Icons.power_rounded,
              );
            },
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. QUICK ACTION TOOLBAR
  // -------------------------------------------------------------
  Widget _buildActionToolbar(
    BuildContext context,
    DeviceModel camera,
    bool isStreaming,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Snapshot
          Expanded(
            child: _buildActionButton(
              icon: Icons.camera_alt_rounded,
              label: 'Fotoğraf',
              isActive: false,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              onTap: isStreaming ? () => _triggerSnapshot(context, camera.name) : null,
              isDark: isDark,
            ),
          ),
          // 2. Intercom
          Expanded(
            child: _buildActionButton(
              icon: _isIntercomActive ? Icons.mic_rounded : Icons.mic_none_rounded,
              label: 'Konuş',
              isActive: _isIntercomActive,
              color: const Color(0xFF29B6F6),
              onTap: isStreaming ? _toggleIntercom : null,
              isDark: isDark,
            ),
          ),
          // 3. Night Vision
          Expanded(
            child: _buildActionButton(
              icon: _nightVisionEnabled ? Icons.nightlight_round : Icons.nightlight_outlined,
              label: 'Gece Görüşü',
              isActive: _nightVisionEnabled,
              color: const Color(0xFF66BB6A),
              onTap: isStreaming
                  ? () {
                      setState(() => _nightVisionEnabled = !_nightVisionEnabled);
                      showGlowingToast(
                        context,
                        message: _nightVisionEnabled
                            ? 'Kızılötesi (IR) gece görüşü açıldı.'
                            : 'Gece görüşü kapatıldı (Standart renkli mod).',
                        icon: Icons.nightlight_round,
                      );
                    }
                  : null,
              isDark: isDark,
            ),
          ),
          // 4. Motion Detection
          Expanded(
            child: _buildActionButton(
              icon: _motionDetectionEnabled
                  ? Icons.motion_photos_on_rounded
                  : Icons.motion_photos_off_rounded,
              label: 'Hareket',
              isActive: _motionDetectionEnabled,
              color: AppColors.warmAmber,
              onTap: isStreaming
                  ? () {
                      setState(() => _motionDetectionEnabled = !_motionDetectionEnabled);
                      showGlowingToast(
                        context,
                        message: _motionDetectionEnabled
                            ? 'Yapay zeka hareket algılama aktif.'
                            : 'Hareket algılama devre dışı bırakıldı.',
                        icon: Icons.motion_photos_on_rounded,
                      );
                    }
                  : null,
              isDark: isDark,
            ),
          ),
          // 5. Siren
          Expanded(
            child: _buildActionButton(
              icon: _sirenActive ? Icons.warning_rounded : Icons.warning_amber_rounded,
              label: 'Siren',
              isActive: _sirenActive,
              color: Colors.redAccent,
              onTap: isStreaming ? () => _toggleSiren(context) : null,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color color,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive
                    ? color.withValues(alpha: 0.22)
                    : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? color : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                color: disabled
                    ? AppColors.secondary.withValues(alpha: 0.4)
                    : (isActive ? color : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                size: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: disabled
                    ? AppColors.secondary.withValues(alpha: 0.4)
                    : (isActive ? color : AppColors.secondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 4. PTZ PAN/TILT D-PAD CONTROLLER
  // -------------------------------------------------------------
  Widget _buildPtzController(
    BuildContext context,
    bool isStreaming,
    bool isDark,
  ) {
    return Container(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PTZ Motor Kontrolü',
                      style: AppTypography.cardTitle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      '360° Yatay ve 90° Dikey Motor Yönlendirmesi',
                      style: AppTypography.caption.copyWith(color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: isStreaming ? _resetPtz : null,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Ortala'),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Tactile Cross D-Pad
          SizedBox(
            width: 190,
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer controller dial base
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 1.5,
                    ),
                  ),
                ),
                // Center Reset / Center Button
                InkWell(
                  onTap: isStreaming ? _resetPtz : null,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.darkCard : Colors.white,
                      boxShadow: AppColors.subtleShadow,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '0°',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.primaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
                // UP (Tilt +)
                Positioned(
                  top: 8,
                  child: _buildDpadButton(
                    icon: Icons.keyboard_arrow_up_rounded,
                    onTap: isStreaming ? () => _adjustTilt(10) : null,
                    isDark: isDark,
                  ),
                ),
                // DOWN (Tilt -)
                Positioned(
                  bottom: 8,
                  child: _buildDpadButton(
                    icon: Icons.keyboard_arrow_down_rounded,
                    onTap: isStreaming ? () => _adjustTilt(-10) : null,
                    isDark: isDark,
                  ),
                ),
                // LEFT (Pan -)
                Positioned(
                  left: 8,
                  child: _buildDpadButton(
                    icon: Icons.keyboard_arrow_left_rounded,
                    onTap: isStreaming ? () => _adjustPan(-15) : null,
                    isDark: isDark,
                  ),
                ),
                // RIGHT (Pan +)
                Positioned(
                  right: 8,
                  child: _buildDpadButton(
                    icon: Icons.keyboard_arrow_right_rounded,
                    onTap: isStreaming ? () => _adjustPan(15) : null,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Angle Feedback Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'Yatay Açıklık: $_panAngle°',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Container(width: 1, height: 16, color: AppColors.secondary.withValues(alpha: 0.3)),
                Text(
                  'Dikey Eğim: $_tiltAngle°',
                  style: AppTypography.caption.copyWith(
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

  Widget _buildDpadButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? AppColors.darkCard : Colors.white,
          boxShadow: AppColors.subtleShadow,
        ),
        child: Icon(
          icon,
          size: 26,
          color: onTap != null
              ? (isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer)
              : AppColors.secondary.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 5. TELEMETRY & HARDWARE SPECS
  // -------------------------------------------------------------
  Widget _buildTelemetryCard(
    BuildContext context,
    DeviceModel camera,
    bool isStreaming,
    bool isDark,
  ) {
    return Container(
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
          Text(
            'Donanım & Ağ Durumu',
            style: AppTypography.cardTitle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildTelemetryTile(
                  icon: Icons.bolt_rounded,
                  label: 'Güç Tüketimi',
                  value: isStreaming ? '${camera.currentPowerWatts} W' : '0.4 W',
                  color: AppColors.warmAmber,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTelemetryTile(
                  icon: Icons.memory_rounded,
                  label: 'Mikro SD Kayıt',
                  value: '128 GB (%42 Dolu)',
                  color: const Color(0xFF29B6F6),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTelemetryTile(
                  icon: Icons.network_check_rounded,
                  label: 'Wi-Fi Sinyali',
                  value: isStreaming ? '-48 dBm (%98)' : 'Beklemede',
                  color: const Color(0xFF66BB6A),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTelemetryTile(
                  icon: Icons.shield_outlined,
                  label: 'Güvenlik Protokolü',
                  value: 'AES-256 Şifreli',
                  color: const Color(0xFFAB47BC),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(color: AppColors.secondary, fontSize: 10.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter rendering a simulated live CCTV viewfinder grid and motion reticle.
class _CameraFeedPainter extends CustomPainter {
  final bool nightVision;
  final bool showReticle;
  final int pan;
  final int tilt;

  _CameraFeedPainter({
    required this.nightVision,
    required this.showReticle,
    required this.pan,
    required this.tilt,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = (nightVision ? const Color(0xFF8FD8A0) : Colors.white).withValues(alpha: 0.18)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Draw Rule of Thirds grid
    final thirdW = size.width / 3;
    final thirdH = size.height / 3;
    canvas.drawLine(Offset(thirdW, 0), Offset(thirdW, size.height), linePaint);
    canvas.drawLine(Offset(thirdW * 2, 0), Offset(thirdW * 2, size.height), linePaint);
    canvas.drawLine(Offset(0, thirdH), Offset(size.width, thirdH), linePaint);
    canvas.drawLine(Offset(0, thirdH * 2), Offset(size.width, thirdH * 2), linePaint);

    if (showReticle) {
      // Center targeting bracket
      final center = Offset(size.width / 2 + (pan * 0.4), size.height / 2 - (tilt * 0.3));
      final reticlePaint = Paint()
        ..color = (nightVision ? const Color(0xFF8FD8A0) : const Color(0xFF80D8FF)).withValues(alpha: 0.6)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;

      const r = 24.0;
      const corner = 7.0;

      // Top-Left
      canvas.drawLine(Offset(center.dx - r, center.dy - r + corner), Offset(center.dx - r, center.dy - r), reticlePaint);
      canvas.drawLine(Offset(center.dx - r, center.dy - r), Offset(center.dx - r + corner, center.dy - r), reticlePaint);

      // Top-Right
      canvas.drawLine(Offset(center.dx + r - corner, center.dy - r), Offset(center.dx + r, center.dy - r), reticlePaint);
      canvas.drawLine(Offset(center.dx + r, center.dy - r), Offset(center.dx + r, center.dy - r + corner), reticlePaint);

      // Bottom-Left
      canvas.drawLine(Offset(center.dx - r, center.dy + r - corner), Offset(center.dx - r, center.dy + r), reticlePaint);
      canvas.drawLine(Offset(center.dx - r, center.dy + r), Offset(center.dx - r + corner, center.dy + r), reticlePaint);

      // Bottom-Right
      canvas.drawLine(Offset(center.dx + r - corner, center.dy + r), Offset(center.dx + r, center.dy + r), reticlePaint);
      canvas.drawLine(Offset(center.dx + r, center.dy + r), Offset(center.dx + r, center.dy + r - corner), reticlePaint);

      // Small center crosshair dot
      canvas.drawCircle(center, 1.8, reticlePaint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _CameraFeedPainter oldDelegate) {
    return oldDelegate.nightVision != nightVision ||
        oldDelegate.showReticle != showReticle ||
        oldDelegate.pan != pan ||
        oldDelegate.tilt != tilt;
  }
}
