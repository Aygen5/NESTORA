import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nestora/app/di/injection.dart';
import 'package:nestora/core/constants/seed_data.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/core/widgets/glowing_toast.dart';
import 'package:nestora/core/widgets/pulsing_glow_dot.dart';
import 'package:nestora/core/widgets/nestora_logo.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/devices/domain/repositories/devices_repository.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_cubit.dart';
import 'package:nestora/features/devices/presentation/pages/devices_page.dart';
import 'package:nestora/features/home/presentation/pages/dashboard_page.dart';
import 'package:nestora/features/notifications/domain/entities/app_notification.dart';
import 'package:nestora/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:nestora/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:nestora/features/profile/domain/entities/user_profile.dart';
import 'package:nestora/features/profile/domain/repositories/profile_repository.dart';
import 'package:nestora/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:nestora/features/rooms/domain/entities/room.dart';
import 'package:nestora/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_cubit.dart';

class _FakeDevicesRepository implements DevicesRepository {
  List<Device> devices = List.from(SeedData.defaultDevices);

  @override
  Stream<List<Device>> watchDevices(String userId) => Stream.value(devices);

  @override
  Future<Result<void>> updateDeviceState(String userId, String deviceId, Map<String, dynamic> stateFields) async {
    final idx = devices.indexWhere((d) => d.id == deviceId);
    if (idx != -1) {
      var d = devices[idx];
      if (stateFields.containsKey('isFavorite')) {
        d = d.copyWith(isFavorite: stateFields['isFavorite'] as bool);
      }
      if (stateFields.containsKey('isPoweredOn')) {
        d = d.copyWith(isPoweredOn: stateFields['isPoweredOn'] as bool);
      }
      devices[idx] = d;
    }
    return Result.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRoomsRepository implements RoomsRepository {
  @override
  Stream<List<Room>> watchRooms(String userId) => Stream.value(SeedData.defaultRooms);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProfileRepository implements ProfileRepository {
  @override
  Stream<UserProfile?> watchProfile(String userId) => Stream.value(SeedData.defaultProfile);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNotificationsRepository implements NotificationsRepository {
  @override
  Stream<List<AppNotification>> watchNotifications(String userId) => Stream.value(SeedData.defaultNotifications);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    sl.reset();
    sl.registerSingleton<SharedPreferences>(prefs);
  });

  tearDown(() {
    sl.reset();
  });

  group('PulsingGlowDot Widget Tests (Adım 2.5)', () {
    testWidgets('renders dot with specified color, size, and glow radius', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PulsingGlowDot(
                color: Color(0xFF6BD88A),
                size: 10,
                glowRadius: 8,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PulsingGlowDot), findsOneWidget);
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(PulsingGlowDot),
          matching: find.byType(Container),
        ),
      );
      expect(container.constraints?.maxWidth ?? 10, 10);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, const Color(0xFF6BD88A));
      expect(decoration.boxShadow, isNotEmpty);
    });
  });

  group('GlowingToast Notification Tests (Adım 2.6)', () {
    testWidgets('showGlowingToast displays floating card with message and icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showGlowingToast(
                    context,
                    message: 'İşlem başarıyla tamamlandı.',
                    icon: Icons.check_circle_outline_rounded,
                  );
                },
                child: const Text('Tetikle'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tetikle'));
      await tester.pump();

      expect(find.text('İşlem başarıyla tamamlandı.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
      expect(find.byType(GlowingToastWidget), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('showGlowingToast renders error styling when isError is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showGlowingToast(
                    context,
                    message: 'Bir bağlantı hatası oluştu.',
                    isError: true,
                  );
                },
                child: const Text('Hata Tetikle'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Hata Tetikle'));
      await tester.pump();

      expect(find.text('Bir bağlantı hatası oluştu.'), findsOneWidget);
      final toast = tester.widget<GlowingToastWidget>(find.byType(GlowingToastWidget));
      expect(toast.isError, isTrue);

      await tester.pumpAndSettle();
    });
  });

  group('Expanded 76px Header & Enlarged Logo Tests (Adım 2.4)', () {
    testWidgets('DashboardPage top header has 76px height and enlarged logo', (tester) async {
      final fakeDev = _FakeDevicesRepository();
      final fakeRooms = _FakeRoomsRepository();
      final fakeProf = _FakeProfileRepository();
      final fakeNotif = _FakeNotificationsRepository();

      final devCubit = DevicesCubit(devicesRepository: fakeDev);
      final roomsCubit = RoomsCubit(roomsRepository: fakeRooms, devicesRepository: fakeDev);
      final profCubit = ProfileCubit(profileRepository: fakeProf);
      final notifCubit = NotificationsCubit(notificationsRepository: fakeNotif);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<DevicesCubit>.value(value: devCubit),
            BlocProvider<RoomsCubit>.value(value: roomsCubit),
            BlocProvider<ProfileCubit>.value(value: profCubit),
            BlocProvider<NotificationsCubit>.value(value: notifCubit),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify enlarged NestoraLogo (size 34)
      final logoFinder = find.byType(NestoraLogo).first;
      expect(logoFinder, findsOneWidget);
      final logo = tester.widget<NestoraLogo>(logoFinder);
      expect(logo.size, 34);

      // Verify header height is 76
      final headerContainer = tester.widget<Container>(
        find.byWidgetPredicate(
          (w) => w is Container && w.constraints?.maxHeight == 76,
        ).first,
      );
      expect(headerContainer.constraints?.maxHeight, 76);

      // Verify Favorites button exists in Header
      expect(find.byTooltip('Favorilerim'), findsOneWidget);

      // Verify Notifications button exists in Header
      expect(find.byTooltip('Bildirimler'), findsOneWidget);

      // Tapping Favorilerim button opens bottom sheet
      await tester.tap(find.byTooltip('Favorilerim'));
      await tester.pumpAndSettle();

      expect(find.text('Favori Cihazlarım'), findsOneWidget);
      expect(find.text('Tüm Favorileri Cihazlar Sayfasında Aç'), findsOneWidget);

      devCubit.close();
      roomsCubit.close();
      profCubit.close();
      notifCubit.close();
    });

    testWidgets('DevicesPage top header has 76px height, logo 34, and functional favorites toggle', (tester) async {
      final fakeDev = _FakeDevicesRepository();
      final fakeRooms = _FakeRoomsRepository();

      final devCubit = DevicesCubit(devicesRepository: fakeDev);
      final roomsCubit = RoomsCubit(roomsRepository: fakeRooms, devicesRepository: fakeDev);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<DevicesCubit>.value(value: devCubit),
            BlocProvider<RoomsCubit>.value(value: roomsCubit),
          ],
          child: const MaterialApp(
            home: DevicesPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify logo size 34
      final logo = tester.widget<NestoraLogo>(find.byType(NestoraLogo).first);
      expect(logo.size, 34);

      // Verify header height 76
      final preferredSize = tester.widget<PreferredSize>(find.byType(PreferredSize));
      expect(preferredSize.preferredSize.height, 76);

      // Verify favorite filter toggle
      final favFilterFinder = find.byWidgetPredicate(
        (w) => w is Tooltip && (w.message?.contains('Favori Cihazları') == true || w.message?.contains('Tüm Cihazları') == true),
      );
      expect(favFilterFinder, findsOneWidget);

      // Tap to filter by favorites
      await tester.tap(favFilterFinder);
      await tester.pump();

      expect(find.byType(GlowingToastWidget), findsOneWidget);
      expect(find.textContaining('Favori cihazlar filtrelendi'), findsOneWidget);

      await tester.pumpAndSettle();

      devCubit.close();
      roomsCubit.close();
    });
  });
}
