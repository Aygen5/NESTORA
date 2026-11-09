import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../../core/services/remote_config_service.dart';
import '../../../../core/utils/temperature_formatter.dart';
import '../../../../core/widgets/glowing_toast.dart';
import '../../../../core/widgets/nestora_announcement_banner.dart';
import '../../../../core/widgets/nestora_logo.dart';
import '../../../../core/widgets/nestora_switch.dart';
import '../../../../core/widgets/pulsing_glow_dot.dart';
import '../../../devices/domain/device_model.dart';
import '../../../devices/presentation/cubit/devices_cubit.dart';
import '../../../devices/presentation/cubit/devices_state.dart';
import '../../../devices/presentation/pages/ac_control_page.dart';
import '../../../devices/presentation/pages/coffee_machine_control_page.dart';
import '../../../devices/presentation/pages/lamp_control_page.dart';
import '../../../devices/presentation/pages/plug_control_page.dart';
import '../../../devices/presentation/pages/tv_control_page.dart';
import '../../../devices/presentation/pages/devices_page.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../../notifications/presentation/cubit/notifications_state.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/cubit/profile_state.dart';
import '../../../rooms/domain/room_model.dart';
import '../../../rooms/presentation/cubit/rooms_cubit.dart';
import '../../../rooms/presentation/cubit/rooms_state.dart';
import '../../../rooms/presentation/pages/add_edit_room_page.dart';
import '../../../rooms/presentation/pages/room_detail_page.dart';
import '../../../rooms/presentation/pages/rooms_page.dart';

/// Central Dashboard (Home) screen of Nestora smart home platform.
/// Connects dynamically to [ProfileCubit], [NotificationsCubit], [RoomsCubit],
/// and [DevicesCubit] as the single sources of truth.
class DashboardPage extends StatefulWidget {
  final VoidCallback? onNavigateToRooms;
  final void Function({DeviceStatusFilter? status})? onNavigateToDevices;
  final VoidCallback? onNavigateToProfile;

  const DashboardPage({
    super.key,
    this.onNavigateToRooms,
    this.onNavigateToDevices,
    this.onNavigateToProfile,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _activeScenario = 'Evdeyim';
  bool _isAnnouncementDismissed = false;

  /// Generates a contextual Turkish greeting based on the current hour.
  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Günaydın';
    } else if (hour >= 12 && hour < 18) {
      return 'İyi günler';
    } else if (hour >= 18 && hour < 23) {
      return 'İyi akşamlar';
    } else {
      return 'İyi geceler';
    }
  }

  void _onScenarioTapped(String scenario) {
    setState(() => _activeScenario = scenario);
    context.read<DevicesCubit>().applyQuickScene(scenario);
  }

