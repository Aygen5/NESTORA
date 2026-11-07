import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/crashlytics_service.dart';
import '../../domain/entities/device.dart';
import '../../domain/repositories/devices_repository.dart';
import 'devices_state.dart';

/// Single Source of Truth for all simulated smart devices in Nestora.
///
/// Features:
/// - Real-time sync with Cloud Firestore.
/// - Optimistic UI updates for 0-latency slider / dial / toggle responsiveness.
/// - High-frequency update debouncing (default: 300ms) to conserve Firestore write quota on Spark plan.
/// - Quick Scenes ("Evdeyim", "Gündüz", "Gece Modu", "Dışarıda") multi-device orchestration.
/// - Dispatches privacy-safe analytics events and logs errors to Crashlytics.
class DevicesCubit extends Cubit<DevicesState> {
  final DevicesRepository devicesRepository;
  final Duration debounceDuration;
  final AnalyticsService? analyticsService;
  final CrashlyticsService? crashlyticsService;

  StreamSubscription<List<Device>>? _devicesSubscription;
  String? _currentUserId;
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, Map<String, dynamic>> _pendingUpdates = {};

  DevicesCubit({
    required this.devicesRepository,
    this.debounceDuration = AppConstants.sliderDebounceDuration,
    this.analyticsService,
    this.crashlyticsService,
  }) : super(const DevicesInitial());

  /// Loads and listens to real-time updates for all devices belonging to [userId].
  void loadDevices(String userId) {
    final cleanUid = userId.trim();
    if (cleanUid.isEmpty) {
      emit(const DevicesError('Geçersiz kullanıcı kimliği.'));
      return;
    }
    _currentUserId = cleanUid;

    if (state is! DevicesLoaded) {
      emit(const DevicesLoading());
    }

    _devicesSubscription?.cancel();

    _devicesSubscription = devicesRepository.watchDevices(cleanUid).listen(
      (devices) {
        if (state is DevicesLoaded) {
          final current = state as DevicesLoaded;

          // Merge local in-flight debounced updates if any exist
          final mergedDevices = devices.map((incoming) {
            final pending = _pendingUpdates[incoming.id];
            if (pending != null && pending.isNotEmpty) {
              return incoming.copyWith(
                brightness: pending['brightness'] as int? ?? incoming.brightness,
                targetTemp:
                    (pending['targetTemp'] as num?)?.toDouble() ?? incoming.targetTemp,
                colorHex: pending['colorHex'] as String? ?? incoming.colorHex,
                colorName: pending['colorName'] as String? ?? incoming.colorName,
                isPoweredOn: pending['isPoweredOn'] as bool? ?? incoming.isPoweredOn,
                acMode: pending['acMode'] != null
                    ? AcMode.fromString(pending['acMode'] as String)
                    : incoming.acMode,
                fanSpeed: pending['fanSpeed'] != null
                    ? FanSpeed.fromString(pending['fanSpeed'] as String)
                    : incoming.fanSpeed,
              );
            }
            return incoming;
          }).toList();

          emit(current.copyWith(devices: mergedDevices, isSaving: false));
        } else {
          emit(DevicesLoaded(devices: devices));
        }
      },
      onError: (error, stack) {
        crashlyticsService?.recordError(
          error,
          stack,
          reason: 'Devices watchDevices stream error for user: $cleanUid',
        );
        emit(DevicesError('Cihazlar yüklenirken hata oluştu: $error'));
      },
    );
  }

