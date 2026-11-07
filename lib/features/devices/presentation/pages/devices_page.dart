import 'package:flutter/material.dart';
import '../../../../app/app_state.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/nestora_logo.dart';
import '../../../../core/widgets/nestora_switch.dart';
import '../../domain/device_model.dart';
import 'ac_control_page.dart';
import 'add_edit_device_page.dart';
import 'lamp_control_page.dart';

enum DeviceFilter { all, active, inactive, favorites }

class DevicesPage extends StatefulWidget {
  final VoidCallback? onNavigateToProfile;

  const DevicesPage({super.key, this.onNavigateToProfile});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  DeviceFilter _currentFilter = DeviceFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalCount = appState.devices.length;
    final activeCount = appState.devices.where((d) => d.isPoweredOn).length;
    final inactiveCount = totalCount - activeCount;
    final favCount = appState.devices.where((d) => d.isFavorite).length;

    // Filter devices
    List<DeviceModel> filteredDevices = appState.devices.where((d) {
      if (_searchQuery.isNotEmpty) {
        final matchesQuery = d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            d.room.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchesQuery) return false;
      }

      switch (_currentFilter) {
        case DeviceFilter.all:
          return true;
        case DeviceFilter.active:
          return d.isPoweredOn;
        case DeviceFilter.inactive:
          return !d.isPoweredOn;
        case DeviceFilter.favorites:
          return d.isFavorite;
      }
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightScaffold,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkCard : AppColors.lightScaffold).withValues(alpha: 0.9),
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const NestoraLogo(size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Nestora',
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.primaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cihazlar',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: widget.onNavigateToProfile,
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
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Title & Live Sync Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cihazlarım',
                      style: AppTypography.headlineLarge.copyWith(
                        color: AppColors.primaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Evindeki cihazları kolayca yönet.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
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
                        'Canlı Senkron',
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
            const SizedBox(height: 16),

            // Search Bar & Add Device Button
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, size: 20, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() => _searchQuery = val);
                            },
                            decoration: InputDecoration(
                              hintText: 'Cihaz ara...',
                              hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.secondary),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.secondary),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddEditDevicePage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Cihaz Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Summary Status Insight Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.tune_rounded, size: 20, color: AppColors.primaryContainer),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Durum Özeti',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text('$totalCount cihaz', style: AppTypography.caption.copyWith(color: AppColors.secondary)),
                              const SizedBox(width: 4),
                              const Text('•', style: TextStyle(color: AppColors.secondary, fontSize: 10)),
                              const SizedBox(width: 4),
                              Text('$activeCount açık', style: AppTypography.caption.copyWith(color: AppColors.primaryContainer, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              const Text('•', style: TextStyle(color: AppColors.secondary, fontSize: 10)),
                              const SizedBox(width: 4),
                              Text('$inactiveCount kapalı', style: AppTypography.caption.copyWith(color: AppColors.secondary)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.eco_rounded, size: 16, color: AppColors.warmAmber),
                        const SizedBox(width: 4),
                        Text(
                          '%18 Tasarruf',
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
            ),
            const SizedBox(height: 16),

            // Horizontal Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterTab(
                    label: 'Tümü ($totalCount)',
                    isSelected: _currentFilter == DeviceFilter.all,
                    onTap: () => setState(() => _currentFilter = DeviceFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterTab(
                    label: 'Açık ($activeCount)',
                    isSelected: _currentFilter == DeviceFilter.active,
                    onTap: () => setState(() => _currentFilter = DeviceFilter.active),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterTab(
                    label: 'Kapalı ($inactiveCount)',
                    isSelected: _currentFilter == DeviceFilter.inactive,
                    onTap: () => setState(() => _currentFilter = DeviceFilter.inactive),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterTab(
                    label: 'Favoriler ($favCount)',
                    icon: Icons.star_rounded,
                    isSelected: _currentFilter == DeviceFilter.favorites,
                    onTap: () => setState(() => _currentFilter = DeviceFilter.favorites),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Devices Grid (Responsive Layout)
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 580 ? 3 : 2;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: filteredDevices.length,
                  itemBuilder: (context, index) {
                    final device = filteredDevices[index];
                    return _buildDeviceCard(context, appState, device, isDark);
                  },
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  ),
);
}

  Widget _buildFilterTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer
              : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.warmAmber,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    AppState appState,
    DeviceModel device,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        if (device.name == 'Salon Lambası') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LampControlPage()),
          );
        } else if (device.type == DeviceType.ac) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AcControlPage()),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Icon + Star + Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: device.isPoweredOn
                        ? AppColors.warmAmber.withValues(alpha: 0.3)
                        : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    device.icon,
                    size: 20,
                    color: device.isPoweredOn ? AppColors.primaryContainer : AppColors.secondary,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => appState.toggleFavorite(device.id),
                      child: Icon(
                        device.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 20,
                        color: device.isFavorite ? AppColors.warmAmber : AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    NestoraSwitch(
                      value: device.isPoweredOn,
                      onChanged: (_) => appState.toggleDevicePower(device.id),
                    ),
                  ],
                ),
              ],
            ),

            // Bottom info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${device.room.toUpperCase()} • ${device.type.name.toUpperCase()}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.secondary,
                    letterSpacing: 0.8,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  device.name,
                  style: AppTypography.headlineSmall.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: device.isPoweredOn ? AppColors.primaryContainer : AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          device.isPoweredOn
                              ? (device.type == DeviceType.bulb ? 'Açık (%${device.brightness})' : (device.type == DeviceType.ac ? 'Açık (${device.targetTemp}°C)' : 'Açık'))
                              : 'Kapalı',
                          style: AppTypography.caption.copyWith(
                            color: device.isPoweredOn ? AppColors.primaryContainer : AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      device.type == DeviceType.bulb
                          ? '280 lm'
                          : (device.type == DeviceType.plug ? '142 W' : ''),
                      style: AppTypography.caption.copyWith(color: AppColors.secondary, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
