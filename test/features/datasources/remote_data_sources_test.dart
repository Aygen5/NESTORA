import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/di/injection.dart';
import 'package:nestora/core/errors/exceptions.dart';
import 'package:nestora/features/devices/data/datasources/devices_remote_data_source.dart';
import 'package:nestora/features/devices/data/models/device_model.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:nestora/features/notifications/data/models/notification_model.dart';
import 'package:nestora/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:nestora/features/profile/data/models/user_profile_model.dart';
import 'package:nestora/features/rooms/data/datasources/rooms_remote_data_source.dart';
import 'package:nestora/features/rooms/data/models/room_model.dart';

void main() {
  group('RoomsRemoteDataSource Null & Validation Tests', () {
    test('throws ServerException when firestore is null', () async {
      final dataSource = RoomsRemoteDataSourceImpl(firestore: null);

      expect(
        () => dataSource.getRooms('user-1'),
        throwsA(isA<ServerException>()),
      );
      expect(
        () => dataSource.createRoom(
          'user-1',
          const RoomModel(id: 'r-1', name: 'Salon'),
        ),
        throwsA(isA<ServerException>()),
      );
      expect(
        () => dataSource.deleteRoom('user-1', 'r-1'),
        throwsA(isA<ServerException>()),
      );
    });

    test('throws ServerException when userId is blank', () async {
      final dataSource = RoomsRemoteDataSourceImpl(firestore: null);

      expect(
        () => dataSource.getRooms('   '),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('DevicesRemoteDataSource Null & Validation Tests', () {
    test('throws ServerException when firestore is null', () async {
      final dataSource = DevicesRemoteDataSourceImpl(firestore: null);

      expect(
        () => dataSource.getDevices('user-1'),
        throwsA(isA<ServerException>()),
      );
      expect(
        () => dataSource.createDevice(
          'user-1',
          const DeviceModel(
            id: 'd-1',
            name: 'Lamba',
            roomId: 'r-1',
            type: DeviceType.bulb,
          ),
        ),
        throwsA(isA<ServerException>()),
      );
      expect(
        () => dataSource.updateDeviceState('user-1', 'd-1', {'isOn': true}),
        throwsA(isA<ServerException>()),
      );
      expect(
        () => dataSource.deleteDevice('user-1', 'd-1'),
        throwsA(isA<ServerException>()),
      );
      expect(
        () => dataSource.moveDevicesToRoom('user-1', 'r-1', 'r-2'),
        throwsA(isA<ServerException>()),
      );
    });

    test('throws ServerException when userId is blank', () async {
      final dataSource = DevicesRemoteDataSourceImpl(firestore: null);

      expect(
        () => dataSource.getDevices(''),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('NotificationsRemoteDataSource Null & Validation Tests', () {
    test('throws ServerException when firestore is null', () async {
      final dataSource = NotificationsRemoteDataSourceImpl(firestore: null);

      expect(
        () => dataSource.getNotifications('user-1'),
        throwsA(isA<ServerException>()),
      );
      expect(
        () => dataSource.markAsRead('user-1', 'n-1'),
        throwsA(isA<ServerException>()),
      );
      expect(
        () => dataSource.markAllAsRead('user-1'),
        throwsA(isA<ServerException>()),
      );
      expect(
        () => dataSource.deleteNotification('user-1', 'n-1'),
        throwsA(isA<ServerException>()),
      );
      expect(
        () => dataSource.createNotification(
          'user-1',
          NotificationModel(
            id: 'n-1',
            title: 'Test',
            message: 'Mesaj',
            createdAt: DateTime.now(),
          ),
        ),
        throwsA(isA<ServerException>()),
      );
    });

    test('throws ServerException when userId is blank', () async {
      final dataSource = NotificationsRemoteDataSourceImpl(firestore: null);

      expect(
        () => dataSource.getNotifications('  '),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('ProfileRemoteDataSource Null & Validation Tests', () {
    test('throws ServerException when firestore is null', () async {
      final dataSource = ProfileRemoteDataSourceImpl(firestore: null);

      expect(
        () => dataSource.getProfile('user-1'),
        throwsA(isA<ServerException>()),
      );
      expect(
        () => dataSource.updateHomeName('user-1', 'Yeni Ev'),
        throwsA(isA<ServerException>()),
      );
      expect(
        () => dataSource.updateDisplayName('user-1', 'Yeni Ad'),
        throwsA(isA<ServerException>()),
      );
      expect(
        () => dataSource.updatePreferences('user-1', {'ecoModeEnabled': true}),
        throwsA(isA<ServerException>()),
      );
      expect(
        () => dataSource.updateProfile(
          'user-1',
          const UserProfileModel(
            uid: 'user-1',
            email: 'test@nestora.com',
            displayName: 'Ad',
            homeName: 'Ev',
          ),
        ),
        throwsA(isA<ServerException>()),
      );
    });

    test('throws ServerException when userId is blank', () async {
      final dataSource = ProfileRemoteDataSourceImpl(firestore: null);

      expect(
        () => dataSource.getProfile(''),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('ServiceLocator Registration Tests', () {
    test('registers all feature Remote Data Sources cleanly', () {
      sl.reset();

      sl.registerLazySingleton<RoomsRemoteDataSource>(
        () => RoomsRemoteDataSourceImpl(firestore: null),
      );
      sl.registerLazySingleton<DevicesRemoteDataSource>(
        () => DevicesRemoteDataSourceImpl(firestore: null),
      );
      sl.registerLazySingleton<NotificationsRemoteDataSource>(
        () => NotificationsRemoteDataSourceImpl(firestore: null),
      );
      sl.registerLazySingleton<ProfileRemoteDataSource>(
        () => ProfileRemoteDataSourceImpl(firestore: null),
      );

      expect(sl.isRegistered<RoomsRemoteDataSource>(), isTrue);
      expect(sl.isRegistered<DevicesRemoteDataSource>(), isTrue);
      expect(sl.isRegistered<NotificationsRemoteDataSource>(), isTrue);
      expect(sl.isRegistered<ProfileRemoteDataSource>(), isTrue);

      expect(sl<RoomsRemoteDataSource>(), isA<RoomsRemoteDataSourceImpl>());
      expect(sl<DevicesRemoteDataSource>(), isA<DevicesRemoteDataSourceImpl>());
      expect(
        sl<NotificationsRemoteDataSource>(),
        isA<NotificationsRemoteDataSourceImpl>(),
      );
      expect(sl<ProfileRemoteDataSource>(), isA<ProfileRemoteDataSourceImpl>());

      sl.reset();
    });
  });
}
