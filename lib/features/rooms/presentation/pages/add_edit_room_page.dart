import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../../core/services/secure_image_service.dart';
import '../../../../core/utils/temperature_formatter.dart';
import '../../../../core/widgets/glowing_toast.dart';
import '../../../../core/widgets/nestora_button.dart';
import '../../../../core/widgets/nestora_dialog.dart';
import '../../../../core/widgets/nestora_input.dart';
import '../../../devices/presentation/cubit/devices_cubit.dart';
import '../../../devices/presentation/cubit/devices_state.dart';
import '../../domain/entities/room.dart';
import '../../domain/room_model.dart';
import '../cubit/rooms_cubit.dart';

/// Screen for creating a new room or editing an existing room's configuration.
/// Includes form validation, icon picker grid, default temperature setting,
/// device assignment, Firestore persistence, and confirmation deletion.
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
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedType;
  late String _selectedIconName;
  late IconData _selectedIcon;
  late double _targetTemperature;
  final Set<String> _assignedDeviceIds = {};
  String? _nameError;
  String? _selectedImagePath;

  final List<Map<String, dynamic>> _roomTypes = [
    {'name': 'Salon', 'iconName': 'chair', 'icon': Icons.chair_rounded},
    {'name': 'Yatak Odası', 'iconName': 'bed', 'icon': Icons.bed_rounded},
    {'name': 'Mutfak', 'iconName': 'restaurant', 'icon': Icons.restaurant_rounded},
    {'name': 'Çalışma Odası', 'iconName': 'desk', 'icon': Icons.desk_rounded},
    {'name': 'Banyo', 'iconName': 'bathtub', 'icon': Icons.bathtub_rounded},
    {'name': 'Diğer', 'iconName': 'chair', 'icon': Icons.category_rounded},
  ];

  final List<Map<String, dynamic>> _iconPickerItems = [
    {'label': 'Salon', 'iconName': 'chair', 'icon': Icons.chair_rounded},
    {'label': 'Yatak', 'iconName': 'bed', 'icon': Icons.bed_rounded},
    {'label': 'Mutfak', 'iconName': 'restaurant', 'icon': Icons.restaurant_rounded},
    {'label': 'Çalışma', 'iconName': 'desk', 'icon': Icons.desk_rounded},
    {'label': 'Banyo', 'iconName': 'bathtub', 'icon': Icons.bathtub_rounded},
    {'label': 'Balkon', 'iconName': 'deck', 'icon': Icons.deck_rounded},
    {'label': 'Garaj', 'iconName': 'garage', 'icon': Icons.garage_rounded},
    {'label': 'Bahçe', 'iconName': 'park', 'icon': Icons.park_rounded},
  ];

  @override
  void initState() {
    super.initState();
    final initialName = widget.room?.name ?? (widget.isEditing ? 'Salon' : '');
    _nameController = TextEditingController(text: initialName);
    _selectedType = widget.room?.type ?? 'Salon';
    _selectedIcon = widget.room?.icon ?? Icons.chair_rounded;
    _selectedIconName = _iconDataToName(_selectedIcon);
    _targetTemperature = widget.room?.temperature ?? AppConstants.defaultRoomTemp;
    _selectedImagePath = widget.room?.imageAsset ??
        (widget.isEditing ? null : SeedData.getSmartRoomAsset(initialName));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _iconDataToName(IconData icon) {
    if (icon == Icons.bed_rounded) return 'bed';
    if (icon == Icons.restaurant_rounded) return 'restaurant';
    if (icon == Icons.desk_rounded) return 'desk';
    if (icon == Icons.bathtub_rounded) return 'bathtub';
    if (icon == Icons.deck_rounded) return 'deck';
    if (icon == Icons.garage_rounded) return 'garage';
    if (icon == Icons.park_rounded) return 'park';
    return 'chair';
  }

  void _adjustTemperature(double delta) {
    final next = (_targetTemperature + delta).clamp(
      AppConstants.minClimateTemp,
      AppConstants.maxClimateTemp,
    );
    setState(() => _targetTemperature = next);
  }

  Future<void> _pickRoomImage(ImageSource source) async {
    final imageService = sl.isRegistered<SecureImageService>()
        ? sl<SecureImageService>()
        : SecureImageService();

    final result = await imageService.pickAndSaveImage(
      source: source,
      targetPrefix: 'room_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!mounted) return;

    if (result.isSuccess && result.savedPath != null) {
      setState(() {
        _selectedImagePath = result.savedPath;
      });
      showGlowingToast(
        context,
        message: 'Görsel başarıyla seçildi.',
        icon: Icons.image_rounded,
      );
    } else if (result.errorMessage != null) {
      showGlowingToast(
        context,
        message: result.errorMessage!,
        isError: true,
        icon: Icons.warning_amber_rounded,
      );
    }
  }

  void _showImageSourceModal(BuildContext context) {
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
                      'Oda Görseli Seç',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Yalnızca JPG ve PNG formatında yüksek kaliteli görseller kabul edilir (< 5 MB).',
                      style: AppTypography.caption.copyWith(color: AppColors.secondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.photo_library_rounded, color: AppColors.primaryContainer),
                      ),
                      title: Text(
                        'Galeriden Seç',
                        style: AppTypography.labelLarge.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text('Cihazınızdaki fotoğraflardan seçin'),
                      onTap: () {
                        Navigator.pop(modalCtx);
                        _pickRoomImage(ImageSource.gallery);
                      },
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryContainer),
                      ),
                      title: Text(
                        'Kamera ile Çek',
                        style: AppTypography.labelLarge.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text('Yeni bir fotoğraf çekerek belirleyin'),
                      onTap: () {
                        Navigator.pop(modalCtx);
                        _pickRoomImage(ImageSource.camera);
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
                        _showPresetGalleryModal(context);
                      },
                    ),
                    if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty) ...[
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
                        subtitle: const Text('Görselsiz varsayılan görünüme dönün'),
                        onTap: () {
                          Navigator.pop(modalCtx);
                          setState(() => _selectedImagePath = null);
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

  void _showPresetGalleryModal(BuildContext context) {
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
                        final isCurrent = _selectedImagePath == item['path'];

                        return InkWell(
                          onTap: () {
                            Navigator.pop(modalCtx);
                            setState(() {
                              _selectedImagePath = item['path'];
                            });
                            showGlowingToast(
                              context,
                              message: '${item['name']} görseli seçildi.',
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

  void _showDeleteDialog() {
    if (widget.room == null) return;
    showNestoraDialog(
      context: context,
      variation: DialogVariation.variationB,
      title: '"${widget.room!.name}" Odasını Sil',
      description:
          'Bu oda silindiğinde kayıtlı ${widget.room!.deviceCount} cihazınız silinmez; korunur ve Atanmamış Cihazlar havuzuna aktarılır.',
      confirmText: 'Odayı Sil',
      onConfirm: () {
        context.read<RoomsCubit>().deleteRoomById(widget.room!.id);
        Navigator.pop(context); // close AddEditRoomPage
      },
    );
  }

  void _handleSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Oda adı boş bırakılamaz.');
      return;
    }
    if (name.length < 2) {
      setState(() => _nameError = 'Oda adı en az 2 karakter olmalıdır.');
      return;
    }

    setState(() => _nameError = null);

    if (widget.isEditing && widget.room != null) {
      // Update existing room
      final updatedRoom = Room(
        id: widget.room!.id,
        name: name,
        iconName: _selectedIconName,
        targetTemperature: _targetTemperature,
        deviceCount: widget.room!.deviceCount,
        activeDeviceCount: widget.room!.activeDeviceCount,
        humidity: widget.room!.humidity,
        imageAsset: _selectedImagePath,
        updatedAt: DateTime.now(),
      );
      context.read<RoomsCubit>().updateRoomEntity(updatedRoom);
      showGlowingToast(
        context,
        message: 'Oda başarıyla güncellendi.',
        icon: Icons.check_circle_outline_rounded,
      );
    } else {
      // Create new room
      final newRoom = Room(
        id: 'room-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        iconName: _selectedIconName,
        targetTemperature: _targetTemperature,
        deviceCount: _assignedDeviceIds.length,
        humidity: 50,
        imageAsset: _selectedImagePath ?? SeedData.getSmartRoomAsset(name),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      context.read<RoomsCubit>().addRoomEntity(newRoom);
      showGlowingToast(
        context,
        message: 'Oda başarıyla oluşturuldu.',
        icon: Icons.check_circle_outline_rounded,
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final devicesState = context.watch<DevicesCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final devices = (devicesState is DevicesLoaded)
        ? devicesState.devices.map(SeedData.deviceToModel).toList()
        : SeedData.defaultDeviceModels;
    final tempUnit = TemperatureFormatter.currentUnit(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          widget.isEditing ? 'Odayı Düzenle' : 'Oda Ekle',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (widget.isEditing && widget.room != null)
            IconButton(
              tooltip: 'Odayı Sil',
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 22,
              ),
              onPressed: _showDeleteDialog,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Step Banner
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
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
                            Flexible(
                              child: Text(
                                widget.isEditing ? '• Oda Düzenleme' : '• Yeni Oda',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.secondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
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
                      color: isDark
                          ? AppColors.darkCardSecondary
                          : AppColors.lightCardSecondary,
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
                          ),
                          child: Icon(
                            _selectedIcon,
                            size: 28,
                            color: AppColors.primaryContainer,
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
                                _nameController.text.trim().isEmpty
                                    ? 'Yeni Oda'
                                    : _nameController.text.trim(),
                                style: AppTypography.headlineSmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    '$_selectedType • ${TemperatureFormatter.format(_targetTemperature, unit: tempUnit, precision: 1)} • ${_assignedDeviceIds.length} Cihaz',
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

                  // Room Photo Picker Card
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Oda Görseli',
                        style: AppTypography.labelLarge.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'İsteğe Bağlı',
                        style: AppTypography.caption.copyWith(color: AppColors.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildImagePickerWidget(isDark),
                  const SizedBox(height: 20),

                  // 1. Oda Adı Input with Form Validation
                  Text(
                    'Oda Adı',
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  NestoraInput(
                    controller: _nameController,
                    hintText: 'Örn: Salon, Balkon, Misafir Odası',
                    prefixIcon: Icons.edit_note_rounded,
                    onChanged: (val) {
                      setState(() {
                        if (val.trim().isNotEmpty && _nameError != null) {
                          _nameError = null;
                        }
                      });
                    },
                  ),
                  if (_nameError != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        _nameError!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // 2. Varsayılan Hedef Sıcaklık (Default Temperature Setting)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Varsayılan Hedef Sıcaklık',
                        style: AppTypography.labelLarge.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          TemperatureFormatter.format(_targetTemperature, unit: tempUnit, precision: 1),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => _adjustTemperature(-0.5),
                              icon: const Icon(Icons.remove_circle_outline_rounded),
                              color: AppColors.secondary,
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.thermostat_rounded,
                                  size: 20,
                                  color: AppColors.primaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  TemperatureFormatter.format(_targetTemperature, unit: tempUnit, precision: 1),
                                  style: AppTypography.pageTitle(
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ).copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () => _adjustTemperature(0.5),
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              color: AppColors.primaryContainer,
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primaryContainer,
                            thumbColor: AppColors.primaryContainer,
                            inactiveTrackColor: isDark
                                ? AppColors.darkCardSecondary
                                : AppColors.lightCardSecondary,
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _targetTemperature,
                            min: AppConstants.minClimateTemp,
                            max: AppConstants.maxClimateTemp,
                            divisions: 28,
                            onChanged: (val) {
                              setState(() => _targetTemperature = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Oda Türü
                  Text(
                    'Oda Türü',
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
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
                            _selectedIconName = item['iconName'] as String;
                            if (_selectedImagePath == null ||
                                _selectedImagePath!.startsWith('assets/rooms/')) {
                              _selectedImagePath = SeedData.getSmartRoomAsset(item['name'] as String);
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryContainer
                                : (isDark
                                    ? AppColors.darkCardSecondary
                                    : AppColors.lightCardSecondary),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryContainer
                                  : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder),
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
                                        : (isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary),
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
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

                  // 4. Oda İkonu Seçimi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Oda İkonu Seçimi',
                        style: AppTypography.labelLarge.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        '8 Simge',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.secondary,
                        ),
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
                      final isSelected = item['iconName'] == _selectedIconName;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIcon = item['icon'] as IconData;
                            _selectedIconName = item['iconName'] as String;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.secondaryContainer
                                : (isDark
                                    ? AppColors.darkCardSecondary
                                    : AppColors.lightCardSecondary),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryContainer
                                  : Colors.transparent,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                item['icon'] as IconData,
                                size: 24,
                                color: isSelected
                                    ? AppColors.primaryContainer
                                    : AppColors.secondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['label'] as String,
                                style: AppTypography.caption.copyWith(
                                  color: isSelected
                                      ? AppColors.primaryContainer
                                      : AppColors.secondary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // 5. Değişiklik Güvencesi Kartı
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCardSecondary
                          : AppColors.lightCardSecondary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            size: 18,
                            color: AppColors.primaryContainer,
                          ),
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
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Bir odayı sildiğinizde cihazlarınız kaybolmaz; otomatik olarak Atanmamış Cihazlar havuzuna aktarılır.',
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

                  // 6. Atanacak Cihazlar (Opsiyonel)
                  Text(
                    'Atanacak Cihazlar',
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bu odaya eklenecek bağlı cihazları seçin (Opsiyonel)',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: devices.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final dev = devices[index];
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
                        tileColor: isDark
                            ? AppColors.darkCardSecondary
                            : AppColors.lightCardSecondary,
                        title: Text(
                          dev.name,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Mevcut Oda: ${dev.room}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        secondary: Icon(dev.icon, color: AppColors.secondary),
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons
                  NestoraButton(
                    text: widget.isEditing ? 'Değişiklikleri Kaydet' : 'Odayı Oluştur',
                    onPressed: _handleSave,
                  ),

                  if (widget.isEditing && widget.room != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showDeleteDialog,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
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
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerWidget(bool isDark) {
    if (_selectedImagePath == null || _selectedImagePath!.isEmpty) {
      return Container(
        height: 110,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCardSecondary.withValues(alpha: 0.5)
              : AppColors.lightCardSecondary.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryContainer.withValues(alpha: 0.25),
          ),
        ),
        child: InkWell(
          onTap: () => _showImageSourceModal(context),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_photo_alternate_outlined,
                size: 28,
                color: AppColors.primaryContainer,
              ),
              const SizedBox(height: 6),
              Text(
                '+ Oda Fotoğrafı Ekle',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Galeriden, kameradan veya mimari hazır tasarımlardan seçin',
                style: AppTypography.caption.copyWith(color: AppColors.secondary, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    final isAsset = _selectedImagePath!.startsWith('assets/');
    return Container(
      height: 130,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            isAsset
                ? Image.asset(
                    _selectedImagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => _buildImageError(isDark),
                  )
                : Image.file(
                    File(_selectedImagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => _buildImageError(isDark),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 12,
              right: 14,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isAsset ? 'Mimari Hazır Görsel' : 'Özel Fotoğraf',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _showImageSourceModal(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_outlined, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Değiştir',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() => _selectedImagePath = null);
                      showGlowingToast(
                        context,
                        message: 'Oda resmi kaldırıldı.',
                        icon: Icons.delete_sweep_rounded,
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageError(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: AppColors.secondary, size: 30),
      ),
    );
  }
}
