import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/theme/theme_cubit.dart';
import 'package:nestora/core/constants/app_constants.dart';
import 'package:nestora/core/constants/seed_data.dart';
import 'package:nestora/core/services/local_cache_service.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/devices/domain/repositories/devices_repository.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_cubit.dart';
import 'package:nestora/features/devices/presentation/pages/devices_page.dart';
import 'package:nestora/features/notifications/domain/entities/app_notification.dart';
import 'package:nestora/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:nestora/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:nestora/features/profile/domain/entities/user_profile.dart';
import 'package:nestora/features/profile/domain/repositories/profile_repository.dart';
import 'package:nestora/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:nestora/features/profile/presentation/cubit/profile_state.dart';
import 'package:nestora/features/rooms/domain/entities/room.dart';
import 'package:nestora/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_cubit.dart';
import 'package:nestora/features/rooms/presentation/pages/add_edit_room_page.dart';
import 'package:nestora/features/rooms/presentation/pages/room_detail_page.dart';
import 'package:nestora/features/rooms/presentation/pages/rooms_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeProfileRepository implements ProfileRepository {
  UserProfile? storedProfile;
  final StreamController<UserProfile?> _controller =
      StreamController<UserProfile?>.broadcast();

  @override
  Stream<UserProfile?> watchProfile(String userId) async* {
    yield storedProfile;
    yield* _controller.stream;
  }

  @override
  Future<Result<UserProfile?>> getProfile(String userId) async =>
      Result.success(storedProfile);

  @override
  Future<Result<void>> updateProfile(String userId, UserProfile profile) async {
    storedProfile = profile;
    _controller.add(profile);
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateHomeName(String userId, String homeName) async =>
      Result.success(null);

  @override
  Future<Result<void>> updateDisplayName(String userId, String displayName) async =>
      Result.success(null);

  @override
  Future<Result<void>> updatePreferences(
      String userId, UserPreferences preferences) async =>
      Result.success(null);

  @override
  Future<Result<void>> updatePhotoPath(String userId, String? photoPath) async {
    if (storedProfile != null) {
      storedProfile = storedProfile!.copyWith(photoPath: photoPath);
      _controller.add(storedProfile);
    }
    return Result.success(null);
  }
}

class _FakeRoomsRepository implements RoomsRepository {
  List<Room> rooms = List.from(SeedData.defaultRooms);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Stream<List<Room>> watchRooms(String userId) => Stream.value(rooms);

  @override
  Future<Result<List<Room>>> getRooms(String userId) async =>
      Result.success(rooms);

  @override
  Future<Result<Room>> getRoomById(String userId, String roomId) async {
    final room = rooms.firstWhere((r) => r.id == roomId, orElse: () => rooms.first);
    return Result.success(room);
  }

  @override
  Future<Result<void>> createRoom(String userId, Room room) async {
    rooms.add(room);
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateRoom(String userId, Room room) async {
    final idx = rooms.indexWhere((r) => r.id == room.id);
    if (idx != -1) rooms[idx] = room;
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteRoom(String userId, String roomId) async {
    rooms.removeWhere((r) => r.id == roomId);
    return Result.success(null);
  }

  Future<Result<void>> updateRoomImage(
      String userId, String roomId, String? imagePath) async {
    final idx = rooms.indexWhere((r) => r.id == roomId);
    if (idx != -1) {
      rooms[idx] = rooms[idx].copyWith(imageAsset: imagePath);
    }
    return Result.success(null);
  }
}

class _FakeDevicesRepository implements DevicesRepository {
  List<Device> devices = List.from(SeedData.defaultDevices);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Stream<List<Device>> watchDevices(String userId) => Stream.value(devices);

  @override
  Future<Result<List<Device>>> getDevices(String userId) async =>
      Result.success(devices);

  @override
  Future<Result<Device>> getDeviceById(String userId, String deviceId) async {
    final device = devices.firstWhere((d) => d.id == deviceId, orElse: () => devices.first);
    return Result.success(device);
  }

  @override
  Stream<List<Device>> watchDevicesByRoom(String userId, String roomId) =>
      Stream.value(devices.where((d) => d.roomId == roomId).toList());

  @override
  Future<Result<void>> deleteDevicesByRoom(String userId, String roomId) async =>
      Result.success(null);

  @override
  Future<Result<void>> moveDevicesToRoom(
          String userId, String fromRoomId, String? toRoomId) async =>
      Result.success(null);

  @override
  Future<Result<void>> updateDeviceState(
          String userId, String deviceId, Map<String, dynamic> updates) async =>
      Result.success(null);
}

class _FakeNotificationsRepository implements NotificationsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) =>
      Stream.value([]);

