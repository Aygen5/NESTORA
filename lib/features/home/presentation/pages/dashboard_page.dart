import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../devices/presentation/cubit/devices_cubit.dart';
import '../../../devices/presentation/cubit/devices_state.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../../notifications/presentation/cubit/notifications_state.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/cubit/profile_state.dart';
import '../../../rooms/presentation/cubit/rooms_cubit.dart';
import '../../../rooms/presentation/cubit/rooms_state.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/nestora_logo.dart';
import '../../../../core/widgets/nestora_switch.dart';
import '../../../devices/domain/device_model.dart';
import '../../../devices/presentation/pages/ac_control_page.dart';
import '../../../devices/presentation/pages/lamp_control_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../rooms/presentation/pages/rooms_page.dart';
import '../../../rooms/presentation/pages/room_detail_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileCubit>().state;
    final notificationsState = context.watch<NotificationsCubit>().state;
    final roomsState = context.watch<RoomsCubit>().state;
    final devicesState = context.watch<DevicesCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final homeName = (profileState is ProfileLoaded)
        ? profileState.profile.homeName
        : SeedData.defaultProfile.homeName;
    final unreadNotificationCount = (notificationsState is NotificationsLoaded)
        ? notificationsState.unreadCount
        : 0;
    final rooms = (roomsState is RoomsLoaded)
        ? roomsState.rooms.map(SeedData.roomToModel).toList()
        : SeedData.defaultRoomModels;
    final devices = (devicesState is DevicesLoaded)
        ? devicesState.devices.map(SeedData.deviceToModel).toList()
        : SeedData.defaultDeviceModels;
    final activeDeviceCount = (devicesState is DevicesLoaded)
        ? devicesState.activeCount
        : devices.where((d) => d.isPoweredOn).length;

    return SizedBox.expand(
      child: Container(
        color: isDark ? AppColors.darkBackground : AppColors.lightScaffold,
        child: Column(
        children: [
          // Fixed Top Bar / Header
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkCard : AppColors.lightScaffold).withValues(alpha: 0.95),
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
                        const NestoraLogo(size: 28),
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
                        // Notifications Button
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationsPage()),
                            );
                          },
                          icon: Stack(
                            children: [
                              Icon(
                                Icons.notifications_none_rounded,
                                size: 22,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                              if (unreadNotificationCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.warmAmber,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Profile Avatar
                        GestureDetector(
                          onTap: widget.onNavigateToProfile,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.secondaryContainer,
                              border: Border.all(
                                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 20,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
              // 1. NESTORA TYPOGRAPHY & UI HERO BANNER (Image 1 standard)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFF263328), // Deep Forest Green Hero
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0x33FFFFFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            homeName,
                            style: AppTypography.badge(color: Colors.white),
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
                      'Akıllı evinizin kontrolü artık çok daha kolay ve dengeli.',
                      style: AppTypography.description(
                        color: const Color(0xFFDCE5D7),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 2. ENERGY USAGE OVERVIEW (Image 4 standard)
              Container(
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
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                Text(
                                  '7,8 kWh',
                                  style: AppTypography.cardTitle(
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                        backgroundColor: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryContainer),
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
                          'Günlük ortalama: 11,3 kWh',
                          style: AppTypography.badge(color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. QUICK SCENARIOS (Hızlı Senaryolar - Image 4)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hızlı Eylemler',
                    style: AppTypography.sectionTitle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                      onTap: () => setState(() => _activeScenario = 'Evdeyim'),
                    ),
                    const SizedBox(width: 8),
                    _buildScenarioChip(
                      label: 'Gündüz',
                      icon: Icons.wb_sunny_rounded,
                      isSelected: _activeScenario == 'Gündüz',
                      isDark: isDark,
                      onTap: () => setState(() => _activeScenario = 'Gündüz'),
                    ),
                    const SizedBox(width: 8),
                    _buildScenarioChip(
                      label: 'Gece Modu',
                      icon: Icons.bedtime_rounded,
                      isSelected: _activeScenario == 'Gece Modu',
                      isDark: isDark,
                      onTap: () => setState(() => _activeScenario = 'Gece Modu'),
                    ),
                    const SizedBox(width: 8),
                    _buildScenarioChip(
                      label: 'Dışarıda',
                      icon: Icons.exit_to_app_rounded,
                      isSelected: _activeScenario == 'Dışarıda',
                      isDark: isDark,
                      onTap: () => setState(() => _activeScenario = 'Dışarıda'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. ROOMS / SPACES (Evimin Odaları - Image 4 & 5)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Odalar',
                    style: AppTypography.sectionTitle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RoomsPage()),
                      );
                    },
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
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RoomDetailPage(room: room)),
                        );
                      },
                      child: Container(
                        width: 155,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(16),
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
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
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
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${room.temperature}°C',
                                    style: AppTypography.badge(
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              room.name,
                              style: AppTypography.cardTitle(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${room.deviceCount} Cihaz',
                              style: AppTypography.description(color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 26),

              // 5. COMPACT ACTIVE DEVICES (BENİM ÖNERDİĞİM YENİ STANDART - IMAGE 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Aktif Cihazlar',
                    style: AppTypography.sectionTitle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3023), // Dark Pine Pill (Image 1 style)
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

              // Compact 2-column or 3-column Grid (LayoutBuilder responsive)
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

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    ),
  ],
),
),
);
}

  // Exact card layout from User Image 1 ("Benim önerdiğim yeni tasarım standardı")
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
      onTap: () {
        if (device.name == 'Salon Lambası') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LampControlPage()),
          );
        } else if (device.type == DeviceType.ac) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AcControlPage()),
          );
        }
      },
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
            // Top Row: Icon on left, Toggle switch on right
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
                  onChanged: (_) => context.read<DevicesCubit>().toggleDevicePower(device.id),
                ),
              ],
            ),

            // Device Name
            Text(
              device.name,
              style: AppTypography.description(
                color: isDark ? AppColors.darkTextSecondary : AppColors.secondary,
              ).copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Big Value & Label (Matching Image 1)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valueText,
                  style: AppTypography.pageTitle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ).copyWith(fontSize: 22, height: 1.15, fontWeight: FontWeight.w700),
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

  Widget _buildScenarioChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ).copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
