import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/room.dart';
import '../repositories/rooms_repository.dart';

class UpdateRoomParams {
  final String userId;
  final Room room;

  const UpdateRoomParams({required this.userId, required this.room});
}

class UpdateRoomUseCase implements UseCase<void, UpdateRoomParams> {
  final RoomsRepository repository;

  const UpdateRoomUseCase(this.repository);

  @override
  Future<Result<void>> call(UpdateRoomParams params) {
    return repository.updateRoom(params.userId, params.room);
  }
}

