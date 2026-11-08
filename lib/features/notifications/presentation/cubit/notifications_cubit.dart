import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/spark_quota_service.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import 'notifications_state.dart';

/// Cubit managing in-app smart home notifications, real-time unread badges,
/// individual and bulk read confirmations, and deletions.
class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository notificationsRepository;
  final SparkQuotaService? quotaService;
  final LocalCacheService? localCacheService;

  StreamSubscription<List<AppNotification>>? _subscription;
  String? _currentUserId;

  NotificationsCubit({
    required this.notificationsRepository,
    this.quotaService,
    this.localCacheService,
  }) : super(
          NotificationsLoaded(
            notifications: localCacheService?.loadNotifications() ??
                List<AppNotification>.from(SeedData.defaultNotifications),
          ),
        );

  /// Loads and listens to real-time notification updates for [userId].
  void loadNotifications(String userId) {
    final cleanUid = userId.trim();
    if (cleanUid.isEmpty) {
      emit(const NotificationsError('Geçersiz kullanıcı kimliği.'));
      return;
    }
    _currentUserId = cleanUid;

    final cached = localCacheService?.loadNotifications();
    if (cached != null && cached.isNotEmpty) {
      emit(NotificationsLoaded(notifications: cached));
    } else if (state is! NotificationsLoaded) {
      emit(const NotificationsLoading());
    }

    _subscription?.cancel();
    quotaService?.registerListener('NotificationsCubit_$cleanUid');

    _subscription = notificationsRepository.watchNotifications(cleanUid).listen(
      (notifications) {
        localCacheService?.saveNotifications(notifications);
        if (state is NotificationsLoaded) {
          final current = state as NotificationsLoaded;
          emit(current.copyWith(
            notifications: notifications,
            isProcessing: false,
          ));
        } else {
          emit(NotificationsLoaded(notifications: notifications));
        }
      },
      onError: (error) {
        if (state is! NotificationsLoaded) {
          final fallback = localCacheService?.loadNotifications() ??
              List<AppNotification>.from(SeedData.defaultNotifications);
          emit(NotificationsLoaded(notifications: fallback));
        }
      },
    );
  }

  /// Marks a single notification as read with optimistic UI update.
  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    final cleanNotifId = notificationId.trim();
    if (state is! NotificationsLoaded || cleanNotifId.isEmpty) return;
    final current = state as NotificationsLoaded;
    final previousList = current.notifications;

    // Optimistic in-memory update
    final updatedList = current.notifications.map((n) {
      return n.id == cleanNotifId ? n.copyWith(isRead: true) : n;
    }).toList();

    await localCacheService?.saveNotifications(updatedList);
    emit(current.copyWith(notifications: updatedList));

    try {
      final result = await notificationsRepository.markAsRead(
        userId.trim(),
        cleanNotifId,
      );
      if (result.isFailure) {
        final msg = result.failureOrNull?.message ?? 'Güncellenemedi';
        emit(current.copyWith(
          notifications: previousList,
          errorMessage: msg.isNotEmpty ? msg : 'Güncellenemedi',
        ));
      }
    } catch (e) {
      final msg = e.toString().contains('Exception:')
          ? e.toString().replaceAll('Exception: ', '').trim()
          : 'Güncellenemedi';
      emit(current.copyWith(
        notifications: previousList,
        errorMessage: msg.isNotEmpty ? msg : 'Güncellenemedi',
      ));
    }
  }

  /// Marks all unread notifications as read atomically.
  Future<void> markAllAsRead({
    required String userId,
  }) async {
    if (state is! NotificationsLoaded) return;
    final current = state as NotificationsLoaded;

    if (current.unreadCount == 0) return;

    // Optimistic in-memory update
    final updatedList = current.notifications.map((n) {
      return n.isRead ? n : n.copyWith(isRead: true);
    }).toList();

    await localCacheService?.saveNotifications(updatedList);
    emit(current.copyWith(
      notifications: updatedList,
      isProcessing: false,
      feedbackMessage: 'Tüm bildirimler okundu olarak işaretlendi.',
    ));

    await notificationsRepository.markAllAsRead(userId.trim());
  }

  /// Deletes a specific notification with optimistic UI removal.
  Future<void> deleteNotification({
    required String userId,
    required String notificationId,
  }) async {
    final cleanNotifId = notificationId.trim();
    if (state is! NotificationsLoaded || cleanNotifId.isEmpty) return;
    final current = state as NotificationsLoaded;

    // Optimistic in-memory removal
    final updatedList = current.notifications
        .where((n) => n.id != cleanNotifId)
        .toList();

    await localCacheService?.saveNotifications(updatedList);
    emit(current.copyWith(
      notifications: updatedList,
      isProcessing: false,
      feedbackMessage: 'Bildirim silindi.',
    ));

    await notificationsRepository.deleteNotification(
      userId.trim(),
      cleanNotifId,
    );
  }

  /// Adds a local notification immediately and saves to cache.
  Future<void> addNotification(AppNotification notification) async {
    final current = state is NotificationsLoaded
        ? state as NotificationsLoaded
        : NotificationsLoaded(
            notifications: localCacheService?.loadNotifications() ??
                List<AppNotification>.from(SeedData.defaultNotifications),
          );

    final updatedList = [notification, ...current.notifications];
    await localCacheService?.saveNotifications(updatedList);
    emit(current.copyWith(notifications: updatedList));
  }

  /// Creates and dispatches a new in-app notification.
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    NotificationType type = NotificationType.device,
    String? relatedRoomId,
    String? relatedDeviceId,
  }) async {
    final cleanTitle = title.trim();
    final cleanMsg = message.trim();
    if (cleanTitle.isEmpty || cleanMsg.isEmpty) return;

    final notifId = 'notif-${DateTime.now().millisecondsSinceEpoch}';
    final newNotif = AppNotification(
      id: notifId,
      title: cleanTitle,
      message: cleanMsg,
      type: type,
      isRead: false,
      relatedRoomId: relatedRoomId?.trim(),
      relatedDeviceId: relatedDeviceId?.trim(),
      createdAt: DateTime.now(),
    );

    await addNotification(newNotif);
    if (state is NotificationsLoaded) {
      emit((state as NotificationsLoaded).copyWith(
        feedbackMessage: 'Bildirim oluşturuldu.',
      ));
    }

    try {
      await notificationsRepository.createNotification(
        userId.trim(),
        newNotif,
      );
    } catch (_) {}
  }

  /// Clears any transient feedback or error messages.
  void clearMessages() {
    if (state is NotificationsLoaded) {
      final current = state as NotificationsLoaded;
      emit(current.copyWith(clearFeedback: true, clearError: true));
    }
  }

  void _setProcessing(bool isProcessing) {
    if (state is NotificationsLoaded) {
      final current = state as NotificationsLoaded;
      emit(current.copyWith(
        isProcessing: isProcessing,
        clearFeedback: true,
        clearError: true,
      ));
    }
  }

  /// Currently active authenticated user ID.
  String? get currentUserId => _currentUserId;

  /// Convenience method for marking a notification as read.
  Future<void> markNotificationRead(String notificationId, {String? userId}) {
    return markAsRead(
      userId: userId ?? _currentUserId ?? 'demo-user',
      notificationId: notificationId,
    );
  }

  /// Convenience method for marking all notifications as read.
  Future<void> markAllNotificationsRead({String? userId}) {
    return markAllAsRead(
      userId: userId ?? _currentUserId ?? 'demo-user',
    );
  }

  /// Convenience method for deleting a notification.
  Future<void> deleteNotificationById(String notificationId, {String? userId}) {
    return deleteNotification(
      userId: userId ?? _currentUserId ?? 'demo-user',
      notificationId: notificationId,
    );
  }

  /// Convenience method for clearing all notifications.
  Future<void> clearAllNotifications({String? userId}) async {
    if (state is! NotificationsLoaded) return;
    final current = state as NotificationsLoaded;
    if (current.notifications.isEmpty) return;

    _setProcessing(true);
    final user = userId ?? _currentUserId ?? 'demo-user';
    final notifsToDelete = List<AppNotification>.from(current.notifications);

    await localCacheService?.saveNotifications(const []);
    emit(current.copyWith(notifications: const [], isProcessing: true));

    for (final notif in notifsToDelete) {
      await notificationsRepository.deleteNotification(user, notif.id);
    }

    emit(const NotificationsLoaded(
      notifications: [],
      isProcessing: false,
      feedbackMessage: 'Tüm bildirimler temizlendi.',
    ));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    if (_currentUserId != null) {
      quotaService?.unregisterListener('NotificationsCubit_$_currentUserId');
    }
    return super.close();
  }
}

