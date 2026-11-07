import 'package:flutter/material.dart';
import '../../../../app/app_state.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/nestora_button.dart';
import '../../../../core/widgets/nestora_dialog.dart';
import '../../../../core/widgets/nestora_switch.dart';
import '../../../devices/domain/device_model.dart';
import '../../../devices/presentation/pages/add_edit_device_page.dart';
import '../../../devices/presentation/pages/lamp_control_page.dart';
import '../../domain/room_model.dart';
import 'add_edit_room_page.dart';

class RoomDetailPage extends StatefulWidget {
  final RoomModel room;

  const RoomDetailPage({super.key, required this.room});

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentRoom = appState.rooms.firstWhere(
      (r) => r.id == widget.room.id,
      orElse: () => widget.room,
    );
    final roomDevices = appState.devices.where((d) => d.room == currentRoom.name).toList();
    final activeCount = roomDevices.where((d) => d.isPoweredOn).length;
    final allActive = roomDevices.isNotEmpty && activeCount == roomDevices.length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightScaffold,
      appBar: AppBar(
        backgroundColor: (isDark ? AppColors.darkCard : AppColors.lightScaffold).withValues(alpha: 0.9),
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
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? AppColors.error : AppColors.secondary,
              size: 22,
            ),
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditRoomPage(
                    isEditing: true,
                    room: currentRoom,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 22, color: AppColors.error),
            onPressed: () => _showDeleteDialog(context, appState, currentRoom),
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
            // Hero Room Overview Showcase
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.cardShadow,
                image: const DecorationImage(
                  image: AssetImage('assets/screens/nestora_salon_oda_detay.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Live Monitoring Tag
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
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
                            const SizedBox(width: 6),
                            Text(
                              'Canlı İzleme',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.lightTextPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom info: Name & Climate Pills
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.chair_rounded, size: 16, color: Colors.white70),
                                const SizedBox(width: 6),
                                Text(
                                  'YAŞAM ALANI',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white70,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentRoom.name,
                              style: AppTypography.headlineLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${currentRoom.temperature}°C',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Nem %${currentRoom.humidity}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status & Quick Action Ribbon
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${roomDevices.length} Cihaz',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryContainer,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$activeCount Aktif Cihaz',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      appState.toggleAllInRoom(currentRoom.name, !allActive);
                    },
                    icon: const Icon(Icons.power_settings_new_rounded, size: 16),
                    label: Text(allActive ? 'Tümünü Kapat' : 'Tümünü Aç'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bu Odadaki Cihazlar',
                      style: AppTypography.headlineMedium.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bağlı aygıtları yönetin ve hassas ayarlayın',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
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

            // Devices Stack
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: roomDevices.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final device = roomDevices[index];
                return GestureDetector(
                  onTap: () {
                    if (device.name == 'Salon Lambası') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LampControlPage()),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(16),
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
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: device.isPoweredOn
                                        ? AppColors.warmAmber.withValues(alpha: 0.3)
                                        : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    device.icon,
                                    size: 22,
                                    color: device.isPoweredOn
                                        ? AppColors.primaryContainer
                                        : AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          device.name,
                                          style: AppTypography.headlineSmall.copyWith(
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: device.isPoweredOn
                                                ? AppColors.primaryContainer
                                                : AppColors.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${device.type.name} • ${device.isPoweredOn ? "Açık" : "Kapalı"}${device.name == "Akıllı Priz" && device.isPoweredOn ? " (142 W)" : ""}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            NestoraSwitch(
                              value: device.isPoweredOn,
                              onChanged: (_) {
                                appState.toggleDevicePower(device.id);
                              },
                            ),
                          ],
                        ),

                        // Inline Brightness Slider for Lamp
                        if (device.type == DeviceType.bulb && device.isPoweredOn) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.brightness_medium_rounded, size: 14, color: AppColors.secondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Parlaklık',
                                    style: AppTypography.caption.copyWith(color: AppColors.secondary),
                                  ),
                                ],
                              ),
                              Text(
                                '%${device.brightness}',
                                style: AppTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: device.brightness / 100,
                              minHeight: 6,
                              backgroundColor: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.warmAmber),
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

            // Primary Management Actions
            NestoraButton(
              text: '+ Cihaz Ekle',
              icon: Icons.add_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditDevicePage(initialRoom: currentRoom.name),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            NestoraButton(
              text: 'Odayı Düzenle',
              variant: ButtonVariant.secondary,
              icon: Icons.edit_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditRoomPage(
                      isEditing: true,
                      room: currentRoom,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Safe Delete Guidance Panel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
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
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
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
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Oda silindiğinde içindeki cihazlar silinmez. Cihazları başka bir odaya taşıyabilir veya "Atanmamış" olarak bırakabilirsiniz.',
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
                      onPressed: () => _showDeleteDialog(context, appState, currentRoom),
                      icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: AppColors.error),
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
  ),
);
}

  void _showDeleteDialog(BuildContext context, AppState appState, RoomModel currentRoom) {
    showNestoraDialog(
      context: context,
      variation: DialogVariation.variationB,
      title: '"${currentRoom.name}" Odasını Silmek İstiyor musunuz?',
      description:
          'Bu işlem odayı kaldırır. ${currentRoom.deviceCount} cihazınız silinmez, otomatik olarak Atanmamış Cihazlar listesine aktarılır.',
      confirmText: 'Odayı Sil ve Cihazları Koru',
      onConfirm: () {
        appState.deleteRoom(currentRoom.id);
        Navigator.pop(context); // close room detail page
      },
    );
  }
}
