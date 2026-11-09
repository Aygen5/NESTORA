import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../../core/widgets/nestora_logo.dart';
import '../../../devices/domain/device_model.dart';
import '../../../devices/presentation/cubit/devices_cubit.dart';
import '../../../devices/presentation/cubit/devices_state.dart';
import '../../../devices/presentation/pages/ac_control_page.dart';
import '../../../devices/presentation/pages/coffee_machine_control_page.dart';
import '../../../devices/presentation/pages/lamp_control_page.dart';
import '../../../devices/presentation/pages/plug_control_page.dart';
import '../../../devices/presentation/pages/tv_control_page.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../../notifications/presentation/cubit/notifications_state.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/cubit/profile_state.dart';
import '../cubit/rooms_cubit.dart';
import '../cubit/rooms_state.dart';
import '../../domain/room_model.dart';
import 'add_edit_room_page.dart';
import 'room_detail_page.dart';

/// Rooms overview screen of Nestora smart home platform (Image 4).
/// Displays all rooms with architectural photography thumbnails, device status chips,
/// real-time active indicators, and routing to room/device controls.
class RoomsPage extends StatefulWidget {
  final VoidCallback? onNavigateToDevices;
  final VoidCallback? onNavigateToProfile;

  const RoomsPage({
    super.key,
    this.onNavigateToDevices,
    this.onNavigateToProfile,
  });

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final roomsCubit = context.read<RoomsCubit>();
    if (roomsCubit.state is RoomsLoaded) {
      _searchController.text = (roomsCubit.state as RoomsLoaded).searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<RoomsCubit>().setSearchQuery(query);
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<RoomsCubit>().setSearchQuery('');
  }

