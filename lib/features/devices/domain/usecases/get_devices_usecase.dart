import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/device.dart';
import '../repositories/devices_repository.dart';

class GetDevicesUseCase implements UseCase<List<Device>, String> {
  final DevicesRepository repository;

  const GetDevicesUseCase(this.repository);

  @override
  Future<Result<List<Device>>> call(String userId) {
    return repository.getDevices(userId);
  }
}
