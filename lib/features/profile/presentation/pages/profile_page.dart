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
import '../../../../core/widgets/glowing_toast.dart';
import '../../../../core/widgets/nestora_button.dart';
import '../../../../core/widgets/nestora_dialog.dart';
import '../../../../core/widgets/nestora_input.dart';
import '../../../../core/widgets/nestora_logo.dart';
import '../../../../core/widgets/nestora_snackbar.dart';
import '../../../../core/widgets/nestora_switch.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../devices/presentation/cubit/devices_cubit.dart';
import '../../../devices/presentation/cubit/devices_state.dart';
import '../../../notifications/domain/entities/app_notification.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../../notifications/presentation/cubit/notifications_state.dart';
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
      if (photoPath.startsWith('assets/')) {
        return AssetImage(photoPath);
      }
      final file = File(photoPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return const AssetImage('assets/profile/user_avatar.jpg');
  }

  void _showPhotoOptionsModal(BuildContext context, String? currentPhotoPath) {
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
                      'Profil Fotoğrafı Seç',
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
                      onTap: () async {
                        Navigator.pop(modalCtx);
                        await context.read<ProfileCubit>().pickAndSavePhoto(source: ImageSource.gallery);
                        if (context.mounted) {
                          showGlowingToast(
                            context,
                            message: 'Profil fotoğrafı güncellendi.',
                            icon: Icons.face_rounded,
                          );
                        }
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
                      subtitle: const Text('Yeni bir portre fotoğrafı çekin'),
                      onTap: () async {
                        Navigator.pop(modalCtx);
                        await context.read<ProfileCubit>().pickAndSavePhoto(source: ImageSource.camera);
                        if (context.mounted) {
                          showGlowingToast(
                            context,
                            message: 'Profil fotoğrafı güncellendi.',
                            icon: Icons.face_rounded,
                          );
                        }
                      },
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.face_retouching_natural_rounded, color: AppColors.primaryContainer),
                      ),
                      title: Text(
                        'Varsayılan Kadın Portresine Dön',
                        style: AppTypography.labelLarge.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text('Nestora şık kadın profil avatarı'),
                      onTap: () async {
                        Navigator.pop(modalCtx);
                        await context.read<ProfileCubit>().setPhotoPath('assets/profile/user_avatar.jpg');
                        if (context.mounted) {
                          showGlowingToast(
                            context,
                            message: 'Varsayılan kadın portresi uygulandı.',
                            icon: Icons.face_rounded,
                          );
                        }
                      },
                    ),
                    if (currentPhotoPath != null && currentPhotoPath.isNotEmpty) ...[
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
                          'Fotoğrafı Kaldır',
                          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('Profil resmini kaldırıp varsayılan görünüme dönün'),
                        onTap: () async {
                          Navigator.pop(modalCtx);
                          await context.read<ProfileCubit>().removePhoto();
                          if (context.mounted) {
                            showGlowingToast(
                              context,
                              message: 'Profil fotoğrafı kaldırıldı.',
                              icon: Icons.delete_sweep_rounded,
                            );
                          }
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

  void _showEditProfileDialog(
    BuildContext context,
    String currentName,
    String currentEmail,
    String currentRole,
    String currentHome,
  ) {
    final nameController = TextEditingController(text: currentName);
    final emailController = TextEditingController(text: currentEmail);
    final roleController = TextEditingController(text: currentRole.isNotEmpty ? currentRole : 'Ev Sahibi');
    final homeController = TextEditingController(text: currentHome);
    String? emailError;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.manage_accounts_rounded, color: AppColors.primaryContainer, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Profili Düzenle',
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kullanıcı Adı (Ad Soyad)', style: AppTypography.labelSmall),
                      const SizedBox(height: 6),
                      NestoraInput(
                        controller: nameController,
                        hintText: 'Adınız ve soyadınız',
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 14),
                      Text('E-posta Adresi', style: AppTypography.labelSmall),
                      const SizedBox(height: 6),
                      NestoraInput(
                        controller: emailController,
                        hintText: 'ornek@nestora.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (val) {
                          if (emailError != null) {
                            setDialogState(() => emailError = null);
                          }
                        },
                      ),
                      if (emailError != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          emailError!,
                          style: const TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text('Rol / Başlık', style: AppTypography.labelSmall),
                      const SizedBox(height: 6),
                      NestoraInput(
                        controller: roleController,
                        hintText: 'Örn: Ev Sahibi, Aile Bireyi, Yönetici',
                        prefixIcon: Icons.verified_user_outlined,
                      ),
                      const SizedBox(height: 14),
                      Text('Ev Adı', style: AppTypography.labelSmall),
                      const SizedBox(height: 6),
                      NestoraInput(
                        controller: homeController,
                        hintText: 'Örn: Aygen\'in Evi',
                        prefixIcon: Icons.cottage_rounded,
                      ),
                    ],
                  ),
                ),
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
                    final newEmail = emailController.text.trim();
                    final newRole = roleController.text.trim();
                    final newHome = homeController.text.trim();

                    if (newEmail.isNotEmpty && !newEmail.contains('@')) {
                      setDialogState(() => emailError = 'Lütfen geçerli bir e-posta adresi girin.');
                      return;
                    }

                    context.read<ProfileCubit>().updateProfileDetails(
                      displayName: newName.isNotEmpty ? newName : null,
                      email: newEmail.isNotEmpty ? newEmail : null,
                      roleTitle: newRole.isNotEmpty ? newRole : null,
                      homeName: newHome.isNotEmpty ? newHome : null,
                    );
                    Navigator.pop(dialogContext);
                    showGlowingToast(
                      context,
                      message: 'Profil başarıyla güncellendi.',
                      icon: Icons.check_circle_outline_rounded,
                    );
                  },
                ),
              ],
            );
          },
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
    final userRole = profileState is ProfileLoaded
        ? profileState.profile.roleTitle
        : SeedData.defaultProfile.roleTitle;
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

    int unreadNotificationCount = 0;
    try {
      final notificationsState = context.watch<NotificationsCubit>().state;
      if (notificationsState is NotificationsLoaded) {
        unreadNotificationCount = notificationsState.unreadCount;
      }
    } catch (_) {}

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightScaffold,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(76),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkCard : AppColors.lightScaffold).withValues(alpha: 0.95),
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
                      const NestoraLogo(size: 34, enableNavigation: true),
                      const SizedBox(width: 10),
                      Text(
                        'Profil',
                        style: AppTypography.cardTitle(
                          color: AppColors.primaryContainer,
                        ).copyWith(fontWeight: FontWeight.w800, fontSize: 20),
                      ),
                    ],
                  ),
                  Tooltip(
                    message: 'Bildirimler',
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        hoverColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppColors.primaryContainer.withValues(alpha: 0.08),
                        splashColor: AppColors.primaryContainer.withValues(alpha: 0.12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsPage()),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                Icons.notifications_none_rounded,
                                size: 24,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                              if (unreadNotificationCount > 0)
                                Positioned(
                                  right: -4,
                                  top: -3,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                    child: Text(
                                      unreadNotificationCount > 9 ? '9+' : '$unreadNotificationCount',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
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
                ],
              ),
            ),
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
                        key: const Key('profile_avatar_picker'),
                        onTap: () => _showPhotoOptionsModal(context, photoPath),
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

                      // Owner Role Badge (Ev Sahibi / Dinamik Rol)
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
                              userRole.isNotEmpty ? userRole : 'Ev Sahibi',
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
                            const Text('•', style: TextStyle(color: AppColors.secondary, fontSize: 11)),
                            const SizedBox(width: 6),
                            Text(
                              '$roomsCount Oda',
                              style: AppTypography.caption.copyWith(color: AppColors.secondary),
                            ),
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(color: AppColors.secondary, fontSize: 11)),
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
                        key: const Key('profile_edit_button'),
                        onPressed: () => _showEditProfileDialog(
                          context,
                          userName,
                          userEmail,
                          userRole,
                          homeName,
                        ),
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
                      onTap: () => _showEditProfileDialog(
                        context,
                        userName,
                        userEmail,
                        userRole,
                        homeName,
                      ),
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
                      onTap: () => _showEditProfileDialog(
                        context,
                        userName,
                        userEmail,
                        userRole,
                        homeName,
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
                          userRole.isNotEmpty ? '$userRole (Yönetici)' : 'Ev Sahibi (Yönetici)',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () => _showEditProfileDialog(
                        context,
                        userName,
                        userEmail,
                        userRole,
                        homeName,
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
                                  onTap: () {
                                    themeCubit.setTheme(ThemeMode.light);
                                    showGlowingToast(
                                      context,
                                      message: 'Aydınlık Mod etkinleştirildi.',
                                      icon: Icons.light_mode_rounded,
                                    );
                                  },
                                ),
                                _buildThemeOption(
                                  label: 'Koyu',
                                  mode: ThemeMode.dark,
                                  current: currentThemeMode,
                                  onTap: () {
                                    themeCubit.setTheme(ThemeMode.dark);
                                    showGlowingToast(
                                      context,
                                      message: 'Karanlık Mod etkinleştirildi.',
                                      icon: Icons.dark_mode_rounded,
                                    );
                                  },
                                ),
                                _buildThemeOption(
                                  label: 'Sistem',
                                  mode: ThemeMode.system,
                                  current: currentThemeMode,
                                  onTap: () {
                                    themeCubit.setTheme(ThemeMode.system);
                                    showGlowingToast(
                                      context,
                                      message: 'Sistem Teması etkinleştirildi.',
                                      icon: Icons.settings_brightness_rounded,
                                    );
                                  },
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
                                onChanged: (v) {
                                  setState(() => _deviceStatusNotif = v);
                                  showGlowingToast(
                                    context,
                                    message: v
                                        ? 'Cihaz durum bildirimleri açıldı.'
                                        : 'Cihaz durum bildirimleri kapatıldı.',
                                  );
                                },
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
                                onChanged: (v) {
                                  setState(() => _roomStatusNotif = v);
                                  showGlowingToast(
                                    context,
                                    message: v
                                        ? 'Oda güncelleme bildirimleri açıldı.'
                                        : 'Oda güncelleme bildirimleri kapatıldı.',
                                  );
                                },
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
                                key: const Key('profile_weekly_report_switch'),
                                value: _weeklyReportNotif,
                                onChanged: (v) {
                                  setState(() => _weeklyReportNotif = v);
                                  if (v) {
                                    final userId = (profileState is ProfileLoaded)
                                        ? profileState.profile.uid
                                        : 'demo-user';
                                    context.read<NotificationsCubit>().createNotification(
                                      userId: userId,
                                      title: 'Haftalık Enerji & Tüketim Raporu',
                                      message: 'Tebrikler! Bu hafta eviniz %14 daha az enerji tüketti. Detaylı analiz hazır.',
                                      type: NotificationType.eco,
                                    );
                                    showGlowingToast(
                                      context,
                                      message: 'Haftalık özet raporu etkinleştirildi. Yeni rapor bildiriminize eklendi.',
                                      icon: Icons.insights_rounded,
                                    );
                                  } else {
                                    showGlowingToast(
                                      context,
                                      message: 'Haftalık özet raporu bildirimleri kapatıldı.',
                                    );
                                  }
                                },
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
                                  onTap: () {
                                    context.read<ProfileCubit>().setTemperatureUnit('C');
                                    showGlowingToast(
                                      context,
                                      message: 'Sıcaklık birimi °C olarak güncellendi.',
                                      icon: Icons.thermostat_rounded,
                                    );
                                  },
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
                                  onTap: () {
                                    context.read<ProfileCubit>().setTemperatureUnit('F');
                                    showGlowingToast(
                                      context,
                                      message: 'Sıcaklık birimi °F olarak güncellendi.',
                                      icon: Icons.thermostat_rounded,
                                    );
                                  },
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
                            onChanged: (v) {
                              context.read<ProfileCubit>().toggleEcoMode(v);
                              showGlowingToast(
                                context,
                                message: v
                                    ? 'Eko Mod açıldı. Enerji tasarrufu devrede.'
                                    : 'Eko Mod kapatıldı.',
                                icon: Icons.eco_rounded,
                              );
                            },
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
                      onTap: () => _showAboutDialog(context, isDark),
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
                          'v2.4.0 (Build 2026.1)',
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

  void _showAboutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: NestoraLogo(size: 36, enableNavigation: false),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nestora',
                  style: AppTypography.pageTitle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ).copyWith(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sürdürülebilir Akıllı Yaşam Platformu',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nestora; enerji verimliliği, yüksek güvenlik ve doğal konforu '
                  'İskandinav ve modern kaşmir estetiğiyle harmanlayan '
                  'yeni nesil akıllı ev yönetim ekosistemidir.',
                  textAlign: TextAlign.center,
                  style: AppTypography.description(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.eco_rounded, size: 16, color: AppColors.primaryContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sürdürülebilirlik & Eko-Tasarruf Algoritmaları',
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.security_rounded, size: 16, color: AppColors.primaryContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sıfır Gecikmeli Güvenli Yerel Kontrol & Gizlilik',
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.palette_outlined, size: 16, color: AppColors.primaryContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Modern Kaşmir & Doğal Taş Mimari Estetiği',
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, size: 16, color: AppColors.primaryContainer),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Sürüm v2.4.0 (Build 2026.1) • Güncel',
                          style: AppTypography.badge(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ).copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('Kapat'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
