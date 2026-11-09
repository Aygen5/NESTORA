import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/core/constants/seed_data.dart';
import 'package:nestora/core/network/network_info.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/features/auth/data/models/auth_user_model.dart';
import 'package:nestora/features/auth/domain/entities/auth_user.dart';
import 'package:nestora/features/auth/domain/repositories/auth_repository.dart';
import 'package:nestora/features/auth/domain/usecases/auth_usecases.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/devices/domain/repositories/devices_repository.dart';
import 'package:nestora/features/devices/domain/usecases/devices_usecases.dart';
import 'package:nestora/features/notifications/domain/entities/app_notification.dart';
import 'package:nestora/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:nestora/features/notifications/domain/usecases/notifications_usecases.dart';
import 'package:nestora/features/profile/domain/entities/user_profile.dart';
import 'package:nestora/features/profile/domain/repositories/profile_repository.dart';
import 'package:nestora/features/profile/domain/usecases/profile_usecases.dart';
import 'package:nestora/features/rooms/domain/entities/room.dart';
import 'package:nestora/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nestora/features/rooms/domain/usecases/rooms_usecases.dart';

class MockAuthRepo implements AuthRepository {
  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(const AuthUser(id: 'u-1', email: 'test@nestora.com'));

  @override
  AuthUser? get currentUser => const AuthUser(id: 'u-1', email: 'test@nestora.com');

  @override
  Future<Result<AuthUser>> signInWithEmail({required String email, required String password}) async =>
      Result.success(AuthUser(id: 'u-1', email: email));

  @override
  Future<Result<AuthUser>> signUpWithEmail({required String email, required String password, String? displayName}) async =>
      Result.success(AuthUser(id: 'u-1', email: email, displayName: displayName));

  @override
  Future<Result<void>> signOut() async => Result.success(null);

  @override
  Future<Result<void>> sendPasswordReset({required String email}) async => Result.success(null);

  @override
  Future<Result<AuthUser>> signInDemo({String? email, String? password}) async =>
      Result.success(const AuthUser(id: 'demo-1', email: 'aygen@nestora.com'));
}

class MockDevicesRepo implements DevicesRepository {
  @override
  Stream<List<Device>> watchDevices(String userId) => Stream.value(SeedData.defaultDevices);

  @override
  Stream<List<Device>> watchDevicesByRoom(String userId, String roomId) => Stream.value([]);

  @override
  Future<Result<List<Device>>> getDevices(String userId) async => Result.success(SeedData.defaultDevices);

  @override
  Future<Result<Device>> getDeviceById(String userId, String deviceId) async =>
      Result.success(SeedData.defaultDevices.first);

  @override
  Future<Result<void>> createDevice(String userId, Device device) async => Result.success(null);

  @override
  Future<Result<void>> updateDevice(String userId, Device device) async => Result.success(null);

  @override
  Future<Result<void>> updateDeviceState(String userId, String deviceId, Map<String, dynamic> stateUpdates) async =>
      Result.success(null);

  @override
  Future<Result<void>> deleteDevice(String userId, String deviceId) async => Result.success(null);

  @override
  Future<Result<void>> deleteDevicesByRoom(String userId, String roomId) async => Result.success(null);

  @override
  Future<Result<void>> moveDevicesToRoom(String userId, String fromRoomId, String toRoomId) async =>
      Result.success(null);
}

class MockRoomsRepo implements RoomsRepository {
  @override
  Stream<List<Room>> watchRooms(String userId) => Stream.value(SeedData.defaultRooms);

  @override
  Future<Result<List<Room>>> getRooms(String userId) async => Result.success(SeedData.defaultRooms);

  @override
  Future<Result<Room>> getRoomById(String userId, String roomId) async => Result.success(SeedData.defaultRooms.first);

  @override
  Future<Result<void>> createRoom(String userId, Room room) async => Result.success(null);

  @override
  Future<Result<void>> updateRoom(String userId, Room room) async => Result.success(null);

  @override
  Future<Result<void>> deleteRoom(String userId, String roomId) async => Result.success(null);
}

class MockNotificationsRepo implements NotificationsRepository {
  @override
  Stream<List<AppNotification>> watchNotifications(String userId) => Stream.value(SeedData.defaultNotifications);

