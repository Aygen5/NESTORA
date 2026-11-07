import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/device.dart' as entity;
import '../cubit/devices_cubit.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/nestora_button.dart';
import '../../../../core/widgets/nestora_input.dart';
import '../../../../core/widgets/nestora_snackbar.dart';
import '../../../../core/widgets/nestora_switch.dart';
import '../../domain/device_model.dart';

class AddEditDevicePage extends StatefulWidget {
  final String? initialRoom;

  const AddEditDevicePage({super.key, this.initialRoom});

  @override
  State<AddEditDevicePage> createState() => _AddEditDevicePageState();
}

class _AddEditDevicePageState extends State<AddEditDevicePage> {
  bool _isAddMode = true;
  final TextEditingController _nameController = TextEditingController(text: 'Salon Lambası');
  DeviceType _selectedType = DeviceType.bulb;
  late String _selectedRoom;
  bool _isFavorite = true;
  bool _initialPowerState = true;

  // Dynamic panel values
  double _bulbBrightness = 72;
  String _bulbColorPreset = 'Günışığı';
  double _acTemp = 23.0;
  String _fanSpeed = 'Orta';
  bool _energyRelayActive = true;

  @override
  void initState() {
    super.initState();
    _selectedRoom = widget.initialRoom ?? 'Salon';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          _isAddMode ? 'Yeni Cihaz Ekle' : 'Cihazı Düzenle',
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
            // Mode Switcher Segmented Control
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
                      onTap: () => setState(() => _isAddMode = true),
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
                      onTap: () => setState(() => _isAddMode = false),
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

            // Smart Pairing Hero Banner
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.sensors_rounded, color: AppColors.primaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'OTOMATİK ALGILAMA',
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
                          'Nestora Hub Bağlantısı',
                          style: AppTypography.headlineSmall.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          'Ağdaki 2 yeni cihaz sinyal veriyor',
                          style: AppTypography.caption.copyWith(color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.wifi_tethering_rounded, size: 18, color: AppColors.primaryContainer),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 1. Cihaz Adı Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cihaz Adı',
                  style: AppTypography.labelLarge.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
            ),
            const SizedBox(height: 20),

            // 2. Cihaz Türü Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cihaz Türü',
                  style: AppTypography.labelLarge.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Text('Tür parametreleri günceller', style: AppTypography.caption.copyWith(color: AppColors.primaryContainer)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
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
              ],
            ),
            const SizedBox(height: 20),

            // 3. Dinamik Cihaz Ayarları Paneli
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.tune_rounded, size: 16, color: AppColors.primaryContainer),
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
                      children: ['Sıcak Sarı', 'Günışığı', 'Doğal Beyaz', 'Yumuşak Yeşil'].map((colorName) {
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
                        Text('Hedef Sıcaklık', style: AppTypography.labelSmall),
                        Text('${_acTemp.toStringAsFixed(1)}°C', style: AppTypography.headlineSmall.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  ] else if (_selectedType == DeviceType.fan) ...[
                    Text('Hız Kademesi', style: AppTypography.labelSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Hafif', 'Orta', 'Yüksek'].map((spd) {
                        final isSel = _fanSpeed == spd;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () => setState(() => _fanSpeed = spd),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSel ? AppColors.primaryContainer : (isDark ? AppColors.darkCard : Colors.white),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    spd,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isSel ? Colors.white : AppColors.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bolt_rounded, size: 18, color: AppColors.primaryContainer),
                            const SizedBox(width: 6),
                            Text('Enerji Tasarruf Rölesi', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
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
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Oda Seç Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Oda Seç',
                  style: AppTypography.labelLarge.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
              children: ['Salon', 'Yatak Odası', 'Mutfak', 'Çalışma Odası', 'Atanmamış'].map((roomName) {
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

            // 5. Favorilere Ekle Section (Toggle Card)
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

            // 6. Başlangıç Durumu Section
            Text(
              'Başlangıç Durumu',
              style: AppTypography.labelLarge.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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

            // Submit Button
            NestoraButton(
              text: _isAddMode ? 'Cihazı Ekle' : 'Değişiklikleri Kaydet',
              onPressed: () {
                final name = _nameController.text.trim().isEmpty ? 'Yeni Cihaz' : _nameController.text.trim();
                final deviceEntity = entity.Device(
                  id: 'dev-${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  roomId: _selectedRoom,
                  type: _selectedType,
                  isPoweredOn: _initialPowerState,
                  brightness: _selectedType == DeviceType.bulb ? _bulbBrightness.round() : 72,
                  targetTemp: _selectedType == DeviceType.ac ? _acTemp : 24.0,
                  isFavorite: _isFavorite,
                );
                context.read<DevicesCubit>().addDeviceEntity(deviceEntity);

                showNestoraSnackbar(
                  context,
                  message: 'Cihaz başarıyla eklendi.',
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

  Widget _buildDeviceTypeButton(
    String label,
    DeviceType type,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
