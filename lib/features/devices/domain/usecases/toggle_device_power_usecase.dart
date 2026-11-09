import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/devices_repository.dart';

class ToggleDevicePowerParams {
  final String userId;
  final String deviceId;
  final bool currentPowerState;

  const ToggleDevicePowerParams({
    required this.userId,
    required this.deviceId,
    required this.currentPowerState,
  });
}

class ToggleDevicePowerUseCase implements UseCase<void, ToggleDevicePowerParams> {
  final DevicesRepository repository;

  const ToggleDevicePowerUseCase(this.repository);

  @override
  Future<Result<void>> call(ToggleDevicePowerParams params) {
    final nextState = !params.currentPowerState;
    return repository.updateDeviceState(
      params.userId,
      params.deviceId,
      {
        'isOn': nextState,
        'isPoweredOn': nextState,
      },
    );
  }
}