  @override
  Future<Result<List<AppNotification>>> getNotifications(String userId) async =>
      Result.success(SeedData.defaultNotifications);

  @override
  Future<Result<void>> markAsRead(String userId, String notificationId) async => Result.success(null);

  @override
  Future<Result<void>> markAllAsRead(String userId) async => Result.success(null);

  @override
  Future<Result<void>> deleteNotification(String userId, String notificationId) async => Result.success(null);

  @override
  Future<Result<void>> createNotification(String userId, AppNotification notification) async => Result.success(null);
}

class MockProfileRepo implements ProfileRepository {
  @override
  Stream<UserProfile?> watchProfile(String userId) => Stream.value(SeedData.defaultProfile);

  @override
  Future<Result<UserProfile?>> getProfile(String userId) async => Result.success(SeedData.defaultProfile);

  @override
  Future<Result<void>> updateProfile(String userId, UserProfile profile) async => Result.success(null);

  @override
  Future<Result<void>> updateHomeName(String userId, String homeName) async => Result.success(null);

  @override
  Future<Result<void>> updateDisplayName(String userId, String displayName) async => Result.success(null);

  @override
  Future<Result<void>> updatePreferences(String userId, UserPreferences preferences) async => Result.success(null);

  @override
  Future<Result<void>> updatePhotoPath(String userId, String? photoPath) async => Result.success(null);
}

