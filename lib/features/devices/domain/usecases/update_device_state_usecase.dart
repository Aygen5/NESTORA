import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/devices_repository.dart';

class UpdateDeviceStateParams {
  final String userId;
  final String deviceId;
  final Map<String, dynamic> stateUpdates;

  const UpdateDeviceStateParams({
    required this.userId,
    required this.deviceId,
    required this.stateUpdates,
  });
}

class UpdateDeviceStateUseCase implements UseCase<void, UpdateDeviceStateParams> {
  final DevicesRepository repository;

  const UpdateDeviceStateUseCase(this.repository);

  @override
  Future<Result<void>> call(UpdateDeviceStateParams params) {
    return repository.updateDeviceState(
      params.userId,
      params.deviceId,
      params.stateUpdates,
    );
  }
}