  /// Sets brightness (0-100%) for a lighting device with optimistic UI and 300ms Firestore debounce.
  void setBrightness(String userId, String deviceId, int brightness) {
    if (state is! DevicesLoaded) return;
    final current = state as DevicesLoaded;
    final cleanBrightness = brightness.clamp(AppConstants.minBrightness, AppConstants.maxBrightness);

    final device = current.findDeviceById(deviceId);
    if (device == null) return;

    final isNowOn = cleanBrightness > 0 ? true : device.isPoweredOn;
    final calculatedWatts = isNowOn ? (cleanBrightness / 100.0) * 15.0 : 0.0;

    final updatedDevice = device.copyWith(
      brightness: cleanBrightness,
      isPoweredOn: isNowOn,
      currentPowerWatts: double.parse(calculatedWatts.toStringAsFixed(1)),
    );

    _optimisticUpdate(updatedDevice);

    _debounceWrite(
      userId: userId,
      deviceId: deviceId,
      updates: {
        'brightness': cleanBrightness,
        'isPoweredOn': isNowOn,
        'currentPowerWatts': updatedDevice.currentPowerWatts,
      },
    );
  }

  /// Sets target temperature (16.0°C - 30.0°C, 0.5°C step) with optimistic UI and 300ms debounce.
  void setTargetTemperature(String userId, String deviceId, double targetTemp) {
    if (state is! DevicesLoaded) return;
    final current = state as DevicesLoaded;

    final cleanTemp = ((targetTemp * 2).round() / 2.0).clamp(
      AppConstants.minClimateTemp,
      AppConstants.maxClimateTemp,
    );

    final device = current.findDeviceById(deviceId);
    if (device == null) return;

    final updatedDevice = device.copyWith(targetTemp: cleanTemp);
    _optimisticUpdate(updatedDevice);

    _debounceWrite(
      userId: userId,
      deviceId: deviceId,
      updates: {'targetTemp': cleanTemp},
    );
  }

  /// Sets light color/glow hex and name with optimistic UI and 300ms debounce.
  void setColor(
    String userId,
    String deviceId,
    String colorHex,
    String colorName,
  ) {
    if (state is! DevicesLoaded) return;
    final current = state as DevicesLoaded;

    final device = current.findDeviceById(deviceId);
    if (device == null) return;

    final updatedDevice = device.copyWith(
      colorHex: colorHex.trim(),
      colorName: colorName.trim(),
    );
    _optimisticUpdate(updatedDevice);

    _debounceWrite(
      userId: userId,
      deviceId: deviceId,
      updates: {
        'colorHex': colorHex.trim(),
        'colorName': colorName.trim(),
      },
    );
  }

  /// Toggles device power on/off with optimistic UI and immediate synchronization.
  Future<void> togglePower(String userId, String deviceId) async {
    if (state is! DevicesLoaded) return;
    final current = state as DevicesLoaded;

    final device = current.findDeviceById(deviceId);
    if (device == null) return;

    final newPowerState = !device.isPoweredOn;
    double newWatts = 0.0;
    if (newPowerState) {
      if (device.type == DeviceType.bulb) {
        newWatts = (device.brightness / 100.0) * 15.0;
      } else if (device.type == DeviceType.ac) {
        newWatts = 1200.0;
      } else if (device.type == DeviceType.plug) {
        newWatts = 240.0;
      } else if (device.type == DeviceType.tv) {
        newWatts = 95.0;
      } else if (device.type == DeviceType.security) {
        newWatts = 4.5;
      } else {
        newWatts = 45.0;
      }
    }

    final updatedDevice = device.copyWith(
      isPoweredOn: newPowerState,
      currentPowerWatts: double.parse(newWatts.toStringAsFixed(1)),
    );

    _optimisticUpdate(updatedDevice);

    analyticsService?.logDeviceToggle(
      deviceType: device.type.name,
      isPoweredOn: newPowerState,
    );

    // Cancel pending debounce for power to ensure immediate consistent state
    _debounceTimers[deviceId]?.cancel();
    _pendingUpdates.remove(deviceId);

    await devicesRepository.updateDeviceState(
      userId,
      deviceId,
      {
        'isPoweredOn': newPowerState,
        'currentPowerWatts': updatedDevice.currentPowerWatts,
      },
    );
  }

