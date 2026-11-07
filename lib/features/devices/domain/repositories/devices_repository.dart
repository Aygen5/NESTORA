import '../../../../core/utils/result.dart';
import '../entities/device.dart';

/// Contract for operations on virtual smart devices in the user's home.
abstract class DevicesRepository {
  /// Real-time stream of all devices belonging to [userId].
  Stream<List<Device>> watchDevices(String userId);

  /// Real-time stream of devices located in a specific [roomId].
  Stream<List<Device>> watchDevicesByRoom(String userId, String roomId);

  /// Fetches a list of all devices belonging to [userId].
  Future<Result<List<Device>>> getDevices(String userId);

  /// Fetches a single device by [deviceId].
  Future<Result<Device>> getDeviceById(String userId, String deviceId);

  /// Creates a new device in Firestore.
  Future<Result<void>> createDevice(String userId, Device device);

  /// Updates all attributes of an existing device.
  Future<Result<void>> updateDevice(String userId, Device device);

  /// Partial update for device state properties (e.g. brightness, isPoweredOn, targetTemp, acMode).
  Future<Result<void>> updateDeviceState(
    String userId,
    String deviceId,
    Map<String, dynamic> stateUpdates,
  );

  /// Deletes a single device by [deviceId].
  Future<Result<void>> deleteDevice(String userId, String deviceId);

  /// Deletes all devices located in [roomId] atomically.
  Future<Result<void>> deleteDevicesByRoom(String userId, String roomId);

  /// Reassigns all devices from [fromRoomId] to [toRoomId] atomically.
  Future<Result<void>> moveDevicesToRoom(
    String userId,
    String fromRoomId,
    String toRoomId,
  );
}
