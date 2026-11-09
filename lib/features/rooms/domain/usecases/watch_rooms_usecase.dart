import '../../../../core/usecases/usecase.dart';
import '../entities/room.dart';
import '../repositories/rooms_repository.dart';

class WatchRoomsUseCase implements StreamUseCase<List<Room>, String> {
  final RoomsRepository repository;

  const WatchRoomsUseCase(this.repository);

  @override
  Stream<List<Room>> call(String userId) {
    return repository.watchRooms(userId);
  }
}
