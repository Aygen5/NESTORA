import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/room.dart';
import '../repositories/rooms_repository.dart';

class CreateRoomParams {
  final String userId;
  final Room room;

  const CreateRoomParams({required this.userId, required this.room});
}

class CreateRoomUseCase implements UseCase<void, CreateRoomParams> {
  final RoomsRepository repository;

  const CreateRoomUseCase(this.repository);

  @override
  Future<Result<void>> call(CreateRoomParams params) {
    return repository.createRoom(params.userId, params.room);
  }
}
