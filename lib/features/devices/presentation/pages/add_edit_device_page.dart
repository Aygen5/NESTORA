import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../../core/widgets/nestora_button.dart';
import '../../../../core/widgets/nestora_dialog.dart';
import '../../../../core/widgets/nestora_input.dart';
import '../../../../core/widgets/nestora_snackbar.dart';
import '../../../../core/widgets/nestora_switch.dart';
import '../../../rooms/domain/room_model.dart';
import '../../../rooms/presentation/cubit/rooms_cubit.dart';
import '../../../rooms/presentation/cubit/rooms_state.dart';
import '../../domain/device_model.dart';
import '../../domain/entities/device.dart' as entity;
import '../cubit/devices_cubit.dart';
import '../cubit/devices_state.dart';

/// Screen for creating a new virtual smart device or editing an existing one.
/// Includes smart pairing discovery, device type selection, dynamic hardware panels,
/// room assignment synced with RoomsCubit, form validation, and safe deletion.
class AddEditDevicePage extends StatefulWidget {
  final String? initialRoom;
  final bool isEditing;
  final DeviceModel? device;
  final String? deviceId;

  const AddEditDevicePage({
    super.key,
    this.initialRoom,
    this.isEditing = false,
    this.device,
    this.deviceId,
  });

  @override
  State<AddEditDevicePage> createState() => _AddEditDevicePageState();
}

