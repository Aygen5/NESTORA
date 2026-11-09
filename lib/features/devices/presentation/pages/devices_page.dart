import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../../core/utils/temperature_formatter.dart';
import '../../../../core/widgets/glowing_toast.dart';
import '../../../../core/widgets/nestora_logo.dart';
import '../../../../core/widgets/nestora_switch.dart';
import '../../../../core/widgets/pulsing_glow_dot.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../../notifications/presentation/cubit/notifications_state.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/cubit/profile_state.dart';
import '../../../../core/widgets/nestora_image_helper.dart';
import '../../../rooms/presentation/cubit/rooms_cubit.dart';
import '../../../rooms/presentation/cubit/rooms_state.dart';
import '../../domain/device_model.dart';
import '../cubit/devices_cubit.dart';
import '../cubit/devices_state.dart';
import 'ac_control_page.dart';
import 'add_edit_device_page.dart';
import 'coffee_machine_control_page.dart';
import 'lamp_control_page.dart';
import 'plug_control_page.dart';
import 'tv_control_page.dart';

/// The 5 main device category tabs required by Nestora smart home specs:
/// Tümü, Aydınlatma, İklimlendirme, Güvenlik, Prizler
enum DeviceCategoryTab {
  all('Tümü', Icons.apps_rounded),
  lighting('Aydınlatma', Icons.lightbulb_rounded),
  climate('İklimlendirme', Icons.thermostat_rounded),
  security('Güvenlik', Icons.videocam_rounded),
  plugs('Prizler', Icons.power_rounded);

  final String label;
  final IconData icon;
  const DeviceCategoryTab(this.label, this.icon);
}

/// Secondary quick status filters for power & favorites
enum DeviceStatusFilter {
  all('Hepsi'),
  active('Açık'),
  inactive('Kapalı'),
  favorites('Favoriler');

  final String label;
  const DeviceStatusFilter(this.label);
}

class DevicesPage extends StatefulWidget {
  final VoidCallback? onNavigateToProfile;
  final DeviceStatusFilter? initialStatusFilter;

