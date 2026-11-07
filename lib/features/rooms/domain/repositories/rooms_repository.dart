import '../../../../core/utils/result.dart';
import '../entities/room.dart';

/// Contract for operations on rooms in the user's smart home.
abstract class RoomsRepository {
  /// Real-time stream of all rooms for the given [userId].
  Stream<List<Room>> watchRooms(String userId);

  /// Fetches a list of all rooms for [userId].
  Future<Result<List<Room>>> getRooms(String userId);

  /// Fetches a single room by [roomId].
  Future<Result<Room>> getRoomById(String userId, String roomId);

  /// Creates a new room.
  Future<Result<void>> createRoom(String userId, Room room);

  /// Updates an existing room.
  Future<Result<void>> updateRoom(String userId, Room room);

  /// Deletes a room by [roomId].
  Future<Result<void>> deleteRoom(String userId, String roomId);
}
