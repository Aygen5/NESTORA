import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../../core/services/secure_image_service.dart';
import '../../../../core/utils/temperature_formatter.dart';
import '../../../../core/widgets/glowing_toast.dart';
import '../../../../core/widgets/nestora_button.dart';
import '../../../../core/widgets/nestora_dialog.dart';
import '../../../../core/widgets/nestora_image_helper.dart';
import '../../../../core/widgets/nestora_switch.dart';
import '../../../../core/widgets/pulsing_glow_dot.dart';
import '../../../devices/domain/device_model.dart';
import '../../../devices/presentation/cubit/devices_cubit.dart';
import '../../../devices/presentation/cubit/devices_state.dart';
import '../../../devices/presentation/pages/ac_control_page.dart';
import '../../../devices/presentation/pages/add_edit_device_page.dart';
import '../../../devices/presentation/pages/coffee_machine_control_page.dart';
import '../../../devices/presentation/pages/lamp_control_page.dart';
import '../../../devices/presentation/pages/plug_control_page.dart';
import '../../../devices/presentation/pages/security_camera_control_page.dart';
import '../../../devices/presentation/pages/tv_control_page.dart';
import '../cubit/rooms_cubit.dart';
import '../cubit/rooms_state.dart';
import '../../domain/room_model.dart';
import 'add_edit_room_page.dart';

/// Detailed view of a specific smart room.
/// Displays ambient environment metrics (temperature, humidity, air quality),
/// connected devices with live controls, and bulk room actions.
class RoomDetailPage extends StatefulWidget {
  final RoomModel room;

  const RoomDetailPage({super.key, required this.room});

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  bool _isFavorite = false;

