import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import '../../../../core/errors/exceptions.dart';
import '../models/device_model.dart';

/// Contract for Remote Data Source managing virtual Device documents in Cloud Firestore.
abstract class DevicesRemoteDataSource {
  /// Real-time stream of all devices belonging to [userId].
  Stream<List<DeviceModel>> watchDevices(String userId);

  /// Real-time stream of devices located in a specific [roomId].
  Stream<List<DeviceModel>> watchDevicesByRoom(String userId, String roomId);

  /// One-time fetch of all devices belonging to [userId].
  Future<List<DeviceModel>> getDevices(String userId);

  /// Fetches a specific device document by [deviceId].
  Future<DeviceModel> getDeviceById(String userId, String deviceId);

  /// Creates a new device document in Firestore.
  Future<void> createDevice(String userId, DeviceModel device);

  /// Updates all attributes of an existing device.
  Future<void> updateDevice(String userId, DeviceModel device);

  /// Partial update for high-frequency or specific virtual device state changes
  /// (e.g. brightness, isOn, targetTemperature, acMode) with automatic server timestamp.
  Future<void> updateDeviceState(
    String userId,
    String deviceId,
    Map<String, dynamic> stateUpdates,
  );

  /// Deletes a device document by [deviceId].
  Future<void> deleteDevice(String userId, String deviceId);

  /// Deletes all devices associated with [roomId] in a single atomic batch.
  Future<void> deleteDevicesByRoom(String userId, String roomId);

  /// Reassigns all devices in [fromRoomId] to [toRoomId] in a single atomic batch.
  Future<void> moveDevicesToRoom(
    String userId,
    String fromRoomId,
    String toRoomId,
  );
}

/// Firebase implementation of [DevicesRemoteDataSource].
class DevicesRemoteDataSourceImpl implements DevicesRemoteDataSource {
  final FirebaseFirestore? firestore;

  DevicesRemoteDataSourceImpl({
    this.firestore,
  });

  FirebaseFirestore get _db {
    if (firestore == null) {
      throw const ServerException('Firestore servisi hazır değil.');
    }
    return firestore!;
  }

  CollectionReference<Map<String, dynamic>> _devicesRef(String userId) {
    if (userId.trim().isEmpty) {
      throw const ServerException('Geçersiz kullanıcı kimliği.');
    }
    return _db.collection('users').doc(userId.trim()).collection('devices');
  }

  @override
  Stream<List<DeviceModel>> watchDevices(String userId) {
    try {
      return _devicesRef(userId)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => DeviceModel.fromFirestore(doc))
              .toList());
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Cihazlar dinlenirken hata oluştu.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Cihazlar dinlenirken beklenmeyen hata oluştu: $e');
    }
  }

  @override
  Stream<List<DeviceModel>> watchDevicesByRoom(String userId, String roomId) {
    try {
      return _devicesRef(userId)
          .where('roomId', isEqualTo: roomId.trim())
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => DeviceModel.fromFirestore(doc))
              .toList());
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Oda cihazları dinlenirken hata oluştu.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Oda cihazları dinlenirken beklenmeyen hata: $e');
    }
  }

  @override
  Future<List<DeviceModel>> getDevices(String userId) async {
    try {
      final snapshot = await _devicesRef(userId).get();
      return snapshot.docs
          .map((doc) => DeviceModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Cihazlar getirilemedi.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Cihazlar getirilirken beklenmeyen hata: $e');
    }
  }

  @override
  Future<DeviceModel> getDeviceById(String userId, String deviceId) async {
    try {
      final doc = await _devicesRef(userId).doc(deviceId.trim()).get();
      if (!doc.exists) {
        throw const ServerException('Cihaz bulunamadı.', code: 'not-found');
      }
      return DeviceModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Cihaz bilgisi alınamadı.',
        code: e.code,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Cihaz bilgisi alınırken beklenmeyen hata: $e');
    }
  }

  @override
  Future<void> createDevice(String userId, DeviceModel device) async {
    try {
      final docRef = device.id.trim().isNotEmpty
          ? _devicesRef(userId).doc(device.id.trim())
          : _devicesRef(userId).doc();
      await docRef.set(device.toFirestore(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Cihaz eklenirken hata oluştu.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Cihaz eklenirken beklenmeyen hata: $e');
    }
  }

  @override
  Future<void> updateDevice(String userId, DeviceModel device) async {
    try {
      await _devicesRef(userId)
          .doc(device.id.trim())
          .set(device.toFirestore(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Cihaz güncellenirken hata oluştu.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Cihaz güncellenirken beklenmeyen hata: $e');
    }
  }

  @override
  Future<void> updateDeviceState(
    String userId,
    String deviceId,
    Map<String, dynamic> stateUpdates,
  ) async {
    try {
      final payload = Map<String, dynamic>.from(stateUpdates);
      payload['updatedAt'] = FieldValue.serverTimestamp();

      // Ensure both boolean flags are synchronized for legacy & current SDK models
      if (payload.containsKey('isPoweredOn') && !payload.containsKey('isOn')) {
        payload['isOn'] = payload['isPoweredOn'];
      } else if (payload.containsKey('isOn') && !payload.containsKey('isPoweredOn')) {
        payload['isPoweredOn'] = payload['isOn'];
      }

      await _devicesRef(userId).doc(deviceId.trim()).set(payload, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Cihaz durumu güncellenirken hata oluştu.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Cihaz durumu güncellenirken beklenmeyen hata: $e');
    }
  }

  @override
  Future<void> deleteDevice(String userId, String deviceId) async {
    try {
      await _devicesRef(userId).doc(deviceId.trim()).delete();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Cihaz silinirken hata oluştu.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Cihaz silinirken beklenmeyen hata: $e');
    }
  }

  @override
  Future<void> deleteDevicesByRoom(String userId, String roomId) async {
    try {
      final snapshot = await _devicesRef(userId)
          .where('roomId', isEqualTo: roomId.trim())
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Oda cihazları silinirken hata oluştu.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Oda cihazları silinirken beklenmeyen hata: $e');
    }
  }

  @override
  Future<void> moveDevicesToRoom(
    String userId,
    String fromRoomId,
    String toRoomId,
  ) async {
    try {
      final snapshot = await _devicesRef(userId)
          .where('roomId', isEqualTo: fromRoomId.trim())
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'roomId': toRoomId.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Cihazlar taşınırken hata oluştu.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Cihazlar taşınırken beklenmeyen hata: $e');
    }
  }
}
