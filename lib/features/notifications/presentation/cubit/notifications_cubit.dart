import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/spark_quota_service.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../domain/usecases/notifications_usecases.dart';
import 'notifications_state.dart';

// Akıllı ev bildirimlerini, okunma durumunu ve gerçek zamanlı bildirim sayısını yönetir.
class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository notificationsRepository;
  final SparkQuotaService? quotaService;
  final LocalCacheService? localCacheService;

  // İş mantığı kullanım senaryoları (Use Cases)
  final GetNotificationsUseCase getNotificationsUseCase;
  final WatchNotificationsUseCase watchNotificationsUseCase;
  final MarkNotificationReadUseCase markNotificationReadUseCase;
  final MarkAllNotificationsReadUseCase markAllNotificationsReadUseCase;
  final DeleteNotificationUseCase deleteNotificationUseCase;
  final CreateNotificationUseCase createNotificationUseCase;

  StreamSubscription<List<AppNotification>>? _subscription;
  String? _currentUserId;

  NotificationsCubit({
    required this.notificationsRepository,
    this.quotaService,
    this.localCacheService,
    GetNotificationsUseCase? getNotificationsUseCase,
    WatchNotificationsUseCase? watchNotificationsUseCase,
    MarkNotificationReadUseCase? markNotificationReadUseCase,
    MarkAllNotificationsReadUseCase? markAllNotificationsReadUseCase,
    DeleteNotificationUseCase? deleteNotificationUseCase,
    CreateNotificationUseCase? createNotificationUseCase,
  })  : getNotificationsUseCase = getNotificationsUseCase ?? GetNotificationsUseCase(notificationsRepository),
        watchNotificationsUseCase = watchNotificationsUseCase ?? WatchNotificationsUseCase(notificationsRepository),
        markNotificationReadUseCase = markNotificationReadUseCase ?? MarkNotificationReadUseCase(notificationsRepository),
        markAllNotificationsReadUseCase = markAllNotificationsReadUseCase ?? MarkAllNotificationsReadUseCase(notificationsRepository),
        deleteNotificationUseCase = deleteNotificationUseCase ?? DeleteNotificationUseCase(notificationsRepository),
        createNotificationUseCase = createNotificationUseCase ?? CreateNotificationUseCase(notificationsRepository),
        super(
          NotificationsLoaded(
            notifications: localCacheService?.loadNotifications() ??
                List<AppNotification>.from(SeedData.defaultNotifications),
          ),
        );

  // Çıkış yapıldığında bildirim durumunu sıfırlar ve akış aboneliğini sonlandırır.
  void reset() {
    _subscription?.cancel();
    _currentUserId = null;
    emit(const NotificationsLoaded(notifications: []));
  }

  // Kullanıcıya ait bildirimleri gerçek zamanlı dinler ve yükler.
  void loadNotifications(String userId) {
    final cleanUid = userId.trim();
    if (cleanUid.isEmpty) {
      emit(const NotificationsError('Geçersiz kullanıcı kimliği.'));
      return;
    }
    _currentUserId = cleanUid;

    final cached = localCacheService?.loadNotifications(userId: cleanUid);
    final initialNotifs = (cached != null && cached.isNotEmpty)
        ? cached
        : (cleanUid == SeedData.defaultProfile.uid
            ? List<AppNotification>.from(SeedData.defaultNotifications)
            : <AppNotification>[]);
    emit(NotificationsLoaded(notifications: initialNotifs));

    _subscription?.cancel();
    quotaService?.registerListener('NotificationsCubit_$cleanUid');

    _subscription = watchNotificationsUseCase(cleanUid).listen(
      (notifications) {
        final effective = (notifications.isEmpty && cleanUid == SeedData.defaultProfile.uid)
            ? (localCacheService?.loadNotifications(userId: cleanUid) ??
                List<AppNotification>.from(SeedData.defaultNotifications))
            : notifications;

        localCacheService?.saveNotifications(effective, userId: cleanUid);
        if (state is NotificationsLoaded) {
          final current = state as NotificationsLoaded;
          emit(current.copyWith(
            notifications: effective,
            isProcessing: false,
          ));
        } else {
          emit(NotificationsLoaded(notifications: effective));
        }
      },
      onError: (error) {
        if (state is! NotificationsLoaded) {
          final fallback = localCacheService?.loadNotifications(userId: cleanUid) ??
              (cleanUid == SeedData.defaultProfile.uid
                  ? List<AppNotification>.from(SeedData.defaultNotifications)
                  : <AppNotification>[]);
          emit(NotificationsLoaded(notifications: fallback));
        }
      },
    );
  }

  // Tek bir bildirimi okundu olarak işaretler.
  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    final cleanNotifId = notificationId.trim();
    if (state is! NotificationsLoaded || cleanNotifId.isEmpty) return;
    final current = state as NotificationsLoaded;
    final previousList = current.notifications;

    // İyimser arayüz güncellemesi
    final updatedList = current.notifications.map((n) {
      return n.id == cleanNotifId ? n.copyWith(isRead: true) : n;
    }).toList();

    await localCacheService?.saveNotifications(updatedList, userId: userId.trim());
    emit(current.copyWith(notifications: updatedList));

    try {
      final result = await markNotificationReadUseCase(
        MarkNotificationReadParams(
          userId: userId.trim(),
          notificationId: cleanNotifId,
        ),
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

  // Okunmamış tüm bildirimleri tek seferde okundu olarak işaretler.
  Future<void> markAllAsRead({
    required String userId,
  }) async {
    if (state is! NotificationsLoaded) return;
    final current = state as NotificationsLoaded;

    if (current.unreadCount == 0) return;

    // İyimser arayüz güncellemesi
    final updatedList = current.notifications.map((n) {
      return n.isRead ? n : n.copyWith(isRead: true);
    }).toList();

    await localCacheService?.saveNotifications(updatedList, userId: userId.trim());
    emit(current.copyWith(
      notifications: updatedList,
      isProcessing: false,
      feedbackMessage: 'Tüm bildirimler okundu olarak işaretlendi.',
    ));

    await markAllNotificationsReadUseCase(userId.trim());
  }

  // Belirli bir bildirimi siler.
  Future<void> deleteNotification({
    required String userId,
    required String notificationId,
  }) async {
    final cleanNotifId = notificationId.trim();
    if (state is! NotificationsLoaded || cleanNotifId.isEmpty) return;
    final current = state as NotificationsLoaded;

    // Arayüzden anında kaldırır.
    final updatedList = current.notifications
        .where((n) => n.id != cleanNotifId)
        .toList();

    await localCacheService?.saveNotifications(updatedList, userId: userId.trim());
    emit(current.copyWith(
      notifications: updatedList,
      isProcessing: false,
      feedbackMessage: 'Bildirim silindi.',
    ));

    await deleteNotificationUseCase(
      DeleteNotificationParams(
        userId: userId.trim(),
        notificationId: cleanNotifId,
      ),
    );
  }

  // Yerel bir bildirimi anında ekler ve önbelleğe yazar.
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

  // Yeni bir uygulama içi bildirim oluşturur.
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
      await createNotificationUseCase(
        CreateNotificationParams(
          userId: userId.trim(),
          notification: newNotif,
        ),
      );
    } catch (_) {}
  }

  // Geri bildirim ve hata mesajlarını temizler.
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

  // İzin hatasını önlemek için aktif Firebase kullanıcı ID'sini çözümler.
  String _resolveUserId([String? userId]) {
    if (userId != null && userId.trim().isNotEmpty && userId.trim() != 'demo-user') {
      return userId.trim();
    }
    if (_currentUserId != null && _currentUserId!.trim().isNotEmpty && _currentUserId!.trim() != 'demo-user') {
      return _currentUserId!.trim();
    }
    try {
      final fbUid = FirebaseAuth.instance.currentUser?.uid;
      if (fbUid != null && fbUid.isNotEmpty) {
        return fbUid;
      }
    } catch (_) {}
    return _currentUserId ?? 'demo-user';
  }

  // Aktif kullanıcının ID'si.
  String? get currentUserId => _currentUserId;

  // Bildirimi okundu işaretlemek için yardımcı metot.
  Future<void> markNotificationRead(String notificationId, {String? userId}) {
    return markAsRead(
      userId: _resolveUserId(userId),
      notificationId: notificationId,
    );
  }

  // Tüm bildirimleri okundu yapmak için yardımcı metot.
  Future<void> markAllNotificationsRead({String? userId}) {
    return markAllAsRead(
      userId: _resolveUserId(userId),
    );
  }

  // Bildirim silmek için yardımcı metot.
  Future<void> deleteNotificationById(String notificationId, {String? userId}) {
    return deleteNotification(
      userId: _resolveUserId(userId),
      notificationId: notificationId,
    );
  }

  // Tüm bildirimleri temizlemek için yardımcı metot.
  Future<void> clearAllNotifications({String? userId}) async {
    if (state is! NotificationsLoaded) return;
    final current = state as NotificationsLoaded;
    if (current.notifications.isEmpty) return;

    _setProcessing(true);
    final user = _resolveUserId(userId);
    final notifsToDelete = List<AppNotification>.from(current.notifications);

    await localCacheService?.saveNotifications(const [], userId: user);
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

