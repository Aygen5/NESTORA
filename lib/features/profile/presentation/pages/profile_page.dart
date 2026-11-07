import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/app_state.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/theme_cubit.dart';
import '../../../../core/widgets/nestora_switch.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final themeCubit = context.watch<ThemeCubit>();
    final currentThemeMode = themeCubit.state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightScaffold,
      appBar: AppBar(
        backgroundColor: (isDark ? AppColors.darkCard : AppColors.lightScaffold).withValues(alpha: 0.9),
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.eco_rounded, size: 24, color: AppColors.primaryContainer),
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
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.secondaryContainer,
                            width: 3,
                          ),
                          image: const DecorationImage(
                            image: AssetImage('assets/screens/nestora_profil_ve_ayarlar.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryContainer,
                          border: Border.all(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    appState.userName,
                    style: AppTypography.headlineMedium.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    appState.userEmail,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.secondary,
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
                        Icon(Icons.cottage_rounded, size: 16, color: AppColors.primaryContainer),
                        const SizedBox(width: 6),
                        Text(
                          appState.homeName,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('•', style: TextStyle(color: AppColors.secondary, fontSize: 10)),
                        const SizedBox(width: 6),
                        Text(
                          '${appState.rooms.length} Oda',
                          style: AppTypography.caption.copyWith(color: AppColors.secondary),
                        ),
                        const SizedBox(width: 6),
                        const Text('•', style: TextStyle(color: AppColors.secondary, fontSize: 10)),
                        const SizedBox(width: 6),
                        Text(
                          '${appState.devices.length} Cihaz',
                          style: AppTypography.caption.copyWith(color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Edit Profile Button
                  OutlinedButton.icon(
                    onPressed: () {},
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
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.secondary),
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
                        appState.userEmail,
                        style: AppTypography.caption.copyWith(color: AppColors.secondary),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.secondary),
                    ],
                  ),
                  isDark: isDark,
                ),
                const Divider(height: 1),
                _buildSettingsRow(
                  icon: Icons.lock_reset_rounded,
                  title: 'Şifre Değiştir',
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.secondary),
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
                // Theme selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.palette_rounded, size: 18, color: AppColors.primaryContainer),
                          const SizedBox(width: 8),
                          Text(
                            'Görünüm',
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
                          Icon(Icons.notifications_active_rounded, size: 18, color: AppColors.primaryContainer),
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

            // 5. Logout Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: widget.onLogout,
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
    required bool isDark,
  }) {
    return Padding(
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

