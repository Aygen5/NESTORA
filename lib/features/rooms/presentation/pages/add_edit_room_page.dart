import 'package:flutter/material.dart';
import '../../../../app/app_state.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/nestora_button.dart';
import '../../../../core/widgets/nestora_input.dart';
import '../../../../core/widgets/nestora_snackbar.dart';
import '../../domain/room_model.dart';

class AddEditRoomPage extends StatefulWidget {
  final bool isEditing;
  final RoomModel? room;

  const AddEditRoomPage({
    super.key,
    this.isEditing = false,
    this.room,
  });

  @override
  State<AddEditRoomPage> createState() => _AddEditRoomPageState();
}

class _AddEditRoomPageState extends State<AddEditRoomPage> {
  late TextEditingController _nameController;
  late String _selectedType;
  late IconData _selectedIcon;
  final Set<String> _assignedDeviceIds = {};

  final List<Map<String, dynamic>> _roomTypes = [
    {'name': 'Salon', 'icon': Icons.chair_rounded},
    {'name': 'Yatak Odası', 'icon': Icons.bed_rounded},
    {'name': 'Mutfak', 'icon': Icons.restaurant_rounded},
    {'name': 'Çalışma Odası', 'icon': Icons.desk_rounded},
    {'name': 'Banyo', 'icon': Icons.bathtub_rounded},
    {'name': 'Diğer', 'icon': Icons.category_rounded},
  ];

  final List<Map<String, dynamic>> _iconPickerItems = [
    {'label': 'Salon', 'icon': Icons.chair_rounded},
    {'label': 'Yatak', 'icon': Icons.bed_rounded},
    {'label': 'Mutfak', 'icon': Icons.restaurant_rounded},
    {'label': 'Çalışma', 'icon': Icons.desk_rounded},
    {'label': 'Banyo', 'icon': Icons.bathtub_rounded},
    {'label': 'Balkon', 'icon': Icons.deck_rounded},
    {'label': 'Garaj', 'icon': Icons.garage_rounded},
    {'label': 'Bahçe', 'icon': Icons.park_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.room?.name ?? (widget.isEditing ? 'Salon' : ''));
    _selectedType = widget.room?.type ?? 'Salon';
    _selectedIcon = widget.room?.icon ?? Icons.chair_rounded;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          widget.isEditing ? 'Odayı Düzenle' : 'Oda Ekle',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Step Banner
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Nestora Yaşam Alanı',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• Oda Tanımlama',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Adım 1 / 1',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Evinizin atmosferini özelleştirin, cihazlarınızı bir araya toplayın ve akıllı senaryolarınızı kolayca yönetin.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),

            // Live Preview Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.secondaryContainer,
                      image: const DecorationImage(
                        image: AssetImage('assets/screens/nestora_salon_oda_detay.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ÖNİZLEME',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.secondary,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _nameController.text.trim().isEmpty ? 'Yeni Oda' : _nameController.text.trim(),
                          style: AppTypography.headlineSmall.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(_selectedIcon, size: 14, color: AppColors.primaryContainer),
                            const SizedBox(width: 4),
                            Text(
                              '$_selectedType • ${_assignedDeviceIds.length} Cihaz Hazır',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 1. Oda Adı Input
            Text(
              'Oda Adı',
              style: AppTypography.labelLarge.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            NestoraInput(
              controller: _nameController,
              hintText: 'Örn: Salon, Balkon, Misafir Odası',
              prefixIcon: Icons.edit_note_rounded,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            // 2. Oda Türü
            Text(
              'Oda Türü',
              style: AppTypography.labelLarge.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.2,
              ),
              itemCount: _roomTypes.length,
              itemBuilder: (context, index) {
                final item = _roomTypes[index];
                final isSelected = item['name'] == _selectedType;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = item['name'] as String;
                      _selectedIcon = item['icon'] as IconData;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryContainer
                          : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryContainer
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 16,
                          color: isSelected ? Colors.white : AppColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            item['name'] as String,
                            style: AppTypography.labelSmall.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // 3. Oda İkonu Seçimi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Oda İkonu Seçimi',
                  style: AppTypography.labelLarge.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  '8 Simge',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.secondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemCount: _iconPickerItems.length,
              itemBuilder: (context, index) {
                final item = _iconPickerItems[index];
                final isSelected = item['icon'] == _selectedIcon;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = item['icon'] as IconData;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.secondaryContainer
                          : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryContainer : Colors.transparent,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 24,
                          color: isSelected ? AppColors.primaryContainer : AppColors.secondary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          style: AppTypography.caption.copyWith(
                            color: isSelected ? AppColors.primaryContainer : AppColors.secondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // 4. Değişiklik Güvencesi Kartı
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shield_rounded, size: 18, color: AppColors.primaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Oda Değişikliği & Silme Güvencesi',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bir odayı sildiğinizde cihazlarınız kaybolmaz; otomatik olarak "Atanmamış Cihazlar" havuzuna aktarılır veya dilediğiniz başka bir odaya taşınır.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. Atanacak Cihazlar (Opsiyonel)
            Text(
              'Atanacak Cihazlar',
              style: AppTypography.labelLarge.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bu odaya eklenecek bağlı cihazları seçin (Opsiyonel)',
              style: AppTypography.bodySmall.copyWith(color: AppColors.secondary),
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appState.devices.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final dev = appState.devices[index];
                final isChecked = _assignedDeviceIds.contains(dev.id);

                return CheckboxListTile(
                  value: isChecked,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _assignedDeviceIds.add(dev.id);
                      } else {
                        _assignedDeviceIds.remove(dev.id);
                      }
                    });
                  },
                  activeColor: AppColors.primaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                  title: Text(
                    dev.name,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Mevcut Oda: ${dev.room}',
                    style: AppTypography.caption.copyWith(color: AppColors.secondary),
                  ),
                  secondary: Icon(dev.icon, color: AppColors.secondary),
                );
              },
            ),
            const SizedBox(height: 28),

            // Action Button
            NestoraButton(
              text: widget.isEditing ? 'Değişiklikleri Kaydet' : 'Odayı Oluştur',
              onPressed: () {
                final roomName = _nameController.text.trim().isEmpty ? 'Yeni Oda' : _nameController.text.trim();
                if (!widget.isEditing) {
                  final newRoom = RoomModel(
                    id: 'room-${DateTime.now().millisecondsSinceEpoch}',
                    name: roomName,
                    type: _selectedType,
                    icon: _selectedIcon,
                    deviceCount: _assignedDeviceIds.length,
                    activeDeviceCount: 0,
                    temperature: 23.0,
                    humidity: 50,
                  );
                  appState.addRoom(newRoom);
                }
                showNestoraSnackbar(
                  context,
                  message: widget.isEditing ? 'Değişiklikler kaydedildi.' : 'Oda başarıyla oluşturuldu.',
                );
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