  @override
  Future<Result<List<AppNotification>>> getNotifications(String userId) async =>
      Result.success([]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late LocalCacheService localCacheService;
  late _FakeProfileRepository profileRepo;
  late _FakeRoomsRepository roomsRepo;
  late _FakeDevicesRepository devicesRepo;
  late _FakeNotificationsRepository notifRepo;

  late ProfileCubit profileCubit;
  late RoomsCubit roomsCubit;
  late DevicesCubit devicesCubit;
  late NotificationsCubit notifCubit;
  late ThemeCubit themeCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    localCacheService = LocalCacheService(prefs: prefs);

    profileRepo = _FakeProfileRepository()
      ..storedProfile = SeedData.defaultProfile;
    roomsRepo = _FakeRoomsRepository();
    devicesRepo = _FakeDevicesRepository();
    notifRepo = _FakeNotificationsRepository();

    profileCubit = ProfileCubit(
      profileRepository: profileRepo,
      sharedPreferences: prefs,
      localCacheService: localCacheService,
    );
    roomsCubit = RoomsCubit(
      roomsRepository: roomsRepo,
      devicesRepository: devicesRepo,
      localCacheService: localCacheService,
    );
    devicesCubit = DevicesCubit(
      devicesRepository: devicesRepo,
      localCacheService: localCacheService,
    );
    notifCubit = NotificationsCubit(
      notificationsRepository: notifRepo,
    );
    themeCubit = ThemeCubit();
  });

  Widget buildApp(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProfileCubit>.value(value: profileCubit),
        BlocProvider<RoomsCubit>.value(value: roomsCubit),
        BlocProvider<DevicesCubit>.value(value: devicesCubit),
        BlocProvider<NotificationsCubit>.value(value: notifCubit),
        BlocProvider<ThemeCubit>.value(value: themeCubit),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Profile Avatar & Persistence Tests', () {
    testWidgets('DevicesPage renders profile avatar using ProfileCubit photo',
        (tester) async {
      await tester.pumpWidget(buildApp(const DevicesPage()));
      await tester.pumpAndSettle();

      final avatarFinder = find.byKey(const Key('devices_profile_avatar'));
      expect(avatarFinder, findsOneWidget);

      expect(
        find.byWidgetPredicate((widget) {
          if (widget is Image) {
            final image = widget.image;
            if (image is AssetImage &&
                image.assetName.contains('nestora_profil_ve_ayarlar.png')) {
              return true;
            }
          }
          return false;
        }),
        findsNothing,
      );
    });

    testWidgets('ProfileCubit setPhotoPath updates photo and persists in prefs',
        (tester) async {
      const customPhoto = 'data:image/jpeg;base64,/9j/4AAQSkZJRg==';

      await profileCubit.setPhotoPath(customPhoto);

      expect(profileCubit.state, isA<ProfileLoaded>());
      final loaded = profileCubit.state as ProfileLoaded;
      expect(loaded.profile.photoPath, equals(customPhoto));

      expect(prefs.getString(AppConstants.prefProfilePhotoPath), equals(customPhoto));

      final reloadedCubit = ProfileCubit(
        profileRepository: profileRepo,
        sharedPreferences: prefs,
        localCacheService: localCacheService,
      );
      final reloadedState = reloadedCubit.state as ProfileLoaded;
      expect(reloadedState.profile.photoPath, equals(customPhoto));
    });
  });

  group('Room Image Picker Modal Tests (No Camera Option)', () {
    testWidgets('AddEditRoomPage modal contains "Galeriden Seç" but NO "Kamera ile Çek"',
        (tester) async {
      await tester.pumpWidget(buildApp(const AddEditRoomPage()));
      await tester.pumpAndSettle();

      final photoPicker = find.text('+ Oda Fotoğrafı Ekle');
      expect(photoPicker, findsOneWidget);
      await tester.tap(photoPicker);
      await tester.pumpAndSettle();

      expect(find.text('Galeriden Seç'), findsOneWidget);
      expect(find.text('Kamera ile Çek'), findsNothing);
      expect(find.text('Mimari Hazır Görseller'), findsOneWidget);
    });

    testWidgets('RoomDetailPage modal contains "Galeriden Seç" but NO "Kamera ile Çek"',
        (tester) async {
      final room = SeedData.defaultRoomModels.first;
      await tester.pumpWidget(buildApp(RoomDetailPage(room: room)));
      await tester.pumpAndSettle();

      final actionBtn = find.byKey(const Key('room_image_action_button'));
      expect(actionBtn, findsOneWidget);
      await tester.tap(actionBtn);
      await tester.pumpAndSettle();

      expect(find.text('Galeriden Seç'), findsOneWidget);
      expect(find.text('Kamera ile Çek'), findsNothing);
      expect(find.text('Mimari Hazır Görseller'), findsOneWidget);
    });
  });

  group('Room Image Rendering in RoomsPage', () {
    testWidgets('RoomsPage renders custom room image without failing',
        (tester) async {
      final customRoom = Room(
        id: 'room-custom-1',
        name: 'Teras Bahçe',
        iconName: 'yard',
        targetTemperature: 21.0,
        deviceCount: 1,
        activeDeviceCount: 0,
        humidity: 55,
        imageAsset: 'data:image/jpeg;base64,/9j/4AAQSkZJRg==',
      );
      await roomsCubit.addRoomEntity(customRoom);

      await tester.pumpWidget(buildApp(const RoomsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Teras Bahçe'), findsOneWidget);
    });
  });
}