void main() {
  group('Clean Architecture: Use Cases, DTOs & Core Tests', () {
    test('NetworkInfo contract and implementation reports connected status', () async {
      const networkInfo = NetworkInfoImpl();
      expect(await networkInfo.isConnected, isTrue);
    });

    test('AuthUserModel DTO parses and maps correctly', () {
      final model = AuthUserModel.fromMap(
        const {
          'email': 'aygen@nestora.com',
          'displayName': 'Aygen Yıldırım',
          'isAnonymous': false,
        },
        id: 'u-123',
      );

      expect(model.id, equals('u-123'));
      expect(model.email, equals('aygen@nestora.com'));
      expect(model.displayName, equals('Aygen Yıldırım'));
      expect(model.initials, equals('AY'));

      final json = model.toMap();
      expect(json['id'], equals('u-123'));
      expect(json['email'], equals('aygen@nestora.com'));
    });

    test('Auth Use Cases execute business logic properly', () async {
      final repo = MockAuthRepo();
      final signIn = SignInWithEmailUseCase(repo);
      final signUp = SignUpWithEmailUseCase(repo);
      final signOut = SignOutUseCase(repo);
      final reset = SendPasswordResetUseCase(repo);
      final currentUser = GetCurrentUserUseCase(repo);
      final watchState = WatchAuthStateUseCase(repo);

      final signInResult = await signIn(email: 'test@nestora.com', password: 'Password1!');
      expect(signInResult.isSuccess, isTrue);
      expect(signInResult.dataOrNull?.email, equals('test@nestora.com'));

      final signUpResult = await signUp(email: 'new@nestora.com', password: 'Password1!', displayName: 'New User');
      expect(signUpResult.isSuccess, isTrue);

      expect(currentUser()?.id, equals('u-1'));
      expect(await signOut(), isA<Result<void>>());
      expect(await reset(email: 'test@nestora.com'), isA<Result<void>>());
      expect(await watchState().first, isNotNull);
    });

    test('Devices Use Cases execute business logic properly', () async {
      final repo = MockDevicesRepo();
      final getDevices = GetDevicesUseCase(repo);
      final watchDevices = WatchDevicesUseCase(repo);
      final togglePower = ToggleDevicePowerUseCase(repo);
      final updateState = UpdateDeviceStateUseCase(repo);
      final createDevice = CreateDeviceUseCase(repo);
      final updateDevice = UpdateDeviceUseCase(repo);
      final deleteDevice = DeleteDeviceUseCase(repo);
      final moveDevices = MoveDevicesToRoomUseCase(repo);

      final list = await getDevices('u-1');
      expect(list.isSuccess, isTrue);
      expect(list.dataOrNull?.length, equals(SeedData.defaultDevices.length));

      final streamFirst = await watchDevices('u-1').first;
      expect(streamFirst.isNotEmpty, isTrue);

      final toggleRes = await togglePower(
        const ToggleDevicePowerParams(userId: 'u-1', deviceId: 'dev-1', currentPowerState: true),
      );
      expect(toggleRes.isSuccess, isTrue);

      final stateRes = await updateState(
        const UpdateDeviceStateParams(userId: 'u-1', deviceId: 'dev-1', stateUpdates: {'brightness': 80}),
      );
      expect(stateRes.isSuccess, isTrue);

      final createRes = await createDevice(
        CreateDeviceParams(userId: 'u-1', device: SeedData.defaultDevices.first),
      );
      expect(createRes.isSuccess, isTrue);

      final updateRes = await updateDevice(
        UpdateDeviceParams(userId: 'u-1', device: SeedData.defaultDevices.first),
      );
      expect(updateRes.isSuccess, isTrue);

      final deleteRes = await deleteDevice(
        const DeleteDeviceParams(userId: 'u-1', deviceId: 'dev-1'),
      );
      expect(deleteRes.isSuccess, isTrue);

      final moveRes = await moveDevices(
        const MoveDevicesToRoomParams(userId: 'u-1', fromRoomId: 'room-1', toRoomId: 'room-2'),
      );
      expect(moveRes.isSuccess, isTrue);
    });

    test('Rooms Use Cases execute business logic properly', () async {
      final repo = MockRoomsRepo();
      final getRooms = GetRoomsUseCase(repo);
      final watchRooms = WatchRoomsUseCase(repo);
      final createRoom = CreateRoomUseCase(repo);
      final updateRoom = UpdateRoomUseCase(repo);
      final deleteRoom = DeleteRoomUseCase(repo);

      final rooms = await getRooms('u-1');
      expect(rooms.isSuccess, isTrue);
      expect(await watchRooms('u-1').first, isNotEmpty);

      final createRes = await createRoom(CreateRoomParams(userId: 'u-1', room: SeedData.defaultRooms.first));
      expect(createRes.isSuccess, isTrue);

      final updateRes = await updateRoom(UpdateRoomParams(userId: 'u-1', room: SeedData.defaultRooms.first));
      expect(updateRes.isSuccess, isTrue);

      final deleteRes = await deleteRoom(const DeleteRoomParams(userId: 'u-1', roomId: 'room-1'));
      expect(deleteRes.isSuccess, isTrue);
    });

    test('Notifications Use Cases execute business logic properly', () async {
      final repo = MockNotificationsRepo();
      final getNotifs = GetNotificationsUseCase(repo);
      final watchNotifs = WatchNotificationsUseCase(repo);
      final markRead = MarkNotificationReadUseCase(repo);
      final markAllRead = MarkAllNotificationsReadUseCase(repo);
      final deleteNotif = DeleteNotificationUseCase(repo);
      final createNotif = CreateNotificationUseCase(repo);

      expect((await getNotifs('u-1')).isSuccess, isTrue);
      expect(await watchNotifs('u-1').first, isNotEmpty);
      expect((await markRead(const MarkNotificationReadParams(userId: 'u-1', notificationId: 'n-1'))).isSuccess, isTrue);
      expect((await markAllRead('u-1')).isSuccess, isTrue);
      expect((await deleteNotif(const DeleteNotificationParams(userId: 'u-1', notificationId: 'n-1'))).isSuccess, isTrue);
      expect(
        (await createNotif(
          CreateNotificationParams(userId: 'u-1', notification: SeedData.defaultNotifications.first),
        )).isSuccess,
        isTrue,
      );
    });

    test('Profile Use Cases execute business logic properly', () async {
      final repo = MockProfileRepo();
      final getProfile = GetUserProfileUseCase(repo);
      final watchProfile = WatchUserProfileUseCase(repo);
      final updateProfile = UpdateUserProfileUseCase(repo);
      final updatePhoto = UpdatePhotoPathUseCase(repo);

      expect((await getProfile('u-1')).isSuccess, isTrue);
      expect(await watchProfile('u-1').first, isNotNull);
      expect((await updateProfile(UpdateUserProfileParams(userId: 'u-1', profile: SeedData.defaultProfile))).isSuccess, isTrue);
      expect((await updatePhoto(const UpdatePhotoPathParams(userId: 'u-1', photoPath: '/path/test.png'))).isSuccess, isTrue);
    });
  });
}
