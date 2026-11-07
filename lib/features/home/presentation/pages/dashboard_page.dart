import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../../core/widgets/nestora_logo.dart';
import '../../../../core/widgets/nestora_switch.dart';
import '../../../devices/domain/device_model.dart';
import '../../../devices/presentation/cubit/devices_cubit.dart';
import '../../../devices/presentation/cubit/devices_state.dart';
import '../../../devices/presentation/pages/ac_control_page.dart';
import '../../../devices/presentation/pages/lamp_control_page.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../../notifications/presentation/cubit/notifications_state.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/cubit/profile_state.dart';
import '../../../rooms/domain/room_model.dart';
import '../../../rooms/presentation/cubit/rooms_cubit.dart';
import '../../../rooms/presentation/cubit/rooms_state.dart';
import '../../../rooms/presentation/pages/room_detail_page.dart';
import '../../../rooms/presentation/pages/rooms_page.dart';

/// Central Dashboard (Home) screen of Nestora smart home platform.
/// Connects dynamically to [ProfileCubit], [NotificationsCubit], [RoomsCubit],
/// and [DevicesCubit] as the single sources of truth.
class DashboardPage extends StatefulWidget {
  final VoidCallback? onNavigateToDevices;
  final VoidCallback? onNavigateToProfile;

  const DashboardPage({
    super.key,
    this.onNavigateToDevices,
    this.onNavigateToProfile,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _activeScenario = 'Evdeyim';

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
    try {
      context.goToRooms();
    } catch (_) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RoomsPage()),
      );
    }
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
    if (device.name == 'Salon Lambası' || device.type == DeviceType.bulb) {
      try {
        context.goToLampControl(device.id);
      } catch (_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LampControlPage()),
        );
      }
    } else if (device.type == DeviceType.ac) {
      try {
        context.goToClimateControl(device.id);
      } catch (_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AcControlPage()),
        );
      }
    } else {
      // Toggle power directly for other devices (plug, etc.)
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
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.feedbackMessage!),
              duration: const Duration(milliseconds: 1800),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: isDark ? AppColors.darkCard : AppColors.primaryContainer,
            ),
          );
        }
      },
      child: SizedBox.expand(
        child: Container(
          color: isDark ? AppColors.darkBackground : AppColors.lightScaffold,
          child: Column(
            children: [
              // Fixed Top Bar / Header
              _buildHeader(
                context: context,
                isDark: isDark,
                unreadNotificationCount: unreadNotificationCount,
                photoPath: photoPath,
                displayName: displayName,
              ),

              // Scrollable Dashboard Body
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      children: [
                        // 1. NESTORA TYPOGRAPHY & HERO BANNER
                        _buildHeroBanner(
                          isDark: isDark,
                          homeName: homeName,
                          greeting: greeting,
                          userFirstName: userFirstName,
                          activeDeviceCount: activeDeviceCount,
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
                        ),

                        const SizedBox(height: 26),

                        // 5. COMPACT ACTIVE DEVICES
                        _buildCompactDevicesSection(
                          context: context,
                          isDark: isDark,
                          devices: devices,
                          activeDeviceCount: activeDeviceCount,
                        ),

                        const SizedBox(height: 28),
                      ],
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

  // Top Header: Logo, Nestora branding, Notifications Bell with Badge, Profile Avatar
  Widget _buildHeader({
    required BuildContext context,
    required bool isDark,
    required int unreadNotificationCount,
    required String? photoPath,
    required String displayName,
  }) {
    final bool hasLocalPhoto = photoPath != null &&
        photoPath.trim().isNotEmpty &&
        File(photoPath.trim()).existsSync();

    return Container(
      height: 64,
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
              Row(
                children: [
                  const NestoraLogo(size: 28, enableNavigation: true),
                  const SizedBox(width: 8),
                  Text(
                    'Nestora',
                    style: AppTypography.cardTitle(
                      color: AppColors.primaryContainer,
                    ).copyWith(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ],
              ),
              Row(
                children: [
                  // Notifications Button with dynamic badge
                  IconButton(
                    tooltip: 'Bildirimler',
                    onPressed: _navigateToNotifications,
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 22,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        if (unreadNotificationCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.warmAmber,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Text(
                                unreadNotificationCount > 9
                                    ? '9+'
                                    : '$unreadNotificationCount',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Profile Avatar (local photo or user initial)
                  GestureDetector(
                    onTap: _navigateToProfile,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondaryContainer,
                        border: Border.all(
                          color: AppColors.primaryContainer.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: hasLocalPhoto
                            ? Image.file(
                                File(photoPath.trim()),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildFallbackAvatar(displayName),
                              )
                            : _buildFallbackAvatar(displayName),
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

  // 1. Hero Banner: Home Name, Welcome Greeting, Status
  Widget _buildHeroBanner({
    required bool isDark,
    required String homeName,
    required String greeting,
    required String userFirstName,
    required int activeDeviceCount,
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
              Text(
                'NESTORA · AKILLI YAŞAM',
                style: AppTypography.badge(
                  color: const Color(0xFFB7CCB9),
                ).copyWith(letterSpacing: 1.0, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  homeName,
                  style: AppTypography.badge(color: Colors.white).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
        ],
      ),
    );
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
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      size: 18,
                      color: AppColors.primaryContainer,
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
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Hedef %68',
                  style: AppTypography.badge(
                    color: AppColors.primaryContainer,
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
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryContainer,
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

  // 4. Rooms Horizontal Carousel
  Widget _buildRoomsSection({
    required BuildContext context,
    required bool isDark,
    required List<RoomModel> rooms,
    required List<DeviceModel> devices,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Odalar',
              style: AppTypography.sectionTitle(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            GestureDetector(
              onTap: _navigateToRooms,
              child: Text(
                'Tümünü Gör',
                style: AppTypography.buttonText(
                  color: AppColors.primaryContainer,
                ).copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: rooms.map((room) {
              final roomDevicesCount = devices
                  .where((d) => d.room == room.name || d.id.startsWith(room.id))
                  .length;
              final effectiveDeviceCount =
                  roomDevicesCount > 0 ? roomDevicesCount : room.deviceCount;

              return GestureDetector(
                onTap: () => _navigateToRoomDetail(room),
                child: Container(
                  width: 155,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.secondaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              room.icon,
                              size: 16,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCardSecondary
                                  : AppColors.lightCardSecondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${room.temperature.toStringAsFixed(1).replaceAll('.0', '')}°C',
                              style: AppTypography.badge(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        room.name,
                        style: AppTypography.cardTitle(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$effectiveDeviceCount Cihaz',
                        style: AppTypography.description(
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 5. Compact Active Devices Grid
  Widget _buildCompactDevicesSection({
    required BuildContext context,
    required bool isDark,
    required List<DeviceModel> devices,
    required int activeDeviceCount,
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
  }) {
    String valueText = device.isPoweredOn ? 'Açık' : 'Kapalı';
    String valueLabel = 'Durum';

    if (device.type == DeviceType.bulb) {
      valueText = '%${device.brightness}';
      valueLabel = 'Parlaklık';
    } else if (device.type == DeviceType.ac) {
      valueText = '${device.targetTemp}°';
      valueLabel = 'Hedef sıcaklık';
    } else if (device.type == DeviceType.plug) {
      valueText = device.isPoweredOn ? '240 W' : '0 W';
      valueLabel = 'Anlık güç';
    }

    return GestureDetector(
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
                      ? AppColors.primaryContainer
                      : (isDark ? AppColors.darkTextSecondary : AppColors.secondary),
                ),
                NestoraSwitch(
                  value: device.isPoweredOn,
                  onChanged: (_) => context
                      .read<DevicesCubit>()
                      .toggleDevicePower(device.id),
                ),
              ],
            ),
            Text(
              device.name,
              style: AppTypography.description(
                color: isDark ? AppColors.darkTextSecondary : AppColors.secondary,
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
                  style: AppTypography.badge(color: AppColors.secondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
