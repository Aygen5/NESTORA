import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/notifications/domain/entities/app_notification.dart';
import 'package:nestora/features/profile/domain/entities/user_profile.dart';
import 'package:nestora/features/rooms/domain/entities/room.dart';

void main() {
  group('Room Entity Tests', () {
    test('instantiates with defaults and supports copyWith', () {
      const room = Room(id: 'room-1', name: 'Salon');

      expect(room.id, 'room-1');
      expect(room.name, 'Salon');
      expect(room.iconName, 'chair');
      expect(room.targetTemperature, 22.0);
      expect(room.deviceCount, 0);
      expect(room.activeDeviceCount, 0);
      expect(room.humidity, 50);

      final updated = room.copyWith(
        name: 'Büyük Salon',
        targetTemperature: 23.5,
        deviceCount: 3,
        activeDeviceCount: 2,
      );

      expect(updated.name, 'Büyük Salon');
      expect(updated.targetTemperature, 23.5);
      expect(updated.deviceCount, 3);
      expect(updated.activeDeviceCount, 2);
      expect(updated.iconName, 'chair');
    });

    test('value equality and hashCode behave correctly', () {
      final now = DateTime(2026, 11, 7, 12, 0);
      final roomA = Room(id: 'r-1', name: 'Mutfak', createdAt: now);
      final roomB = Room(id: 'r-1', name: 'Mutfak', createdAt: now);
      final roomC = Room(id: 'r-2', name: 'Mutfak', createdAt: now);

      expect(roomA, equals(roomB));
      expect(roomA.hashCode, equals(roomB.hashCode));
      expect(roomA, isNot(equals(roomC)));
      expect(roomA.toString(), contains('Room(id: r-1, name: Mutfak'));
    });
  });

  group('Device Entity & Enums Tests', () {
    test('DeviceType, AcMode, and FanSpeed fromString parsing', () {
      expect(DeviceType.fromString('bulb'), DeviceType.bulb);
      expect(DeviceType.fromString('AC'), DeviceType.ac);
      expect(DeviceType.fromString('PLUG'), DeviceType.plug);
      expect(DeviceType.fromString('unknown'), DeviceType.bulb);

      expect(AcMode.fromString('cool'), AcMode.cool);
      expect(AcMode.fromString('HEAT'), AcMode.heat);
      expect(AcMode.fromString('auto'), AcMode.auto);
      expect(AcMode.fromString(null), AcMode.auto);

      expect(FanSpeed.fromString('high'), FanSpeed.high);
      expect(FanSpeed.fromString('mid'), FanSpeed.mid);
      expect(FanSpeed.fromString('LOW'), FanSpeed.low);
      expect(FanSpeed.fromString('unknown'), FanSpeed.mid);
    });

    test('Device instantiates with defaults and boolean convenience getters', () {
      const lamp = Device(
        id: 'dev-1',
        name: 'Tavan Lambası',
        roomId: 'room-1',
        type: DeviceType.bulb,
        isPoweredOn: true,
        brightness: 72,
        currentPowerWatts: 12.0,
      );

      expect(lamp.isLamp, isTrue);
      expect(lamp.isClimate, isFalse);
      expect(lamp.isPlug, isFalse);
      expect(lamp.brightness, 72);
      expect(lamp.currentPowerWatts, 12.0);

      const ac = Device(
        id: 'dev-2',
        name: 'Klima',
        roomId: 'room-2',
        type: DeviceType.ac,
        targetTemp: 22.0,
      );

      expect(ac.isClimate, isTrue);
      expect(ac.isLamp, isFalse);

      final updatedAc = ac.copyWith(targetTemp: 24.5, isPoweredOn: true);
      expect(updatedAc.targetTemp, 24.5);
      expect(updatedAc.isPoweredOn, isTrue);
    });

    test('Device equality and toString', () {
      const dev1 = Device(id: 'd-1', name: 'Priz', roomId: 'r-1', type: DeviceType.plug);
      const dev2 = Device(id: 'd-1', name: 'Priz', roomId: 'r-1', type: DeviceType.plug);

      expect(dev1, equals(dev2));
      expect(dev1.hashCode, equals(dev2.hashCode));
      expect(dev1.toString(), contains('Device(id: d-1, name: Priz'));
    });
  });

  group('AppNotification Entity Tests', () {
    test('NotificationType fromString parsing', () {
      expect(NotificationType.fromString('device'), NotificationType.device);
      expect(NotificationType.fromString('SECURITY'), NotificationType.security);
      expect(NotificationType.fromString('eco'), NotificationType.eco);
      expect(NotificationType.fromString('system'), NotificationType.system);
      expect(NotificationType.fromString('other'), NotificationType.device);
    });

    test('timeAgoFormatted outputs correct Turkish relative time', () {
      final now = DateTime.now();

      final justNow = AppNotification(
        id: 'n-1',
        title: 'Test',
        message: 'Mesaj',
        createdAt: now.subtract(const Duration(seconds: 20)),
      );
      expect(justNow.timeAgoFormatted, 'Az önce');

      final minutesAgo = AppNotification(
        id: 'n-2',
        title: 'Test',
        message: 'Mesaj',
        createdAt: now.subtract(const Duration(minutes: 5)),
      );
      expect(minutesAgo.timeAgoFormatted, '5 dakika önce');

      final hoursAgo = AppNotification(
        id: 'n-3',
        title: 'Test',
        message: 'Mesaj',
        createdAt: now.subtract(const Duration(hours: 3)),
      );
      expect(hoursAgo.timeAgoFormatted, '3 saat önce');

      final daysAgo = AppNotification(
        id: 'n-4',
        title: 'Test',
        message: 'Mesaj',
        createdAt: now.subtract(const Duration(days: 2)),
      );
      expect(daysAgo.timeAgoFormatted, '2 gün önce');
    });

    test('copyWith and value equality', () {
      final time = DateTime(2026, 11, 7, 10, 0);
      final notif = AppNotification(
        id: 'n-1',
        title: 'Lamba açıldı',
        message: 'Açıklama',
        createdAt: time,
      );

      final readNotif = notif.copyWith(isRead: true);
      expect(readNotif.isRead, isTrue);
      expect(notif.isRead, isFalse);
      expect(notif.toString(), contains('AppNotification(id: n-1'));
    });
  });

  group('UserProfile Entity Tests', () {
    test('UserProfile instantiates with default preferences and computes initials', () {
      const profile = UserProfile(
        uid: 'user-123',
        email: 'aygenyildirim27@gmail.com',
        displayName: 'Aygen Yıldırım',
        homeName: "Aygen'in Evi",
      );

      expect(profile.uid, 'user-123');
      expect(profile.displayName, 'Aygen Yıldırım');
      expect(profile.initials, 'AY');
      expect(profile.preferences.notificationsEnabled, isTrue);
      expect(profile.preferences.ecoModeEnabled, isTrue);
      expect(profile.preferences.temperatureUnit, 'C');

      const singleNameProfile = UserProfile(
        uid: 'user-456',
        email: 'aygen@nestora.com',
        displayName: 'Aygen',
        homeName: 'Ev',
      );
      expect(singleNameProfile.initials, 'A');

      const emailOnlyProfile = UserProfile(
        uid: 'user-789',
        email: 'demo@nestora.com',
        displayName: '',
        homeName: 'Demo Evi',
      );
      expect(emailOnlyProfile.initials, 'D');
    });

    test('UserPreferences and UserProfile copyWith and equality', () {
      const prefs = UserPreferences();
      final updatedPrefs = prefs.copyWith(ecoModeEnabled: false, temperatureUnit: 'F');

      expect(updatedPrefs.ecoModeEnabled, isFalse);
      expect(updatedPrefs.temperatureUnit, 'F');
      expect(updatedPrefs.notificationsEnabled, isTrue);

      const profile = UserProfile(
        uid: 'u-1',
        email: 'test@nestora.com',
        displayName: 'Test User',
        homeName: 'Test Home',
      );

      final updatedProfile = profile.copyWith(homeName: 'Yeni Akıllı Ev');
      expect(updatedProfile.homeName, 'Yeni Akıllı Ev');
      expect(updatedProfile.uid, 'u-1');
      expect(profile.toString(), contains('UserProfile(uid: u-1'));
    });
  });
}
