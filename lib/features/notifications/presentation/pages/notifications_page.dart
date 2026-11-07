import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../../core/widgets/nestora_dialog.dart';
import '../../../../core/widgets/nestora_snackbar.dart';
import '../../domain/notification_model.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';

/// Screen displaying in-app smart home notifications grouped by date (Bugün, Dün, Geçen Hafta),
/// with unread status tracking, smart navigation to related devices/rooms, and deletion controls.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  void _onNotificationTap(BuildContext context, NotificationModel notif) {
    // 1. Mark notification as read
    context.read<NotificationsCubit>().markNotificationRead(notif.id);

    // 2. Smart Navigation based on target entity
    final titleLower = notif.title.toLowerCase();
    final descLower = notif.description.toLowerCase();

    if (notif.relatedDeviceId != null && notif.relatedDeviceId!.isNotEmpty) {
      final devId = notif.relatedDeviceId!;
      if (devId == 'dev-5' || titleLower.contains('klima') || descLower.contains('klima') || titleLower.contains('sıcaklık')) {
        context.goToClimateControl(devId);
        return;
      } else if (titleLower.contains('lamba') || descLower.contains('lamba') || descLower.contains('parlaklık')) {
        context.goToLampControl(devId);
        return;
      } else {
        context.go(AppRoutePaths.devices);
        return;
      }
    }

    if (notif.relatedRoomId != null && notif.relatedRoomId!.isNotEmpty) {
      context.goToRoomDetail(notif.relatedRoomId!);
      return;
    }

    // Keyword Fallbacks
    if (titleLower.contains('klima') || descLower.contains('klima')) {
      context.goToClimateControl('dev-5');
    } else if (titleLower.contains('lamba') || descLower.contains('lamba')) {
      context.goToLampControl('dev-1');
    } else if (titleLower.contains('oda') || descLower.contains('oda')) {
      context.goToRooms();
    } else {
      context.go(AppRoutePaths.dashboard);
    }
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showNestoraDeleteDialog(
      context: context,
      title: 'Tüm Bildirimler Silinecek',
      message: 'Tüm bildirimleriniz kalıcı olarak temizlenecektir. Devam etmek istiyor musunuz?',
      deleteButtonText: 'Tümünü Temizle',
    );

    if (confirmed == true && context.mounted) {
      await context.read<NotificationsCubit>().clearAllNotifications();
      if (context.mounted) {
        showNestoraSnackbar(context, message: 'Tüm bildirimler temizlendi.');
      }
    }
  }

  int _dateDiffInDays(DateTime? date) {
    if (date == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return today.difference(target).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final notificationsCubit = context.watch<NotificationsCubit>();
    final notificationsState = notificationsCubit.state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<NotificationModel> notifications = (notificationsState is NotificationsLoaded)
        ? notificationsState.notifications.map(SeedData.notificationToModel).toList()
        : SeedData.defaultNotificationModels;

    final unreadCount = (notificationsState is NotificationsLoaded)
        ? notificationsState.unreadCount
        : notifications.where((n) => n.isUnread).length;

    // Date Grouping: Bugün, Dün, Geçen Hafta
    final todayNotifications = notifications.where((n) => _dateDiffInDays(n.createdAt) == 0).toList();
    final yesterdayNotifications = notifications.where((n) => _dateDiffInDays(n.createdAt) == 1).toList();
    final lastWeekNotifications = notifications.where((n) => _dateDiffInDays(n.createdAt) > 1).toList();

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
          'Bildirimler',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, size: 22),
              tooltip: 'Tümünü Temizle',
              onPressed: () => _confirmClearAll(context),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => context.go(AppRoutePaths.profile),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Status & Bulk Action Bar
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (unreadCount > 0) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryContainer,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            unreadCount > 0
                                ? '$unreadCount Okunmamış Bildirim'
                                : 'Tüm Bildirimler Okundu',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: unreadCount > 0
                          ? () {
                              context.read<NotificationsCubit>().markAllNotificationsRead();
                              showNestoraSnackbar(
                                context,
                                message: 'Tüm bildirimler okundu olarak işaretlendi.',
                              );
                            }
                          : null,
                      child: Text(
                        'Tümünü Okundu İşaretle',
                        style: AppTypography.labelMedium.copyWith(
                          color: unreadCount > 0 ? AppColors.primaryContainer : AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Notification List or Empty State
                if (notifications.isEmpty) ...[
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            size: 32,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz bildirimin yok.',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Evinizde cihaz veya oda etkileşimi gerçekleştirdiğinizde bildirimler burada listelenir.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ] else ...[
                  // Date Group A: Bugün
                  if (todayNotifications.isNotEmpty) ...[
                    _buildGroupHeader('Bugün', todayNotifications.length, isDark),
                    const SizedBox(height: 10),
                    ...todayNotifications.map((notif) => _buildNotificationCard(context, notif, isDark)),
                    const SizedBox(height: 16),
                  ],

                  // Date Group B: Dün
                  if (yesterdayNotifications.isNotEmpty) ...[
                    _buildGroupHeader('Dün', yesterdayNotifications.length, isDark),
                    const SizedBox(height: 10),
                    ...yesterdayNotifications.map((notif) => _buildNotificationCard(context, notif, isDark)),
                    const SizedBox(height: 16),
                  ],

                  // Date Group C: Geçen Hafta
                  if (lastWeekNotifications.isNotEmpty) ...[
                    _buildGroupHeader('Geçen Hafta', lastWeekNotifications.length, isDark),
                    const SizedBox(height: 10),
                    ...lastWeekNotifications.map((notif) => _buildNotificationCard(context, notif, isDark)),
                    const SizedBox(height: 16),
                  ],
                ],

                // 3. Ambient Nature & Energy Insight Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.eco_rounded, size: 20, color: AppColors.primaryContainer),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Doğal Yaşam Ritmi',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tüm sanal aygıtlar sessiz ve dengeli modda çalışıyor.',
                              style: AppTypography.caption.copyWith(color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ),
                    ],
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

  Widget _buildGroupHeader(String title, int count, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTypography.caption.copyWith(
            color: AppColors.primaryContainer,
            letterSpacing: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count Bildirim',
            style: AppTypography.caption.copyWith(color: AppColors.secondary),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notif,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(notif.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
              SizedBox(width: 6),
              Text(
                'Sil',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        onDismissed: (_) {
          context.read<NotificationsCubit>().deleteNotificationById(notif.id);
          showNestoraSnackbar(context, message: 'Bildirim silindi.');
        },
        child: GestureDetector(
          onTap: () => _onNotificationTap(context, notif),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: notif.isUnread
                  ? (isDark ? AppColors.darkCard : AppColors.lightCard)
                  : (isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: notif.isUnread
                    ? AppColors.primaryContainer.withValues(alpha: 0.3)
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              boxShadow: notif.isUnread ? AppColors.cardShadow : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: notif.iconBg ?? AppColors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notif.icon,
                    size: 20,
                    color: AppColors.primaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: AppTypography.headlineSmall.copyWith(
                                fontSize: 15,
                                fontWeight: notif.isUnread ? FontWeight.bold : FontWeight.w600,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          if (notif.isUnread) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryContainer,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.description,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 12, color: AppColors.secondary),
                              const SizedBox(width: 4),
                              Text(
                                notif.timeAgo,
                                style: AppTypography.caption.copyWith(color: AppColors.secondary),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              context.read<NotificationsCubit>().deleteNotificationById(notif.id);
                              showNestoraSnackbar(context, message: 'Bildirim silindi.');
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppColors.secondary,
                              ),
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
        ),
      ),
    );
  }
}
