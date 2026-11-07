import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/room.dart';
import '../../domain/repositories/rooms_repository.dart';
import '../datasources/rooms_remote_data_source.dart';
import '../models/room_model.dart';

/// Implementation of [RoomsRepository] coordinating between Firestore remote data source and domain layer.
class RoomsRepositoryImpl implements RoomsRepository {
  final RoomsRemoteDataSource remoteDataSource;

  RoomsRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Stream<List<Room>> watchRooms(String userId) {
    return remoteDataSource
        .watchRooms(userId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Result<List<Room>>> getRooms(String userId) async {
    try {
      final models = await remoteDataSource.getRooms(userId);
      return Result.success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure('Odalar alınırken beklenmeyen bir hata oluştu: $e'),
      );
    }
  }

  @override
  Future<Result<Room>> getRoomById(String userId, String roomId) async {
    try {
      final model = await remoteDataSource.getRoomById(userId, roomId);
      return Result.success(model.toEntity());
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure('Oda bilgisi alınırken beklenmeyen bir hata oluştu: $e'),
      );
    }
  }

  @override
  Future<Result<void>> createRoom(String userId, Room room) async {
    try {
      await remoteDataSource.createRoom(
        userId,
        RoomModel.fromEntity(room),
      );
      return Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure('Oda eklenirken beklenmeyen bir hata oluştu: $e'),
      );
    }
  }

  @override
  Future<Result<void>> updateRoom(String userId, Room room) async {
    try {
      await remoteDataSource.updateRoom(
        userId,
        RoomModel.fromEntity(room),
      );
      return Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure('Oda güncellenirken beklenmeyen bir hata oluştu: $e'),
      );
    }
  }

  @override
  Future<Result<void>> deleteRoom(String userId, String roomId) async {
    try {
      await remoteDataSource.deleteRoom(userId, roomId);
      return Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure('Oda silinirken beklenmeyen bir hata oluştu: $e'),
      );
    }
  }
}
