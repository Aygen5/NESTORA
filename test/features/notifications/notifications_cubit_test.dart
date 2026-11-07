import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/di/injection.dart';
import 'package:nestora/core/errors/failures.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/features/notifications/domain/entities/app_notification.dart';
import 'package:nestora/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:nestora/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:nestora/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Fake NotificationsRepository
class FakeNotificationsRepository implements NotificationsRepository {
  bool shouldThrow = false;
  String errorMessage = 'Bildirim hatası';
  final List<AppNotification> items = [];

  final StreamController<List<AppNotification>> _controller =
      StreamController<List<AppNotification>>.broadcast();

  void emitList(List<AppNotification> list) {
    items.clear();
    items.addAll(list);
    _controller.add(List.from(items));
  }

  void emitError(dynamic error) {
    _controller.addError(error);
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) =>
      _controller.stream;

  @override
  Future<Result<List<AppNotification>>> getNotifications(String userId) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    return Result.success(items);
  }

  @override
  Future<Result<void>> markAsRead(String userId, String notificationId) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    final idx = items.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      items[idx] = items[idx].copyWith(isRead: true);
      _controller.add(List.from(items));
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> markAllAsRead(String userId) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    for (int i = 0; i < items.length; i++) {
      items[i] = items[i].copyWith(isRead: true);
    }
    _controller.add(List.from(items));
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteNotification(
    String userId,
    String notificationId,
  ) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    items.removeWhere((n) => n.id == notificationId);
    _controller.add(List.from(items));
    return Result.success(null);
  }

  @override
  Future<Result<void>> createNotification(
    String userId,
    AppNotification notification,
  ) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    items.add(notification);
    _controller.add(List.from(items));
    return Result.success(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNotificationsRepository fakeRepo;
  late NotificationsCubit cubit;

  final now = DateTime.now();
  final sampleNotifications = [
    AppNotification(
      id: 'notif-1',
      title: 'Güvenlik Uyarısı',
      message: 'Ön kapı açıldı.',
      type: NotificationType.security,
      isRead: false,
      createdAt: now,
    ),
    AppNotification(
      id: 'notif-2',
      title: 'Cihaz Durumu',
      message: 'Salon lambası açıldı.',
      type: NotificationType.device,
      isRead: false,
      createdAt: now.subtract(const Duration(days: 1)),
    ),
    AppNotification(
      id: 'notif-3',
      title: 'Enerji Özeti',
      message: 'Haftalık tüketim %12 düştü.',
      type: NotificationType.eco,
      isRead: true,
      createdAt: now.subtract(const Duration(days: 5)),
    ),
  ];

  setUp(() {
    fakeRepo = FakeNotificationsRepository();
    cubit = NotificationsCubit(notificationsRepository: fakeRepo);
  });

  tearDown(() async {
    await cubit.close();
  });

  group('NotificationsCubit Initialization & Stream Tests', () {
    test('initial state is NotificationsInitial', () {
      expect(cubit.state, isA<NotificationsInitial>());
    });

    test('loadNotifications with empty userId emits NotificationsError', () {
      cubit.loadNotifications('   ');
      expect(cubit.state, isA<NotificationsError>());
      expect((cubit.state as NotificationsError).message, 'Geçersiz kullanıcı kimliği.');
    });

    test('loadNotifications emits [NotificationsLoading, NotificationsLoaded] with list', () async {
      final states = <NotificationsState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.loadNotifications('user-1');
      expect(cubit.state, isA<NotificationsLoading>());

      fakeRepo.emitList(sampleNotifications);
      await pumpEventQueue();

      expect(states.length, 2);
      expect(states[0], isA<NotificationsLoading>());
      expect(states[1], isA<NotificationsLoaded>());

      final loaded = states[1] as NotificationsLoaded;
      expect(loaded.notifications.length, 3);
      expect(loaded.unreadCount, 2);
      expect(loaded.hasUnread, isTrue);
      expect(loaded.unreadNotifications.length, 2);

      await sub.cancel();
    });

    test('loadNotifications emits NotificationsError on stream error', () async {
      cubit.loadNotifications('user-1');
      fakeRepo.emitError('Bağlantı koptu');
      await pumpEventQueue();

      expect(cubit.state, isA<NotificationsError>());
      expect((cubit.state as NotificationsError).message, contains('Bağlantı koptu'));
    });
  });

  group('NotificationsLoaded Date Grouping Tests', () {
    setUp(() async {
      cubit.loadNotifications('user-1');
      fakeRepo.emitList(sampleNotifications);
      await pumpEventQueue();
    });

    test('groupedNotifications correctly categorizes into Bugün, Dün, Daha Eski', () {
      final state = cubit.state as NotificationsLoaded;
      final groups = state.groupedNotifications;

      expect(groups.containsKey('Bugün'), isTrue);
      expect(groups['Bugün']?.length, 1);
      expect(groups['Bugün']?.first.id, 'notif-1');

      expect(groups.containsKey('Dün'), isTrue);
      expect(groups['Dün']?.length, 1);
      expect(groups['Dün']?.first.id, 'notif-2');

      expect(groups.containsKey('Daha Eski'), isTrue);
      expect(groups['Daha Eski']?.length, 1);
      expect(groups['Daha Eski']?.first.id, 'notif-3');
    });
  });

  group('Notifications Mark as Read & Delete Operations', () {
    setUp(() async {
      cubit.loadNotifications('user-1');
      fakeRepo.emitList(sampleNotifications);
      await pumpEventQueue();
    });

    test('markAsRead updates isRead to true optimistically and in repo', () async {
      await cubit.markAsRead(userId: 'user-1', notificationId: 'notif-1');

      final state = cubit.state as NotificationsLoaded;
      expect(state.unreadCount, 1);
      expect(state.notifications.firstWhere((n) => n.id == 'notif-1').isRead, isTrue);
    });

    test('markAsRead reverts state on repository failure', () async {
      fakeRepo.shouldThrow = true;
      fakeRepo.errorMessage = 'Güncellenemedi';

      await cubit.markAsRead(userId: 'user-1', notificationId: 'notif-1');

      final state = cubit.state as NotificationsLoaded;
      expect(state.errorMessage, 'Güncellenemedi');
      expect(state.notifications.firstWhere((n) => n.id == 'notif-1').isRead, isFalse);
    });

    test('markAllAsRead marks all notifications as read atomically', () async {
      await cubit.markAllAsRead(userId: 'user-1');

      final state = cubit.state as NotificationsLoaded;
      expect(state.unreadCount, 0);
      expect(state.hasUnread, isFalse);
      expect(state.feedbackMessage, 'Tüm bildirimler okundu olarak işaretlendi.');
      expect(fakeRepo.items.every((n) => n.isRead), isTrue);
    });

    test('deleteNotification removes notification from list', () async {
      await cubit.deleteNotification(userId: 'user-1', notificationId: 'notif-1');

      final state = cubit.state as NotificationsLoaded;
      expect(state.notifications.length, 2);
      expect(state.feedbackMessage, 'Bildirim silindi.');
      expect(fakeRepo.items.any((n) => n.id == 'notif-1'), isFalse);
    });

    test('createNotification adds a new notification', () async {
      await cubit.createNotification(
        userId: 'user-1',
        title: 'Klima Uyarısı',
        message: 'Hedef sıcaklığa ulaşıldı.',
      );

      final state = cubit.state as NotificationsLoaded;
      expect(state.feedbackMessage, 'Bildirim oluşturuldu.');
      expect(fakeRepo.items.length, 4);
    });

    test('clearMessages clears feedback and error messages', () async {
      await cubit.markAllAsRead(userId: 'user-1');
      var state = cubit.state as NotificationsLoaded;
      expect(state.feedbackMessage, isNotNull);

      cubit.clearMessages();
      state = cubit.state as NotificationsLoaded;
      expect(state.feedbackMessage, isNull);
      expect(state.errorMessage, isNull);
    });
  });

  group('ServiceLocator Registration for NotificationsCubit', () {
    setUp(() async {
      sl.reset();
      SharedPreferences.setMockInitialValues({});
      final p = await SharedPreferences.getInstance();
      await initDependencies(sharedPreferences: p);
    });

    tearDown(() {
      sl.reset();
    });

    test('NotificationsCubit is registered and resolvable from ServiceLocator', () {
      expect(sl.isRegistered<NotificationsCubit>(), isTrue);
      final notifCubit = sl<NotificationsCubit>();
      expect(notifCubit, isA<NotificationsCubit>());
      notifCubit.close();
    });
  });
}