  void _navigateToNotifications() {
    try {
      context.goToNotifications();
    } catch (_) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationsPage()),
      );
    }
  }

  void _navigateToProfile() {
    if (widget.onNavigateToProfile != null) {
      widget.onNavigateToProfile!();
    } else {
      try {
        context.goToProfile();
      } catch (_) {
        // Fallback if not inside GoRouter
      }
    }
  }

  void _navigateToRooms() {
    if (widget.onNavigateToRooms != null) {
      widget.onNavigateToRooms!();
      return;
    }
    try {
      context.goToRooms();
    } catch (_) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RoomsPage()),
      );
    }
  }

  void _navigateToAddRoom() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddEditRoomPage(isEditing: false),
      ),
    );
  }

  void _navigateToRoomDetail(RoomModel room) {
    try {
      context.goToRoomDetail(room.id, room: room);
    } catch (_) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RoomDetailPage(room: room)),
      );
    }
  }

  void _navigateToDevice(DeviceModel device) {
    final lower = device.name.toLowerCase();
    final isBulb = device.type == DeviceType.bulb || lower.contains('lamba');
    final isAc = device.type == DeviceType.ac || lower.contains('klima');
    final isTv = device.type == DeviceType.tv || lower.contains('televizyon') || lower.contains('tv');
    final isCoffee = (lower.contains('kahve') || lower.contains('coffee'));
    final isPlug = device.type == DeviceType.plug || lower.contains('priz');

    if (isBulb) {
      try {
        context.goToLampControl(device.id);
      } catch (_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LampControlPage(deviceId: device.id)),
        );
      }
    } else if (isAc) {
      try {
        context.goToClimateControl(device.id);
      } catch (_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AcControlPage(deviceId: device.id)),
        );
      }
    } else if (isTv) {
      try {
        context.goToTvControl(device.id);
      } catch (_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TvControlPage(deviceId: device.id)),
        );
      }
    } else if (isCoffee) {
      try {
        context.goToCoffeeControl(device.id);
      } catch (_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CoffeeMachineControlPage(deviceId: device.id)),
        );
      }
    } else if (isPlug) {
      try {
        context.goToPlugControl(device.id);
      } catch (_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlugControlPage(deviceId: device.id)),
        );
      }
    } else {
      context.read<DevicesCubit>().toggleDevicePower(device.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileCubit>().state;
    final notificationsState = context.watch<NotificationsCubit>().state;
    final roomsState = context.watch<RoomsCubit>().state;
    final devicesState = context.watch<DevicesCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Profile data
    final homeName = (profileState is ProfileLoaded)
        ? profileState.profile.homeName
        : SeedData.defaultProfile.homeName;
    final displayName = (profileState is ProfileLoaded)
        ? profileState.profile.displayName
        : SeedData.defaultProfile.displayName;
    final photoPath = (profileState is ProfileLoaded)
        ? profileState.profile.photoPath
        : null;

    // Notifications data
    final unreadNotificationCount = (notificationsState is NotificationsLoaded)
        ? notificationsState.unreadCount
        : 0;

    final tempUnit = (profileState is ProfileLoaded)
        ? profileState.profile.preferences.temperatureUnit
        : 'C';

    // Rooms data
    final rooms = (roomsState is RoomsLoaded)
        ? roomsState.rooms.map(SeedData.roomToModel).toList()
        : SeedData.defaultRoomModels;

    // Devices data
    final devices = (devicesState is DevicesLoaded)
        ? devicesState.devices.map(SeedData.deviceToModel).toList()
        : SeedData.defaultDeviceModels;
    final activeDeviceCount = (devicesState is DevicesLoaded)
        ? devicesState.activeCount
        : devices.where((d) => d.isPoweredOn).length;
    final totalWatts = (devicesState is DevicesLoaded)
        ? devicesState.totalPowerWatts
        : devices
            .where((d) => d.isPoweredOn)
            .fold<double>(0.0, (sum, d) => sum + (d.type == DeviceType.ac ? 1100.0 : (d.type == DeviceType.plug ? 240.0 : 12.0)));

    final greeting = _getTimeBasedGreeting();
    final userFirstName = displayName.trim().isNotEmpty
        ? displayName.trim().split(' ').first
        : '';

    return BlocListener<DevicesCubit, DevicesState>(
      listenWhen: (previous, current) {
        if (current is DevicesLoaded && current.feedbackMessage != null) {
          if (previous is! DevicesLoaded ||
              previous.feedbackMessage != current.feedbackMessage) {
            return true;
          }
        }
        return false;
      },
      listener: (context, state) {
        if (state is DevicesLoaded && state.feedbackMessage != null) {
          showGlowingToast(context, message: state.feedbackMessage!);
        }
      },
      child: SizedBox.expand(
        child: Container(
          color: isDark ? AppColors.darkBackground : AppColors.lightScaffold,
          child: Column(
            children: [
              // Fixed Top Bar / Header (76px Height)
              _buildHeader(
                context: context,
                isDark: isDark,
                unreadNotificationCount: unreadNotificationCount,
                favoriteDevices: devices.where((d) => d.isFavorite).toList(),
                photoPath: photoPath,
                displayName: displayName,
              ),

              // Scrollable Dashboard Body
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                        // Remote Broadcast Announcement Banner
                        if (!_isAnnouncementDismissed &&
                            sl.isRegistered<RemoteConfigService>() &&
                            sl<RemoteConfigService>().announcement.hasContent) ...[
                          NestoraAnnouncementBanner(
                            margin: const EdgeInsets.only(bottom: 14),
                            announcement: sl<RemoteConfigService>().announcement,
                            onDismiss: () =>
                                setState(() => _isAnnouncementDismissed = true),
                          ),
                        ],

                        // B.1 Greeting & Location (Image 3)
                        _buildGreetingSection(
                          isDark: isDark,
                          homeName: homeName,
                          userFirstName: userFirstName,
                        ),

                        const SizedBox(height: 14),

                        // B.2 Modern Villa Card & System Status (Image 3)
                        _buildHouseIllustrationCard(
                          isDark: isDark,
                          totalRooms: rooms.length,
                          totalDevices: devices.length,
                        ),

                        const SizedBox(height: 14),

                        // C.2 3'lü Canlı İstatistik Rozetleri (Image 3)
                        _buildSummaryStatsRow(
                          isDark: isDark,
                          totalDevices: devices.length,
                          activeDeviceCount: activeDeviceCount,
                          totalRooms: rooms.length,
                        ),

                        const SizedBox(height: 16),

                        // 1. NESTORA TYPOGRAPHY & HERO BANNER (Active Scenario - Image 1)
                        _buildHeroBanner(
                          isDark: isDark,
                          homeName: homeName,
                          greeting: greeting,
                          userFirstName: userFirstName,
                          activeDeviceCount: activeDeviceCount,
                          activeScenario: _activeScenario,
                        ),

                        const SizedBox(height: 18),

                        // 2. ENERGY USAGE OVERVIEW
                        _buildEnergyOverview(
                          isDark: isDark,
                          totalWatts: totalWatts,
                        ),

                        const SizedBox(height: 20),

                        // 3. QUICK SCENARIOS (Hızlı Senaryolar)
                        _buildQuickScenarios(isDark: isDark),

                        const SizedBox(height: 24),

                        // 4. ROOMS / SPACES (Odalarım Karuseli)
                        _buildRoomsSection(
                          context: context,
                          isDark: isDark,
                          rooms: rooms,
                          devices: devices,
                          tempUnit: tempUnit,
                        ),

                        const SizedBox(height: 26),

                        // 5. COMPACT ACTIVE DEVICES
                        _buildCompactDevicesSection(
                          context: context,
                          isDark: isDark,
                          devices: devices,
                          activeDeviceCount: activeDeviceCount,
                          tempUnit: tempUnit,
                        ),

                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Top Header: Expanded 76px Height, Logo 34px, Favorites with Modal, Notifications, Profile
  Widget _buildHeader({
    required BuildContext context,
    required bool isDark,
    required int unreadNotificationCount,
    required List<DeviceModel> favoriteDevices,
    required String? photoPath,
    required String displayName,
  }) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkCard : AppColors.lightScaffold)
            .withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo & Nestora Typography
              Row(
                children: [
                  const NestoraLogo(size: 34, enableNavigation: true),
                  const SizedBox(width: 10),
                  Text(
                    'Nestora',
                    style: AppTypography.cardTitle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.primaryContainer,
                    ).copyWith(fontWeight: FontWeight.w800, fontSize: 20),
                  ),
                ],
              ),
              // Action Buttons: Favoriler, Bildirimler, Profil
              Row(
                children: [
                  // Favoriler Butonu (With count badge and hover effect)
                  _buildHeaderButton(
                    tooltip: 'Favorilerim',
                    icon: favoriteDevices.isNotEmpty
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    iconColor: favoriteDevices.isNotEmpty
                        ? AppColors.warmAmber
                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    badgeCount: favoriteDevices.length,
                    badgeColor: AppColors.warmAmber,
                    onTap: () => _showFavoritesSheet(context, favoriteDevices),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 4),
                  // Bildirimler Butonu (With unread count badge and hover effect)
                  _buildHeaderButton(
                    tooltip: 'Bildirimler',
                    icon: Icons.notifications_none_rounded,
                    iconColor: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    badgeCount: unreadNotificationCount,
                    badgeColor: AppColors.error,
                    onTap: _navigateToNotifications,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  // Profile Avatar (local photo, asset portrait or user initial)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      key: const Key('dashboard_profile_avatar'),
                      onTap: _navigateToProfile,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondaryContainer,
                          border: Border.all(
                            color: AppColors.primaryContainer.withValues(alpha: 0.35),
                            width: 1.8,
                          ),
                        ),
                        child: ClipOval(
                          child: _buildHeaderAvatar(photoPath, displayName),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAvatar(String? photoPath, String displayName) {
    if (photoPath != null && photoPath.trim().isNotEmpty) {
      final trimmed = photoPath.trim();
      if (trimmed.startsWith('assets/')) {
        return Image.asset(
          trimmed,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(displayName),
        );
      }
      final file = File(trimmed);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(displayName),
        );
      }
    }
    return _buildFallbackAvatar(displayName);
  }

  Widget _buildHeaderButton({
    required String tooltip,
    required IconData icon,
    required Color iconColor,
    required int badgeCount,
    required Color badgeColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.primaryContainer.withValues(alpha: 0.08),
          splashColor: AppColors.primaryContainer.withValues(alpha: 0.12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 24, color: iconColor),
                if (badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFavoritesSheet(BuildContext context, List<DeviceModel> initialFavorites) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return BlocBuilder<DevicesCubit, DevicesState>(
          builder: (context, state) {
            final liveFavorites = (state is DevicesLoaded)
                ? state.favoriteDevices.map(SeedData.deviceToModel).toList()
                : initialFavorites;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
                maxWidth: 600,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sheet pull handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Sheet Title & Close
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.secondaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.star_rounded,
                                  color: AppColors.warmAmber,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Favori Cihazlarım',
                                    style: AppTypography.headlineSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${liveFavorites.length} cihaz favorilerde',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(modalContext),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Favorites Content List
                    if (liveFavorites.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: AppColors.secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.star_outline_rounded,
                                size: 30,
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Henüz favori cihazınız yok',
                              style: AppTypography.cardTitle(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Cihaz kartlarındaki yıldız simgesine dokunarak favorilerinize cihaz ekleyebilirsiniz.',
                              textAlign: TextAlign.center,
                              style: AppTypography.description(color: AppColors.secondary),
                            ),
                          ],
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: liveFavorites.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (ctx, index) {
                            final d = liveFavorites[index];
                            return _buildFavoriteTile(ctx, d, isDark, modalContext);
                          },
                        ),
                      ),
                    // Bottom Navigation Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.tune_rounded, size: 18),
                          label: const Text('Tüm Favorileri Cihazlar Sayfasında Aç'),
                          onPressed: () {
                            Navigator.pop(modalContext);
                            if (widget.onNavigateToDevices != null) {
                              widget.onNavigateToDevices!(status: DeviceStatusFilter.favorites);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFavoriteTile(
    BuildContext context,
    DeviceModel device,
    bool isDark,
    BuildContext modalContext,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          // Device Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: device.isPoweredOn
                  ? AppColors.primaryContainer
                  : (isDark ? Colors.white12 : Colors.black12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              device.icon,
              size: 20,
              color: device.isPoweredOn ? Colors.white : AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          // Info & Detail Navigation on Tap
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.pop(modalContext);
                _navigateToDevice(device);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    device.isPoweredOn ? 'Açık • Dokunarak Yönet' : 'Kapalı • Dokunarak Yönet',
                    style: AppTypography.caption.copyWith(
                      color: device.isPoweredOn ? AppColors.primaryContainer : AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Star un-favorite button
          IconButton(
            tooltip: 'Favorilerden Çıkar',
            icon: const Icon(Icons.star_rounded, color: AppColors.warmAmber, size: 22),
            onPressed: () {
              context.read<DevicesCubit>().toggleDeviceFavorite(device.id);
              showGlowingToast(
                context,
                message: '${device.name} favorilerden çıkarıldı.',
                icon: Icons.star_border_rounded,
              );
            },
          ),
          // Power switch
          NestoraSwitch(
            value: device.isPoweredOn,
            onChanged: (_) {
              final willBeOn = !device.isPoweredOn;
              context.read<DevicesCubit>().toggleDevicePower(device.id);
              showGlowingToast(
                context,
                message: willBeOn
                    ? '${device.name} açıldı.'
                    : '${device.name} kapatıldı.',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar(String displayName) {
    if (displayName.trim().isNotEmpty) {
      return Center(
        child: Text(
          displayName.trim().substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: AppColors.primaryContainer,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }
    return const Icon(
      Icons.person_rounded,
      size: 20,
      color: AppColors.primaryContainer,
    );
  }

  // B.1 Greeting & Location Section (Image 3)
  Widget _buildGreetingSection({
    required bool isDark,
    required String homeName,
    required String userFirstName,
  }) {
    final effectiveHomeName = homeName.trim().isNotEmpty ? homeName.trim() : "Aygen'in Evi";
    final effectiveName = userFirstName.trim().isNotEmpty ? userFirstName.trim() : 'Aygen';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 14,
                color: AppColors.primaryContainer,
              ),
              const SizedBox(width: 5),
              Text(
                effectiveHomeName,
                style: AppTypography.badge(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ).copyWith(fontWeight: FontWeight.w600, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Merhaba, $effectiveName',
          style: AppTypography.headlineLarge.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 26,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Evin bugün nasıl?',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.secondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // B.2 Modern Villa Illustration Card & Status Bar (Image 3)
  Widget _buildHouseIllustrationCard({
    required bool isDark,
    required int totalRooms,
    required int totalDevices,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(
              'assets/screens/modern_smart_house.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                child: const Center(
                  child: Icon(Icons.home_work_rounded, size: 54, color: AppColors.secondary),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkCard : Colors.white).withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PulsingGlowDot(
                        color: Color(0xFF4CAF50),
                        size: 7,
                        glowRadius: 5,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tüm Sistemler Normal',
                        style: AppTypography.badge(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ).copyWith(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    '$totalRooms Oda • $totalDevices Cihaz',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.secondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // C.2 3'lü Canlı İstatistik Rozetleri (Image 3)
  Widget _buildSummaryStatsRow({
    required bool isDark,
    required int totalDevices,
    required int activeDeviceCount,
    required int totalRooms,
  }) {
    return Row(
      children: [
        // 1. Toplam Cihaz
        Expanded(
          child: _SummaryStatCard(
            key: const Key('stat_card_devices'),
            isDark: isDark,
            icon: Icons.devices_other_rounded,
            value: '$totalDevices',
            label: 'Cihaz',
            hasDot: false,
          ),
        ),
        const SizedBox(width: 10),
        // 2. Açık Cihaz
        Expanded(
          child: _SummaryStatCard(
            key: const Key('stat_card_active'),
            isDark: isDark,
            icon: Icons.power_rounded,
            value: '$activeDeviceCount',
            label: 'Açık',
            hasDot: true,
            dotColor: const Color(0xFFC5A880), // Warm amber / natural stone accent
          ),
        ),
        const SizedBox(width: 10),
        // 3. Oda Sayısı
        Expanded(
          child: _SummaryStatCard(
            key: const Key('stat_card_rooms'),
            isDark: isDark,
            icon: Icons.door_sliding_outlined,
            value: '$totalRooms',
            label: 'Oda',
            hasDot: false,
          ),
        ),
      ],
    );
  }

  // 1. Hero Banner: Home Name, Welcome Greeting, Status
  Widget _buildHeroBanner({
    required bool isDark,
    required String homeName,
    required String greeting,
    required String userFirstName,
    required int activeDeviceCount,
    required String activeScenario,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFF263328),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'NESTORA · AKILLI YAŞAM',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.badge(
                    color: const Color(0xFFB7CCB9),
                  ).copyWith(letterSpacing: 1.0, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Live Sync Badge with Pulsing Glow Dot
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0x22FFFFFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PulsingGlowDot(
                          color: Color(0xFF6BD88A),
                          size: 7,
                          glowRadius: 5,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Canlı',
                          style: AppTypography.badge(color: Colors.white).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Eviniz, tek dokunuşla.',
            style: AppTypography.pageTitle(
              color: Colors.white,
            ).copyWith(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            userFirstName.isNotEmpty
                ? '$greeting, $userFirstName. Akıllı evinizin kontrolü artık çok daha kolay ve dengeli.'
                : 'Akıllı evinizin kontrolü artık çok daha kolay ve dengeli.',
            style: AppTypography.description(
              color: const Color(0xFFDCE5D7),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            key: const Key('dashboard_hero_active_scenario_badge'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _getScenarioAccentColor(activeScenario),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getScenarioIcon(activeScenario),
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Aktif Senaryo: $activeScenario',
                              style: AppTypography.badge(color: Colors.white).copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$activeDeviceCount açık',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getScenarioDescription(activeScenario),
                        style: const TextStyle(
                          color: Color(0xFFDCE5D7),
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScenarioAccentColor(String scenario) {
    switch (scenario) {
      case 'Evdeyim':
        return const Color(0xFF4CAF50);
      case 'Gündüz':
        return const Color(0xFFFFB300);
      case 'Gece Modu':
        return const Color(0xFF5C6BC0);
      case 'Dışarıda':
        return const Color(0xFFEF5350);
      default:
        return AppColors.primaryContainer;
    }
  }

  IconData _getScenarioIcon(String scenario) {
    switch (scenario) {
      case 'Evdeyim':
        return Icons.roofing_rounded;
      case 'Gündüz':
        return Icons.wb_sunny_rounded;
      case 'Gece Modu':
        return Icons.bedtime_rounded;
      case 'Dışarıda':
        return Icons.exit_to_app_rounded;
      default:
        return Icons.tune_rounded;
    }
  }

  String _getScenarioDescription(String scenario) {
    switch (scenario) {
      case 'Evdeyim':
        return 'Yaşam alanları aktif. Konfor sıcaklığı ve aydınlatma devrede.';
      case 'Gündüz':
        return 'Doğal gün ışığı devrede. Gereksiz lambalar kapalı, eko-klima aktif.';
      case 'Gece Modu':
        return 'Gece modu devrede. Yalnızca gece aydınlatması açık, klima sessiz modda.';
      case 'Dışarıda':
        return 'Ev boş modunda. Tüm lamba ve prizler kapalı, maksimum tasarruf devrede.';
      default:
        return 'Akıllı ev senaryosu devrede.';
    }
  }

  // 2. Energy Overview Card
  Widget _buildEnergyOverview({
    required bool isDark,
    required double totalWatts,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(18),
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
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF28342B) : AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      size: 18,
                      color: isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bugün Tüketilen Enerji',
                        style: AppTypography.description(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      Text(
                        '7,8 kWh',
                        style: AppTypography.cardTitle(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ).copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF28342B) : AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Hedef %68',
                  style: AppTypography.badge(
                    color: isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.68,
              minHeight: 6,
              backgroundColor: isDark
                  ? AppColors.darkCardSecondary
                  : AppColors.lightCardSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? const Color(0xFF6BD88A) : AppColors.primaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '7,8 kWh',
                style: AppTypography.badge(color: AppColors.secondary),
              ),
              Text(
                totalWatts > 0
                    ? 'Anlık: ${totalWatts.toStringAsFixed(0)} W · Hedef: 11,3 kWh'
                    : 'Günlük ortalama: 11,3 kWh',
                style: AppTypography.badge(color: AppColors.secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Quick Scenarios: Evdeyim, Gündüz, Gece Modu, Dışarıda
  Widget _buildQuickScenarios({required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hızlı Eylemler',
              style: AppTypography.sectionTitle(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              'Mod Seçimi',
              style: AppTypography.description(color: AppColors.secondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildScenarioChip(
                label: 'Evdeyim',
                icon: Icons.roofing_rounded,
                isSelected: _activeScenario == 'Evdeyim',
                isDark: isDark,
                onTap: () => _onScenarioTapped('Evdeyim'),
              ),
              const SizedBox(width: 8),
              _buildScenarioChip(
                label: 'Gündüz',
                icon: Icons.wb_sunny_rounded,
                isSelected: _activeScenario == 'Gündüz',
                isDark: isDark,
                onTap: () => _onScenarioTapped('Gündüz'),
              ),
              const SizedBox(width: 8),
              _buildScenarioChip(
                label: 'Gece Modu',
                icon: Icons.bedtime_rounded,
                isSelected: _activeScenario == 'Gece Modu',
                isDark: isDark,
                onTap: () => _onScenarioTapped('Gece Modu'),
              ),
              const SizedBox(width: 8),
              _buildScenarioChip(
                label: 'Dışarıda',
                icon: Icons.exit_to_app_rounded,
                isSelected: _activeScenario == 'Dışarıda',
                isDark: isDark,
                onTap: () => _onScenarioTapped('Dışarıda'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScenarioChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final animDuration = disableAnimations ? Duration.zero : const Duration(milliseconds: 200);

    return GestureDetector(
      key: Key('scenario_chip_$label'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: animDuration,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryContainer
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          boxShadow: isSelected ? AppColors.cardShadow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.secondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.buttonText(
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
              ).copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Odalarım 2x2 Grid (Image 3)
  Widget _buildRoomsSection({
    required BuildContext context,
    required bool isDark,
    required List<RoomModel> rooms,
    required List<DeviceModel> devices,
    required String tempUnit,
  }) {
    final displayedRooms = rooms.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Odalarım',
              key: const Key('dashboard_rooms_title'),
              style: AppTypography.sectionTitle(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  key: const Key('dashboard_add_room_button'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: _navigateToAddRoom,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF283B2C)
                          : AppColors.primaryContainer.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF4C7554)
                            : AppColors.primaryContainer.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 15,
                          color: isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Oda Ekle',
                          style: AppTypography.buttonText(
                            color: isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer,
                          ).copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  key: const Key('dashboard_view_all_rooms_button'),
                  onTap: _navigateToRooms,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(
                      'Tümünü Gör',
                      style: AppTypography.buttonText(
                        color: isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer,
                      ).copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final childAspectRatio = constraints.maxWidth > 600
                ? 2.2
                : (constraints.maxWidth > 400 ? 1.5 : 1.3);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedRooms.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, index) {
                final room = displayedRooms[index];
                final roomDevices = devices
                    .where((d) => d.roomId == room.id || d.room == room.name)
                    .toList();
                final roomActiveCount =
                    roomDevices.where((d) => d.isPoweredOn).length;
                final roomDeviceCount =
                    roomDevices.isNotEmpty ? roomDevices.length : room.deviceCount;

                return _buildRoomGridCard(
                  context: context,
                  room: room,
                  roomActiveCount: roomActiveCount,
                  roomDeviceCount: roomDeviceCount,
                  isDark: isDark,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRoomGridCard({
    required BuildContext context,
    required RoomModel room,
    required int roomActiveCount,
    required int roomDeviceCount,
    required bool isDark,
  }) {
    final hasActive = roomActiveCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('dashboard_room_card_${room.id}'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => _navigateToRoomDetail(room),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Icon container + Active Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF28342B)
                          : AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      room.icon,
                      size: 19,
                      color: isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer,
                    ),
                  ),
                  Container(
                    key: Key('dashboard_room_active_pill_${room.id}'),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasActive
                          ? (isDark
                              ? const Color(0xFF223828)
                              : AppColors.primaryContainer.withValues(alpha: 0.12))
                          : (isDark
                              ? AppColors.darkCardSecondary
                              : AppColors.lightCardSecondary),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasActive
                            ? (isDark
                                ? const Color(0xFF4C7554)
                                : AppColors.primaryContainer.withValues(alpha: 0.25))
                            : (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$roomActiveCount Açık',
                      style: AppTypography.badge(
                        color: hasActive
                            ? (isDark
                                ? const Color(0xFF8FD8A0)
                                : AppColors.primaryContainer)
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.secondary),
                      ).copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                  ),
                ],
              ),
              // Bottom: Room Name and Device Count
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    room.name,
                    style: AppTypography.cardTitle(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ).copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$roomDeviceCount Cihaz',
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.secondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 5. Compact Active Devices Grid
  Widget _buildCompactDevicesSection({
    required BuildContext context,
    required bool isDark,
    required List<DeviceModel> devices,
    required int activeDeviceCount,
    required String tempUnit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aktif Cihazlar',
              style: AppTypography.sectionTitle(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3023),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$activeDeviceCount cihaz açık',
                style: AppTypography.badge(
                  color: const Color(0xFFDCE5D7),
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 580 ? 3 : 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: devices.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) {
                final device = devices[index];
                return _buildCompactDeviceCard(
                  context: context,
                  device: device,
                  isDark: isDark,
                  tempUnit: tempUnit,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCompactDeviceCard({
    required BuildContext context,
    required DeviceModel device,
    required bool isDark,
    required String tempUnit,
  }) {
    String valueText = device.isPoweredOn ? 'Açık' : 'Kapalı';
    String valueLabel = 'Durum';

    if (device.type == DeviceType.bulb) {
      valueText = '%${device.brightness}';
      valueLabel = 'Parlaklık';
    } else if (device.type == DeviceType.ac) {
      valueText = TemperatureFormatter.format(device.targetTemp, unit: tempUnit);
      valueLabel = 'Hedef sıcaklık';
    } else if (device.type == DeviceType.plug) {
      valueText = device.isPoweredOn ? '240 W' : '0 W';
      valueLabel = 'Anlık güç';
    }

    return GestureDetector(
      key: Key('compact_device_card_${device.id}'),
      onTap: () => _navigateToDevice(device),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  device.icon,
                  size: 24,
                  color: device.isPoweredOn
                      ? (isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer)
                      : (isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.5) : AppColors.secondary),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        final newFav = !device.isFavorite;
                        context.read<DevicesCubit>().toggleDeviceFavorite(device.id);
                        showGlowingToast(
                          context,
                          message: newFav
                              ? '${device.name} favorilere eklendi.'
                              : '${device.name} favorilerden çıkarıldı.',
                          icon: newFav ? Icons.star_rounded : Icons.star_border_rounded,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          device.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 20,
                          color: device.isFavorite
                              ? AppColors.warmAmber
                              : (isDark ? Colors.white38 : Colors.black26),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    NestoraSwitch(
                      key: Key('compact_device_switch_${device.id}'),
                      value: device.isPoweredOn,
                      onChanged: (_) {
                        final willBeOn = !device.isPoweredOn;
                        context
                            .read<DevicesCubit>()
                            .toggleDevicePower(device.id);
                        showGlowingToast(
                          context,
                          message: willBeOn
                              ? '${device.name} açıldı.'
                              : '${device.name} kapatıldı.',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            Text(
              device.name,
              style: AppTypography.description(
                color: isDark ? AppColors.darkTextPrimary : AppColors.secondary,
              ).copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valueText,
                  style: AppTypography.pageTitle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ).copyWith(
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  valueLabel,
                  style: AppTypography.badge(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStatCard extends StatefulWidget {
  final bool isDark;
  final IconData icon;
  final String value;
  final String label;
  final bool hasDot;
  final Color? dotColor;

  const _SummaryStatCard({
    super.key,
    required this.isDark,
    required this.icon,
    required this.value,
    required this.label,
    required this.hasDot,
    this.dotColor,
  });

  @override
  State<_SummaryStatCard> createState() => _SummaryStatCardState();
}

class _SummaryStatCardState extends State<_SummaryStatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    final Color bgColor = isDark
        ? (_isHovered ? const Color(0xFF222923) : AppColors.darkCard)
        : (_isHovered ? const Color(0xFFFBF8F4) : AppColors.lightCard);

    final Color borderColor = isDark
        ? (_isHovered ? const Color(0xFF4C7554) : AppColors.darkBorder)
        : (_isHovered
            ? AppColors.primaryContainer.withValues(alpha: 0.35)
            : AppColors.lightBorder);

    final Color iconBgColor = isDark
        ? (_isHovered ? const Color(0xFF2B372E) : AppColors.darkCardSecondary)
        : (_isHovered ? const Color(0xFFE2DDD4) : AppColors.secondaryContainer);

    final Color iconColor = isDark
        ? (_isHovered ? const Color(0xFFA5E6B4) : const Color(0xFF8FD8A0))
        : (_isHovered ? AppColors.primary : AppColors.primaryContainer);

    final List<BoxShadow> shadows = _isHovered
        ? (isDark
            ? const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: Color(0x1E8FD8A0),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                  spreadRadius: -3,
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x181E3023),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: Color(0x0C1E3023),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ])
        : AppColors.cardShadow;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -5.0 : 0.0, 0.0),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: _isHovered ? 1.4 : 1.0,
          ),
          boxShadow: shadows,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular Icon Container
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                size: 19,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 8),
            // Value (with optional warm dot)
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.value,
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                if (widget.hasDot) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.dotColor ?? const Color(0xFFC5A880),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            // Label
            Text(
              widget.label,
              style: AppTypography.caption.copyWith(
                color: isDark
                    ? (_isHovered
                        ? AppColors.darkTextPrimary
                        : AppColors.darkTextSecondary)
                    : (_isHovered
                        ? AppColors.lightTextPrimary
                        : AppColors.secondary),
                fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
