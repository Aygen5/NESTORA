import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/crashlytics_service.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/spark_quota_service.dart';
import '../../domain/entities/device.dart';
import '../../domain/repositories/devices_repository.dart';
import '../../domain/usecases/devices_usecases.dart';
import 'devices_state.dart';

// Akıllı cihazların durumunu, gerçek zamanlı senkronizasyonunu ve yerel önbelleğini yönetir.
class DevicesCubit extends Cubit<DevicesState> {
  final DevicesRepository devicesRepository;
  final Duration debounceDuration;
  final AnalyticsService? analyticsService;
  final CrashlyticsService? crashlyticsService;
  final SparkQuotaService? quotaService;
  final LocalCacheService? localCacheService;

  // İş mantığı kullanım senaryoları (Use Cases)
  final GetDevicesUseCase getDevicesUseCase;
  final WatchDevicesUseCase watchDevicesUseCase;
  final ToggleDevicePowerUseCase toggleDevicePowerUseCase;
  final UpdateDeviceStateUseCase updateDeviceStateUseCase;
  final CreateDeviceUseCase createDeviceUseCase;
  final UpdateDeviceUseCase updateDeviceUseCase;
  final DeleteDeviceUseCase deleteDeviceUseCase;
  final MoveDevicesToRoomUseCase moveDevicesToRoomUseCase;

  StreamSubscription<List<Device>>? _devicesSubscription;
  String? _currentUserId;
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, Map<String, dynamic>> _pendingUpdates = {};

  DevicesCubit({
    required this.devicesRepository,
    this.debounceDuration = AppConstants.sliderDebounceDuration,
    this.analyticsService,
    this.crashlyticsService,
    this.quotaService,
    this.localCacheService,
    GetDevicesUseCase? getDevicesUseCase,
    WatchDevicesUseCase? watchDevicesUseCase,
    ToggleDevicePowerUseCase? toggleDevicePowerUseCase,
    UpdateDeviceStateUseCase? updateDeviceStateUseCase,
    CreateDeviceUseCase? createDeviceUseCase,
    UpdateDeviceUseCase? updateDeviceUseCase,
    DeleteDeviceUseCase? deleteDeviceUseCase,
    MoveDevicesToRoomUseCase? moveDevicesToRoomUseCase,
  })  : getDevicesUseCase = getDevicesUseCase ?? GetDevicesUseCase(devicesRepository),
        watchDevicesUseCase = watchDevicesUseCase ?? WatchDevicesUseCase(devicesRepository),
        toggleDevicePowerUseCase = toggleDevicePowerUseCase ?? ToggleDevicePowerUseCase(devicesRepository),
        updateDeviceStateUseCase = updateDeviceStateUseCase ?? UpdateDeviceStateUseCase(devicesRepository),
        createDeviceUseCase = createDeviceUseCase ?? CreateDeviceUseCase(devicesRepository),
        updateDeviceUseCase = updateDeviceUseCase ?? UpdateDeviceUseCase(devicesRepository),
        deleteDeviceUseCase = deleteDeviceUseCase ?? DeleteDeviceUseCase(devicesRepository),
        moveDevicesToRoomUseCase = moveDevicesToRoomUseCase ?? MoveDevicesToRoomUseCase(devicesRepository),
        super(DevicesLoaded(
          devices: localCacheService?.loadDevices() ?? SeedData.defaultDevices,
        ));

  DevicesLoaded _ensureLoaded() {
    if (state is DevicesLoaded) {
      return state as DevicesLoaded;
    }
    final defaultList = localCacheService?.loadDevices(userId: _currentUserId) ??
        (_currentUserId == SeedData.defaultProfile.uid ? SeedData.defaultDevices : <Device>[]);
    final loaded = DevicesLoaded(devices: defaultList);
    emit(loaded);
    return loaded;
  }

  // Çıkış yapıldığında cihaz durumunu, dinleyicileri ve gecikme zamanlayıcılarını sıfırlar.
  void reset() {
    _devicesSubscription?.cancel();
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _pendingUpdates.clear();
    _currentUserId = null;
    emit(DevicesLoaded(
      devices: localCacheService?.loadDevices(userId: 'usr-1') ?? SeedData.defaultDevices,
    ));
  }

