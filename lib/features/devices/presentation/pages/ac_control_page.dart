import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/seed_data.dart';
import '../cubit/devices_cubit.dart';
import '../cubit/devices_state.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/nestora_button.dart';
import '../../../../core/widgets/nestora_dialog.dart';
import '../../../../core/widgets/nestora_switch.dart';
import '../../domain/device_model.dart';
import 'add_edit_device_page.dart';

class AcControlPage extends StatefulWidget {
  const AcControlPage({super.key});

  @override
  State<AcControlPage> createState() => _AcControlPageState();
}

class _AcControlPageState extends State<AcControlPage> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devicesCubit = context.watch<DevicesCubit>();
    final devicesState = devicesCubit.state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final devices = (devicesState is DevicesLoaded)
        ? devicesState.devices.map(SeedData.deviceToModel).toList()
        : SeedData.defaultDeviceModels;
    final ac = devices.firstWhere(
      (d) => d.id == 'dev-5',
      orElse: () => devices.firstWhere((d) => d.type == DeviceType.ac, orElse: () => devices.first),
    );
    final isPowered = ac.isPoweredOn;
    final currentTemp = ac.targetTemp;

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
          'İklimlendirme Kontrolü',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              ac.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: ac.isFavorite ? AppColors.warmAmber : AppColors.secondary,
              size: 22,
            ),
            onPressed: () => context.read<DevicesCubit>().toggleDeviceFavorite(ac.id),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditDevicePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 22, color: AppColors.error),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
            // Status & Room Pills
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.bed_rounded, size: 16, color: AppColors.primaryContainer),
                          const SizedBox(width: 4),
                          Text(
                            ac.room,
                            style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Klima',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.secondary),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      isPowered ? 'Açık' : 'Kapalı',
                      style: AppTypography.labelMedium.copyWith(
                        color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    NestoraSwitch(
                      value: isPowered,
                      onChanged: (_) => context.read<DevicesCubit>().toggleDevicePower(ac.id),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // AC Unit Minimalist Visual
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                borderRadius: BorderRadius.circular(20),
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
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'NESTORA CLIMATE PRO',
                            style: AppTypography.caption.copyWith(
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isPowered ? 'Aktif' : 'Standby',
                          style: AppTypography.caption.copyWith(
                            color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // AC Unit Body
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              height: 4,
                              width: 48,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isPowered ? '$currentTemp°C' : '--°C',
                                style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Louver Blade
                        Container(
                          height: 5,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: isPowered ? 0.8 : 0.3,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Airflow waves animation
                  if (isPowered) ...[
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: 0.4 + (_waveController.value * 0.6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.air_rounded, color: AppColors.primaryContainer, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'Ferah Hava Akışı',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Temperature Dial & Control Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(24),
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
                      Text(
                        'Hedef Ayar',
                        style: AppTypography.labelMedium.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Menzil: 16°C - 30°C',
                        style: AppTypography.caption.copyWith(color: AppColors.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Circular Arc Dial
                  SizedBox(
                    height: 220,
                    width: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Arc painter
                        CustomPaint(
                          size: const Size(220, 220),
                          painter: TemperatureArcPainter(
                            temperature: currentTemp,
                            minTemp: 16,
                            maxTemp: 30,
                            isPowered: isPowered,
                          ),
                        ),

                        // Center Temp Readout
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$currentTemp',
                                  style: AppTypography.displayLarge.copyWith(
                                    color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 54,
                                    height: 1.0,
                                  ),
                                ),
                                Text(
                                  '°C',
                                  style: AppTypography.headlineMedium.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hedef Sıcaklık',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.thermostat_rounded, size: 12, color: AppColors.secondary),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Oda: 25.4°C',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Floating +/- buttons on the side
                        Positioned(
                          left: 0,
                          child: GestureDetector(
                            onTap: () {
                              if (currentTemp > 16) {
                                context.read<DevicesCubit>().setAcTemp(ac.id, (currentTemp - 1).toDouble());
                              }
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                                boxShadow: AppColors.subtleShadow,
                              ),
                              child: Icon(
                                Icons.remove_rounded,
                                size: 22,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              if (currentTemp < 30) {
                                context.read<DevicesCubit>().setAcTemp(ac.id, (currentTemp + 1).toDouble());
                              }
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                                boxShadow: AppColors.subtleShadow,
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                size: 22,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Preset Buttons
                  Row(
                    children: [
                      _buildPresetButton(
                        label: '20°C Serin',
                        temp: 20,
                        currentTemp: currentTemp,
                        onTap: () => context.read<DevicesCubit>().setAcTemp(ac.id, 20.0),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildPresetButton(
                        label: '24°C Konfor',
                        temp: 24,
                        currentTemp: currentTemp,
                        onTap: () => context.read<DevicesCubit>().setAcTemp(ac.id, 24.0),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildPresetButton(
                        label: '26°C Eko',
                        temp: 26,
                        currentTemp: currentTemp,
                        onTap: () => context.read<DevicesCubit>().setAcTemp(ac.id, 26.0),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Operational Mode Section ("Çalışma Modu")
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Çalışma Modu',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  '${ac.acMode.name.toUpperCase()} Seçili',
                  style: AppTypography.caption.copyWith(color: AppColors.secondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildModeCard(
                    title: 'Soğutma',
                    subtitle: 'Ferah Esinti',
                    icon: Icons.ac_unit_rounded,
                    isSelected: ac.acMode == AcMode.cool,
                    onTap: () => context.read<DevicesCubit>().setAcModeChoice(ac.id, AcMode.cool),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildModeCard(
                    title: 'Isıtma',
                    subtitle: 'Dengeli Ilık',
                    icon: Icons.local_fire_department_rounded,
                    isSelected: ac.acMode == AcMode.heat,
                    onTap: () => context.read<DevicesCubit>().setAcModeChoice(ac.id, AcMode.heat),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildModeCard(
                    title: 'Otomatik',
                    subtitle: 'Akıllı Ayar',
                    icon: Icons.autorenew_rounded,
                    isSelected: ac.acMode == AcMode.auto,
                    onTap: () => context.read<DevicesCubit>().setAcModeChoice(ac.id, AcMode.auto),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Fan Speed Settings Pills ("Fan Hızı")
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fan Hızı',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.air_rounded, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      '${ac.fanSpeed.name.toUpperCase()} Akış',
                      style: AppTypography.caption.copyWith(color: AppColors.secondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildFanPill('Düşük', FanSpeed.low, ac.fanSpeed, () => context.read<DevicesCubit>().setAcFanSpeedChoice(ac.id, FanSpeed.low), isDark),
                const SizedBox(width: 8),
                _buildFanPill('Orta', FanSpeed.mid, ac.fanSpeed, () => context.read<DevicesCubit>().setAcFanSpeedChoice(ac.id, FanSpeed.mid), isDark),
                const SizedBox(width: 8),
                _buildFanPill('Yüksek', FanSpeed.high, ac.fanSpeed, () => context.read<DevicesCubit>().setAcFanSpeedChoice(ac.id, FanSpeed.high), isDark),
                const SizedBox(width: 8),
                _buildFanPill('Oto', FanSpeed.auto, ac.fanSpeed, () => context.read<DevicesCubit>().setAcFanSpeedChoice(ac.id, FanSpeed.auto), isDark),
              ],
            ),
            const SizedBox(height: 20),

            // Ambient Schedule / Eco Insights Mini-Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.eco_rounded, size: 20, color: AppColors.primaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enerji Tasarrufu',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          'Hedef sıcaklık %14 daha az enerji harcar',
                          style: AppTypography.caption.copyWith(color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.secondary),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            NestoraButton(
              text: 'Cihazı Düzenle',
              icon: Icons.tune_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditDevicePage()),
                );
              },
            ),
            const SizedBox(height: 10),
            NestoraButton(
              text: 'Cihazı Sil',
              variant: ButtonVariant.ghost,
              icon: Icons.delete_outline_rounded,
              onPressed: () => _showDeleteDialog(context),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  ),
);
}

  Widget _buildPresetButton({
    required String label,
    required int temp,
    required int currentTemp,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final isSelected = temp == currentTemp;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryContainer
                : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryContainer
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : AppColors.primaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                color: isSelected ? Colors.white70 : AppColors.secondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFanPill(
    String label,
    FanSpeed speed,
    FanSpeed currentSpeed,
    VoidCallback onTap,
    bool isDark,
  ) {
    final isSelected = speed == currentSpeed;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.secondaryContainer
                : (isDark ? AppColors.darkCard : AppColors.lightCard),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryContainer
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? AppColors.primaryContainer
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showNestoraDialog(
      context: context,
      variation: DialogVariation.variationA,
      title: 'Klimayı Sil',
      description:
          'Bu cihazı silmek istediğine emin misin? Bu işlem geri alınamaz ve cihazın bağlı olduğu tüm rutinler devre dışı bırakılır.',
      onConfirm: () {
        context.read<DevicesCubit>().deleteDeviceById('dev-5');
        Navigator.pop(context);
      },
    );
  }
}

class TemperatureArcPainter extends CustomPainter {
  final int temperature;
  final int minTemp;
  final int maxTemp;
  final bool isPowered;

  TemperatureArcPainter({
    required this.temperature,
    required this.minTemp,
    required this.maxTemp,
    required this.isPowered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 24;

    // Background track arc
    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const startAngle = 0.75 * math.pi;
    const sweepAngle = 1.5 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Progress arc
    if (isPowered) {
      final ratio = ((temperature - minTemp) / (maxTemp - minTemp)).clamp(0.0, 1.0);
      final activePaint = Paint()
        ..color = AppColors.primaryContainer
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * ratio,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TemperatureArcPainter oldDelegate) {
    return oldDelegate.temperature != temperature ||
        oldDelegate.isPowered != isPowered;
  }
}