class _AddEditDevicePageState extends State<AddEditDevicePage>
    with SingleTickerProviderStateMixin {
  late bool _isAddMode;
  DeviceModel? _targetDevice;

  final TextEditingController _nameController = TextEditingController();
  String? _nameError;

  DeviceType _selectedType = DeviceType.bulb;
  late String _selectedRoom;
  bool _isFavorite = false;
  bool _initialPowerState = true;

  // Dynamic panel values
  double _bulbBrightness = 72.0;
  String _bulbColorPreset = 'Sıcak Günışığı (2700K)';
  double _acTemp = 24.0;
  AcMode _acMode = AcMode.auto;
  FanSpeed _acFanSpeed = FanSpeed.mid;
  String _fanSpeed = 'Orta';
  bool _energyRelayActive = true;
  String _tvMode = 'Standart';
  bool _securityMotionAlert = true;

  // Smart Pairing Simulation
  late AnimationController _radarController;
  bool _isScanning = false;
  bool _hasScanned = false;
  Timer? _scanTimer;

  static const List<Map<String, dynamic>> _discoveredDevices = [
    {
      'name': 'Nestora Akıllı Led Ampul',
      'type': DeviceType.bulb,
      'room': 'Salon',
      'brightness': 85.0,
      'color': 'Sıcak Günışığı (2700K)',
      'isFavorite': true,
      'isPoweredOn': true,
    },
    {
      'name': 'Nestora Enerji Prizi V2',
      'type': DeviceType.plug,
      'room': 'Mutfak',
      'relay': true,
      'isFavorite': false,
      'isPoweredOn': true,
    },
    {
      'name': 'Nestora Inverter Klima',
      'type': DeviceType.ac,
      'room': 'Yatak Odası',
      'temp': 22.0,
      'mode': AcMode.cool,
      'fanSpeed': FanSpeed.mid,
      'isFavorite': true,
      'isPoweredOn': true,
    },
    {
      'name': 'Nestora Akıllı Sirkülatör',
      'type': DeviceType.fan,
      'room': 'Çalışma Odası',
      'fanSpeed': 'Yüksek',
      'isFavorite': false,
      'isPoweredOn': true,
    },
    {
      'name': 'Nestora 2K Güvenlik Kamerası',
      'type': DeviceType.security,
      'room': 'Giriş / Dış',
      'motion': true,
      'isFavorite': true,
      'isPoweredOn': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _isAddMode = !widget.isEditing && widget.device == null && widget.deviceId == null;
    _selectedRoom = widget.initialRoom ?? 'Salon';

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    if (widget.device != null) {
      _loadDeviceValues(widget.device!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_targetDevice == null && widget.deviceId != null) {
      final devicesState = context.read<DevicesCubit>().state;
      if (devicesState is DevicesLoaded) {
        final found = devicesState.findDeviceById(widget.deviceId!);
        if (found != null) {
          _loadDeviceValues(SeedData.deviceToModel(found));
        }
      }
    }
  }

  void _loadDeviceValues(DeviceModel device) {
    setState(() {
      _targetDevice = device;
      _isAddMode = false;
      _nameController.text = device.name;
      _selectedType = device.type;
      _selectedRoom = device.room.isNotEmpty ? device.room : (widget.initialRoom ?? 'Salon');
      _isFavorite = device.isFavorite;
      _initialPowerState = device.isPoweredOn;
      _bulbBrightness = device.brightness.toDouble();
      _bulbColorPreset = device.colorName.isNotEmpty ? device.colorName : 'Sıcak Günışığı (2700K)';
      _acTemp = device.targetTemp;
      _acMode = device.acMode;
      _acFanSpeed = device.fanSpeed;
    });
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _radarController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _startSmartPairingScan() {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _hasScanned = false;
    });
    _radarController.repeat();

    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      _radarController.stop();
      _radarController.reset();
      setState(() {
        _isScanning = false;
        _hasScanned = true;
      });
      showNestoraSnackbar(
        context,
        message: 'Ağ taraması tamamlandı! 5 yeni sanal cihaz algılandı.',
      );
    });
  }

  void _applyDiscoveredDevice(Map<String, dynamic> item) {
    setState(() {
      _nameController.text = item['name'] as String;
      _selectedType = item['type'] as DeviceType;
      _selectedRoom = item['room'] as String;
      _isFavorite = item['isFavorite'] as bool? ?? false;
      _initialPowerState = item['isPoweredOn'] as bool? ?? true;

      if (item.containsKey('brightness')) {
        _bulbBrightness = (item['brightness'] as num).toDouble();
      }
      if (item.containsKey('color')) {
        _bulbColorPreset = item['color'] as String;
      }
      if (item.containsKey('temp')) {
        _acTemp = (item['temp'] as num).toDouble();
      }
      if (item.containsKey('mode')) {
        _acMode = item['mode'] as AcMode;
      }
      if (item.containsKey('fanSpeed')) {
        if (item['fanSpeed'] is FanSpeed) {
          _acFanSpeed = item['fanSpeed'] as FanSpeed;
        } else {
          _fanSpeed = item['fanSpeed'] as String;
        }
      }
      if (item.containsKey('relay')) {
        _energyRelayActive = item['relay'] as bool;
      }
      if (item.containsKey('motion')) {
        _securityMotionAlert = item['motion'] as bool;
      }
      _nameError = null;
    });

    showNestoraSnackbar(
      context,
      message: '"${item['name']}" bilgileri forma başarıyla aktarıldı.',
    );
  }

  String _resolveRoomId(String roomName, List<RoomModel> rooms) {
    final match = rooms.where((r) => r.name.trim().toLowerCase() == roomName.trim().toLowerCase()).firstOrNull;
    if (match != null) return match.id;
    if (roomName == 'Salon') return 'room-1';
    if (roomName == 'Yatak Odası') return 'room-2';
    if (roomName == 'Mutfak') return 'room-3';
    if (roomName == 'Çalışma Odası') return 'room-4';
    if (roomName == 'Banyo' || roomName == 'Giriş / Dış') return 'room-5';
    return 'room-${roomName.trim().toLowerCase().replaceAll(' ', '-')}';
  }

  void _saveDevice(BuildContext context) {
    final cleanName = _nameController.text.trim();
    if (cleanName.isEmpty) {
      setState(() => _nameError = 'Lütfen cihaz adını giriniz.');
      showNestoraSnackbar(
        context,
        message: 'Lütfen cihaz adını giriniz.',
        isError: true,
      );
      return;
    }
    setState(() => _nameError = null);

    final roomsState = context.read<RoomsCubit>().state;
    final List<RoomModel> currentRooms = (roomsState is RoomsLoaded)
        ? roomsState.rooms.map(SeedData.roomToModel).toList()
        : SeedData.defaultRoomModels;
    final targetRoomId = _resolveRoomId(_selectedRoom, currentRooms);

    final devicesCubit = context.read<DevicesCubit>();

    if (_isAddMode || _targetDevice == null) {
      // Create new device
      final newDeviceEntity = entity.Device(
        id: 'dev-${DateTime.now().millisecondsSinceEpoch}',
        name: cleanName,
        roomId: targetRoomId,
        type: _selectedType,
        isPoweredOn: _initialPowerState,
        brightness: _selectedType == DeviceType.bulb ? _bulbBrightness.round() : 72,
        colorHex: _selectedType == DeviceType.bulb ? _getColorHex(_bulbColorPreset) : '#E1C1A0',
        colorName: _selectedType == DeviceType.bulb ? _bulbColorPreset : 'Sıcak Günışığı (2700K)',
        targetTemp: _selectedType == DeviceType.ac ? _acTemp : 24.0,
        acMode: _acMode,
        fanSpeed: _acFanSpeed,
        isFavorite: _isFavorite,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      devicesCubit.addDeviceEntity(newDeviceEntity);

      showNestoraSnackbar(
        context,
        message: '"$cleanName" başarıyla eklendi.',
      );
      Navigator.pop(context, true);
    } else {
      // Update existing device
      final updatedDeviceEntity = entity.Device(
        id: _targetDevice!.id,
        name: cleanName,
        roomId: targetRoomId,
        type: _selectedType,
        isPoweredOn: _initialPowerState,
        brightness: _selectedType == DeviceType.bulb ? _bulbBrightness.round() : _targetDevice!.brightness,
        colorHex: _selectedType == DeviceType.bulb ? _getColorHex(_bulbColorPreset) : _targetDevice!.colorHex,
        colorName: _selectedType == DeviceType.bulb ? _bulbColorPreset : _targetDevice!.colorName,
        targetTemp: _selectedType == DeviceType.ac ? _acTemp : _targetDevice!.targetTemp,
        acMode: _acMode,
        fanSpeed: _acFanSpeed,
        isFavorite: _isFavorite,
        updatedAt: DateTime.now(),
      );

      devicesCubit.updateDeviceEntity(updatedDeviceEntity);

      showNestoraSnackbar(
        context,
        message: '"$cleanName" başarıyla güncellendi.',
      );
      Navigator.pop(context, true);
    }
  }

  void _showDeleteDialog(BuildContext context, DeviceModel device) async {
    final confirmed = await showNestoraDeleteDialog(
      context: context,
      title: '"${device.name}" Silinecek',
      message: 'Bu cihazı akıllı ev sisteminizden silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
      deleteButtonText: 'Cihazı Sil',
    );
    if (confirmed == true && context.mounted) {
      context.read<DevicesCubit>().deleteDeviceById(device.id);
      showNestoraSnackbar(
        context,
        message: '"${device.name}" başarıyla silindi.',
      );
      Navigator.pop(context, true);
    }
  }

  String _getColorHex(String preset) {
    switch (preset) {
      case 'Doğal Beyaz (4000K)':
      case 'Doğal Beyaz':
        return '#F5F5F0';
      case 'Sıcak Sarı':
        return '#FFCC66';
      case 'Yumuşak Yeşil':
        return '#A8D5BA';
      case 'Gece Mavisi':
        return '#6BA4B8';
      case 'Sıcak Günışığı (2700K)':
      case 'Günışığı':
      default:
        return '#E1C1A0';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final roomsState = context.watch<RoomsCubit>().state;
    final List<String> roomOptions = (roomsState is RoomsLoaded && roomsState.rooms.isNotEmpty)
        ? [...roomsState.rooms.map((r) => r.name), 'Atanmamış']
        : ['Salon', 'Yatak Odası', 'Mutfak', 'Çalışma Odası', 'Banyo', 'Atanmamış'];

    final devicesState = context.watch<DevicesCubit>().state;
    final List<DeviceModel> existingDevices = (devicesState is DevicesLoaded)
        ? devicesState.devices.map(SeedData.deviceToModel).toList()
        : SeedData.defaultDeviceModels;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightScaffold,
      appBar: AppBar(
        backgroundColor: (isDark ? AppColors.darkCard : AppColors.lightScaffold).withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isAddMode ? 'Yeni Cihaz Ekle' : 'Cihazı Düzenle',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Mode Switcher Segmented Control
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _isAddMode = true;
                            _targetDevice = null;
                            _nameController.clear();
                            _nameError = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isAddMode ? AppColors.primaryContainer : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: _isAddMode ? AppColors.subtleShadow : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 18,
                                  color: _isAddMode ? Colors.white : AppColors.secondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Yeni Cihaz Ekle',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: _isAddMode ? Colors.white : AppColors.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isAddMode = false;
                              if (_targetDevice == null && existingDevices.isNotEmpty) {
                                _loadDeviceValues(existingDevices.first);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isAddMode ? AppColors.primaryContainer : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: !_isAddMode ? AppColors.subtleShadow : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 18,
                                  color: !_isAddMode ? Colors.white : AppColors.secondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Cihazı Düzenle',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: !_isAddMode ? Colors.white : AppColors.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Device Selection Chip Bar (When in Edit Mode)
                if (!_isAddMode && existingDevices.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Düzenlenecek Cihaz',
                        style: AppTypography.labelMedium.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${existingDevices.length} Cihaz Mevcut',
                        style: AppTypography.caption.copyWith(color: AppColors.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: existingDevices.map((dev) {
                        final isSel = _targetDevice?.id == dev.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _loadDeviceValues(dev),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppColors.primaryContainer
                                    : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSel ? AppColors.primaryContainer : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    dev.icon,
                                    size: 16,
                                    color: isSel ? Colors.white : AppColors.secondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    dev.name,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isSel ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
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
                  const SizedBox(height: 16),
                ],

                // 2. Smart Pairing Hero Banner & Scanning Flow
                GestureDetector(
                  onTap: _startSmartPairingScan,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isScanning
                            ? AppColors.primaryContainer
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            RotationTransition(
                              turns: _radarController,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  _isScanning ? Icons.radar_rounded : Icons.sensors_rounded,
                                  color: AppColors.primaryContainer,
                                  size: 26,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'SANAL EŞLEŞTİRME',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.primaryContainer,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isScanning ? 'Nestora Hub Ağı Taranıyor...' : 'Sanal Cihaz Arama & Eşleştirme',
                                    style: AppTypography.headlineSmall.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    _isScanning
                                        ? 'Yerel simülasyon mesh sinyalleri taranıyor'
                                        : 'Ağdaki yeni cihazları keşfetmek için dokunun',
                                    style: AppTypography.caption.copyWith(color: AppColors.secondary),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isScanning ? AppColors.primaryContainer : (isDark ? AppColors.darkCard : Colors.white),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isScanning ? Icons.hourglass_top_rounded : Icons.wifi_find_rounded,
                                size: 18,
                                color: _isScanning ? Colors.white : AppColors.primaryContainer,
                              ),
                            ),
                          ],
                        ),

                        // Discovered Devices List
                        if (_hasScanned) ...[
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Keşfedilen Cihazlar',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryContainer,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_discoveredDevices.length} Bulundu',
                                style: AppTypography.caption.copyWith(color: AppColors.secondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _discoveredDevices.map((item) {
                              return InkWell(
                                onTap: () => _applyDiscoveredDevice(item),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkCard : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.add_link_rounded, size: 14, color: AppColors.primaryContainer),
                                      const SizedBox(width: 4),
                                      Text(
                                        item['name'] as String,
                                        style: AppTypography.caption.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Cihaz Adı Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cihaz Adı',
                      style: AppTypography.labelLarge.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Zorunlu', style: AppTypography.caption.copyWith(color: AppColors.secondary)),
                  ],
                ),
                const SizedBox(height: 8),
                NestoraInput(
                  controller: _nameController,
                  hintText: 'Örn: Salon Lambası, Çalışma Prizi',
                  prefixIcon: Icons.edit_note_rounded,
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                ),
                if (_nameError != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      _nameError!,
                      style: AppTypography.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // 4. Cihaz Türü Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cihaz Türü',
                      style: AppTypography.labelLarge.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        'Tür parametreleri günceller',
                        style: AppTypography.caption.copyWith(color: AppColors.primaryContainer),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildDeviceTypeButton('Ampul', DeviceType.bulb, Icons.lightbulb_rounded, isDark),
                      const SizedBox(width: 8),
                      _buildDeviceTypeButton('Priz', DeviceType.plug, Icons.power_rounded, isDark),
                      const SizedBox(width: 8),
                      _buildDeviceTypeButton('Klima', DeviceType.ac, Icons.ac_unit_rounded, isDark),
                      const SizedBox(width: 8),
                      _buildDeviceTypeButton('Fan', DeviceType.fan, Icons.air_rounded, isDark),
                      const SizedBox(width: 8),
                      _buildDeviceTypeButton('TV', DeviceType.tv, Icons.tv_rounded, isDark),
                      const SizedBox(width: 8),
                      _buildDeviceTypeButton('Güvenlik', DeviceType.security, Icons.videocam_rounded, isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Dinamik Cihaz Ayarları Paneli (Özel Donanım Ayarları)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
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
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: AppColors.secondaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.tune_rounded, size: 16, color: AppColors.primaryContainer),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Özel Donanım Ayarları',
                                style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _selectedType.name.toUpperCase(),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Dynamic content depending on type
                      if (_selectedType == DeviceType.bulb) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Parlaklık Düzeyi',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              '%${_bulbBrightness.round()}',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryContainer,
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primaryContainer,
                            inactiveTrackColor: isDark ? AppColors.darkCard : Colors.white,
                            thumbColor: AppColors.primaryContainer,
                          ),
                          child: Slider(
                            value: _bulbBrightness,
                            min: 0,
                            max: 100,
                            onChanged: (val) => setState(() => _bulbBrightness = val),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('%0 Gece', style: AppTypography.caption.copyWith(color: AppColors.secondary)),
                            Text('%50 Dengeli', style: AppTypography.caption.copyWith(color: AppColors.secondary)),
                            Text('%100 Tam Güç', style: AppTypography.caption.copyWith(color: AppColors.secondary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Işık Rengi & Atmosfer',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            'Sıcak Günışığı (2700K)',
                            'Doğal Beyaz (4000K)',
                            'Sıcak Sarı',
                            'Yumuşak Yeşil',
                            'Gece Mavisi'
                          ].map((colorName) {
                            final isSel = _bulbColorPreset == colorName;
                            return GestureDetector(
                              onTap: () => setState(() => _bulbColorPreset = colorName),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSel ? AppColors.secondaryContainer : (isDark ? AppColors.darkCard : Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSel ? AppColors.primaryContainer : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  colorName,
                                  style: AppTypography.caption.copyWith(
                                    color: isSel ? AppColors.primaryContainer : AppColors.secondary,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ] else if (_selectedType == DeviceType.ac) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Hedef Sıcaklık',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              '${_acTemp.toStringAsFixed(1)}°C',
                              style: AppTypography.headlineSmall.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryContainer,
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primaryContainer,
                            thumbColor: AppColors.primaryContainer,
                          ),
                          child: Slider(
                            value: _acTemp,
                            min: 16,
                            max: 30,
                            divisions: 28,
                            onChanged: (val) => setState(() => _acTemp = val),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Çalışma Modu', style: AppTypography.labelSmall),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildChoiceChip('Soğutma', _acMode == AcMode.cool, () => setState(() => _acMode = AcMode.cool), isDark),
                            const SizedBox(width: 6),
                            _buildChoiceChip('Isıtma', _acMode == AcMode.heat, () => setState(() => _acMode = AcMode.heat), isDark),
                            const SizedBox(width: 6),
                            _buildChoiceChip('Otomatik', _acMode == AcMode.auto, () => setState(() => _acMode = AcMode.auto), isDark),
                            const SizedBox(width: 6),
                            _buildChoiceChip('Fan', _acMode == AcMode.fanOnly, () => setState(() => _acMode = AcMode.fanOnly), isDark),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('Fan Hızı', style: AppTypography.labelSmall),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildChoiceChip('Düşük', _acFanSpeed == FanSpeed.low, () => setState(() => _acFanSpeed = FanSpeed.low), isDark),
                            const SizedBox(width: 6),
                            _buildChoiceChip('Orta', _acFanSpeed == FanSpeed.mid, () => setState(() => _acFanSpeed = FanSpeed.mid), isDark),
                            const SizedBox(width: 6),
                            _buildChoiceChip('Yüksek', _acFanSpeed == FanSpeed.high, () => setState(() => _acFanSpeed = FanSpeed.high), isDark),
                            const SizedBox(width: 6),
                            _buildChoiceChip('Oto', _acFanSpeed == FanSpeed.auto, () => setState(() => _acFanSpeed = FanSpeed.auto), isDark),
                          ],
                        ),
                      ] else if (_selectedType == DeviceType.fan) ...[
                        Text('Hız Kademesi', style: AppTypography.labelSmall),
                        const SizedBox(height: 8),
                        Row(
                          children: ['Hafif', 'Orta', 'Yüksek', 'Otomatik'].map((spd) {
                            final isSel = _fanSpeed == spd;
                            return _buildChoiceChip(spd, isSel, () => setState(() => _fanSpeed = spd), isDark);
                          }).toList(),
                        ),
                      ] else if (_selectedType == DeviceType.plug) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.bolt_rounded, size: 18, color: AppColors.primaryContainer),
                                const SizedBox(width: 6),
                                Text(
                                  'Enerji Tasarruf Rölesi',
                                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            NestoraSwitch(
                              value: _energyRelayActive,
                              onChanged: (v) => setState(() => _energyRelayActive = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cihaz bekleme modundayken harcamayı sıfırlar.',
                          style: AppTypography.caption.copyWith(color: AppColors.secondary),
                        ),
                      ] else if (_selectedType == DeviceType.tv) ...[
                        Text('Ses & Görüntü Modu', style: AppTypography.labelSmall),
                        const SizedBox(height: 8),
                        Row(
                          children: ['Standart', 'Sinema', 'Eko'].map((m) {
                            final isSel = _tvMode == m;
                            return _buildChoiceChip(m, isSel, () => setState(() => _tvMode = m), isDark);
                          }).toList(),
                        ),
                      ] else if (_selectedType == DeviceType.security) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.security_rounded, size: 18, color: AppColors.primaryContainer),
                                const SizedBox(width: 6),
                                Text(
                                  'Hareket Algılama & Gece Görüşü',
                                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            NestoraSwitch(
                              value: _securityMotionAlert,
                              onChanged: (v) => setState(() => _securityMotionAlert = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Beklenmeyen hareket algılandığında anlık bildirim gönderir.',
                          style: AppTypography.caption.copyWith(color: AppColors.secondary),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Oda Seç Section (Dynamic from RoomsCubit)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Oda Seç',
                      style: AppTypography.labelLarge.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Atanacak Oda',
                      style: AppTypography.caption.copyWith(color: AppColors.secondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: roomOptions.map((roomName) {
                    final isSelected = _selectedRoom == roomName;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRoom = roomName),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryContainer
                              : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryContainer : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          roomName,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // 7. Favorilere Ekle Section (Toggle Card)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.star_rounded, size: 20, color: AppColors.warmAmber),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Favorilere Ekle',
                                    style: AppTypography.labelMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Ana sayfada ve hızlı erişimde göster',
                                    style: AppTypography.caption.copyWith(color: AppColors.secondary),
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
                      NestoraSwitch(
                        value: _isFavorite,
                        onChanged: (val) => setState(() => _isFavorite = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 8. Başlangıç Durumu Section
                Text(
                  'Başlangıç Durumu',
                  style: AppTypography.labelLarge.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _initialPowerState = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _initialPowerState ? AppColors.primaryContainer : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Açık',
                                style: AppTypography.labelMedium.copyWith(
                                  color: _initialPowerState ? Colors.white : AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _initialPowerState = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_initialPowerState ? AppColors.primaryContainer : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Kapalı',
                                style: AppTypography.labelMedium.copyWith(
                                  color: !_initialPowerState ? Colors.white : AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 9. Submit Button (Add or Save)
                NestoraButton(
                  text: _isAddMode ? 'Cihazı Ekle' : 'Değişiklikleri Kaydet',
                  icon: _isAddMode ? Icons.add_circle_outline_rounded : Icons.check_circle_outline_rounded,
                  onPressed: () => _saveDevice(context),
                ),

                // 10. Delete Button (in Edit Mode)
                if (!_isAddMode && _targetDevice != null) ...[
                  const SizedBox(height: 12),
                  NestoraButton(
                    text: 'Cihazı Sil',
                    variant: ButtonVariant.ghost,
                    icon: Icons.delete_outline_rounded,
                    onPressed: () => _showDeleteDialog(context, _targetDevice!),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceTypeButton(
    String label,
    DeviceType type,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer
              : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryContainer : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? Colors.white : AppColors.secondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isSelected ? Colors.white : AppColors.secondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryContainer
                  : (isDark ? AppColors.darkCard : Colors.white),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: isSelected ? Colors.white : AppColors.secondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
