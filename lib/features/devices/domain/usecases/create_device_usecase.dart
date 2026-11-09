import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/device.dart';
import '../repositories/devices_repository.dart';

class CreateDeviceParams {
  final String userId;
  final Device device;

  const CreateDeviceParams({required this.userId, required this.device});
}

class CreateDeviceUseCase implements UseCase<void, CreateDeviceParams> {
  final DevicesRepository repository;

  const CreateDeviceUseCase(this.repository);

  @override
  Future<Result<void>> call(CreateDeviceParams params) {
    return repository.createDevice(params.userId, params.device);
  }
}