  // Kullanıcıya ait tüm cihazları gerçek zamanlı dinler ve yükler.
  void loadDevices(String userId) {
    final cleanUid = userId.trim();
    if (cleanUid.isEmpty) {
      return;
    }
    _currentUserId = cleanUid;

    final initialDevices = localCacheService?.loadDevices(userId: cleanUid);
    final effectiveInitial = (initialDevices != null && initialDevices.isNotEmpty)
        ? initialDevices
        : (cleanUid == SeedData.defaultProfile.uid ? SeedData.defaultDevices : <Device>[]);
    emit(DevicesLoaded(devices: effectiveInitial));

    _devicesSubscription?.cancel();
    quotaService?.registerListener('DevicesCubit_$cleanUid');

    try {
      _devicesSubscription = watchDevicesUseCase(cleanUid).listen(
        (devices) {
          final effectiveDevices = (devices.isEmpty && cleanUid == SeedData.defaultProfile.uid)
              ? (localCacheService?.loadDevices(userId: cleanUid) ?? SeedData.defaultDevices)
              : devices;

          // Bekleyen yerel değişiklikler varsa birleştir.
          final mergedDevices = effectiveDevices.map((incoming) {
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

          localCacheService?.saveDevices(mergedDevices, userId: cleanUid);

          if (state is DevicesLoaded) {
            final current = state as DevicesLoaded;
            emit(current.copyWith(devices: mergedDevices, isSaving: false));
          } else {
            emit(DevicesLoaded(devices: mergedDevices));
          }
        },
        onError: (error, stack) {
          crashlyticsService?.recordError(
            error,
            stack,
            reason: 'Devices watchDevices stream notice for user: $cleanUid',
          );
          // Çevrimdışı ve demo modunda hata fırlatıldığında mevcut aktif cihaz listesini korur.
          debugPrint('DevicesCubit: Stream notice ($error). Using local active devices.');
        },
      );
    } catch (e) {
      debugPrint('DevicesCubit: watchDevices initialization notice: $e');
    }
  }

  // Aydınlatma parlaklığını (%0-100) iyimser arayüz ve 300ms geciktirmeyle günceller.
  void setBrightness(String userId, String deviceId, int brightness) {
    final current = _ensureLoaded();
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

  // Termostat hedef sıcaklığını (16-30°C) iyimser arayüz ve geciktirmeyle günceller.
  void setTargetTemperature(String userId, String deviceId, double targetTemp) {
    final current = _ensureLoaded();

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

  // Lamba ışık rengini iyimser arayüz ve geciktirmeyle günceller.
  void setColor(
    String userId,
    String deviceId,
    String colorHex,
    String colorName,
  ) {
    final current = _ensureLoaded();

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
        'color': colorHex.trim(),
        'colorHex': colorHex.trim(),
        'colorName': colorName.trim(),
      },
    );
  }

  // Cihazın güç durumunu (açık/kapalı) anında günceller ve Firestore'a yansıtır.
  Future<void> togglePower(String userId, String deviceId) async {
    final current = _ensureLoaded();

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

    try {
      await updateDeviceStateUseCase(
        UpdateDeviceStateParams(
          userId: userId,
          deviceId: deviceId,
          stateUpdates: {
            'isOn': newPowerState,
            'isPoweredOn': newPowerState,
            'currentPowerWatts': updatedDevice.currentPowerWatts,
          },
        ),
      );
    } catch (e) {
      debugPrint('togglePower notice: $e');
    }
  }

  // Cihazın favori durumunu değiştirir.
  Future<void> toggleFavorite(String userId, String deviceId) async {
    final current = _ensureLoaded();

    final device = current.findDeviceById(deviceId);
    if (device == null) return;

    final newFav = !device.isFavorite;
    final updatedDevice = device.copyWith(isFavorite: newFav);
    _optimisticUpdate(updatedDevice);

    try {
      await devicesRepository.updateDeviceState(
        userId,
        deviceId,
        {'isFavorite': newFav},
      );
    } catch (_) {}
  }

  // Klima çalışma modunu ayarlar.
  Future<void> setAcMode(String userId, String deviceId, AcMode mode) async {
    final current = _ensureLoaded();

    final device = current.findDeviceById(deviceId);
    if (device == null) return;

    final updatedDevice = device.copyWith(acMode: mode);
    _optimisticUpdate(updatedDevice);

    try {
      await devicesRepository.updateDeviceState(
        userId,
        deviceId,
        {'acMode': mode.toShortString()},
      );
    } catch (_) {}
  }

  // Klima fan hızını ayarlar.
  Future<void> setFanSpeed(String userId, String deviceId, FanSpeed speed) async {
    final current = _ensureLoaded();

    final device = current.findDeviceById(deviceId);
    if (device == null) return;

    final updatedDevice = device.copyWith(fanSpeed: speed);
    _optimisticUpdate(updatedDevice);

    try {
      await devicesRepository.updateDeviceState(
        userId,
        deviceId,
        {'fanSpeed': speed.toShortString()},
      );
    } catch (_) {}
  }

  // 4 hızlı akıllı ev senaryosundan birini ("Evdeyim", "Gündüz", "Gece Modu", "Dışarıda") uygular.
  Future<void> applyScene({
    required String userId,
    required String sceneKey,
  }) async {
    final current = _ensureLoaded();
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
        } else if (dev.type == DeviceType.plug) {
          updated = dev.copyWith(
            isPoweredOn: true,
            currentPowerWatts: 240.0,
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
          // Yalnızca gece lambasını loş açık bırak, diğerlerini kapat.
          final isNightLight = dev.name.toLowerCase().contains('gece') ||
              dev.name.toLowerCase().contains('yatak') ||
              dev.name.toLowerCase().contains('komodin');
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
        } else if (dev.type == DeviceType.tv || dev.type == DeviceType.plug) {
          updated = dev.copyWith(
            isPoweredOn: false,
            currentPowerWatts: 0.0,
          );
        }
      } else if (normalized == 'away' || normalized == 'disarida' || normalized.contains('disari')) {
        sceneDisplayName = 'Dışarıda';
        updated = dev.copyWith(
          isPoweredOn: false,
          currentPowerWatts: 0.0,
          targetTemp: dev.type == DeviceType.ac ? 18.0 : dev.targetTemp,
        );
      }

      updatedDevices.add(updated);
    }

    analyticsService?.logScenarioActivated(scenarioName: sceneDisplayName);

    emit(current.copyWith(
      devices: updatedDevices,
      feedbackMessage: '$sceneDisplayName senaryosu uygulandı.',
    ));
    localCacheService?.saveDevices(updatedDevices, userId: userId);

    // Değişiklikleri arka planda Firestore'a yansıtır.
    for (final dev in updatedDevices) {
      try {
        devicesRepository.updateDeviceState(userId, dev.id, {
          'isPoweredOn': dev.isPoweredOn,
          'brightness': dev.brightness,
          'targetTemp': dev.targetTemp,
          'colorHex': dev.colorHex,
          'colorName': dev.colorName,
          'acMode': dev.acMode.toShortString(),
          'fanSpeed': dev.fanSpeed.toShortString(),
          'currentPowerWatts': dev.currentPowerWatts,
        });
      } catch (_) {}
    }
  }

