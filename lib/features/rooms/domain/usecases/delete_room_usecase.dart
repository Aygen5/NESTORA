import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/rooms_repository.dart';

class DeleteRoomParams {
  final String userId;
  final String roomId;

  const DeleteRoomParams({required this.userId, required this.roomId});
}

class DeleteRoomUseCase implements UseCase<void, DeleteRoomParams> {
  final RoomsRepository repository;

  const DeleteRoomUseCase(this.repository);

  @override
  Future<Result<void>> call(DeleteRoomParams params) {
    return repository.deleteRoom(params.userId, params.roomId);
  }
}
