import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../devices/presentation/cubit/devices_cubit.dart';
import '../../../devices/presentation/cubit/devices_state.dart';
import '../cubit/rooms_cubit.dart';
import '../cubit/rooms_state.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import 'add_edit_room_page.dart';
import 'room_detail_page.dart';

class RoomsPage extends StatelessWidget {
  const RoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final roomsState = context.watch<RoomsCubit>().state;
    final devicesState = context.watch<DevicesCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rooms = (roomsState is RoomsLoaded)
        ? roomsState.rooms.map(SeedData.roomToModel).toList()
        : SeedData.defaultRoomModels;
    final devices = (devicesState is DevicesLoaded)
        ? devicesState.devices.map(SeedData.deviceToModel).toList()
        : SeedData.defaultDeviceModels;

    final totalRooms = rooms.length;
    final totalDevices = devices.length;
    final activeDevices = devices.where((d) => d.isPoweredOn).length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightScaffold,
      appBar: AppBar(
        backgroundColor: (isDark ? AppColors.darkCard : AppColors.lightScaffold).withValues(alpha: 0.9),
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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.secondaryContainer,
                  width: 2,
                ),
                image: const DecorationImage(
                  image: AssetImage('assets/screens/nestora_profil_ve_ayarlar.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Title & Add Room Button
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddEditRoomPage(isEditing: false),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Oda Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Summary pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$totalRooms Oda • $totalDevices Cihaz • $activeDevices Aktif',
                    style: AppTypography.labelMedium.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rooms List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rooms.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final room = rooms[index];
                final roomDevices = devices.where((d) => d.room == room.name).toList();

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoomDetailPage(room: room),
                      ),
                    );
                  },
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
                                    color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
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
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: room.activeDeviceCount > 0
                                                ? AppColors.primaryContainer
                                                : AppColors.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${room.deviceCount} Cihaz • ${room.activeDeviceCount} Açık',
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
                                color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isDeviceOn
                                      ? AppColors.secondaryContainer
                                      : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
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
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        fontWeight: isDeviceOn ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isDeviceOn ? '• Açık' : '• Kapalı',
                                      style: AppTypography.caption.copyWith(
                                        color: isDeviceOn ? AppColors.primaryContainer : AppColors.secondary,
                                        fontWeight: isDeviceOn ? FontWeight.bold : FontWeight.normal,
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
                color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_home_rounded,
                    size: 24,
                    color: AppColors.primaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Evini genişletmek için yeni oda tanımlayabilirsin.',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
  ),
);
}
}
