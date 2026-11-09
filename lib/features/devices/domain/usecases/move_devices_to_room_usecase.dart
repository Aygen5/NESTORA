import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/devices_repository.dart';

class MoveDevicesToRoomParams {
  final String userId;
  final String fromRoomId;
  final String toRoomId;

  const MoveDevicesToRoomParams({
    required this.userId,
    required this.fromRoomId,
    required this.toRoomId,
  });
}

class MoveDevicesToRoomUseCase implements UseCase<void, MoveDevicesToRoomParams> {
  final DevicesRepository repository;

  const MoveDevicesToRoomUseCase(this.repository);

  @override
  Future<Result<void>> call(MoveDevicesToRoomParams params) {
    return repository.moveDevicesToRoom(
      params.userId,
      params.fromRoomId,
      params.toRoomId,
    );
  }
}
