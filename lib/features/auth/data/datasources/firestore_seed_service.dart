import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import 'package:flutter/foundation.dart';

/// Service providing initial seed data generation in Cloud Firestore for demo accounts
/// or initial onboarding environments according to the project's data architecture.
class FirestoreSeedService {
  final FirebaseFirestore? firestore;

  const FirestoreSeedService({
    this.firestore,
  });

  /// Checks if the user's rooms collection is empty, and if so, seeds default rooms,
  /// devices, and notifications in an atomic batch. Returns true if seeded.
  Future<bool> seedDemoUserDataIfEmpty(
    String uid, {
    String? displayName,
    String? homeName,
    String? email,
  }) async {
    if (firestore == null) {
      debugPrint('FirestoreSeedService: Firestore instance is null, skipping seed.');
      return false;
    }

    try {
      final userDocRef = firestore!.collection('users').doc(uid);
      final roomsCollection = userDocRef.collection('rooms');

      // Check if user already has seeded rooms
      final existingRooms = await roomsCollection.limit(1).get();
      if (existingRooms.docs.isNotEmpty) {
        debugPrint('FirestoreSeedService: User $uid already has data, skipping seed.');
        return false;
      }

      final batch = firestore!.batch();

      // 1. User Profile Document
      final effectiveName = displayName ?? 'Aygen Yıldırım';
      final effectiveHomeName = homeName ?? "$effectiveName'in Evi";

      batch.set(
        userDocRef,
        {
          'displayName': effectiveName,
          'homeName': effectiveHomeName,
          'email': email ?? 'demo@nestora.app',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'preferences': {
            'notificationsEnabled': true,
            'ecoModeEnabled': true,
            'temperatureUnit': 'C',
          },
        },
        SetOptions(merge: true),
      );

      // 2. Initial Rooms
      final rooms = [
        {
          'id': 'room-1',
          'name': 'Salon',
          'icon': 'chair',
          'targetTemperature': 22.4,
          'humidity': 48,
        },
        {
          'id': 'room-2',
          'name': 'Yatak Odası',
          'icon': 'bed',
          'targetTemperature': 24.0,
          'humidity': 50,
        },
        {
          'id': 'room-3',
          'name': 'Mutfak',
          'icon': 'restaurant',
          'targetTemperature': 21.8,
          'humidity': 52,
        },
        {
          'id': 'room-4',
          'name': 'Çalışma Odası',
          'icon': 'desk',
          'targetTemperature': 23.1,
          'humidity': 45,
        },
      ];

      for (final room in rooms) {
        final docRef = roomsCollection.doc(room['id'] as String);
        batch.set(docRef, {
          'name': room['name'],
          'icon': room['icon'],
          'targetTemperature': room['targetTemperature'],
          'humidity': room['humidity'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Initial Devices
      final devicesCollection = userDocRef.collection('devices');
      final devices = [
        {
          'id': 'dev-1',
          'name': 'Salon Lambası',
          'roomId': 'room-1',
          'type': 'bulb',
          'isOn': true,
          'brightness': 72,
          'color': '#E1C1A0',
          'targetTemperature': null,
          'mode': null,
          'fanSpeed': null,
          'currentPowerWatts': 12.0,
        },
        {
          'id': 'dev-2',
          'name': 'Televizyon',
          'roomId': 'room-1',
          'type': 'tv',
          'isOn': false,
          'brightness': null,
          'color': null,
          'targetTemperature': null,
          'mode': null,
          'fanSpeed': null,
          'currentPowerWatts': 0.0,
        },
        {
          'id': 'dev-3',
          'name': 'Akıllı Priz',
          'roomId': 'room-1',
          'type': 'plug',
          'isOn': true,
          'brightness': null,
          'color': null,
          'targetTemperature': null,
          'mode': null,
          'fanSpeed': null,
          'currentPowerWatts': 120.0,
        },
        {
          'id': 'dev-4',
          'name': 'Masa Lambası',
          'roomId': 'room-4',
          'type': 'bulb',
          'isOn': true,
          'brightness': 85,
          'color': '#EAF0E6',
          'targetTemperature': null,
          'mode': null,
          'fanSpeed': null,
          'currentPowerWatts': 9.0,
        },
        {
          'id': 'dev-5',
          'name': 'Yatak Odası Kliması',
          'roomId': 'room-2',
          'type': 'ac',
          'isOn': true,
          'brightness': null,
          'color': null,
          'targetTemperature': 24.0,
          'mode': 'auto',
          'fanSpeed': 'mid',
          'currentPowerWatts': 850.0,
        },
        {
          'id': 'dev-6',
          'name': 'Komodin Lambası',
          'roomId': 'room-2',
          'type': 'bulb',
          'isOn': true,
          'brightness': 50,
          'color': '#FEDDBB',
          'targetTemperature': null,
          'mode': null,
          'fanSpeed': null,
          'currentPowerWatts': 6.0,
        },
        {
          'id': 'dev-7',
          'name': 'Kahve Makinesi',
          'roomId': 'room-3',
          'type': 'plug',
          'isOn': false,
          'brightness': null,
          'color': null,
          'targetTemperature': null,
          'mode': null,
          'fanSpeed': null,
          'currentPowerWatts': 0.0,
        },
      ];

      for (final dev in devices) {
        final docRef = devicesCollection.doc(dev['id'] as String);
        batch.set(docRef, {
          'id': dev['id'],
          'name': dev['name'],
          'roomId': dev['roomId'],
          'type': dev['type'],
          'isOn': dev['isOn'],
          'isPoweredOn': dev['isOn'],
          'brightness': dev['brightness'],
          'color': dev['color'],
          'colorHex': dev['color'],
          'colorName': 'Sıcak Günışığı (2700K)',
          'targetTemp': dev['targetTemperature'],
          'targetTemperature': dev['targetTemperature'],
          'mode': dev['mode'],
          'fanSpeed': dev['fanSpeed'],
          'currentPowerWatts': dev['currentPowerWatts'],
          'isFavorite': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 4. Initial Notifications
      final notificationsCollection = userDocRef.collection('notifications');
      final notifications = [
        {
          'id': 'notif-1',
          'title': 'Salon Lambası açıldı.',
          'message': 'Salon ortamında parlaklık %72 olarak devreye girdi.',
          'type': 'device',
          'isRead': false,
          'relatedRoomId': 'room-1',
          'relatedDeviceId': 'dev-1',
        },
        {
          'id': 'notif-2',
          'title': 'Masa Lambası parlaklığı güncellendi.',
          'message': 'Çalışma Odası için odak aydınlatması güncellendi.',
          'type': 'device',
          'isRead': false,
          'relatedRoomId': 'room-4',
          'relatedDeviceId': 'dev-4',
        },
        {
          'id': 'notif-3',
          'title': 'Yatak Odası kliması açıldı.',
          'message': 'Hedef sıcaklık 24°C olarak ayarlandı.',
          'type': 'device',
          'isRead': true,
          'relatedRoomId': 'room-2',
          'relatedDeviceId': 'dev-5',
        },
      ];

      for (final notif in notifications) {
        final docRef = notificationsCollection.doc(notif['id'] as String);
        batch.set(docRef, {
          'id': notif['id'],
          'title': notif['title'],
          'message': notif['message'],
          'type': notif['type'],
          'isRead': notif['isRead'],
          'relatedRoomId': notif['relatedRoomId'],
          'relatedDeviceId': notif['relatedDeviceId'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('FirestoreSeedService: Successfully seeded initial data for demo user $uid.');
      return true;
    } catch (e) {
      debugPrint('FirestoreSeedService: Seed operation notice ($e)');
      return false;
    }
  }
}

