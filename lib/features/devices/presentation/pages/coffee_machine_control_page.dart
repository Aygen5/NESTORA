import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../../core/widgets/glowing_toast.dart';
import '../../../../core/widgets/nestora_button.dart';
import '../../../../core/widgets/nestora_dialog.dart';
import '../../../../core/widgets/nestora_switch.dart';
import '../../../../core/widgets/pulsing_glow_dot.dart';
import '../../../notifications/domain/entities/app_notification.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../domain/device_model.dart';
import '../cubit/devices_cubit.dart';
import '../cubit/devices_state.dart';
import 'add_edit_device_page.dart';

/// Coffee recipe option model.
class CoffeeRecipe {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String defaultVolume;

  const CoffeeRecipe({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.defaultVolume,
  });
}

/// Dedicated, interactive Coffee Machine control screen for Nestora.
/// Features a realistic espresso machine figure, animated steam and coffee pour,
/// coffee type, strength, cup size selectors, and an interactive "Demlemeyi Başlat" flow.
class CoffeeMachineControlPage extends StatefulWidget {
  final String? deviceId;

  const CoffeeMachineControlPage({super.key, this.deviceId});

  @override
  State<CoffeeMachineControlPage> createState() => _CoffeeMachineControlPageState();
}

class _CoffeeMachineControlPageState extends State<CoffeeMachineControlPage>
    with SingleTickerProviderStateMixin {
  String _selectedRecipeId = 'espresso';
  String _selectedStrength = 'Dengeli'; // Hafif, Dengeli, Yoğun
  String _selectedCupSize = 'Orta (120 ml)'; // Küçük, Orta, Büyük

  bool _isBrewing = false;
  double _brewProgress = 0.0;
  Timer? _brewTimer;
  late AnimationController _steamController;

  static const List<CoffeeRecipe> _recipes = [
    CoffeeRecipe(
      id: 'espresso',
      name: 'Espresso',
      description: 'Klasik yoğun İtalyan çekimi',
      icon: Icons.coffee_rounded,
      defaultVolume: '40 ml',
    ),
    CoffeeRecipe(
      id: 'americano',
      name: 'Americano',
      description: 'Yumuşak sıcak su ilaveli',
      icon: Icons.local_cafe_rounded,
      defaultVolume: '120 ml',
    ),
    CoffeeRecipe(
      id: 'cappuccino',
      name: 'Cappuccino',
      description: 'Kadifemsi süt köpüklü',
      icon: Icons.emoji_food_beverage_rounded,
      defaultVolume: '150 ml',
    ),
    CoffeeRecipe(
      id: 'latte',
      name: 'Caffè Latte',
      description: 'Bol sütlü yumuşak içim',
      icon: Icons.coffee_maker_rounded,
      defaultVolume: '200 ml',
    ),
    CoffeeRecipe(
      id: 'filter',
      name: 'Filtre Kahve',
      description: 'Geleneksel taze çekilmiş',
      icon: Icons.free_breakfast_rounded,
      defaultVolume: '180 ml',
    ),
  ];

  static const List<String> _strengths = ['Hafif', 'Dengeli', 'Yoğun'];
  static const List<String> _cupSizes = ['Küçük (60 ml)', 'Orta (120 ml)', 'Büyük (240 ml)'];

  @override
  void initState() {
    super.initState();
    _steamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void dispose() {
    _brewTimer?.cancel();
    _steamController.dispose();
    super.dispose();
  }

  CoffeeRecipe get _activeRecipe => _recipes.firstWhere(
        (r) => r.id == _selectedRecipeId,
        orElse: () => _recipes.first,
      );

  void _startBrewing(DeviceModel coffeeMachine) {
    if (_isBrewing) return;

    // If machine is powered off, power it on
    if (!coffeeMachine.isPoweredOn) {
      context.read<DevicesCubit>().toggleDevicePower(coffeeMachine.id);
    }

    setState(() {
      _isBrewing = true;
      _brewProgress = 0.0;
    });

    _steamController.repeat(reverse: true);

    const totalSteps = 40;
    const stepDuration = Duration(milliseconds: 100);
    int currentStep = 0;

    _brewTimer = Timer.periodic(stepDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      currentStep++;
      final progress = currentStep / totalSteps;

      setState(() {
        _brewProgress = progress.clamp(0.0, 1.0);
      });

      if (currentStep >= totalSteps) {
        timer.cancel();
        _steamController.stop();

        setState(() {
          _isBrewing = false;
          _brewProgress = 1.0;
        });

        // Trigger glowing toast
        showGlowingToast(
          context,
          message: 'Afiyet olsun! Taze ${_activeRecipe.name} kahveniz hazır.',
          icon: Icons.coffee_rounded,
        );

        // Dispatch in-app notification via NotificationsCubit
        try {
          final notifsCubit = context.read<NotificationsCubit>();
          notifsCubit.addNotification(
            AppNotification(
              id: 'notif-coffee-${DateTime.now().millisecondsSinceEpoch}',
              title: 'Kahveniz Hazır!',
              message: 'Taze ${_activeRecipe.name} ($_selectedStrength, $_selectedCupSize) başarıyla hazırlandı. Afiyet olsun.',
              type: NotificationType.device,
              createdAt: DateTime.now(),
              isRead: false,
            ),
          );
        } catch (_) {}
      }
    });
  }

  void _showDeleteDialog(BuildContext context, DeviceModel coffeeMachine) {
    showNestoraDeleteDialog(
      context: context,
      variation: DeleteDialogVariation.deviceDelete,
      title: '"${coffeeMachine.name}" Silinecek',
      message:
          'Bu kahve makinesi silindiğinde mevcut tüm kahve tarifleri ve rutinlerden kaldırılacaktır. Onaylıyor musunuz?',
      deleteButtonText: 'Cihazı Sil',
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<DevicesCubit>().deleteDeviceById(coffeeMachine.id);
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final devicesCubit = context.watch<DevicesCubit>();
    final devicesState = devicesCubit.state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final devices = (devicesState is DevicesLoaded)
        ? devicesState.devices.map(SeedData.deviceToModel).toList()
        : SeedData.defaultDeviceModels;

    final coffeeMachine = devices.firstWhere(
      (d) => widget.deviceId != null && widget.deviceId!.isNotEmpty
          ? d.id == widget.deviceId
          : (d.name.toLowerCase().contains('kahve') || d.name.toLowerCase().contains('coffee')),
      orElse: () => devices.firstWhere(
        (d) => d.name.toLowerCase().contains('kahve'),
        orElse: () => devices.first,
      ),
    );

    final isPowered = coffeeMachine.isPoweredOn;
    final activeRecipe = _activeRecipe;
    final liveWatts = _isBrewing ? 1350.0 : (isPowered ? 45.0 : 0.0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightScaffold,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(76),
        child: Container(
          height: 76,
          padding: const EdgeInsets.only(top: 16),
          color: (isDark ? AppColors.darkCard : AppColors.lightScaffold).withValues(alpha: 0.95),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coffeeMachine.name,
                      style: AppTypography.headlineSmall.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${coffeeMachine.room} • Akıllı Espresso Makinesi',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: coffeeMachine.isFavorite ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
                icon: Icon(
                  coffeeMachine.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  color: coffeeMachine.isFavorite ? AppColors.warmAmber : AppColors.secondary,
                  size: 24,
                ),
                onPressed: () {
                  final newFav = !coffeeMachine.isFavorite;
                  context.read<DevicesCubit>().toggleDeviceFavorite(coffeeMachine.id);
                  showGlowingToast(
                    context,
                    message: newFav
                        ? '${coffeeMachine.name} favorilere eklendi.'
                        : '${coffeeMachine.name} favorilerden çıkarıldı.',
                    icon: newFav ? Icons.star_rounded : Icons.star_border_rounded,
                  );
                },
              ),
              IconButton(
                tooltip: 'Cihazı Düzenle',
                icon: const Icon(Icons.edit_outlined, size: 22),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditDevicePage(device: coffeeMachine, isEditing: true),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Cihazı Sil',
                icon: const Icon(Icons.delete_outline_rounded, size: 22, color: AppColors.error),
                onPressed: () => _showDeleteDialog(context, coffeeMachine),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              children: [
                // 1. Room, Boiler Status & Power Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.coffee_rounded, size: 14, color: AppColors.primaryContainer),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        coffeeMachine.room,
                                        style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '15 Bar Termoblok',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.secondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPowered
                              ? AppColors.secondaryContainer
                              : (isDark ? AppColors.darkCard : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            if (isPowered) ...[
                              const PulsingGlowDot(size: 6, color: AppColors.primaryContainer),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              isPowered ? '92°C Hazır • ${liveWatts.toStringAsFixed(0)} W' : 'Soğuk • Kapalı',
                              style: AppTypography.labelSmall.copyWith(
                                color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Hardware Coffee Machine Figure with Steam & Coffee Pour Animation
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                      // Espresso Machine Canvas
                      SizedBox(
                        height: 220,
                        width: 240,
                        child: AnimatedBuilder(
                          animation: _steamController,
                          builder: (context, _) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Ambient Warm Halo when machine is heated
                                if (isPowered)
                                  Container(
                                    width: 210,
                                    height: 210,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFD4C3A3).withValues(alpha: 0.18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFD4C3A3).withValues(alpha: 0.25),
                                          blurRadius: 30,
                                          spreadRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),

                                // Machine Body (Casing)
                                Positioned(
                                  top: 10,
                                  child: Container(
                                    width: 170,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF232B25) : const Color(0xFFE2DDD5),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                      border: Border.all(
                                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 10),
                                        // Pressure Gauge / Indicator
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isPowered ? AppColors.primaryContainer : Colors.grey.shade600,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.water_drop_rounded,
                                                size: 12,
                                                color: isPowered ? const Color(0xFF81C784) : Colors.white60,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isPowered ? '92°C OPTIMAL' : 'BEKLEMEDE',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Portafilter & Dual Spout
                                Positioned(
                                  top: 96,
                                  child: Container(
                                    width: 70,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5A665E),
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Animated Steam Puffs (Rising when brewing)
                                if (_isBrewing || (isPowered && !_isBrewing))
                                  Positioned(
                                    top: 75 - (_steamController.value * 20),
                                    child: Opacity(
                                      opacity: _isBrewing
                                          ? (0.8 - (_steamController.value * 0.5))
                                          : 0.3,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.air_rounded,
                                            size: 18,
                                            color: isDark ? Colors.white70 : Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.cloud_rounded,
                                            size: 14,
                                            color: isDark ? Colors.white60 : Colors.grey.shade400,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Animated Coffee Stream (Pouring during brew)
                                if (_isBrewing)
                                  Positioned(
                                    top: 114,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 3,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4E342E), // Rich coffee color
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Container(
                                          width: 3,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4E342E),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Ceramic Coffee Cup on Drip Tray
                                Positioned(
                                  bottom: 26,
                                  child: Container(
                                    width: 48,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFFF5F3EF) : Colors.white,
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                      border: Border.all(
                                        color: const Color(0xFFD4C3A3),
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 38,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: (_isBrewing || _brewProgress > 0)
                                              ? const Color(0xFF6D4C41) // Crema coffee
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Metallic Drip Tray Base
                                Positioned(
                                  bottom: 12,
                                  child: Container(
                                    width: 180,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1B201D) : const Color(0xFFD8D2C7),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Brewing Progress Feedback
                      if (_isBrewing) ...[
                        Text(
                          'Demleniyor... %${(_brewProgress * 100).toInt()}',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _brewProgress,
                              minHeight: 8,
                              backgroundColor:
                                  isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryContainer),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Master Power Switch Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.power_settings_new_rounded,
                              size: 20,
                              color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isPowered ? 'Makine Açık' : 'Makine Kapalı',
                              style: AppTypography.headlineSmall.copyWith(
                                color: isPowered ? AppColors.primaryContainer : AppColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 14),
                            NestoraSwitch(
                              value: isPowered,
                              onChanged: (_) {
                                context.read<DevicesCubit>().toggleDevicePower(coffeeMachine.id);
                                showGlowingToast(
                                  context,
                                  message: isPowered ? 'Kahve makinesi kapatıldı.' : 'Kahve makinesi açıldı.',
                                  icon: Icons.coffee_rounded,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Start Brewing Action Button
                NestoraButton(
                  text: _isBrewing
                      ? 'Demleniyor... %${(_brewProgress * 100).toInt()}'
                      : 'Demlemeyi Başlat (${activeRecipe.name})',
                  icon: Icons.coffee_rounded,
                  isLoading: _isBrewing,
                  onPressed: _isBrewing ? null : () => _startBrewing(coffeeMachine),
                ),
                const SizedBox(height: 20),

                // 4. Coffee Recipe Type Selector
                Container(
                  padding: const EdgeInsets.all(20),
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
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_cafe_rounded,
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
                                  'Kahve Türü',
                                  style: AppTypography.headlineSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  'Seçilen: ${activeRecipe.name} (${activeRecipe.defaultVolume})',
                                  style: AppTypography.caption.copyWith(color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Recipe Selection Tiles
                      Column(
                        children: _recipes.map((recipe) {
                          final isSelected = recipe.id == _selectedRecipeId;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () {
                                setState(() => _selectedRecipeId = recipe.id);
                                showGlowingToast(
                                  context,
                                  message: '${recipe.name} seçildi.',
                                  icon: recipe.icon,
                                );
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.secondaryContainer.withValues(alpha: 0.6)
                                      : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryContainer
                                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primaryContainer
                                            : (isDark ? AppColors.darkCard : Colors.white),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        recipe.icon,
                                        size: 18,
                                        color: isSelected ? Colors.white : AppColors.primaryContainer,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            recipe.name,
                                            style: AppTypography.labelLarge.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                          Text(
                                            recipe.description,
                                            style: AppTypography.caption.copyWith(color: AppColors.secondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      recipe.defaultVolume,
                                      style: AppTypography.labelSmall.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? AppColors.primaryContainer : AppColors.secondary,
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
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Coffee Strength & Cup Size Card
                Container(
                  padding: const EdgeInsets.all(20),
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
                      // Strength Row
                      Row(
                        children: [
                          const Icon(Icons.grain_rounded, size: 20, color: AppColors.primaryContainer),
                          const SizedBox(width: 8),
                          Text(
                            'Kahve Sertliği',
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: _strengths.map((str) {
                          final isSelected = str == _selectedStrength;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedStrength = str);
                                  showGlowingToast(
                                    context,
                                    message: 'Sertlik seviyesi: $str',
                                    icon: Icons.grain_rounded,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryContainer
                                        : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      str,
                                      style: AppTypography.labelMedium.copyWith(
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Cup Size Row
                      Row(
                        children: [
                          const Icon(Icons.local_cafe_outlined, size: 20, color: AppColors.primaryContainer),
                          const SizedBox(width: 8),
                          Text(
                            'Fincan Boyutu',
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: _cupSizes.map((size) {
                          final isSelected = size == _selectedCupSize;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedCupSize = size);
                                  showGlowingToast(
                                    context,
                                    message: 'Boyut seçildi: $size',
                                    icon: Icons.local_cafe_rounded,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryContainer
                                        : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      size,
                                      style: AppTypography.caption.copyWith(
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 11,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
