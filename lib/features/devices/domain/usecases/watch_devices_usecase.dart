import '../../../../core/usecases/usecase.dart';
import '../entities/device.dart';
import '../repositories/devices_repository.dart';

class WatchDevicesUseCase implements StreamUseCase<List<Device>, String> {
  final DevicesRepository repository;

  const WatchDevicesUseCase(this.repository);

  @override
  Stream<List<Device>> call(String userId) {
    return repository.watchDevices(userId);
  }
}

