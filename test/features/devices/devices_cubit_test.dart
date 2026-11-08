import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/di/injection.dart';
import 'package:nestora/core/errors/failures.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/devices/domain/repositories/devices_repository.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_cubit.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Fake DevicesRepository with recorded state writes
class FakeDevicesRepository implements DevicesRepository {
  bool shouldThrow = false;
  String errorMessage = 'Sunucu hatası';
  final List<Device> devices = [];

  final StreamController<List<Device>> _streamController =
      StreamController<List<Device>>.broadcast();

  final Map<String, Map<String, dynamic>> recordedStateUpdates = {};
  String? lastDeletedDeviceId;

  void emitDevices(List<Device> list) {
    devices.clear();
    devices.addAll(list);
    _streamController.add(List.from(devices));
  }

  void emitError(dynamic error) {
    _streamController.addError(error);
  }

  @override
  Stream<List<Device>> watchDevices(String userId) => _streamController.stream;

  @override
  Stream<List<Device>> watchDevicesByRoom(String userId, String roomId) =>
      _streamController.stream.map(
        (list) => list.where((d) => d.roomId == roomId).toList(),
      );

  @override
  Future<Result<List<Device>>> getDevices(String userId) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    return Result.success(devices);
  }

  @override
  Future<Result<Device>> getDeviceById(String userId, String deviceId) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    final device = devices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => throw StateError('Not found'),
    );
    return Result.success(device);
  }

  @override
  Future<Result<void>> createDevice(String userId, Device device) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    devices.add(device);
    _streamController.add(List.from(devices));
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateDevice(String userId, Device device) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    final idx = devices.indexWhere((d) => d.id == device.id);
    if (idx != -1) {
      devices[idx] = device;
      _streamController.add(List.from(devices));
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateDeviceState(
    String userId,
    String deviceId,
    Map<String, dynamic> stateUpdates,
  ) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    recordedStateUpdates[deviceId] = Map.from(stateUpdates);

    final idx = devices.indexWhere((d) => d.id == deviceId);
    if (idx != -1) {
      final cur = devices[idx];
      devices[idx] = cur.copyWith(
        isPoweredOn: stateUpdates['isPoweredOn'] as bool? ?? cur.isPoweredOn,
        brightness: stateUpdates['brightness'] as int? ?? cur.brightness,
        targetTemp: (stateUpdates['targetTemp'] as num?)?.toDouble() ?? cur.targetTemp,
        colorHex: stateUpdates['colorHex'] as String? ?? cur.colorHex,
        colorName: stateUpdates['colorName'] as String? ?? cur.colorName,
        currentPowerWatts:
            (stateUpdates['currentPowerWatts'] as num?)?.toDouble() ??
                cur.currentPowerWatts,
        isFavorite: stateUpdates['isFavorite'] as bool? ?? cur.isFavorite,
      );
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteDevice(String userId, String deviceId) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    lastDeletedDeviceId = deviceId;
    devices.removeWhere((d) => d.id == deviceId);
    _streamController.add(List.from(devices));
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteDevicesByRoom(String userId, String roomId) async {
    devices.removeWhere((d) => d.roomId == roomId);
    return Result.success(null);
  }

  @override
  Future<Result<void>> moveDevicesToRoom(
    String userId,
    String fromRoomId,
    String toRoomId,
  ) async {
    return Result.success(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDevicesRepository fakeRepo;
  late DevicesCubit cubit;

  final sampleDevices = [
    const Device(
      id: 'lamp-1',
      name: 'Salon Lambası',
      roomId: 'living-room',
      type: DeviceType.bulb,
      isPoweredOn: true,
      brightness: 72,
      colorHex: '#E1C1A0',
      colorName: 'Sıcak Günışığı (2700K)',
      currentPowerWatts: 10.8,
      isFavorite: true,
    ),
    const Device(
      id: 'ac-1',
      name: 'Yatak Odası Kliması',
      roomId: 'bedroom',
      type: DeviceType.ac,
      isPoweredOn: false,
      targetTemp: 22.0,
      acMode: AcMode.cool,
      fanSpeed: FanSpeed.mid,
      currentPowerWatts: 0.0,
      isFavorite: false,
    ),
    const Device(
      id: 'plug-1',
      name: 'Kahve Makinesi Prizi',
      roomId: 'kitchen',
      type: DeviceType.plug,
      isPoweredOn: true,
      currentPowerWatts: 240.0,
      isFavorite: true,
    ),
  ];

  setUp(() {
    fakeRepo = FakeDevicesRepository();
    // Use short 20ms debounce for fast deterministic tests
    cubit = DevicesCubit(
      devicesRepository: fakeRepo,
      debounceDuration: const Duration(milliseconds: 20),
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  group('DevicesCubit Initialization & Stream Tests', () {
    test('initial state is DevicesLoaded in offline/demo simulation mode', () {
      expect(cubit.state, isA<DevicesLoaded>());
      final loaded = cubit.state as DevicesLoaded;
      expect(loaded.devices.isNotEmpty, isTrue);
    });

    test('loadDevices with empty userId preserves loaded state', () {
      cubit.loadDevices('   ');
      expect(cubit.state, isA<DevicesLoaded>());
    });

    test('loadDevices updates DevicesLoaded with devices list', () async {
      final states = <DevicesState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.loadDevices('user-1');

      fakeRepo.emitDevices(sampleDevices);
      await pumpEventQueue();

      final loaded = cubit.state as DevicesLoaded;
      expect(loaded.totalCount, 3);
      expect(loaded.activeCount, 2); // lamp-1 and plug-1
      expect(loaded.favoriteDevices.length, 2);
      expect(loaded.totalPowerWatts, 250.8); // 10.8 + 240.0

      await sub.cancel();
    });

    test('loadDevices maintains resilient loaded state on stream error', () async {
      cubit.loadDevices('user-1');
      fakeRepo.emitError('Firestore koptu');
      await pumpEventQueue();

      expect(cubit.state, isA<DevicesLoaded>());
    });
  });

  group('DevicesLoaded Getters & Filtering Tests', () {
    setUp(() async {
      cubit.loadDevices('user-1');
      fakeRepo.emitDevices(sampleDevices);
      await pumpEventQueue();
    });

    test('findDeviceById returns device or null', () {
      final state = cubit.state as DevicesLoaded;
      expect(state.findDeviceById('lamp-1')?.name, 'Salon Lambası');
      expect(state.findDeviceById('unknown'), isNull);
    });

    test('getDevicesByRoom returns devices located in specific room', () {
      final state = cubit.state as DevicesLoaded;
      expect(state.getDevicesByRoom('living-room').length, 1);
      expect(state.getDevicesByRoom('living-room').first.id, 'lamp-1');
      expect(state.getDevicesByRoom('kitchen').first.id, 'plug-1');
    });

    test('selectCategory filters devices and null resets filter', () {
      cubit.selectCategory(DeviceType.bulb);
      var state = cubit.state as DevicesLoaded;
      expect(state.filteredDevices.length, 1);
      expect(state.filteredDevices.first.type, DeviceType.bulb);

      cubit.selectCategory(null);
      state = cubit.state as DevicesLoaded;
      expect(state.filteredDevices.length, 3);
    });

    test('searchDevices filters devices case-insensitively and clearSearch resets it', () {
      cubit.searchDevices('klima');
      var state = cubit.state as DevicesLoaded;
      expect(state.filteredDevices.length, 1);
      expect(state.filteredDevices.first.name, 'Yatak Odası Kliması');

      cubit.clearSearch();
      state = cubit.state as DevicesLoaded;
      expect(state.filteredDevices.length, 3);
    });
  });

  group('Optimistic Updates & Debounced Writes Tests', () {
    setUp(() async {
      cubit.loadDevices('user-1');
      fakeRepo.emitDevices(sampleDevices);
      await pumpEventQueue();
    });

    test('setBrightness updates UI immediately and writes to Firestore after debounce', () async {
      cubit.setBrightness('user-1', 'lamp-1', 40);

      // Instant optimistic update
      var state = cubit.state as DevicesLoaded;
      expect(state.findDeviceById('lamp-1')?.brightness, 40);
      expect(fakeRepo.recordedStateUpdates.containsKey('lamp-1'), isFalse);

      // Wait for 30ms (> 20ms debounce)
      await Future.delayed(const Duration(milliseconds: 30));

      expect(fakeRepo.recordedStateUpdates.containsKey('lamp-1'), isTrue);
      expect(fakeRepo.recordedStateUpdates['lamp-1']?['brightness'], 40);
    });

    test('setTargetTemperature clamps between 16 and 30 and debounces', () async {
      cubit.setTargetTemperature('user-1', 'ac-1', 25.5);

      var state = cubit.state as DevicesLoaded;
      expect(state.findDeviceById('ac-1')?.targetTemp, 25.5);

      await Future.delayed(const Duration(milliseconds: 30));

      expect(fakeRepo.recordedStateUpdates['ac-1']?['targetTemp'], 25.5);
    });

    test('setColor updates colorHex and colorName with debounce', () async {
      cubit.setColor('user-1', 'lamp-1', '#FF0000', 'Kırmızı');

      var state = cubit.state as DevicesLoaded;
      expect(state.findDeviceById('lamp-1')?.colorHex, '#FF0000');

      await Future.delayed(const Duration(milliseconds: 30));

      expect(fakeRepo.recordedStateUpdates['lamp-1']?['colorHex'], '#FF0000');
      expect(fakeRepo.recordedStateUpdates['lamp-1']?['colorName'], 'Kırmızı');
    });

    test('togglePower writes immediately without debounce delay', () async {
      await cubit.togglePower('user-1', 'lamp-1');

      var state = cubit.state as DevicesLoaded;
      expect(state.findDeviceById('lamp-1')?.isPoweredOn, isFalse);
      expect(fakeRepo.recordedStateUpdates['lamp-1']?['isPoweredOn'], isFalse);
    });

    test('toggleFavorite toggles favorite and writes immediately', () async {
      await cubit.toggleFavorite('user-1', 'ac-1');

      var state = cubit.state as DevicesLoaded;
      expect(state.findDeviceById('ac-1')?.isFavorite, isTrue);
      expect(fakeRepo.recordedStateUpdates['ac-1']?['isFavorite'], isTrue);
    });

    test('setAcMode and setFanSpeed write updates immediately', () async {
      await cubit.setAcMode('user-1', 'ac-1', AcMode.heat);
      expect(fakeRepo.recordedStateUpdates['ac-1']?['acMode'], 'heat');

      await cubit.setFanSpeed('user-1', 'ac-1', FanSpeed.high);
      expect(fakeRepo.recordedStateUpdates['ac-1']?['fanSpeed'], 'high');
    });
  });

  group('Quick Scenes Multi-Device Orchestration Tests', () {
    setUp(() async {
      cubit.loadDevices('user-1');
      fakeRepo.emitDevices(sampleDevices);
      await pumpEventQueue();
    });

    test('applyScene home turns on lights and sets AC to 22.0', () async {
      await cubit.applyScene(userId: 'user-1', sceneKey: 'home');

      final state = cubit.state as DevicesLoaded;
      expect(state.feedbackMessage, contains('Evdeyim'));

      final lamp = state.findDeviceById('lamp-1');
      expect(lamp?.isPoweredOn, isTrue);
      expect(lamp?.brightness, 80);

      final ac = state.findDeviceById('ac-1');
      expect(ac?.isPoweredOn, isTrue);
      expect(ac?.targetTemp, 22.0);
    });

    test('applyScene away turns off all devices and zeroes power', () async {
      await cubit.applyScene(userId: 'user-1', sceneKey: 'away');

      final state = cubit.state as DevicesLoaded;
      expect(state.feedbackMessage, contains('Dışarıda'));
      expect(state.activeCount, 0);
      expect(state.totalPowerWatts, 0.0);
    });

    test('applyScene night configures warm dimmed ambient', () async {
      await cubit.applyScene(userId: 'user-1', sceneKey: 'night');

      final state = cubit.state as DevicesLoaded;
      expect(state.feedbackMessage, contains('Gece Modu'));

      final ac = state.findDeviceById('ac-1');
      expect(ac?.targetTemp, 21.0);
      expect(ac?.fanSpeed, FanSpeed.low);
    });
  });

  group('CRUD Operations & Error Handling Tests', () {
    setUp(() async {
      cubit.loadDevices('user-1');
      fakeRepo.emitDevices(sampleDevices);
      await pumpEventQueue();
    });

    test('createDevice validates device name and room', () async {
      await cubit.createDevice(
        userId: 'user-1',
        name: '   ',
        roomId: 'living-room',
        type: DeviceType.bulb,
      );
      var state = cubit.state as DevicesLoaded;
      expect(state.errorMessage, 'Cihaz adı boş bırakılamaz.');

      await cubit.createDevice(
        userId: 'user-1',
        name: 'Masa Lambası',
        roomId: '   ',
        type: DeviceType.bulb,
      );
      state = cubit.state as DevicesLoaded;
      expect(state.errorMessage, 'Lütfen cihaz için bir oda seçiniz.');
    });

    test('createDevice successfully creates new device', () async {
      await cubit.createDevice(
        userId: 'user-1',
        name: 'Yeni TV',
        roomId: 'living-room',
        type: DeviceType.tv,
      );

      final state = cubit.state as DevicesLoaded;
      expect(state.feedbackMessage, 'Cihaz başarıyla eklendi.');
      expect(fakeRepo.devices.length, 4);
      expect(fakeRepo.devices.last.name, 'Yeni TV');
    });

    test('updateDevice updates device and deletes device removes it', () async {
      final updatedLamp = sampleDevices.first.copyWith(name: 'Başucu Lambası');
      await cubit.updateDevice(userId: 'user-1', device: updatedLamp);

      var state = cubit.state as DevicesLoaded;
      expect(state.feedbackMessage, 'Cihaz başarıyla güncellendi.');
      expect(fakeRepo.devices.first.name, 'Başucu Lambası');

      await cubit.deleteDevice(userId: 'user-1', deviceId: 'lamp-1');
      state = cubit.state as DevicesLoaded;
      expect(state.feedbackMessage, 'Cihaz başarıyla silindi.');
      expect(fakeRepo.lastDeletedDeviceId, 'lamp-1');
    });

    test('clearMessages clears feedback and error messages', () async {
      await cubit.deleteDevice(userId: 'user-1', deviceId: 'lamp-1');
      var state = cubit.state as DevicesLoaded;
      expect(state.feedbackMessage, isNotNull);

      cubit.clearMessages();
      state = cubit.state as DevicesLoaded;
      expect(state.feedbackMessage, isNull);
      expect(state.errorMessage, isNull);
    });
  });

  group('ServiceLocator Registration for DevicesCubit', () {
    setUp(() async {
      sl.reset();
      SharedPreferences.setMockInitialValues({});
      final p = await SharedPreferences.getInstance();
      await initDependencies(sharedPreferences: p);
    });

    tearDown(() {
      sl.reset();
    });

    test('DevicesCubit is registered and resolvable from ServiceLocator', () {
      expect(sl.isRegistered<DevicesCubit>(), isTrue);
      final devicesCubit = sl<DevicesCubit>();
      expect(devicesCubit, isA<DevicesCubit>());
      devicesCubit.close();
    });
  });
}
