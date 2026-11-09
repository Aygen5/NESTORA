import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/devices_repository.dart';

class DeleteDeviceParams {
  final String userId;
  final String deviceId;

  const DeleteDeviceParams({required this.userId, required this.deviceId});
}

class DeleteDeviceUseCase implements UseCase<void, DeleteDeviceParams> {
  final DevicesRepository repository;

  const DeleteDeviceUseCase(this.repository);

  @override
  Future<Result<void>> call(DeleteDeviceParams params) {
    return repository.deleteDevice(params.userId, params.deviceId);
  }
}

