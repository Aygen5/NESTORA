import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/device.dart';
import '../repositories/devices_repository.dart';

class UpdateDeviceParams {
  final String userId;
  final Device device;

  const UpdateDeviceParams({required this.userId, required this.device});
}

class UpdateDeviceUseCase implements UseCase<void, UpdateDeviceParams> {
  final DevicesRepository repository;

  const UpdateDeviceUseCase(this.repository);

  @override
  Future<Result<void>> call(UpdateDeviceParams params) {
    return repository.updateDevice(params.userId, params.device);
  }
}

