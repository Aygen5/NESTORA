import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// Data model representing a remote broadcast announcement configured via Firebase Remote Config.
class AppAnnouncement {
  final bool isEnabled;
  final String title;
  final String message;
  final String type; // 'info', 'warning', 'success', 'update'
  final bool isDismissible;

  const AppAnnouncement({
    this.isEnabled = false,
    this.title = '',
    this.message = '',
    this.type = 'info',
    this.isDismissible = true,
  });

  bool get hasContent => isEnabled && (title.isNotEmpty || message.isNotEmpty);
}

/// Service managing dynamic feature flags, remote application announcements,
/// and runtime parameters via [FirebaseRemoteConfig] with local fallback.
class RemoteConfigService {
  final FirebaseRemoteConfig? remoteConfig;
  final bool enableDebugLogs;

  /// In-memory override store for unit and widget tests.
  final Map<String, dynamic> _testOverrides = {};

  RemoteConfigService({
    this.remoteConfig,
    this.enableDebugLogs = false,
  });

  /// In-app default configurations matching the Spark tier budget.
  static final Map<String, dynamic> defaultParameters = {
    AppConstants.remoteConfigDemoEmail: AppConstants.demoEmail,
    AppConstants.remoteConfigDemoPassword: AppConstants.demoPassword,
    AppConstants.remoteConfigAnnouncementEnabled: false,
    AppConstants.remoteConfigAnnouncementTitle: '',
    AppConstants.remoteConfigAnnouncementMessage: '',
    AppConstants.remoteConfigAnnouncementType: 'info',
    AppConstants.remoteConfigAnnouncementDismissible: true,
    AppConstants.remoteConfigMinSupportedVersion: '1.0.0',
    AppConstants.remoteConfigMaintenanceMode: false,
    AppConstants.remoteConfigEnergyTipEnabled: true,
    AppConstants.remoteConfigMaxRoomsPerUser: 20,
    AppConstants.remoteConfigMaxDevicesPerRoom: 50,
  };

  /// Initializes default values and attempts an asynchronous fetch/activation.
  Future<void> initializeDefaults() async {
    if (remoteConfig == null) return;

    try {
      await remoteConfig!.setDefaults(defaultParameters);

      await remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 5),
          minimumFetchInterval: kDebugMode
              ? const Duration(seconds: 0)
              : const Duration(hours: 1),
        ),
      );

      await remoteConfig!.fetchAndActivate();

      if (enableDebugLogs) {
        debugPrint('[RemoteConfigService] Successfully fetched and activated remote configs.');
      }
    } catch (e) {
      debugPrint('RemoteConfigService: RemoteConfig init notice ($e)');
    }
  }

  /// Sets an in-memory test override for a key.
  void setOverride(String key, dynamic value) {
    _testOverrides[key] = value;
  }

  /// Clears all test overrides.
  void clearOverrides() {
    _testOverrides.clear();
  }

  /// Retrieves the active application broadcast announcement.
  AppAnnouncement get announcement {
    final enabled = getBool(AppConstants.remoteConfigAnnouncementEnabled, defaultValue: false);
    final title = getString(AppConstants.remoteConfigAnnouncementTitle, defaultValue: '');
    final message = getString(AppConstants.remoteConfigAnnouncementMessage, defaultValue: '');
    final type = getString(AppConstants.remoteConfigAnnouncementType, defaultValue: 'info');
    final dismissible = getBool(AppConstants.remoteConfigAnnouncementDismissible, defaultValue: true);

    return AppAnnouncement(
      isEnabled: enabled,
      title: title,
      message: message,
      type: type,
      isDismissible: dismissible,
    );
  }

  /// Whether the app is currently in remote maintenance mode.
  bool get isMaintenanceMode =>
      getBool(AppConstants.remoteConfigMaintenanceMode, defaultValue: false);

  /// Minimum supported app version string (e.g. '1.0.0').
  String get minSupportedVersion =>
      getString(AppConstants.remoteConfigMinSupportedVersion, defaultValue: '1.0.0');

  /// Maximum allowed smart rooms per user home.
  int get maxRoomsPerUser =>
      getInt(AppConstants.remoteConfigMaxRoomsPerUser, defaultValue: 20);

  /// Maximum allowed devices per room.
  int get maxDevicesPerRoom =>
      getInt(AppConstants.remoteConfigMaxDevicesPerRoom, defaultValue: 50);

  /// Whether energy-saving dynamic tip cards should be displayed on Dashboard.
  bool get isEnergyTipEnabled =>
      getBool(AppConstants.remoteConfigEnergyTipEnabled, defaultValue: true);

  /// Retrieves demo account email.
  String get demoEmail {
    final val = getString(AppConstants.remoteConfigDemoEmail, defaultValue: AppConstants.demoEmail);
    const envVal = String.fromEnvironment('DEMO_EMAIL');
    if (envVal.isNotEmpty) return envVal;
    return val.isNotEmpty ? val : AppConstants.demoEmail;
  }

  /// Retrieves demo account password.
  String get demoPassword {
    final val = getString(AppConstants.remoteConfigDemoPassword, defaultValue: AppConstants.demoPassword);
    const envVal = String.fromEnvironment('DEMO_PASSWORD');
    if (envVal.isNotEmpty) return envVal;
    return val.isNotEmpty ? val : AppConstants.demoPassword;
  }

  /// Retrieves a string value with fallback.
  String getString(String key, {String defaultValue = ''}) {
    if (_testOverrides.containsKey(key)) {
      return _testOverrides[key]?.toString() ?? defaultValue;
    }
    if (remoteConfig != null) {
      try {
        final val = remoteConfig!.getString(key).trim();
        if (val.isNotEmpty) return val;
      } catch (_) {}
    }
    return defaultParameters[key]?.toString() ?? defaultValue;
  }

  /// Retrieves a boolean value with fallback.
  bool getBool(String key, {bool defaultValue = false}) {
    if (_testOverrides.containsKey(key)) {
      final val = _testOverrides[key];
      if (val is bool) return val;
      return val?.toString().toLowerCase() == 'true';
    }
    if (remoteConfig != null) {
      try {
        return remoteConfig!.getBool(key);
      } catch (_) {}
    }
    return (defaultParameters[key] as bool?) ?? defaultValue;
  }

  /// Retrieves an integer value with fallback.
  int getInt(String key, {int defaultValue = 0}) {
    if (_testOverrides.containsKey(key)) {
      final val = _testOverrides[key];
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? defaultValue;
    }
    if (remoteConfig != null) {
      try {
        return remoteConfig!.getInt(key);
      } catch (_) {}
    }
    return (defaultParameters[key] as int?) ?? defaultValue;
  }

  /// Retrieves a double value with fallback.
  double getDouble(String key, {double defaultValue = 0.0}) {
    if (_testOverrides.containsKey(key)) {
      final val = _testOverrides[key];
      if (val is double) return val;
      return double.tryParse(val.toString()) ?? defaultValue;
    }
    if (remoteConfig != null) {
      try {
        return remoteConfig!.getDouble(key);
      } catch (_) {}
    }
    return (defaultParameters[key] as double?) ?? defaultValue;
  }
}

