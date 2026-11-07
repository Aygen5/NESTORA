import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/theme_cubit.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../../core/widgets/nestora_button.dart';
import '../../../../core/widgets/nestora_dialog.dart';
import '../../../../core/widgets/nestora_input.dart';
import '../../../../core/widgets/nestora_snackbar.dart';
import '../../../../core/widgets/nestora_switch.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../devices/presentation/cubit/devices_cubit.dart';
import '../../../devices/presentation/cubit/devices_state.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../rooms/presentation/cubit/rooms_cubit.dart';
import '../../../rooms/presentation/cubit/rooms_state.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

/// Screen managing user profile information, role status (Ev Sahibi), local avatar selection,
/// persisted ThemeMode preferences (Açık, Koyu, Sistem), and secure logout confirmation.
class ProfilePage extends StatefulWidget {
  final VoidCallback? onLogout;

  const ProfilePage({super.key, this.onLogout});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _deviceStatusNotif = true;
  bool _roomStatusNotif = true;
  bool _weeklyReportNotif = false;

  ImageProvider _resolveAvatarImage(String? photoPath) {
    if (photoPath != null && photoPath.isNotEmpty) {
      final file = File(photoPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return const AssetImage('assets/screens/nestora_profil_ve_ayarlar.png');
  }

  void _pickPhoto(BuildContext context) async {
    await context.read<ProfileCubit>().pickAndSavePhoto(source: ImageSource.gallery);
    if (context.mounted) {
      showNestoraSnackbar(context, message: 'Profil fotoğrafı güncellendi.');
    }
  }

  void _showEditProfileDialog(BuildContext context, String currentName, String currentHome) {
    final nameController = TextEditingController(text: currentName);
    final homeController = TextEditingController(text: currentHome);

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Profili Düzenle',
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kullanıcı Adı', style: AppTypography.labelSmall),
              const SizedBox(height: 6),
              NestoraInput(
                controller: nameController,
                hintText: 'Adınız ve soyadınız',
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),
              Text('Ev Adı', style: AppTypography.labelSmall),
              const SizedBox(height: 6),
              NestoraInput(
                controller: homeController,
                hintText: 'Örn: Doğa Evi',
                prefixIcon: Icons.cottage_rounded,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('İptal'),
            ),
            NestoraButton(
              text: 'Kaydet',
              onPressed: () {
                final newName = nameController.text.trim();
                final newHome = homeController.text.trim();
                if (newName.isNotEmpty) {
                  context.read<ProfileCubit>().updateDisplayName(newName);
                }
                if (newHome.isNotEmpty) {
                  context.read<ProfileCubit>().updateHomeName(newHome);
                }
                Navigator.pop(dialogContext);
                showNestoraSnackbar(context, message: 'Profil başarıyla güncellendi.');
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showNestoraDeleteDialog(
      context: context,
      title: 'Oturumu Kapat',
      message: 'Hesabınızdan çıkış yapmak istediğinize emin misiniz? Güvenli bir şekilde oturum sonlandırılacaktır.',
      deleteButtonText: 'Çıkış Yap',
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<AuthCubit>().signOut();
      } catch (_) {}

      if (!context.mounted) return;

      if (widget.onLogout != null) {
        widget.onLogout!();
      } else {
        context.go(AppRoutePaths.welcome);
      }

      showNestoraSnackbar(context, message: 'Oturum kapatıldı.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileCubit>().state;
    final roomsState = context.watch<RoomsCubit>().state;
    final devicesState = context.watch<DevicesCubit>().state;
    final themeCubit = context.watch<ThemeCubit>();
    final currentThemeMode = themeCubit.state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userName = profileState is ProfileLoaded
        ? profileState.profile.displayName
        : SeedData.defaultProfile.displayName;
    final userEmail = profileState is ProfileLoaded
        ? profileState.profile.email
        : SeedData.defaultProfile.email;
    final homeName = profileState is ProfileLoaded
        ? profileState.profile.homeName
        : SeedData.defaultProfile.homeName;
    final photoPath = profileState is ProfileLoaded ? profileState.profile.photoPath : null;

    final roomsCount = roomsState is RoomsLoaded
        ? roomsState.rooms.length
        : SeedData.defaultRooms.length;
    final devicesCount = devicesState is DevicesLoaded
        ? devicesState.devices.length
        : SeedData.defaultDevices.length;

    final currentUnit = profileState is ProfileLoaded
        ? profileState.profile.preferences.temperatureUnit
        : 'C';
    final ecoModeActive = profileState is ProfileLoaded
        ? profileState.profile.preferences.ecoModeEnabled
        : true;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightScaffold,
      appBar: AppBar(
        backgroundColor: (isDark ? AppColors.darkCard : AppColors.lightScaffold).withValues(alpha: 0.9),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.eco_rounded, size: 24, color: AppColors.primaryContainer),
            const SizedBox(width: 8),
            Text(
              'Profil',
              style: AppTypography.headlineSmall.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            },
          ),
          const SizedBox(width: 8),
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
                // 1. Profile Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      // Avatar with Gallery Photo Picker Trigger
                      GestureDetector(
                        onTap: () => _pickPhoto(context),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.secondaryContainer,
                                  width: 3,
                                ),
                                image: DecorationImage(
                                  image: _resolveAvatarImage(photoPath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryContainer,
                                border: Border.all(
                                  color: isDark ? AppColors.darkCard : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // User Display Name
                      Text(
                        userName,
                        style: AppTypography.headlineMedium.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // User Email
                      Text(
                        userEmail,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Owner Role Badge (Ev Sahibi)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 14, color: AppColors.primaryContainer),
                            const SizedBox(width: 4),
                            Text(
                              'Ev Sahibi',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Mini Summary Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cottage_rounded, size: 16, color: AppColors.primaryContainer),
                            const SizedBox(width: 6),
                            Text(
                              homeName,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(color: AppColors.secondary, fontSize: 10)),
                            const SizedBox(width: 6),
                            Text(
                              '$roomsCount Oda',
                              style: AppTypography.caption.copyWith(color: AppColors.secondary),
                            ),
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(color: AppColors.secondary, fontSize: 10)),
                            const SizedBox(width: 6),
                            Text(
                              '$devicesCount Cihaz',
                              style: AppTypography.caption.copyWith(color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Edit Profile Button
                      OutlinedButton.icon(
                        onPressed: () => _showEditProfileDialog(context, userName, homeName),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Profili Düzenle'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryContainer,
                          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Account Group Card
                _buildGroupCard(
                  context: context,
                  title: 'HESAP',
                  icon: Icons.badge_outlined,
                  isDark: isDark,
                  children: [
                    _buildSettingsRow(
                      icon: Icons.person_outline_rounded,
                      title: 'Profil Bilgilerim',
                      subtitle: userName,
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.secondary),
                      onTap: () => _showEditProfileDialog(context, userName, homeName),
                      isDark: isDark,
                    ),
                    const Divider(height: 1),
                    _buildSettingsRow(
                      icon: Icons.mail_outline_rounded,
                      title: 'E-posta Adresim',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userEmail,
                            style: AppTypography.caption.copyWith(color: AppColors.secondary),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.primaryContainer),
                        ],
                      ),
                      isDark: isDark,
                    ),
                    const Divider(height: 1),
                    _buildSettingsRow(
                      icon: Icons.verified_user_outlined,
                      title: 'Kullanıcı Rolü',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Ev Sahibi (Yönetici)',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 3. App Settings Group Card
                _buildGroupCard(
                  context: context,
                  title: 'UYGULAMA AYARLARI',
                  icon: Icons.tune_rounded,
                  isDark: isDark,
                  children: [
                    // Theme Mode Selector (Açık, Koyu, Sistem)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.palette_rounded, size: 18, color: AppColors.primaryContainer),
                              const SizedBox(width: 8),
                              Text(
                                'Görünüm Modu',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                _buildThemeOption(
                                  label: 'Açık',
                                  mode: ThemeMode.light,
                                  current: currentThemeMode,
                                  onTap: () => themeCubit.setTheme(ThemeMode.light),
                                ),
                                _buildThemeOption(
                                  label: 'Koyu',
                                  mode: ThemeMode.dark,
                                  current: currentThemeMode,
                                  onTap: () => themeCubit.setTheme(ThemeMode.dark),
                                ),
                                _buildThemeOption(
                                  label: 'Sistem',
                                  mode: ThemeMode.system,
                                  current: currentThemeMode,
                                  onTap: () => themeCubit.setTheme(ThemeMode.system),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Notification Preferences
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.notifications_active_rounded, size: 18, color: AppColors.primaryContainer),
                              const SizedBox(width: 8),
                              Text(
                                'Bildirim Tercihleri',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Cihaz Durum Bildirimleri', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                    Text('Kritik cihaz uyarıları ve bağlantı bilgisi', style: AppTypography.caption.copyWith(color: AppColors.secondary)),
                                  ],
                                ),
                              ),
                              NestoraSwitch(
                                value: _deviceStatusNotif,
                                onChanged: (v) => setState(() => _deviceStatusNotif = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Oda Güncelleme Bildirimleri', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                    Text('Sıcaklık ve hava kalitesi değişimleri', style: AppTypography.caption.copyWith(color: AppColors.secondary)),
                                  ],
                                ),
                              ),
                              NestoraSwitch(
                                value: _roomStatusNotif,
                                onChanged: (v) => setState(() => _roomStatusNotif = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Haftalık Özet Raporu', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                    Text('Enerji tasarrufu ve tüketim analizleri', style: AppTypography.caption.copyWith(color: AppColors.secondary)),
                                  ],
                                ),
                              ),
                              NestoraSwitch(
                                value: _weeklyReportNotif,
                                onChanged: (v) => setState(() => _weeklyReportNotif = v),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Temperature Unit Preference
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.thermostat_rounded, size: 18, color: AppColors.primaryContainer),
                              const SizedBox(width: 8),
                              Text(
                                'Sıcaklık Birimi',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => context.read<ProfileCubit>().setTemperatureUnit('C'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: currentUnit == 'C' ? AppColors.primaryContainer : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '°C',
                                      style: TextStyle(
                                        color: currentUnit == 'C' ? Colors.white : AppColors.secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.read<ProfileCubit>().setTemperatureUnit('F'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: currentUnit == 'F' ? AppColors.primaryContainer : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '°F',
                                      style: TextStyle(
                                        color: currentUnit == 'F' ? Colors.white : AppColors.secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Eco Mode Preference
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.energy_savings_leaf_rounded, size: 18, color: AppColors.primaryContainer),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Eko Modu (Tasarruf)',
                                        style: AppTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Akıllı ev simülasyonunda enerji tüketimini optimize eder',
                                        style: AppTypography.caption.copyWith(color: AppColors.secondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          NestoraSwitch(
                            value: ecoModeActive,
                            onChanged: (v) => context.read<ProfileCubit>().toggleEcoMode(v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 4. About Group Card
                _buildGroupCard(
                  context: context,
                  title: 'HAKKINDA',
                  icon: Icons.info_outline_rounded,
                  isDark: isDark,
                  children: [
                    _buildSettingsRow(
                      icon: Icons.eco_rounded,
                      title: 'Hakkında',
                      subtitle: 'Sürdürülebilir Akıllı Yaşam',
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.secondary),
                      isDark: isDark,
                    ),
                    const Divider(height: 1),
                    _buildSettingsRow(
                      icon: Icons.terminal_rounded,
                      title: 'Uygulama Sürümü',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'v1.0.0 Güncel',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. Logout Button with Confirmation Dialog
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Çıkış Yap'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error.withValues(alpha: 0.12),
                      foregroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
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

  Widget _buildGroupCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                Icon(icon, size: 16, color: AppColors.secondary),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: AppColors.primaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: AppTypography.caption.copyWith(color: AppColors.secondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required ThemeMode mode,
    required ThemeMode current,
    required VoidCallback onTap,
  }) {
    final isSelected = mode == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.secondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