  void _navigateToEditRoom(RoomModel currentRoom) {
    try {
      context.goToAddEditRoom(room: currentRoom);
    } catch (_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddEditRoomPage(
            isEditing: true,
            room: currentRoom,
          ),
        ),
      );
    }
  }

  void _navigateToAddDevice(RoomModel currentRoom) {
    try {
      context.goToAddEditDevice(
        initialRoom: currentRoom.name,
        initialRoomId: currentRoom.id,
      );
    } catch (_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddEditDevicePage(
            initialRoom: currentRoom.name,
            initialRoomId: currentRoom.id,
          ),
        ),
      );
    }
  }

  void _navigateToDeviceControl(DeviceModel device) {
    final lower = device.name.toLowerCase();
    final isBulb = device.type == DeviceType.bulb || lower.contains('lamba');
    final isAc = device.type == DeviceType.ac || lower.contains('klima');
    final isTv = device.type == DeviceType.tv || lower.contains('televizyon') || lower.contains('tv');
    final isCoffee = (lower.contains('kahve') || lower.contains('coffee'));
    final isPlug = device.type == DeviceType.plug || lower.contains('priz');
    final isSecurity = device.type == DeviceType.security ||
        lower.contains('kamera') ||
        lower.contains('camera') ||
        lower.contains('güvenlik');

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
    } else if (isSecurity) {
      try {
        context.goToCameraControl(device.id);
      } catch (_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SecurityCameraControlPage(deviceId: device.id)),
        );
      }
    } else {
      try {
        context.goToAddEditDevice(device: device, isEditing: true);
      } catch (_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddEditDevicePage(device: device, isEditing: true)),
        );
      }
    }
  }

  Future<void> _pickRoomImage(
    BuildContext context,
    RoomModel currentRoom,
    ImageSource source,
  ) async {
    final imageService = sl.isRegistered<SecureImageService>()
        ? sl<SecureImageService>()
        : SecureImageService();

    final result = await imageService.pickAndSaveImage(
      source: source,
      targetPrefix: 'room_${currentRoom.id}',
    );

    if (!context.mounted) return;

    if (result.isSuccess && result.savedPath != null) {
      await context.read<RoomsCubit>().updateRoomImage(
            currentRoom.id,
            result.savedPath,
          );
      if (context.mounted) {
        showGlowingToast(
          context,
          message: 'Oda resmi başarıyla güncellendi.',
          icon: Icons.image_rounded,
        );
      }
    } else if (result.errorMessage != null) {
      showGlowingToast(
        context,
        message: result.errorMessage!,
        isError: true,
        icon: Icons.warning_amber_rounded,
      );
    }
  }

  void _showImageOptionsModal(BuildContext context, RoomModel currentRoom) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalCtx) {
        return Material(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${currentRoom.name} Görseli',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Yalnızca JPG ve PNG formatında yüksek kaliteli görseller kabul edilir.',
                      style: AppTypography.caption.copyWith(color: AppColors.secondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF283B2C) : AppColors.primaryContainer.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.photo_library_rounded,
                          color: isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer,
                        ),
                      ),
                      title: Text(
                        'Galeriden Seç',
                        style: AppTypography.labelLarge.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text('Bilgisayardan veya galeriden görsel yükleyin'),
                      onTap: () {
                        Navigator.pop(modalCtx);
                        _pickRoomImage(context, currentRoom, ImageSource.gallery);
                      },
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.collections_rounded, color: AppColors.primaryContainer),
                      ),
                      title: Text(
                        'Mimari Hazır Görseller',
                        style: AppTypography.labelLarge.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text('Modern İskandinav & Kaşmir mimari fotoğraflar'),
                      onTap: () {
                        Navigator.pop(modalCtx);
                        _showPresetGalleryModal(context, currentRoom);
                      },
                    ),
                    if (currentRoom.imageAsset != null && currentRoom.imageAsset!.isNotEmpty) ...[
                      const Divider(),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                        ),
                        title: const Text(
                          'Resmi Kaldır',
                          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('Varsayılan şeffaf görünüme dönün'),
                        onTap: () {
                          Navigator.pop(modalCtx);
                          context.read<RoomsCubit>().updateRoomImage(currentRoom.id, null);
                          showGlowingToast(
                            context,
                            message: 'Oda resmi kaldırıldı.',
                            icon: Icons.delete_sweep_rounded,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPresetGalleryModal(BuildContext context, RoomModel currentRoom) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final presets = [
      {'name': 'Salon', 'path': 'assets/rooms/salon.jpg'},
      {'name': 'Yatak Odası', 'path': 'assets/rooms/yatak_odasi.jpg'},
      {'name': 'Mutfak', 'path': 'assets/rooms/mutfak.jpg'},
      {'name': 'Çalışma Odası', 'path': 'assets/rooms/calisma_odasi.jpg'},
      {'name': 'Banyo', 'path': 'assets/rooms/banyo.jpg'},
      {'name': 'Balkon', 'path': 'assets/rooms/balkon.jpg'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalCtx) {
        return Material(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Modern Mimari Görseller',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nestora mimari kataloğundan dilediğiniz odayı seçin:',
                      style: AppTypography.caption.copyWith(color: AppColors.secondary),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                      ),
                      itemCount: presets.length,
                      itemBuilder: (ctx, index) {
                        final item = presets[index];
                        final isCurrent = currentRoom.imageAsset == item['path'];

                        return InkWell(
                          onTap: () {
                            Navigator.pop(modalCtx);
                            context.read<RoomsCubit>().updateRoomImage(
                                  currentRoom.id,
                                  item['path'],
                                );
                            showGlowingToast(
                              context,
                              message: '${item['name']} görseli uygulandı.',
                              icon: Icons.check_circle_outline_rounded,
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCurrent
                                    ? AppColors.primaryContainer
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                width: isCurrent ? 2.5 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(item['path']!, fit: BoxFit.cover),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.75),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 10,
                                    bottom: 8,
                                    right: 10,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['name']!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isCurrent)
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppColors.primaryContainer,
                                            size: 16,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, RoomModel currentRoom, List<RoomModel> otherRooms) {
    String? selectedTargetRoomId = otherRooms.isNotEmpty ? otherRooms.first.id : null;

    showNestoraDialog(
      context: context,
      variation: DialogVariation.variationB,
      title: '"${currentRoom.name}" Odasını Sil',
      description:
          'Bu işlem odayı sistemden kaldırır. Bağlı olan ${currentRoom.deviceCount} cihazınız sahipsiz kalmayacak; diğer bir odaya aktarılacaktır.',
      confirmText: 'Odayı Sil ve Cihazları Aktar',
      onConfirm: () {
        context.read<RoomsCubit>().deleteRoomById(
              currentRoom.id,
              moveToRoomId: selectedTargetRoomId,
            );
        Navigator.pop(context); // close room detail page
      },
    );
  }

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

    final currentRoom = rooms.firstWhere(
      (r) => r.id == widget.room.id,
      orElse: () => widget.room,
    );

    final otherRooms = rooms.where((r) => r.id != currentRoom.id).toList();

    final roomDevices = devices
        .where((d) => d.roomId == currentRoom.id || d.room == currentRoom.name)
        .toList();

    final activeCount = roomDevices.where((d) => d.isPoweredOn).length;
    final allActive = roomDevices.isNotEmpty && activeCount == roomDevices.length;
    final tempUnit = TemperatureFormatter.currentUnit(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightScaffold,
      appBar: AppBar(
        backgroundColor: (isDark ? AppColors.darkCard : AppColors.lightScaffold)
            .withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Oda Detayı',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _isFavorite ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? AppColors.error : AppColors.secondary,
              size: 22,
            ),
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
              showGlowingToast(
                context,
                message: _isFavorite
                    ? '${currentRoom.name} favorilere eklendi.'
                    : '${currentRoom.name} favorilerden çıkarıldı.',
                icon: _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              );
            },
          ),
          IconButton(
            tooltip: 'Odayı Düzenle',
            icon: const Icon(Icons.edit_outlined, size: 22),
            onPressed: () => _navigateToEditRoom(currentRoom),
          ),
          IconButton(
            tooltip: 'Odayı Sil',
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 22,
              color: AppColors.error,
            ),
            onPressed: () => _showDeleteDialog(context, currentRoom, otherRooms),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // 1. Hero Room Overview Showcase with Environmental Sensors
              _buildHeroRoomBanner(context, currentRoom, tempUnit, isDark),
              const SizedBox(height: 16),

              // 2. Status & Quick Bulk Action Ribbon
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCardSecondary
                                  : AppColors.lightCardSecondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${roomDevices.length} Cihaz',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$activeCount Aktif Cihaz',
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
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: roomDevices.isEmpty
                          ? null
                          : () {
                              context
                                  .read<DevicesCubit>()
                                  .toggleAllInRoom(currentRoom.id, !allActive, roomName: currentRoom.name);
                            },
                      icon: const Icon(Icons.power_settings_new_rounded, size: 16),
                      label: Text(allActive ? 'Tümünü Kapat' : 'Tümünü Aç'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Section Header: Bu Odadaki Cihazlar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bu Odadaki Cihazlar',
                          style: AppTypography.headlineMedium.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bağlı aygıtları yönetin ve hassas ayarlayın',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.secondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCardSecondary
                          : AppColors.lightCardSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${roomDevices.length} Kayıtlı',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4. Devices List or Empty Room View
              if (roomDevices.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.devices_other_rounded,
                        size: 40,
                        color: AppColors.secondary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Bu odada henüz bağlı cihaz bulunmuyor.',
                        style: AppTypography.cardTitle(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Odanıza yeni bir lamba, klima veya priz ekleyerek başlayabilirsiniz.',
                        textAlign: TextAlign.center,
                        style: AppTypography.description(color: AppColors.secondary),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: roomDevices.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final device = roomDevices[index];
                    return GestureDetector(
                      onTap: () => _navigateToDeviceControl(device),
                      child: Container(
                        padding: const EdgeInsets.all(16),
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
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: device.isPoweredOn
                                              ? (isDark
                                                  ? const Color(0xFF283B2C)
                                                  : AppColors.warmAmber.withValues(alpha: 0.25))
                                              : (isDark
                                                  ? AppColors.darkCardSecondary
                                                  : AppColors.lightCardSecondary),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          device.icon,
                                          size: 22,
                                          color: device.isPoweredOn
                                              ? (isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer)
                                              : (isDark ? AppColors.darkTextSecondary : AppColors.secondary),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    device.name,
                                                    style: AppTypography
                                                        .headlineSmall
                                                        .copyWith(
                                                      color: isDark
                                                          ? AppColors.darkTextPrimary
                                                          : AppColors.lightTextPrimary,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: device.isPoweredOn
                                                        ? (isDark ? const Color(0xFF8FD8A0) : AppColors.primaryContainer)
                                                        : AppColors.secondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${device.type.name} • ${device.isPoweredOn ? "Açık" : "Kapalı"}${device.type == DeviceType.plug && device.isPoweredOn ? " (240 W)" : ""}${device.type == DeviceType.ac && device.isPoweredOn ? " (${TemperatureFormatter.format(device.targetTemp, unit: tempUnit)})" : ""}',
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                color: AppColors.secondary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                NestoraSwitch(
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

                            // Inline Interactive Brightness Slider for Lamp
                            if (device.type == DeviceType.bulb &&
                                device.isPoweredOn) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.brightness_medium_rounded,
                                        size: 14,
                                        color: AppColors.secondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Parlaklık',
                                        style: AppTypography.caption
                                            .copyWith(color: AppColors.secondary),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '%${device.brightness}',
                                    style: AppTypography.labelSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: AppColors.warmAmber,
                                  thumbColor: AppColors.primaryContainer,
                                  inactiveTrackColor: isDark
                                      ? AppColors.darkCardSecondary
                                      : AppColors.lightCardSecondary,
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 7,
                                  ),
                                ),
                                child: Slider(
                                  value: device.brightness.toDouble(),
                                  min: 0,
                                  max: 100,
                                  onChanged: (val) {
                                    context
                                        .read<DevicesCubit>()
                                        .setLampBrightness(
                                          device.id,
                                          val.round(),
                                        );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // 5. Primary Management Actions
              NestoraButton(
                text: '+ Cihaz Ekle',
                icon: Icons.add_rounded,
                onPressed: () => _navigateToAddDevice(currentRoom),
              ),
              const SizedBox(height: 10),
              NestoraButton(
                text: 'Odayı Düzenle',
                variant: ButtonVariant.secondary,
                icon: Icons.edit_rounded,
                onPressed: () => _navigateToEditRoom(currentRoom),
              ),
              const SizedBox(height: 24),

              // 6. Safe Delete Guidance Panel
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardSecondary
                      : AppColors.lightCardSecondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.security_rounded,
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
                                'Güvenli Oda Silme',
                                style: AppTypography.headlineSmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Oda silindiğinde içindeki cihazlar silinmez. Cihazlar diğer odalara aktarılır veya korunur.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () =>
                            _showDeleteDialog(context, currentRoom, otherRooms),
                        icon: const Icon(
                          Icons.delete_sweep_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        label: Text(
                          'Odayı Sil',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _buildHeroRoomBanner(
    BuildContext context,
    RoomModel currentRoom,
    String tempUnit,
    bool isDark,
  ) {
    final hasImage = currentRoom.imageAsset != null && currentRoom.imageAsset!.isNotEmpty;

    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Image or Transparent Placeholder
            Positioned.fill(
              child: hasImage
                  ? _buildRoomImage(currentRoom.imageAsset!)
                  : _buildTransparentPlaceholder(isDark),
            ),

            // Subtle dark overlay gradient for readability when image is present
            if (hasImage)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),

            // Top Header: Live Badge + Change/Add Photo Button
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLiveBadge(hasImage, isDark),
                  InkWell(
                    key: const Key('room_image_action_button'),
                    onTap: () => _showImageOptionsModal(context, currentRoom),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: hasImage
                            ? Colors.black.withValues(alpha: 0.45)
                            : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: hasImage
                              ? Colors.white.withValues(alpha: 0.3)
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasImage ? Icons.camera_alt_outlined : Icons.add_photo_alternate_rounded,
                            size: 15,
                            color: hasImage
                                ? Colors.white
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hasImage ? 'Resmi Değiştir' : 'Oda Resmi Ekle',
                            style: AppTypography.labelSmall.copyWith(
                              color: hasImage
                                  ? Colors.white
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Center Call-to-action if placeholder (no image)
            if (!hasImage)
              Center(
                child: InkWell(
                  key: const Key('room_image_placeholder_cta'),
                  onTap: () => _showImageOptionsModal(context, currentRoom),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryContainer.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 32,
                          color: AppColors.primaryContainer,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '+ Oda Resmi Ekle',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Yüksek kaliteli JPG/PNG seçin',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.secondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom Info: Room Name + Environmental Sensors
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'YAŞAM ALANI',
                    style: AppTypography.labelSmall.copyWith(
                      color: hasImage ? Colors.white.withValues(alpha: 0.8) : AppColors.secondary,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentRoom.name,
                    style: AppTypography.headlineMedium.copyWith(
                      color: hasImage
                          ? Colors.white
                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                      shadows: hasImage
                          ? [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildSensorPill(
                        TemperatureFormatter.format(currentRoom.temperature, unit: tempUnit),
                        icon: Icons.thermostat_rounded,
                        hasImage: hasImage,
                        isDark: isDark,
                      ),
                      _buildSensorPill(
                        'Nem %${currentRoom.humidity.toInt()}',
                        icon: Icons.water_drop_outlined,
                        hasImage: hasImage,
                        isDark: isDark,
                      ),
                      _buildSensorPill(
                        'Hava: Temiz',
                        icon: Icons.air_rounded,
                        hasImage: hasImage,
                        isDark: isDark,
                        customColor: const Color(0xFF2E6930),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomImage(String path) {
    return buildNestoraImage(
      path,
      fit: BoxFit.cover,
      errorWidget: _buildPlaceholderBackground(false),
    );
  }

  Widget _buildTransparentPlaceholder(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCardSecondary.withValues(alpha: 0.5)
            : AppColors.lightCardSecondary.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildPlaceholderBackground(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: AppColors.secondary, size: 36),
      ),
    );
  }

  Widget _buildLiveBadge(bool hasImage, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: hasImage
            ? Colors.black.withValues(alpha: 0.45)
            : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasImage
              ? Colors.white.withValues(alpha: 0.25)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PulsingGlowDot(color: Color(0xFF4CAF50), size: 7),
          const SizedBox(width: 6),
          Text(
            'Canlı İzleme',
            style: AppTypography.labelSmall.copyWith(
              color: hasImage
                  ? Colors.white
                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorPill(
    String label, {
    required IconData icon,
    required bool hasImage,
    required bool isDark,
    Color? customColor,
  }) {
    final textColor = customColor ??
        (hasImage
            ? Colors.white
            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: hasImage
            ? Colors.black.withValues(alpha: 0.45)
            : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasImage
              ? Colors.white.withValues(alpha: 0.2)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
