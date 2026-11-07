import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import 'notifications_state.dart';

/// Cubit managing in-app smart home notifications, real-time unread badges,
/// individual and bulk read confirmations, and deletions.
class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository notificationsRepository;

  StreamSubscription<List<AppNotification>>? _subscription;

  NotificationsCubit({
    required this.notificationsRepository,
  }) : super(const NotificationsInitial());

  /// Loads and listens to real-time notification updates for [userId].
  void loadNotifications(String userId) {
    final cleanUid = userId.trim();
    if (cleanUid.isEmpty) {
      emit(const NotificationsError('Geçersiz kullanıcı kimliği.'));
      return;
    }

    if (state is! NotificationsLoaded) {
      emit(const NotificationsLoading());
    }

    _subscription?.cancel();

    _subscription = notificationsRepository.watchNotifications(cleanUid).listen(
      (notifications) {
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
        emit(NotificationsError('Bildirimler dinlenirken hata: $error'));
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

    // Optimistic in-memory update
    final updatedList = current.notifications.map((n) {
      return n.id == cleanNotifId ? n.copyWith(isRead: true) : n;
    }).toList();

    emit(current.copyWith(notifications: updatedList));

    final result = await notificationsRepository.markAsRead(
      userId.trim(),
      cleanNotifId,
    );

    if (result.isFailure) {
      // Revert if failed
      emit(current.copyWith(
        notifications: current.notifications,
        errorMessage: result.failure.message,
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

    _setProcessing(true);

    // Optimistic in-memory update
    final updatedList = current.notifications.map((n) {
      return n.isRead ? n : n.copyWith(isRead: true);
    }).toList();

    emit(current.copyWith(notifications: updatedList, isProcessing: true));

    final result = await notificationsRepository.markAllAsRead(userId.trim());

    if (result.isSuccess) {
      emit(current.copyWith(
        notifications: updatedList,
        isProcessing: false,
        feedbackMessage: 'Tüm bildirimler okundu olarak işaretlendi.',
      ));
    } else {
      emit(current.copyWith(
        notifications: current.notifications,
        isProcessing: false,
        errorMessage: result.failure.message,
      ));
    }
  }

  /// Deletes a specific notification with optimistic UI removal.
  Future<void> deleteNotification({
    required String userId,
    required String notificationId,
  }) async {
    final cleanNotifId = notificationId.trim();
    if (state is! NotificationsLoaded || cleanNotifId.isEmpty) return;
    final current = state as NotificationsLoaded;

    _setProcessing(true);

    // Optimistic in-memory removal
    final updatedList = current.notifications
        .where((n) => n.id != cleanNotifId)
        .toList();

    emit(current.copyWith(notifications: updatedList, isProcessing: true));

    final result = await notificationsRepository.deleteNotification(
      userId.trim(),
      cleanNotifId,
    );

    if (result.isSuccess) {
      emit(current.copyWith(
        notifications: updatedList,
        isProcessing: false,
        feedbackMessage: 'Bildirim silindi.',
      ));
    } else {
      emit(current.copyWith(
        notifications: current.notifications,
        isProcessing: false,
        errorMessage: result.failure.message,
      ));
    }
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

    _setProcessing(true);

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

    final result = await notificationsRepository.createNotification(
      userId.trim(),
      newNotif,
    );

    if (result.isSuccess) {
      _emitSuccess('Bildirim oluşturuldu.');
    } else {
      _emitError(result.failure.message);
    }
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

  void _emitSuccess(String message) {
    if (state is NotificationsLoaded) {
      final current = state as NotificationsLoaded;
      emit(current.copyWith(
        isProcessing: false,
        feedbackMessage: message,
      ));
    }
  }

  void _emitError(String message) {
    if (state is NotificationsLoaded) {
      final current = state as NotificationsLoaded;
      emit(current.copyWith(
        isProcessing: false,
        errorMessage: message,
      ));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
