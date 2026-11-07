import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/core/utils/firestore_helpers.dart';
import 'package:nestora/features/devices/data/models/device_model.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/notifications/data/models/notification_model.dart';
import 'package:nestora/features/notifications/domain/entities/app_notification.dart';
import 'package:nestora/features/profile/data/models/user_profile_model.dart';
import 'package:nestora/features/profile/domain/entities/user_profile.dart';
import 'package:nestora/features/rooms/data/models/room_model.dart';
import 'package:nestora/features/rooms/domain/entities/room.dart';

void main() {
  group('FirestoreHelpers Unit Tests', () {
    test('parseDateTime converts Timestamps, ISO Strings, ints and DateTimes safely', () {
      final now = DateTime(2026, 11, 7, 15, 30);
      final timestamp = Timestamp.fromDate(now);

      expect(FirestoreHelpers.parseDateTime(timestamp), equals(now));
      expect(FirestoreHelpers.parseDateTime(now), equals(now));
      expect(FirestoreHelpers.parseDateTime(now.toIso8601String()), equals(now));
      expect(FirestoreHelpers.parseDateTime(now.millisecondsSinceEpoch), equals(now));
      expect(FirestoreHelpers.parseDateTime(null, now), equals(now));
      expect(FirestoreHelpers.parseDateTime('invalid-date', now), equals(now));
    });

    test('parseDouble handles ints, doubles, strings and nulls safely', () {
      expect(FirestoreHelpers.parseDouble(22), equals(22.0));
      expect(FirestoreHelpers.parseDouble(22.5), equals(22.5));
      expect(FirestoreHelpers.parseDouble('23.4'), equals(23.4));
      expect(FirestoreHelpers.parseDouble(null, 18.0), equals(18.0));
      expect(FirestoreHelpers.parseDouble('invalid', 16.0), equals(16.0));
    });

    test('parseInt handles doubles, ints, strings and nulls safely', () {
      expect(FirestoreHelpers.parseInt(42), equals(42));
      expect(FirestoreHelpers.parseInt(42.9), equals(42));
      expect(FirestoreHelpers.parseInt('75'), equals(75));
      expect(FirestoreHelpers.parseInt(null, 10), equals(10));
      expect(FirestoreHelpers.parseInt('invalid', 5), equals(5));
    });

    test('parseBool handles bools, numbers, strings safely', () {
      expect(FirestoreHelpers.parseBool(true), isTrue);
      expect(FirestoreHelpers.parseBool(false), isFalse);
      expect(FirestoreHelpers.parseBool(1), isTrue);
      expect(FirestoreHelpers.parseBool(0), isFalse);
      expect(FirestoreHelpers.parseBool('true'), isTrue);
      expect(FirestoreHelpers.parseBool('false'), isFalse);
      expect(FirestoreHelpers.parseBool('yes'), isTrue);
      expect(FirestoreHelpers.parseBool('no'), isFalse);
      expect(FirestoreHelpers.parseBool(null, true), isTrue);
    });

    test('dateTimeToTimestamp returns Timestamp for DateTime and serverTimestamp for null', () {
      final now = DateTime(2026, 11, 7);
      expect(FirestoreHelpers.dateTimeToTimestamp(now), isA<Timestamp>());
      expect(FirestoreHelpers.dateTimeToTimestamp(null), isA<FieldValue>());
    });
  });

  group('RoomModel DTO Tests', () {
    test('fromMap parses raw Firestore map and handles missing fields safely', () {
      final raw = {
        'name': 'Salon',
        'icon': 'chair',
        'targetTemperature': 23, // int representation
        'humidity': 52.0, // double representation
        'deviceCount': '4', // string representation
        'activeDeviceCount': 2,
        'imageAsset': 'assets/screens/salon.png',
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 7)),
      };

      final room = RoomModel.fromMap(raw, id: 'room-1');

      expect(room.id, 'room-1');
      expect(room.name, 'Salon');
      expect(room.iconName, 'chair');
      expect(room.targetTemperature, 23.0);
      expect(room.humidity, 52);
      expect(room.deviceCount, 4);
      expect(room.activeDeviceCount, 2);
      expect(room.imageAsset, 'assets/screens/salon.png');
      expect(room.createdAt, equals(DateTime(2026, 11, 7)));
    });

    test('toFirestore and toMap serialization', () {
      const room = RoomModel(
        id: 'room-2',
        name: 'Yatak Odası',
        iconName: 'bed',
        targetTemperature: 24.0,
        deviceCount: 2,
      );

      final firestorePayload = room.toFirestore();
      expect(firestorePayload['name'], 'Yatak Odası');
      expect(firestorePayload['icon'], 'bed');
      expect(firestorePayload['targetTemperature'], 24.0);
      expect(firestorePayload['updatedAt'], isA<FieldValue>());

      final localMap = room.toMap();
      expect(localMap['id'], 'room-2');
      expect(localMap['name'], 'Yatak Odası');
    });

    test('fromEntity creates identical RoomModel', () {
      const entity = Room(
        id: 'r-3',
        name: 'Mutfak',
        iconName: 'restaurant',
        targetTemperature: 21.5,
      );

      final model = RoomModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.name, entity.name);
      expect(model.toEntity(), equals(entity));
    });
  });

  group('DeviceModel DTO Tests', () {
    test('fromMap parses all device types, modes and fan speeds safely', () {
      final raw = {
        'name': 'Yatak Odası Kliması',
        'roomId': 'room-2',
        'type': 'ac',
        'isOn': 1,
        'targetTemperature': 24,
        'mode': 'cool',
        'fanSpeed': 'high',
        'currentPowerWatts': 850,
        'isFavorite': 'true',
      };

      final device = DeviceModel.fromMap(raw, id: 'dev-5');

      expect(device.id, 'dev-5');
      expect(device.name, 'Yatak Odası Kliması');
      expect(device.roomId, 'room-2');
      expect(device.type, DeviceType.ac);
      expect(device.isPoweredOn, isTrue);
      expect(device.targetTemp, 24.0);
      expect(device.acMode, AcMode.cool);
      expect(device.fanSpeed, FanSpeed.high);
      expect(device.currentPowerWatts, 850.0);
      expect(device.isFavorite, isTrue);
      expect(device.isClimate, isTrue);
    });

    test('toFirestore formats device fields correctly', () {
      const device = DeviceModel(
        id: 'dev-1',
        name: 'Salon Lambası',
        roomId: 'room-1',
        type: DeviceType.bulb,
        isPoweredOn: true,
        brightness: 72,
        colorHex: '#E1C1A0',
        currentPowerWatts: 12.0,
      );

      final payload = device.toFirestore();
      expect(payload['name'], 'Salon Lambası');
      expect(payload['roomId'], 'room-1');
      expect(payload['type'], 'bulb');
      expect(payload['isOn'], isTrue);
      expect(payload['brightness'], 72);
      expect(payload['color'], '#E1C1A0');
      expect(payload['currentPowerWatts'], 12.0);
      expect(payload['updatedAt'], isA<FieldValue>());
    });

    test('fromEntity converts domain entity accurately', () {
      const entity = Device(
        id: 'dev-3',
        name: 'Priz',
        roomId: 'room-1',
        type: DeviceType.plug,
        isPoweredOn: true,
      );

      final model = DeviceModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.name, entity.name);
      expect(model.type, DeviceType.plug);
      expect(model.toEntity(), equals(entity));
    });
  });

  group('NotificationModel DTO Tests', () {
    test('fromMap safely maps both isRead and legacy isUnread formats', () {
      final raw1 = {
        'title': 'Lamba Açıldı',
        'message': 'Parlaklık %72',
        'type': 'device',
        'isRead': true,
        'createdAt': Timestamp.now(),
      };
      final notif1 = NotificationModel.fromMap(raw1, id: 'n-1');
      expect(notif1.isRead, isTrue);

      final raw2 = {
        'title': 'Klima Kapatıldı',
        'description': 'Klima beklemede',
        'type': 'device',
        'isUnread': true, // legacy format
        'createdAt': Timestamp.now(),
      };
      final notif2 = NotificationModel.fromMap(raw2, id: 'n-2');
      expect(notif2.isRead, isFalse);
      expect(notif2.message, 'Klima beklemede');
    });

    test('toFirestore serializes correctly', () {
      final now = DateTime(2026, 11, 7, 14, 0);
      final notif = NotificationModel(
        id: 'n-3',
        title: 'Uyarı',
        message: 'İçerik',
        type: NotificationType.security,
        isRead: false,
        relatedRoomId: 'room-1',
        createdAt: now,
      );

      final payload = notif.toFirestore();
      expect(payload['title'], 'Uyarı');
      expect(payload['type'], 'security');
      expect(payload['isRead'], isFalse);
      expect(payload['relatedRoomId'], 'room-1');
      expect(payload['createdAt'], isA<Timestamp>());
    });

    test('fromEntity maps domain entity', () {
      final entity = AppNotification(
        id: 'n-4',
        title: 'Başlık',
        message: 'Mesaj',
        createdAt: DateTime(2026, 11, 7),
      );

      final model = NotificationModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.title, entity.title);
      expect(model.toEntity(), equals(entity));
    });
  });

  group('UserProfileModel DTO Tests', () {
    test('fromMap parses nested preferences and handles missing keys', () {
      final raw = {
        'displayName': 'Aygen Yıldırım',
        'homeName': "Aygen'in Evi",
        'email': 'aygen@nestora.com',
        'photoPath': '/data/user/profile.jpg',
        'preferences': {
          'notificationsEnabled': false,
          'ecoModeEnabled': true,
          'temperatureUnit': 'F',
        },
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 7)),
      };

      final profile = UserProfileModel.fromMap(raw, uid: 'user-001');

      expect(profile.uid, 'user-001');
      expect(profile.displayName, 'Aygen Yıldırım');
      expect(profile.homeName, "Aygen'in Evi");
      expect(profile.photoPath, '/data/user/profile.jpg');
      expect(profile.preferences.notificationsEnabled, isFalse);
      expect(profile.preferences.ecoModeEnabled, isTrue);
      expect(profile.preferences.temperatureUnit, 'F');
      expect(profile.initials, 'AY');
    });

    test('toFirestore serializes profile and preferences map', () {
      const profile = UserProfileModel(
        uid: 'user-002',
        email: 'test@nestora.com',
        displayName: 'Test User',
        homeName: 'My House',
        preferences: UserPreferences(
          notificationsEnabled: true,
          ecoModeEnabled: false,
          temperatureUnit: 'C',
        ),
      );

      final payload = profile.toFirestore();
      expect(payload['displayName'], 'Test User');
      expect(payload['homeName'], 'My House');
      expect(payload['preferences']['notificationsEnabled'], isTrue);
      expect(payload['preferences']['ecoModeEnabled'], isFalse);
      expect(payload['preferences']['temperatureUnit'], 'C');
      expect(payload['updatedAt'], isA<FieldValue>());
    });

    test('fromEntity maps domain UserProfile', () {
      const entity = UserProfile(
        uid: 'user-003',
        email: 'demo@nestora.com',
        displayName: 'Demo',
        homeName: 'Demo House',
      );

      final model = UserProfileModel.fromEntity(entity);
      expect(model.uid, entity.uid);
      expect(model.displayName, entity.displayName);
      expect(model.toEntity(), equals(entity));
    });
  });
}