  // Sisteme yeni bir akıllı cihaz ekler ve kaydeder.
  Future<void> createDevice({
    required String userId,
    required String name,
    required String roomId,
    required DeviceType type,
    String? deviceId,
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

    if (state is DevicesLoaded && quotaService != null) {
      final currentDevices = (state as DevicesLoaded).devices;
      final roomDevicesCount = currentDevices.where((d) => d.roomId == cleanRoomId).length;
      if (!quotaService!.canAddDevice(roomDevicesCount)) {
        _emitErrorMessage(
          'Bu odadaki maksimum cihaz sınırına (${quotaService!.maxDevicesPerRoom}) ulaşıldı. Spark planı kotası gereği daha fazla cihaz eklenemez.',
        );
        return;
      }
    }

    _setSaving(true);
    final current = _ensureLoaded();

    final effectiveDeviceId = (deviceId != null && deviceId.trim().isNotEmpty)
        ? deviceId.trim()
        : 'device-${DateTime.now().millisecondsSinceEpoch}';
    final newDevice = Device(
      id: effectiveDeviceId,
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

    final updated = [...current.devices, newDevice];
    emit(current.copyWith(devices: updated, isSaving: false, feedbackMessage: 'Cihaz başarıyla eklendi.'));
    localCacheService?.saveDevices(updated, userId: userId);
    analyticsService?.logDeviceCreated(deviceType: newDevice.type.name);

    try {
      await createDeviceUseCase(CreateDeviceParams(userId: userId, device: newDevice));
    } catch (e) {
      debugPrint('createDevice notice: $e');
    }
  }

  // Mevcut bir cihazın tüm bilgilerini günceller.
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

    final current = _ensureLoaded();
    final updatedList = current.devices.map((d) => d.id == device.id ? updated : d).toList();
    emit(current.copyWith(devices: updatedList, isSaving: false, feedbackMessage: 'Cihaz başarıyla güncellendi.'));
    localCacheService?.saveDevices(updatedList, userId: userId);

    try {
      await devicesRepository.updateDevice(userId, updated);
    } catch (e) {
      debugPrint('updateDevice notice: $e');
    }
  }

  // Cihazı sistemden ve veritabanından siler.
  Future<void> deleteDevice({
    required String userId,
    required String deviceId,
  }) async {
    _setSaving(true);

    _debounceTimers[deviceId]?.cancel();
    _pendingUpdates.remove(deviceId);

    final current = _ensureLoaded();
    final updatedList = current.devices.where((d) => d.id != deviceId).toList();
    emit(current.copyWith(devices: updatedList, isSaving: false, feedbackMessage: 'Cihaz başarıyla silindi.'));
    localCacheService?.saveDevices(updatedList, userId: userId);

    try {
      await deleteDeviceUseCase(DeleteDeviceParams(userId: userId, deviceId: deviceId));
    } catch (e) {
      debugPrint('deleteDevice notice: $e');
    }
  }

  // Cihazları kategorisine göre filtreler (null tümünü gösterir).
  void selectCategory(DeviceType? category) {
    if (state is DevicesLoaded) {
      final current = state as DevicesLoaded;
      emit(current.copyWith(
        selectedCategory: category,
        clearCategory: category == null,
      ));
    }
  }

  // Cihaz arama filtresini günceller.
  void searchDevices(String query) {
    if (state is DevicesLoaded) {
      final current = state as DevicesLoaded;
      emit(current.copyWith(searchQuery: query));
    }
  }

  // Cihaz arama filtresini temizler.
  void clearSearch() {
    if (state is DevicesLoaded) {
      final current = state as DevicesLoaded;
      emit(current.copyWith(clearSearch: true));
    }
  }

  // Bildirim ve hata mesajlarını temizler.
  void clearMessages() {
    if (state is DevicesLoaded) {
      final current = state as DevicesLoaded;
      emit(current.copyWith(clearFeedback: true, clearError: true));
    }
  }

  // Bekleyen tüm geciktirilmiş güncellemeleri anında Firestore'a kaydeder.
  Future<void> flushPendingUpdates(String userId) async {
    final keys = List<String>.from(_pendingUpdates.keys);
    for (final deviceId in keys) {
      _debounceTimers[deviceId]?.cancel();
      _debounceTimers.remove(deviceId);
      final payload = _pendingUpdates.remove(deviceId);
      if (payload != null && payload.isNotEmpty) {
        try {
          await devicesRepository.updateDeviceState(userId, deviceId, payload);
        } catch (_) {}
      }
    }
  }

  void _optimisticUpdate(Device updatedDevice) {
    final current = _ensureLoaded();

    final updatedList = current.devices.map((d) {
      return d.id == updatedDevice.id ? updatedDevice : d;
    }).toList();

    emit(current.copyWith(devices: updatedList));
    localCacheService?.saveDevices(updatedList, userId: _currentUserId);
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
        try {
          await devicesRepository.updateDeviceState(userId, deviceId, payload);
        } catch (_) {}
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

  void _emitErrorMessage(String message) {
    if (state is DevicesLoaded) {
      final current = state as DevicesLoaded;
      emit(current.copyWith(
        isSaving: false,
        errorMessage: message,
      ));
    }
  }

  // İzin hatası almamak için aktif Firebase kullanıcı ID'sini çözümler.
  String _resolveUserId([String? userId]) {
    if (userId != null && userId.trim().isNotEmpty && userId.trim() != 'demo-user') {
      return userId.trim();
    }
    if (_currentUserId != null && _currentUserId!.trim().isNotEmpty && _currentUserId!.trim() != 'demo-user') {
      return _currentUserId!.trim();
    }
    try {
      final fbUid = FirebaseAuth.instance.currentUser?.uid;
      if (fbUid != null && fbUid.isNotEmpty) {
        return fbUid;
      }
    } catch (_) {}
    return _currentUserId ?? 'demo-user';
  }

  // Oturumu açık olan kullanıcının ID'si.
  String? get currentUserId => _currentUserId;

  // Cihazın açık/kapalı durumunu değiştirmek için yardımcı metot.
  Future<void> toggleDevicePower(String deviceId, {String? userId}) {
    return togglePower(_resolveUserId(userId), deviceId);
  }

  // Cihazı favorilere eklemek/çıkarmak için yardımcı metot.
  Future<void> toggleDeviceFavorite(String deviceId, {String? userId}) {
    return toggleFavorite(_resolveUserId(userId), deviceId);
  }

  // Lamba parlaklığını ayarlamak için yardımcı metot.
  void setLampBrightness(String deviceId, int brightness, {String? userId}) {
    setBrightness(_resolveUserId(userId), deviceId, brightness);
  }

  // Lamba rengini ayarlamak için yardımcı metot.
  void setLampColor(String deviceId, {required String name, required String hex, String? userId}) {
    setColor(_resolveUserId(userId), deviceId, hex, name);
  }

  // Klima hedef sıcaklığını ayarlamak için yardımcı metot.
  void setAcTemp(String deviceId, double targetTemp, {String? userId}) {
    setTargetTemperature(_resolveUserId(userId), deviceId, targetTemp);
  }

  // Klima modunu ayarlamak için yardımcı metot.
  Future<void> setAcModeChoice(String deviceId, AcMode mode, {String? userId}) {
    return setAcMode(_resolveUserId(userId), deviceId, mode);
  }

  // Klima fan hızını ayarlamak için yardımcı metot.
  Future<void> setAcFanSpeedChoice(String deviceId, FanSpeed speed, {String? userId}) {
    return setFanSpeed(_resolveUserId(userId), deviceId, speed);
  }

  // Cihaz nesnesi eklemek için yardımcı metot.
  Future<void> addDeviceEntity(Device device, {String? userId}) {
    return createDevice(
      userId: _resolveUserId(userId),
      deviceId: device.id,
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

  // Cihaz nesnesi güncellemek için yardımcı metot.
  Future<void> updateDeviceEntity(Device device, {String? userId}) {
    return updateDevice(
      userId: _resolveUserId(userId),
      device: device,
    );
  }

  // Cihaz silmek için yardımcı metot.
  Future<void> deleteDeviceById(String deviceId, {String? userId}) {
    return deleteDevice(userId: _resolveUserId(userId), deviceId: deviceId);
  }

  // Bir odadaki tüm cihazları açıp kapatmak için yardımcı metot.
  Future<void> toggleAllInRoom(String roomNameOrId, bool powerState, {String? userId, String? roomName}) async {
    final current = _ensureLoaded();
    final effectiveUid = _resolveUserId(userId);
    final target = roomNameOrId.trim().toLowerCase();
    final cleanRoomName = roomName?.trim().toLowerCase();
    String? mappedRoomId;
    if (target.contains('salon')) mappedRoomId = 'room-1';
    if (target.contains('yatak')) mappedRoomId = 'room-2';
    if (target.contains('mutfak')) mappedRoomId = 'room-3';
    if (target.contains('calisma') || target.contains('çalışma')) mappedRoomId = 'room-4';

    final devicesToUpdate = <Device>[];
    final updatedDevices = current.devices.map((d) {
      final devRoomId = d.roomId.trim().toLowerCase();
      final devRoomExact = d.roomId.trim();
      final matchesRoom = devRoomExact == roomNameOrId.trim() ||
          devRoomId == target ||
          (cleanRoomName != null && devRoomId == cleanRoomName) ||
          (cleanRoomName != null && d.name.toLowerCase().contains(cleanRoomName)) ||
          (mappedRoomId != null && devRoomId == mappedRoomId) ||
          devRoomId.contains(target) ||
          target.contains(devRoomId) ||
          (cleanRoomName != null && cleanRoomName.contains(devRoomId));

      if (matchesRoom) {
        double newWatts = 0.0;
        if (powerState) {
          if (d.type == DeviceType.bulb) {
            newWatts = (d.brightness / 100.0) * 15.0;
          } else if (d.type == DeviceType.ac) {
            newWatts = 1200.0;
          } else if (d.type == DeviceType.plug) {
            newWatts = 240.0;
          } else if (d.type == DeviceType.tv) {
            newWatts = 95.0;
          } else {
            newWatts = 45.0;
          }
        }
        final updated = d.copyWith(
          isPoweredOn: powerState,
          currentPowerWatts: double.parse(newWatts.toStringAsFixed(1)),
        );
        devicesToUpdate.add(updated);
        return updated;
      }
      return d;
    }).toList();

    emit(current.copyWith(
      devices: updatedDevices,
      feedbackMessage: powerState
          ? 'Odadaki tüm cihazlar açıldı.'
          : 'Odadaki tüm cihazlar kapatıldı.',
    ));
    localCacheService?.saveDevices(updatedDevices, userId: effectiveUid);

    for (final dev in devicesToUpdate) {
      try {
        await devicesRepository.updateDeviceState(effectiveUid, dev.id, {
          'isOn': dev.isPoweredOn,
          'isPoweredOn': dev.isPoweredOn,
          'currentPowerWatts': dev.currentPowerWatts,
        });
      } catch (_) {}
    }
  }

  // Evdeki tüm cihazları tek seferde açıp kapatmak için yardımcı metot.
  Future<void> toggleAllDevices(bool powerState, {String? userId}) async {
    final current = _ensureLoaded();
    final updatedDevices = current.devices.map((d) {
      double newWatts = 0.0;
      if (powerState) {
        if (d.type == DeviceType.bulb) {
          newWatts = (d.brightness / 100.0) * 15.0;
        } else if (d.type == DeviceType.ac) {
          newWatts = 1200.0;
        } else if (d.type == DeviceType.plug) {
          newWatts = 240.0;
        } else if (d.type == DeviceType.tv) {
          newWatts = 95.0;
        } else {
          newWatts = 45.0;
        }
      }
      return d.copyWith(
        isPoweredOn: powerState,
        currentPowerWatts: double.parse(newWatts.toStringAsFixed(1)),
      );
    }).toList();

    emit(current.copyWith(
      devices: updatedDevices,
      feedbackMessage: powerState
          ? 'Tüm cihazlar açıldı.'
          : 'Tüm cihazlar kapatıldı.',
    ));
    localCacheService?.saveDevices(updatedDevices, userId: userId ?? _currentUserId);

    for (final dev in updatedDevices) {
      try {
        devicesRepository.updateDeviceState(userId ?? _currentUserId ?? 'demo-user', dev.id, {
          'isOn': dev.isPoweredOn,
          'isPoweredOn': dev.isPoweredOn,
          'currentPowerWatts': dev.currentPowerWatts,
        });
      } catch (_) {}
    }
  }

  // 4 hızlı senaryoyu tek çağrıyla uygulamak için yardımcı metot.
  Future<void> applyQuickScene(String sceneKey, {String? userId}) {
    return applyScene(
      userId: userId ?? _currentUserId ?? 'demo-user',
      sceneKey: sceneKey,
    );
  }

  @override
  Future<void> close() {
    _devicesSubscription?.cancel();
    if (_currentUserId != null) {
      quotaService?.unregisterListener('DevicesCubit_$_currentUserId');
    }
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _pendingUpdates.clear();
    return super.close();
  }
}
