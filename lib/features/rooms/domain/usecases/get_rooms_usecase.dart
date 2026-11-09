import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/room.dart';
import '../repositories/rooms_repository.dart';

class GetRoomsUseCase implements UseCase<List<Room>, String> {
  final RoomsRepository repository;

  const GetRoomsUseCase(this.repository);

  @override
  Future<Result<List<Room>>> call(String userId) {
    return repository.getRooms(userId);
  }
}