  void _navigateToAddRoom() {
    try {
      context.goToAddEditRoom();
    } catch (_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AddEditRoomPage(isEditing: false),
        ),
      );
    }
  }

  void _navigateToRoomDetail(RoomModel room) {
    try {
      context.goToRoomDetail(room.id, room: room);
    } catch (_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoomDetailPage(room: room),
        ),
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

  void _navigateToProfile() {
    if (widget.onNavigateToProfile != null) {
      widget.onNavigateToProfile!();
    } else {
      try {
        context.goToProfile();
      } catch (_) {}
    }
  }

  Widget _buildAvatar(String? photoPath, String displayName) {
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
    final roomsState = context.watch<RoomsCubit>().state;
    final devicesState = context.watch<DevicesCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allRooms = (roomsState is RoomsLoaded)
        ? roomsState.rooms.map(SeedData.roomToModel).toList()
        : SeedData.defaultRoomModels;

    final filteredRooms = (roomsState is RoomsLoaded)
        ? roomsState.filteredRooms.map(SeedData.roomToModel).toList()
        : allRooms;

    final devices = (devicesState is DevicesLoaded)
        ? devicesState.devices.map(SeedData.deviceToModel).toList()
        : SeedData.defaultDeviceModels;

    final totalRooms = allRooms.length;
    final totalDevices = devices.length;
    final activeDevices = devices.where((d) => d.isPoweredOn).length;
    final searchQuery = (roomsState is RoomsLoaded) ? roomsState.searchQuery : '';

    String? photoPath;
    String displayName = 'Aygen Yıldırım';
    int unreadNotificationCount = 0;

    try {
      final profileState = context.watch<ProfileCubit>().state;
      if (profileState is ProfileLoaded) {
        photoPath = profileState.profile.photoPath;
        displayName = profileState.profile.displayName;
      }
    } catch (_) {}

    try {
      final notificationsState = context.watch<NotificationsCubit>().state;
      if (notificationsState is NotificationsLoaded) {
        unreadNotificationCount = notificationsState.unreadCount;
      }
    } catch (_) {}

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
                      // Notifications Button
                      IconButton(
                        tooltip: 'Bildirimler',
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 24,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            if (unreadNotificationCount > 0)
                              Positioned(
                                right: -3,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    unreadNotificationCount > 9 ? '9+' : '$unreadNotificationCount',
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsPage()),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      // Profile Avatar
                      GestureDetector(
                        key: const Key('rooms_profile_avatar'),
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
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // E.1 & E.2: Title, Subtitle & "+ Oda Ekle" Button (Image 4)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Odalarım',
                          key: const Key('rooms_page_title'),
                          style: AppTypography.headlineLarge.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Evindeki alanları düzenle ve cihazlarını yönet.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.secondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    key: const Key('rooms_add_room_button'),
                    onPressed: _navigateToAddRoom,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Oda Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF26392D), // Rich dark forest green
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // E.3: Summary status pill (Image 4: ● 4 Oda • 7 Cihaz • 4 Aktif)
              Row(
                children: [
                  Container(
                    key: const Key('rooms_summary_pill'),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF223828)
                          : const Color(0xFFE8EFE9), // Soft green tint
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF4C7554)
                            : AppColors.primaryContainer.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$totalRooms Oda • $totalDevices Cihaz • $activeDevices Aktif',
                          style: AppTypography.labelMedium.copyWith(
                            color: isDark
                                ? const Color(0xFF8FD8A0)
                                : AppColors.primaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  boxShadow: AppColors.cardShadow,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Oda veya alan ara...',
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.secondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.secondary,
                            ),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // E.4: Rooms List or Empty State (Image 4)
              if (filteredRooms.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        Icons.meeting_room_outlined,
                        size: 48,
                        color: AppColors.secondary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        searchQuery.isNotEmpty
                            ? '"$searchQuery" aramasına uygun oda bulunamadı.'
                            : 'Henüz kayıtlı bir oda bulunmuyor.',
                        textAlign: TextAlign.center,
                        style: AppTypography.cardTitle(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        searchQuery.isNotEmpty
                            ? 'Farklı bir arama terimi deneyebilir veya filtreyi temizleyebilirsiniz.'
                            : 'Yukarıdaki "+ Oda Ekle" butonu ile ilk odanızı oluşturabilirsiniz.',
                        textAlign: TextAlign.center,
                        style: AppTypography.description(color: AppColors.secondary),
                      ),
                      if (searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _clearSearch,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryContainer,
                            side: const BorderSide(color: AppColors.primaryContainer),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Aramayı Temizle'),
                        ),
                      ],
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredRooms.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final room = filteredRooms[index];
                    final roomDevices = devices
                        .where((d) => d.roomId == room.id || d.room == room.name)
                        .toList();
                    final roomActiveCount =
                        roomDevices.where((d) => d.isPoweredOn).length;
                    final effectiveDeviceCount =
                        roomDevices.isNotEmpty ? roomDevices.length : room.deviceCount;
                    final imageAsset = room.imageAsset ?? SeedData.getSmartRoomAsset(room.name);

                    return GestureDetector(
                      key: Key('rooms_room_card_${room.id}'),
                      onTap: () => _navigateToRoomDetail(room),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(22),
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
                                    // Architectural Thumbnail with Room Icon
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        width: 58,
                                        height: 58,
                                        color: isDark
                                            ? AppColors.darkCardSecondary
                                            : AppColors.secondaryContainer,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            if (imageAsset != null && imageAsset.isNotEmpty)
                                              Image.asset(
                                                imageAsset,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  color: AppColors.secondaryContainer,
                                                  alignment: Alignment.center,
                                                  child: Icon(room.icon, size: 24, color: AppColors.primaryContainer),
                                                ),
                                              ),
                                            Container(
                                              color: Colors.black.withValues(alpha: 0.28),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                room.icon,
                                                size: 22,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              room.name,
                                              style: AppTypography.headlineSmall.copyWith(
                                                color: isDark
                                                    ? AppColors.darkTextPrimary
                                                    : AppColors.lightTextPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                            if (roomActiveCount > 0) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF4CAF50),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '$effectiveDeviceCount Cihaz • $roomActiveCount Açık',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.secondary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Chevron Navigation Button
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF28342B)
                                        : const Color(0xFFF1EFEA),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    size: 22,
                                    color: isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer,
                                  ),
                                ),
                              ],
                            ),

                            // Mini device chips with direct navigation
                            if (roomDevices.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: roomDevices.map((dev) {
                                  final isDeviceOn = dev.isPoweredOn;
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      key: Key('room_device_chip_${dev.id}'),
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () => _navigateToDevice(dev),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDeviceOn
                                              ? (isDark ? const Color(0xFF223828) : const Color(0xFFE8EFE9))
                                              : (isDark ? const Color(0xFF1E2420) : const Color(0xFFF1EFEA)),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isDeviceOn
                                                ? (isDark ? const Color(0xFF4C7554) : AppColors.primaryContainer.withValues(alpha: 0.25))
                                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              dev.icon,
                                              size: 14,
                                              color: isDeviceOn
                                                  ? (isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer)
                                                  : (isDark ? AppColors.darkTextSecondary : AppColors.secondary),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              dev.name,
                                              style: AppTypography.labelSmall.copyWith(
                                                color: isDeviceOn
                                                    ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                                                    : (isDark ? AppColors.darkTextSecondary : AppColors.secondary),
                                                fontWeight: isDeviceOn
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isDeviceOn ? '• Açık' : '• Kapalı',
                                              style: AppTypography.caption.copyWith(
                                                color: isDeviceOn
                                                    ? (isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer)
                                                    : (isDark ? AppColors.darkTextSecondary : AppColors.secondary),
                                                fontWeight: isDeviceOn
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 20),

              // E.5: Bottom Add Room Callout (Image 4)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('rooms_bottom_add_room_card'),
                  borderRadius: BorderRadius.circular(18),
                  onTap: _navigateToAddRoom,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2821)
                          : const Color(0xFFEDF2EC), // Soft green tint from Image 4
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF38523E)
                            : AppColors.primaryContainer.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF283B2C)
                                : AppColors.primaryContainer.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_home_outlined,
                            size: 20,
                            color: isDark
                                ? const Color(0xFF8FD8A0)
                                : AppColors.primaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Evini genişletmek için yeni oda tanımlayabilirsin.',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