  /// Toggles favorite flag on/off.
  Future<void> toggleFavorite(String userId, String deviceId) async {
    if (state is! DevicesLoaded) return;
    final current = state as DevicesLoaded;

    final device = current.findDeviceById(deviceId);
    if (device == null) return;

    final newFav = !device.isFavorite;
    final updatedDevice = device.copyWith(isFavorite: newFav);
    _optimisticUpdate(updatedDevice);

    await devicesRepository.updateDeviceState(
      userId,
      deviceId,
      {'isFavorite': newFav},
    );
  }

  /// Sets air conditioner operating mode.
  Future<void> setAcMode(String userId, String deviceId, AcMode mode) async {
    if (state is! DevicesLoaded) return;
    final current = state as DevicesLoaded;

    final device = current.findDeviceById(deviceId);
    if (device == null) return;

    final updatedDevice = device.copyWith(acMode: mode);
    _optimisticUpdate(updatedDevice);

    await devicesRepository.updateDeviceState(
      userId,
      deviceId,
      {'acMode': mode.toShortString()},
    );
  }

  /// Sets air conditioner fan speed.
  Future<void> setFanSpeed(String userId, String deviceId, FanSpeed speed) async {
    if (state is! DevicesLoaded) return;
    final current = state as DevicesLoaded;

    final device = current.findDeviceById(deviceId);
    if (device == null) return;

    final updatedDevice = device.copyWith(fanSpeed: speed);
    _optimisticUpdate(updatedDevice);

    await devicesRepository.updateDeviceState(
      userId,
      deviceId,
      {'fanSpeed': speed.toShortString()},
    );
  }

  /// Applies one of the 4 quick smart home scenes across all matching virtual devices.
  /// Supported scene keys: 'home', 'day', 'night', 'away'
  Future<void> applyScene({
    required String userId,
    required String sceneKey,
  }) async {
    if (state is! DevicesLoaded) return;
    final current = state as DevicesLoaded;
    final normalized = sceneKey
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g');

    final updatedDevices = <Device>[];
    String sceneDisplayName = 'Senaryo';

    for (final dev in current.devices) {
      Device updated = dev;

      if (normalized == 'home' || normalized == 'evdeyim' || normalized.contains('evde')) {
        sceneDisplayName = 'Evdeyim';
        if (dev.type == DeviceType.bulb) {
          updated = dev.copyWith(
            isPoweredOn: true,
            brightness: 80,
            currentPowerWatts: 12.0,
          );
        } else if (dev.type == DeviceType.ac) {
          updated = dev.copyWith(
            isPoweredOn: true,
            targetTemp: 22.0,
            acMode: AcMode.auto,
            currentPowerWatts: 1100.0,
          );
        }
      } else if (normalized == 'day' || normalized == 'gunduz' || normalized.contains('gunduz')) {
        sceneDisplayName = 'Gündüz';
        if (dev.type == DeviceType.bulb) {
          updated = dev.copyWith(
            isPoweredOn: false,
            currentPowerWatts: 0.0,
          );
        } else if (dev.type == DeviceType.ac) {
          updated = dev.copyWith(
            targetTemp: 24.0,
            acMode: AcMode.auto,
          );
        }
      } else if (normalized == 'night' || normalized == 'gece' || normalized.contains('gece')) {
        sceneDisplayName = 'Gece Modu';
        if (dev.type == DeviceType.bulb) {
          // Keep only 1 warm night lamp or turn off
          final isNightLight = dev.name.toLowerCase().contains('gece') ||
              dev.name.toLowerCase().contains('yatak');
          updated = dev.copyWith(
            isPoweredOn: isNightLight,
            brightness: isNightLight ? 15 : 0,
            colorHex: '#FFC89B',
            colorName: 'Sıcak Amber (2200K)',
            currentPowerWatts: isNightLight ? 2.5 : 0.0,
          );
        } else if (dev.type == DeviceType.ac) {
          updated = dev.copyWith(
            targetTemp: 21.0,
            fanSpeed: FanSpeed.low,
          );
        }
      } else if (normalized == 'away' || normalized == 'disarida' || normalized.contains('disari')) {
        sceneDisplayName = 'Dışarıda';
        updated = dev.copyWith(
          isPoweredOn: false,
          currentPowerWatts: 0.0,
        );
      }

      updatedDevices.add(updated);
    }

    analyticsService?.logScenarioActivated(scenarioName: sceneDisplayName);

    emit(current.copyWith(
      devices: updatedDevices,
      feedbackMessage: '$sceneDisplayName senaryosu uygulandı.',
    ));

    // Persist changes to Firestore
    for (final dev in updatedDevices) {
      await devicesRepository.updateDeviceState(userId, dev.id, {
        'isPoweredOn': dev.isPoweredOn,
        'brightness': dev.brightness,
        'targetTemp': dev.targetTemp,
        'colorHex': dev.colorHex,
        'colorName': dev.colorName,
        'acMode': dev.acMode.toShortString(),
        'fanSpeed': dev.fanSpeed.toShortString(),
        'currentPowerWatts': dev.currentPowerWatts,
      });
    }
  }

