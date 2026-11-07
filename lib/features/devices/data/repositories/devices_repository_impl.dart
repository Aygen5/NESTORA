import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/device.dart';
import '../../domain/repositories/devices_repository.dart';
import '../datasources/devices_remote_data_source.dart';
import '../models/device_model.dart';

/// Implementation of [DevicesRepository] coordinating between Firestore remote data source and domain layer.
class DevicesRepositoryImpl implements DevicesRepository {
  final DevicesRemoteDataSource remoteDataSource;

  DevicesRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Stream<List<Device>> watchDevices(String userId) {
    return remoteDataSource
        .watchDevices(userId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Stream<List<Device>> watchDevicesByRoom(String userId, String roomId) {
    return remoteDataSource
        .watchDevicesByRoom(userId, roomId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Result<List<Device>>> getDevices(String userId) async {
    try {
      final models = await remoteDataSource.getDevices(userId);
      return Result.success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure('Cihazlar alınırken beklenmeyen bir hata oluştu: $e'),
      );
    }
  }

  @override
  Future<Result<Device>> getDeviceById(String userId, String deviceId) async {
    try {
      final model = await remoteDataSource.getDeviceById(userId, deviceId);
      return Result.success(model.toEntity());
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure('Cihaz bilgisi alınırken beklenmeyen bir hata oluştu: $e'),
      );
    }
  }

  @override
  Future<Result<void>> createDevice(String userId, Device device) async {
    try {
      await remoteDataSource.createDevice(
        userId,
        DeviceModel.fromEntity(device),
      );
      return Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure('Cihaz eklenirken beklenmeyen bir hata oluştu: $e'),
      );
    }
  }

  @override
  Future<Result<void>> updateDevice(String userId, Device device) async {
    try {
      await remoteDataSource.updateDevice(
        userId,
        DeviceModel.fromEntity(device),
      );
      return Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure('Cihaz güncellenirken beklenmeyen bir hata oluştu: $e'),
      );
    }
  }

  @override
  Future<Result<void>> updateDeviceState(
    String userId,
    String deviceId,
    Map<String, dynamic> stateUpdates,
  ) async {
    try {
      await remoteDataSource.updateDeviceState(userId, deviceId, stateUpdates);
      return Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure(
          'Cihaz durumu güncellenirken beklenmeyen bir hata oluştu: $e',
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteDevice(String userId, String deviceId) async {
    try {
      await remoteDataSource.deleteDevice(userId, deviceId);
      return Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure('Cihaz silinirken beklenmeyen bir hata oluştu: $e'),
      );
    }
  }

  @override
  Future<Result<void>> deleteDevicesByRoom(String userId, String roomId) async {
    try {
      await remoteDataSource.deleteDevicesByRoom(userId, roomId);
      return Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure('Oda cihazları silinirken beklenmeyen bir hata oluştu: $e'),
      );
    }
  }

  @override
  Future<Result<void>> moveDevicesToRoom(
    String userId,
    String fromRoomId,
    String toRoomId,
  ) async {
    try {
      await remoteDataSource.moveDevicesToRoom(userId, fromRoomId, toRoomId);
      return Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure(
          'Cihazlar taşınırken beklenmeyen bir hata oluştu: $e',
        ),
      );
    }
  }
}