  const DevicesPage({
    super.key,
    this.onNavigateToProfile,
    this.initialStatusFilter,
  });

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  DeviceCategoryTab _selectedCategory = DeviceCategoryTab.all;
  late DeviceStatusFilter _selectedStatus;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatusFilter ?? DeviceStatusFilter.all;
    if (_selectedStatus == DeviceStatusFilter.favorites) {
      _selectedCategory = DeviceCategoryTab.all;
    }
  }

  @override
  void didUpdateWidget(covariant DevicesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatusFilter != null &&
        widget.initialStatusFilter != oldWidget.initialStatusFilter) {
      setState(() {
        _selectedStatus = widget.initialStatusFilter!;
        if (_selectedStatus == DeviceStatusFilter.favorites) {
          _selectedCategory = DeviceCategoryTab.all;
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = DeviceCategoryTab.all;
      _selectedStatus = DeviceStatusFilter.all;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  bool _matchesCategory(DeviceModel device, DeviceCategoryTab category) {
    switch (category) {
      case DeviceCategoryTab.all:
        return true;
      case DeviceCategoryTab.lighting:
        return device.type == DeviceType.bulb;
      case DeviceCategoryTab.climate:
        return device.type == DeviceType.ac || device.type == DeviceType.fan;
      case DeviceCategoryTab.security:
        return device.type == DeviceType.security ||
            device.name.toLowerCase().contains('güvenlik') ||
            device.name.toLowerCase().contains('kamera') ||
            device.name.toLowerCase().contains('alarm');
      case DeviceCategoryTab.plugs:
        return device.type == DeviceType.plug;
    }
  }

  bool _matchesStatus(DeviceModel device, DeviceStatusFilter status) {
    switch (status) {
      case DeviceStatusFilter.all:
        return true;
      case DeviceStatusFilter.active:
        return device.isPoweredOn;
      case DeviceStatusFilter.inactive:
        return !device.isPoweredOn;
      case DeviceStatusFilter.favorites:
        return device.isFavorite;
    }
  }

  double _getDeviceWatts(DeviceModel device) {
    if (!device.isPoweredOn) return 0.0;
    switch (device.type) {
      case DeviceType.bulb:
        return (device.brightness / 100.0) * 15.0;
      case DeviceType.ac:
        return 850.0;
      case DeviceType.fan:
        return 45.0;
      case DeviceType.plug:
        return 140.0;
      case DeviceType.tv:
        return 95.0;
      case DeviceType.security:
        return 4.5;
    }
  }

  String _formatPower(double watts) {
    if (watts >= 1000) {
      return '${(watts / 1000).toStringAsFixed(1).replaceAll('.', ',')} kW';
    }
    return '${watts.round()} W';
  }

  String _formatDevicePower(DeviceModel device) {
    if (!device.isPoweredOn) return '0 W';
    final watts = _getDeviceWatts(device);
    return '${watts.round()} W';
  }

  String _getDeviceTypeLabel(DeviceType type) {
    switch (type) {
      case DeviceType.bulb:
        return 'Aydınlatma';
      case DeviceType.ac:
        return 'İklimlendirme';
      case DeviceType.fan:
        return 'Vantilatör';
      case DeviceType.plug:
        return 'Akıllı Priz';
      case DeviceType.tv:
        return 'Medya / TV';
      case DeviceType.security:
        return 'Güvenlik';
    }
  }

  String _resolveRoomName(BuildContext context, String? roomId, String fallbackRoom) {
    if (roomId == null || roomId.isEmpty) return fallbackRoom;
    try {
      final roomsState = context.read<RoomsCubit>().state;
      if (roomsState is RoomsLoaded) {
        final found = roomsState.rooms.where((r) => r.id == roomId).firstOrNull;
        if (found != null && found.name.isNotEmpty) {
          return found.name;
        }
      }
    } catch (_) {}

    switch (roomId) {
      case 'room-1':
        return 'Salon';
      case 'room-2':
        return 'Yatak Odası';
      case 'room-3':
        return 'Mutfak';
      case 'room-4':
        return 'Çalışma Odası';
      case 'room-5':
        return 'Giriş & Dış';
      default:
        return fallbackRoom.isNotEmpty ? fallbackRoom : 'Genel';
    }
  }

  void _navigateToDeviceDetail(BuildContext context, DeviceModel device) {
    final lower = device.name.toLowerCase();
    final isBulb = device.type == DeviceType.bulb || lower.contains('lamba');
    final isAc = device.type == DeviceType.ac || lower.contains('klima');
    final isTv = device.type == DeviceType.tv || lower.contains('televizyon') || lower.contains('tv');
    final isCoffee = (lower.contains('kahve') || lower.contains('coffee'));
    final isPlug = device.type == DeviceType.plug || lower.contains('priz');

    if (isBulb) {
      try {
        context.push('/devices/lamp/${device.id}');
      } catch (_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LampControlPage(deviceId: device.id)),
        );
      }
    } else if (isAc) {
      try {
        context.push('/devices/climate/${device.id}');
      } catch (_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AcControlPage(deviceId: device.id)),
        );
      }
    } else if (isTv) {
      try {
        context.push('/devices/tv/${device.id}');
      } catch (_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TvControlPage(deviceId: device.id)),
        );
      }
    } else if (isCoffee) {
      try {
        context.push('/devices/coffee/${device.id}');
      } catch (_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CoffeeMachineControlPage(deviceId: device.id)),
        );
      }
    } else if (isPlug) {
      try {
        context.push('/devices/plug/${device.id}');
      } catch (_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlugControlPage(deviceId: device.id)),
        );
      }
    } else {
      try {
        context.push(
          '/devices/add-edit',
          extra: {
            'isEditing': true,
            'device': device,
            'deviceId': device.id,
          },
        );
      } catch (_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddEditDevicePage(device: device, isEditing: true)),
        );
      }
    }
  }

  void _navigateToAddDevice(BuildContext context) {
    try {
      context.push('/devices/add-edit');
    } catch (_) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddEditDevicePage()),
      );
    }
  }

  void _navigateToProfile(BuildContext context) {
    if (widget.onNavigateToProfile != null) {
      widget.onNavigateToProfile!();
    } else {
      try {
        context.go('/profile');
      } catch (_) {
        // noop
      }
    }
  }

  Widget _buildAvatar(String? photoPath, String displayName) {
    return buildNestoraImage(
      photoPath,
      fit: BoxFit.cover,
      placeholder: _buildFallbackAvatar(displayName),
      errorWidget: _buildFallbackAvatar(displayName),
    );
  }

  Widget _buildFallbackAvatar(String displayName) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';
    return Container(
      color: AppColors.secondaryContainer,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.primaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int unreadCount = 0;
    try {
      final notificationsState = context.watch<NotificationsCubit>().state;
      if (notificationsState is NotificationsLoaded) {
        unreadCount = notificationsState.unreadCount;
      }
    } catch (_) {}

    String? photoPath;
    String displayName = 'Aygen';
    try {
      final profileState = context.watch<ProfileCubit>().state;
      if (profileState is ProfileLoaded) {
        photoPath = profileState.profile.photoPath;
        displayName = profileState.profile.displayName;
      }
    } catch (_) {}

    final devicesCubit = context.watch<DevicesCubit>();
    final devicesState = devicesCubit.state;

    final List<DeviceModel> allDevices = (devicesState is DevicesLoaded)
        ? devicesState.devices.map(SeedData.deviceToModel).toList()
        : SeedData.defaultDeviceModels;

    final totalCount = allDevices.length;
    final activeCount = allDevices.where((d) => d.isPoweredOn).length;
    final inactiveCount = totalCount - activeCount;
    final favoriteCount = allDevices.where((d) => d.isFavorite).length;
    final isFavoritesFilterActive = _selectedStatus == DeviceStatusFilter.favorites;

    // Filter devices based on Category, Status, and Search Query
    final filteredDevices = allDevices.where((d) {
      final matchesCat = _matchesCategory(d, _selectedCategory);
      if (!matchesCat) return false;

      final matchesStat = _matchesStatus(d, _selectedStatus);
      if (!matchesStat) return false;

      if (_searchQuery.isNotEmpty) {
        final roomName = _resolveRoomName(context, d.roomId, d.room).toLowerCase();
        final nameMatch = d.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final roomMatch = roomName.contains(_searchQuery.toLowerCase());
        final typeMatch = _getDeviceTypeLabel(d.type).toLowerCase().contains(_searchQuery.toLowerCase());
        if (!nameMatch && !roomMatch && !typeMatch) return false;
      }

      return true;
    }).toList();

    // Total power consumption across all active devices
    final totalPowerWatts = allDevices
        .where((d) => d.isPoweredOn)
        .fold<double>(0.0, (sum, d) => sum + _getDeviceWatts(d));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightScaffold,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(76),
        child: Container(
          height: 76,
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
                  Row(
                    children: [
                      // Favorites Toggle Filter Button with count badge & hover effect
                      Tooltip(
                        message: isFavoritesFilterActive
                            ? 'Tüm Cihazları Göster'
                            : 'Favori Cihazları Filtrele ($favoriteCount)',
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            hoverColor: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppColors.primaryContainer.withValues(alpha: 0.08),
                            splashColor: AppColors.primaryContainer.withValues(alpha: 0.12),
                            onTap: () {
                              setState(() {
                                if (isFavoritesFilterActive) {
                                  _selectedStatus = DeviceStatusFilter.all;
                                  showGlowingToast(
                                    context,
                                    message: 'Tüm cihazlar listeleniyor.',
                                  );
                                } else {
                                  _selectedStatus = DeviceStatusFilter.favorites;
                                  showGlowingToast(
                                    context,
                                    message: 'Favori cihazlar filtrelendi ($favoriteCount cihaz).',
                                    icon: Icons.star_rounded,
                                  );
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: isFavoritesFilterActive
                                  ? BoxDecoration(
                                      color: AppColors.warmAmber.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(12),
                                    )
                                  : null,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    isFavoritesFilterActive
                                        ? Icons.star_rounded
                                        : (favoriteCount > 0
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded),
                                    size: 24,
                                    color: (isFavoritesFilterActive || favoriteCount > 0)
                                        ? AppColors.warmAmber
                                        : (isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary),
                                  ),
                                  if (favoriteCount > 0)
                                    Positioned(
                                      right: -4,
                                      top: -3,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.warmAmber,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                        child: Text(
                                          favoriteCount > 9 ? '9+' : '$favoriteCount',
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
                      ),
                      const SizedBox(width: 4),
                      // Notifications Bell Button with unread count badge & hover effect
                      Tooltip(
                        message: 'Bildirimler',
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            hoverColor: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppColors.primaryContainer.withValues(alpha: 0.08),
                            splashColor: AppColors.primaryContainer.withValues(alpha: 0.12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const NotificationsPage()),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    Icons.notifications_none_rounded,
                                    size: 24,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: -4,
                                      top: -3,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.error,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                        child: Text(
                                          unreadCount > 9 ? '9+' : '$unreadCount',
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
                      ),
                      const SizedBox(width: 8),
                      // Profile Avatar
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          key: const Key('devices_profile_avatar'),
                          onTap: () => _navigateToProfile(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF4C7554) : AppColors.secondaryContainer,
                                width: 2,
                              ),
                              color: isDark ? const Color(0xFF28342B) : AppColors.secondaryContainer,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _buildAvatar(photoPath, displayName),
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
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Live Sync Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cihazlarım',
                            style: AppTypography.headlineLarge.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.primaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Evindeki tüm akıllı cihazları tek merkezden yönet.',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF223828) : AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          PulsingGlowDot(
                            color: isDark ? const Color(0xFF6BD88A) : AppColors.primaryContainer,
                            size: 8,
                            glowRadius: 6,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Canlı Senkron',
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Power & Status Overview Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                size: 22,
                                color: isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Durum Özeti',
                                    style: AppTypography.labelMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$totalCount cihaz • $activeCount açık • $inactiveCount kapalı',
                                    style: AppTypography.caption.copyWith(
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.secondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Quick Toggle All Button
                      TextButton.icon(
                        onPressed: totalCount == 0
                            ? null
                            : () {
                                final allOn = activeCount == totalCount;
                                context.read<DevicesCubit>().toggleAllDevices(!allOn);
                              },
                        icon: Icon(
                          activeCount == totalCount
                              ? Icons.power_settings_new_rounded
                              : Icons.power_settings_new_outlined,
                          size: 16,
                          color: activeCount == totalCount
                              ? AppColors.error
                              : (isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer),
                        ),
                        label: Text(
                          activeCount == totalCount ? 'Tümünü Kapat' : 'Tümünü Aç',
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: activeCount == totalCount
                                ? AppColors.error
                                : (isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Energy Consumption Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppColors.subtleShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 16,
                              color: AppColors.warmAmber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatPower(totalPowerWatts),
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.primaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search Bar + Add Device Button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.secondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) {
                                  setState(() => _searchQuery = val);
                                },
                                decoration: InputDecoration(
                                  hintText: 'Cihaz veya oda ara...',
                                  hintStyle: AppTypography.bodyMedium.copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.secondary,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: AppTypography.bodyMedium.copyWith(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: Icon(
                                  Icons.cancel_rounded,
                                  size: 18,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.secondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToAddDevice(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Cihaz Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26392D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 1. Primary Category Tabs (Tümü, Aydınlatma, İklimlendirme, Güvenlik, Prizler)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: DeviceCategoryTab.values.map((category) {
                      final isSelected = _selectedCategory == category;
                      final count = allDevices.where((d) => _matchesCategory(d, category)).length;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = category);
                          },
                          child: AnimatedContainer(
                            duration: (MediaQuery.maybeOf(context)?.disableAnimations ?? false)
                                ? Duration.zero
                                : const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryContainer
                                  : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryContainer
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                              boxShadow: isSelected ? AppColors.subtleShadow : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  category.icon,
                                  size: 16,
                                  color: isSelected ? Colors.white : AppColors.secondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${category.label} ($count)',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),

                // 2. Secondary Quick Status Filter (Hepsi, Açık, Kapalı, Favoriler)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: DeviceStatusFilter.values.map((status) {
                      final isSelected = _selectedStatus == status;

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(status.label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedStatus = status;
                                if (status == DeviceStatusFilter.favorites) {
                                  _selectedCategory = DeviceCategoryTab.all;
                                }
                              });
                            }
                          },
                          avatar: status == DeviceStatusFilter.favorites
                              ? Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: isSelected
                                      ? (isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer)
                                      : AppColors.warmAmber,
                                )
                              : null,
                          labelStyle: AppTypography.caption.copyWith(
                            color: isSelected
                                ? (isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer)
                                : (isDark ? AppColors.darkTextSecondary : AppColors.secondary),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          selectedColor: isDark ? const Color(0xFF223828) : AppColors.secondaryContainer,
                          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                          side: BorderSide(
                            color: isSelected
                                ? (isDark ? const Color(0xFF4C7554) : AppColors.primaryContainer)
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Devices Grid or Empty State
                if (filteredDevices.isEmpty)
                  _buildEmptyState(context, isDark)
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.15,
                        ),
                        itemCount: filteredDevices.length,
                        itemBuilder: (context, index) {
                          final device = filteredDevices[index];
                          return _buildDeviceCard(context, device, isDark);
                        },
                      );
                    },
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.devices_other_rounded,
              size: 32,
              color: AppColors.primaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cihaz Bulunamadı',
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Seçtiğiniz kategori veya arama kriterine uygun bir cihaz bulunmuyor.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _resetFilters,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Filtreleri Temizle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    DeviceModel device,
    bool isDark,
  ) {
    final roomName = _resolveRoomName(context, device.roomId, device.room);
    final typeLabel = _getDeviceTypeLabel(device.type);
    final deviceWatts = _formatDevicePower(device);
    final tempUnit = TemperatureFormatter.currentUnit(context);

    return GestureDetector(
      onTap: () => _navigateToDeviceDetail(context, device),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: device.isPoweredOn
                ? (isDark ? const Color(0xFF4C7554) : AppColors.primaryContainer.withValues(alpha: 0.35))
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: device.isPoweredOn ? 1.5 : 1.0,
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Category Icon + Favorite Star + Power Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: device.isPoweredOn
                        ? (isDark ? const Color(0xFF283B2C) : AppColors.warmAmber.withValues(alpha: 0.28))
                        : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    device.icon,
                    size: 20,
                    color: device.isPoweredOn
                        ? (isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer)
                        : (isDark ? AppColors.darkTextSecondary : AppColors.secondary),
                  ),
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
                          color: device.isFavorite ? AppColors.warmAmber : AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
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
              ],
            ),

            // Middle info: Room + Category name & Device Name
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${roomName.toUpperCase()} • ${typeLabel.toUpperCase()}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.secondary,
                    letterSpacing: 0.6,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  device.name,
                  style: AppTypography.headlineSmall.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),

            // Bottom row: Status dot + Power consumption in Watts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: device.isPoweredOn
                              ? (isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer)
                              : (isDark ? AppColors.darkTextSecondary : AppColors.secondary),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          device.isPoweredOn
                              ? (device.type == DeviceType.bulb
                                  ? 'Açık (%${device.brightness})'
                                  : (device.type == DeviceType.ac
                                      ? 'Açık (${TemperatureFormatter.format(device.targetTemp, unit: tempUnit)})'
                                      : 'Açık'))
                              : 'Kapalı',
                          style: AppTypography.caption.copyWith(
                            color: device.isPoweredOn
                                ? (isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer)
                                : (isDark ? AppColors.darkTextSecondary : AppColors.secondary),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  deviceWatts,
                  style: AppTypography.caption.copyWith(
                    color: device.isPoweredOn
                        ? (isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer)
                        : (isDark ? AppColors.darkTextSecondary : AppColors.secondary),
                    fontWeight: device.isPoweredOn ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
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