  /// Creates a new virtual device in Firestore.
  Future<void> createDevice({
    required String userId,
    required String name,
    required String roomId,
    required DeviceType type,
    int? brightness,
    double? targetTemp,
    String? colorHex,
    String? colorName,
    bool? isPoweredOn,
    bool? isFavorite,
    AcMode? acMode,
    FanSpeed? fanSpeed,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      _emitErrorMessage('Cihaz adı boş bırakılamaz.');
      return;
    }

    final cleanRoomId = roomId.trim();
    if (cleanRoomId.isEmpty) {
      _emitErrorMessage('Lütfen cihaz için bir oda seçiniz.');
      return;
    }

    _setSaving(true);

    final deviceId = 'device-${DateTime.now().millisecondsSinceEpoch}';
    final newDevice = Device(
      id: deviceId,
      name: cleanName,
      roomId: cleanRoomId,
      type: type,
      isPoweredOn: isPoweredOn ?? false,
      isFavorite: isFavorite ?? false,
      brightness: brightness ?? (type == DeviceType.bulb ? 72 : 0),
      targetTemp: targetTemp ?? (type == DeviceType.ac ? 22.0 : 20.0),
      acMode: acMode ?? AcMode.auto,
      fanSpeed: fanSpeed ?? FanSpeed.mid,
      colorHex: colorHex ?? '#E1C1A0',
      colorName: colorName ?? 'Sıcak Günışığı (2700K)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await devicesRepository.createDevice(userId, newDevice);

    if (result.isSuccess) {
      analyticsService?.logDeviceCreated(deviceType: newDevice.type.name);
      _emitSuccessMessage('Cihaz başarıyla eklendi.');
    } else {
      crashlyticsService?.recordError(
        result.failure,
        null,
        reason: 'createDevice failure: ${result.failure.message}',
      );
      _emitErrorMessage(result.failure.message);
    }
  }

  /// Updates all attributes of an existing device.
  Future<void> updateDevice({
    required String userId,
    required Device device,
  }) async {
    final cleanName = device.name.trim();
    if (cleanName.isEmpty) {
      _emitErrorMessage('Cihaz adı boş bırakılamaz.');
      return;
    }

    _setSaving(true);

    final updated = device.copyWith(
      name: cleanName,
      updatedAt: DateTime.now(),
    );

    final result = await devicesRepository.updateDevice(userId, updated);

    if (result.isSuccess) {
      _emitSuccessMessage('Cihaz başarıyla güncellendi.');
    } else {
      crashlyticsService?.recordError(
        result.failure,
        null,
        reason: 'updateDevice failure: ${result.failure.message}',
      );
      _emitErrorMessage(result.failure.message);
    }
  }

  /// Deletes a device from Firestore.
  Future<void> deleteDevice({
    required String userId,
    required String deviceId,
  }) async {
    _setSaving(true);

    _debounceTimers[deviceId]?.cancel();
    _pendingUpdates.remove(deviceId);

    final result = await devicesRepository.deleteDevice(userId, deviceId);

    if (result.isSuccess) {
      _emitSuccessMessage('Cihaz başarıyla silindi.');
    } else {
      crashlyticsService?.recordError(
        result.failure,
        null,
        reason: 'deleteDevice failure: ${result.failure.message}',
      );
      _emitErrorMessage(result.failure.message);
    }
  }

  /// Filters devices by category. Pass `null` for "All".
  void selectCategory(DeviceType? category) {
    if (state is DevicesLoaded) {
      final current = state as DevicesLoaded;
      emit(current.copyWith(
        selectedCategory: category,
        clearCategory: category == null,
      ));
    }
  }

  /// Updates search query filter.
  void searchDevices(String query) {
    if (state is DevicesLoaded) {
      final current = state as DevicesLoaded;
      emit(current.copyWith(searchQuery: query));
    }
  }

  /// Clears device search filter.
  void clearSearch() {
    if (state is DevicesLoaded) {
      final current = state as DevicesLoaded;
      emit(current.copyWith(clearSearch: true));
    }
  }

  /// Clears transient feedback or error messages.
  void clearMessages() {
    if (state is DevicesLoaded) {
      final current = state as DevicesLoaded;
      emit(current.copyWith(clearFeedback: true, clearError: true));
    }
  }

  /// Immediately flushes all debounced writes to Firestore without waiting for timers.
  Future<void> flushPendingUpdates(String userId) async {
    final keys = List<String>.from(_pendingUpdates.keys);
    for (final deviceId in keys) {
      _debounceTimers[deviceId]?.cancel();
      _debounceTimers.remove(deviceId);
      final payload = _pendingUpdates.remove(deviceId);
      if (payload != null && payload.isNotEmpty) {
        await devicesRepository.updateDeviceState(userId, deviceId, payload);
      }
    }
  }

  void _optimisticUpdate(Device updatedDevice) {
    if (state is! DevicesLoaded) return;
    final current = state as DevicesLoaded;

    final updatedList = current.devices.map((d) {
      return d.id == updatedDevice.id ? updatedDevice : d;
    }).toList();

    emit(current.copyWith(devices: updatedList));
  }

  void _debounceWrite({
    required String userId,
    required String deviceId,
    required Map<String, dynamic> updates,
  }) {
    _pendingUpdates[deviceId] ??= {};
    _pendingUpdates[deviceId]!.addAll(updates);

    _debounceTimers[deviceId]?.cancel();

    _debounceTimers[deviceId] = Timer(debounceDuration, () async {
      final payload = _pendingUpdates.remove(deviceId);
      _debounceTimers.remove(deviceId);
      if (payload != null && payload.isNotEmpty) {
        await devicesRepository.updateDeviceState(userId, deviceId, payload);
      }
    });
  }

  void _setSaving(bool isSaving) {
    if (state is DevicesLoaded) {
      final current = state as DevicesLoaded;
      emit(current.copyWith(
        isSaving: isSaving,
        clearFeedback: true,
        clearError: true,
      ));
    }
  }

  void _emitSuccessMessage(String message) {
    if (state is DevicesLoaded) {
      final current = state as DevicesLoaded;
      emit(current.copyWith(
        isSaving: false,
        feedbackMessage: message,
      ));
    }
  }

  void _emitErrorMessage(String message) {
    if (state is DevicesLoaded) {
      final current = state as DevicesLoaded;
      emit(current.copyWith(
        isSaving: false,
        errorMessage: message,
      ));
    }
  }

  /// Currently active authenticated user ID.
  String? get currentUserId => _currentUserId;

  /// Convenience method for toggling device power.
  Future<void> toggleDevicePower(String deviceId, {String? userId}) {
    return togglePower(userId ?? _currentUserId ?? 'demo-user', deviceId);
  }

  /// Convenience method for toggling favorite flag.
  Future<void> toggleDeviceFavorite(String deviceId, {String? userId}) {
    return toggleFavorite(userId ?? _currentUserId ?? 'demo-user', deviceId);
  }

  /// Convenience method for setting lamp brightness.
  void setLampBrightness(String deviceId, int brightness, {String? userId}) {
    setBrightness(userId ?? _currentUserId ?? 'demo-user', deviceId, brightness);
  }

  /// Convenience method for setting lamp color.
  void setLampColor(String deviceId, {required String name, required String hex, String? userId}) {
    setColor(userId ?? _currentUserId ?? 'demo-user', deviceId, hex, name);
  }

  /// Convenience method for setting AC target temperature.
  void setAcTemp(String deviceId, double targetTemp, {String? userId}) {
    setTargetTemperature(userId ?? _currentUserId ?? 'demo-user', deviceId, targetTemp);
  }

  /// Convenience method for setting AC mode.
  Future<void> setAcModeChoice(String deviceId, AcMode mode, {String? userId}) {
    return setAcMode(userId ?? _currentUserId ?? 'demo-user', deviceId, mode);
  }

  /// Convenience method for setting AC fan speed.
  Future<void> setAcFanSpeedChoice(String deviceId, FanSpeed speed, {String? userId}) {
    return setFanSpeed(userId ?? _currentUserId ?? 'demo-user', deviceId, speed);
  }

  /// Convenience method for adding a Device entity.
  Future<void> addDeviceEntity(Device device, {String? userId}) {
    return createDevice(
      userId: userId ?? _currentUserId ?? 'demo-user',
      name: device.name,
      roomId: device.roomId,
      type: device.type,
      brightness: device.brightness,
      targetTemp: device.targetTemp,
      colorHex: device.colorHex,
      colorName: device.colorName,
      isPoweredOn: device.isPoweredOn,
      isFavorite: device.isFavorite,
      acMode: device.acMode,
      fanSpeed: device.fanSpeed,
    );
  }

  /// Convenience method for updating an existing Device entity.
  Future<void> updateDeviceEntity(Device device, {String? userId}) {
    return updateDevice(
      userId: userId ?? _currentUserId ?? 'demo-user',
      device: device,
    );
  }

  /// Convenience method for deleting a device.
  Future<void> deleteDeviceById(String deviceId, {String? userId}) {
    return deleteDevice(userId: userId ?? _currentUserId ?? 'demo-user', deviceId: deviceId);
  }

  /// Convenience method for toggling power state of all devices in a room.
  Future<void> toggleAllInRoom(String roomNameOrId, bool powerState, {String? userId}) async {
    if (state is! DevicesLoaded) return;
    final current = state as DevicesLoaded;
    final target = roomNameOrId.trim().toLowerCase();
    String? mappedRoomId;
    if (target.contains('salon')) mappedRoomId = 'room-1';
    if (target.contains('yatak')) mappedRoomId = 'room-2';
    if (target.contains('mutfak')) mappedRoomId = 'room-3';
    if (target.contains('calisma') || target.contains('çalışma')) mappedRoomId = 'room-4';

    final roomDevices = current.devices.where(
      (d) =>
          d.roomId.toLowerCase() == target ||
          (mappedRoomId != null && d.roomId.toLowerCase() == mappedRoomId) ||
          d.name.toLowerCase().contains(target),
    ).toList();
    for (final dev in roomDevices) {
      if (dev.isPoweredOn != powerState) {
        await togglePower(userId ?? _currentUserId ?? 'demo-user', dev.id);
      }
    }
  }

  /// Convenience method for applying one of the 4 quick scenes ('Evdeyim', 'Gündüz', 'Gece Modu', 'Dışarıda').
  Future<void> applyQuickScene(String sceneKey, {String? userId}) {
    return applyScene(
      userId: userId ?? _currentUserId ?? 'demo-user',
      sceneKey: sceneKey,
    );
  }

  @override
  Future<void> close() {
    _devicesSubscription?.cancel();
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _pendingUpdates.clear();
    return super.close();
  }
}
