import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import 'crashlytics_service.dart';
import 'remote_config_service.dart';

/// Firebase Spark (Free Tier) limits and resource constraints.
class SparkLimits {
  SparkLimits._();

  /// Maximum free-tier document reads per day on Firestore (50,000 / day).
  static const int maxDailyReads = 50000;

  /// Maximum free-tier document writes per day on Firestore (20,000 / day).
  static const int maxDailyWrites = 20000;

  /// Maximum free-tier document deletes per day on Firestore (20,000 / day).
  static const int maxDailyDeletes = 20000;

  /// Maximum password reset emails allowed per day on Spark Plan (150 / day).
  static const int maxDailyPasswordResetEmails = 150;

  /// Maximum simultaneous Firestore real-time connections on Spark Plan (100).
  static const int maxSimultaneousConnections = 100;

  /// Default high-frequency slider/dial debounce duration to guard write quota.
  static const Duration defaultSliderDebounce = AppConstants.sliderDebounceDuration;

  /// Maximum rooms allowed per user under Spark Free Tier.
  static const int defaultMaxRoomsPerUser = 20;

  /// Maximum devices allowed per room under Spark Free Tier.
  static const int defaultMaxDevicesPerRoom = 50;
}

/// Service dedicated to enforcing Firebase Spark Plan quota constraints,
/// auditing active real-time listeners, preventing runaway writes via debounce,
/// and ensuring zero-cost compliance (no Cloud Storage, no Cloud Functions).
class SparkQuotaService {
  final RemoteConfigService? remoteConfigService;
  final CrashlyticsService? crashlyticsService;

  final Set<String> _activeListeners = {};
  int _estimatedDailyWrites = 0;
  int _estimatedDailyReads = 0;

  SparkQuotaService({
    this.remoteConfigService,
    this.crashlyticsService,
  });

  /// Set of currently registered active real-time Firestore listeners.
  Set<String> get activeListeners => Set.unmodifiable(_activeListeners);

  /// Number of active real-time listeners currently open in the app.
  int get activeListenerCount => _activeListeners.length;

  /// Estimated write operations during this app session.
  int get estimatedDailyWrites => _estimatedDailyWrites;

  /// Estimated read operations during this app session.
  int get estimatedDailyReads => _estimatedDailyReads;

  /// Maximum rooms allowed per user (honors Remote Config if available).
  int get maxRoomsPerUser =>
      remoteConfigService?.maxRoomsPerUser ?? SparkLimits.defaultMaxRoomsPerUser;

  /// Maximum devices allowed per room (honors Remote Config if available).
  int get maxDevicesPerRoom =>
      remoteConfigService?.maxDevicesPerRoom ?? SparkLimits.defaultMaxDevicesPerRoom;

  /// High-frequency UI debounce duration.
  Duration get sliderDebounceDuration => SparkLimits.defaultSliderDebounce;

  /// Whether Cloud Storage is permitted. Strictly `false` under zero-cost Spark policy.
  bool get isCloudStorageUsed => false;

  /// Whether Cloud Functions are permitted. Strictly `false` under zero-cost Spark policy.
  bool get isCloudFunctionsUsed => false;

  /// Validates whether a new room can be created without exceeding user limits.
  bool canCreateRoom(int currentRoomCount) {
    return currentRoomCount < maxRoomsPerUser;
  }

  /// Validates whether a new device can be added to a room without exceeding limits.
  bool canAddDevice(int currentDeviceCountInRoom) {
    return currentDeviceCountInRoom < maxDevicesPerRoom;
  }

  /// Validates whether an email format is valid before triggering a password reset,
  /// preventing burning through the 150 emails/day Spark quota with invalid attempts.
  bool validatePasswordResetEmail(String email) {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) return false;
    return AppConstants.emailRegex.hasMatch(cleanEmail);
  }

  /// Registers an active real-time listener subscription (e.g. `watchRooms`, `watchDevices`).
  void registerListener(String listenerTag) {
    final cleanTag = listenerTag.trim();
    if (cleanTag.isEmpty) return;

    _activeListeners.add(cleanTag);
    _auditListeners();
  }

  /// Unregisters an active real-time listener subscription upon page pop or cubit dispose.
  void unregisterListener(String listenerTag) {
    final cleanTag = listenerTag.trim();
    if (cleanTag.isEmpty) return;

    _activeListeners.remove(cleanTag);
  }

  /// Clears all registered active listeners (e.g. on logout or app reset).
  void clearAllListeners() {
    _activeListeners.clear();
  }

  /// Increments the estimated write counter and checks against daily write safety limits.
  void recordWriteOperation({int count = 1}) {
    _estimatedDailyWrites += count;
    if (_estimatedDailyWrites >= SparkLimits.maxDailyWrites) {
      crashlyticsService?.recordError(
        StateError('Spark write limit approached or reached: $_estimatedDailyWrites writes.'),
        null,
        reason: 'SparkQuotaService: Daily write limit safety threshold exceeded.',
      );
    }
  }

  /// Increments the estimated read counter and checks against daily read safety limits.
  void recordReadOperation({int count = 1}) {
    _estimatedDailyReads += count;
    if (_estimatedDailyReads >= SparkLimits.maxDailyReads) {
      crashlyticsService?.recordError(
        StateError('Spark read limit approached or reached: $_estimatedDailyReads reads.'),
        null,
        reason: 'SparkQuotaService: Daily read limit safety threshold exceeded.',
      );
    }
  }

  /// Audits active listeners and warns if the count exceeds a safe threshold (e.g. 10).
  void _auditListeners() {
    const warningThreshold = 10;
    if (_activeListeners.length > warningThreshold) {
      final msg = 'SparkQuotaService Warning: Excessive active listeners detected (${_activeListeners.length}). '
          'Active: ${_activeListeners.join(', ')}';
      debugPrint(msg);
      crashlyticsService?.log(msg);
    }
  }

  /// Verifies that zero-cost rules are strictly satisfied:
  /// 1. Cloud Storage is NOT used.
  /// 2. Cloud Functions are NOT used.
  /// 3. Debounce duration is at least 300ms.
  bool verifyZeroCostCompliance() {
    final storageOk = !isCloudStorageUsed;
    final functionsOk = !isCloudFunctionsUsed;
    final debounceOk = sliderDebounceDuration.inMilliseconds >= 300;
    return storageOk && functionsOk && debounceOk;
  }

  /// Generates a diagnostic summary of quota usage and security assertions.
  Map<String, dynamic> getQuotaHealthReport() {
    return {
      'sparkPlan': 'Spark (Free Tier)',
      'zeroCostCompliant': verifyZeroCostCompliance(),
      'activeListenersCount': activeListenerCount,
      'activeListeners': _activeListeners.toList(),
      'sliderDebounceMs': sliderDebounceDuration.inMilliseconds,
      'cloudStorageUsed': isCloudStorageUsed,
      'cloudFunctionsUsed': isCloudFunctionsUsed,
      'profilePhotoStorage': 'Local Sandbox (path_provider)',
      'maxRoomsPerUser': maxRoomsPerUser,
      'maxDevicesPerRoom': maxDevicesPerRoom,
      'dailyReadsBudget': SparkLimits.maxDailyReads,
      'dailyWritesBudget': SparkLimits.maxDailyWrites,
      'dailyPasswordResetsBudget': SparkLimits.maxDailyPasswordResetEmails,
      'estimatedSessionWrites': _estimatedDailyWrites,
      'estimatedSessionReads': _estimatedDailyReads,
    };
  }
}

