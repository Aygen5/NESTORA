import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../devices/presentation/cubit/devices_cubit.dart';
import '../../../devices/presentation/cubit/devices_state.dart';
import '../cubit/rooms_cubit.dart';
import '../cubit/rooms_state.dart';
import '../../domain/room_model.dart';
import 'add_edit_room_page.dart';
import 'room_detail_page.dart';

/// Rooms overview screen of Nestora smart home platform.
/// Displays all rooms, provides search/filter, and routes to room details.
class RoomsPage extends StatefulWidget {
  const RoomsPage({super.key});

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

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightScaffold,
      appBar: AppBar(
        backgroundColor: (isDark ? AppColors.darkCard : AppColors.lightScaffold)
            .withValues(alpha: 0.9),
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Odalarım',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 24),
            tooltip: 'Yeni Oda Ekle',
            onPressed: _navigateToAddRoom,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Title & Add Room Button Row
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
                          style: AppTypography.headlineLarge.copyWith(
                            color: AppColors.primaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Evindeki alanları düzenle ve cihazlarını yönet.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _navigateToAddRoom,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Oda Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Summary status pill
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCardSecondary
                          : AppColors.lightCardSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$totalRooms Oda • $totalDevices Cihaz • $activeDevices Aktif',
                          style: AppTypography.labelMedium.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w600,
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

              // Rooms List or Empty State
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

                    return GestureDetector(
                      onTap: () => _navigateToRoomDetail(room),
                      child: Container(
                        padding: const EdgeInsets.all(16),
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
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkCardSecondary
                                            : AppColors.lightCardSecondary,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        room.icon,
                                        size: 24,
                                        color: AppColors.primaryContainer,
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
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: roomActiveCount > 0
                                                    ? AppColors.primaryContainer
                                                    : AppColors.secondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${roomDevices.length} Cihaz • $roomActiveCount Açık • ${room.temperature.toStringAsFixed(1).replaceAll('.0', '')}°C',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkCardSecondary
                                        : AppColors.lightCardSecondary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),

                            // Mini device chips
                            if (roomDevices.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: roomDevices.map((dev) {
                                  final isDeviceOn = dev.isPoweredOn;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDeviceOn
                                          ? AppColors.secondaryContainer
                                          : (isDark
                                              ? AppColors.darkCardSecondary
                                              : AppColors.lightCardSecondary),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          dev.icon,
                                          size: 14,
                                          color: isDeviceOn
                                              ? AppColors.primaryContainer
                                              : AppColors.secondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          dev.name,
                                          style: AppTypography.labelSmall.copyWith(
                                            color: isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.lightTextPrimary,
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
                                                ? AppColors.primaryContainer
                                                : AppColors.secondary,
                                            fontWeight: isDeviceOn
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
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

              const SizedBox(height: 24),

              // Bottom Add Room Callout
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardSecondary
                      : AppColors.lightCardSecondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_home_rounded,
                      size: 24,
                      color: AppColors.primaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Evini genişletmek için yeni oda tanımlayabilirsin.',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
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
