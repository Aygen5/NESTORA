import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

/// Privacy-compliant analytics service for Nestora.
/// Wraps [FirebaseAnalytics] and tracks core product events:
/// - User authentication (method only, strictly NO passwords or personal data)
/// - Room management (room type, room creation/deletion)
/// - Device controls & quick scenarios (scene activation, device power toggle)
/// - Screen views & theme preferences
class AnalyticsService {
  final FirebaseAnalytics? analytics;
  final bool enableDebugLogs;

  /// In-memory log of tracked events for unit tests and local inspection.
  final List<Map<String, dynamic>> recordedEvents = [];
  String? currentUserId;

  AnalyticsService({
    this.analytics,
    this.enableDebugLogs = false,
  });

  /// Provides a [FirebaseAnalyticsObserver] for GoRouter or Navigator.
  NavigatorObserver getAnalyticsObserver() {
    if (analytics != null) {
      return FirebaseAnalyticsObserver(analytics: analytics!);
    }
    return _FallbackNavigatorObserver();
  }

  /// Sets or clears the current user ID.
  Future<void> setUserId(String? userId) async {
    currentUserId = userId;
    if (enableDebugLogs) {
      debugPrint('[AnalyticsService] setUserId: $userId');
    }
    if (analytics != null) {
      try {
        await analytics!.setUserId(id: userId);
      } catch (e) {
        debugPrint('AnalyticsService.setUserId error: $e');
      }
    }
  }

  /// Logs user login event (e.g. 'email', 'demo'). Strictly no password or email.
  Future<void> logLogin({required String method}) async {
    await _logEvent(
      name: 'login',
      parameters: {'login_method': method},
    );
  }

  /// Logs new account sign-up event.
  Future<void> logSignUp({required String method}) async {
    await _logEvent(
      name: 'sign_up',
      parameters: {'sign_up_method': method},
    );
  }

  /// Logs user session termination.
  Future<void> logLogout() async {
    await _logEvent(
      name: 'logout',
      parameters: const {},
    );
  }

  /// Logs screen/route view.
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    final params = <String, Object>{'screen_name': screenName};
    if (screenClass != null) {
      params['screen_class'] = screenClass;
    }

    recordedEvents.add({
      'name': 'screen_view',
      'parameters': params,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (enableDebugLogs) {
      debugPrint('[AnalyticsService] screen_view: $screenName ($screenClass)');
    }

    if (analytics != null) {
      try {
        await analytics!.logScreenView(
          screenName: screenName,
          screenClass: screenClass,
        );
      } catch (e) {
        debugPrint('AnalyticsService.logScreenView error: $e');
      }
    }
  }

  /// Logs creation of a new smart room.
  Future<void> logRoomCreated({required String roomType}) async {
    await _logEvent(
      name: 'room_created',
      parameters: {'room_type': roomType},
    );
  }

  /// Logs room deletion.
  Future<void> logRoomDeleted({required String roomId}) async {
    await _logEvent(
      name: 'room_deleted',
      parameters: {'room_id': roomId},
    );
  }

  /// Logs device creation.
  Future<void> logDeviceCreated({required String deviceType}) async {
    await _logEvent(
      name: 'device_created',
      parameters: {'device_type': deviceType},
    );
  }

  /// Logs device power toggle.
  Future<void> logDeviceToggle({
    required String deviceType,
    required bool isPoweredOn,
  }) async {
    await _logEvent(
      name: 'device_power_toggle',
      parameters: {
        'device_type': deviceType,
        'state': isPoweredOn ? 'on' : 'off',
      },
    );
  }

  /// Logs device property change (e.g. brightness, temperature).
  Future<void> logDeviceStateChanged({
    required String deviceType,
    required String property,
  }) async {
    await _logEvent(
      name: 'device_state_changed',
      parameters: {
        'device_type': deviceType,
        'property': property,
      },
    );
  }

  /// Logs quick scenario activation ('Evdeyim', 'Gündüz', 'Gece Modu', 'Dışarıda').
  Future<void> logScenarioActivated({required String scenarioName}) async {
    await _logEvent(
      name: 'scenario_activated',
      parameters: {'scenario_name': scenarioName},
    );
  }

  /// Logs theme preference change (light, dark, system).
  Future<void> logThemeChanged({required String themeMode}) async {
    await _logEvent(
      name: 'theme_changed',
      parameters: {'theme_mode': themeMode},
    );
  }

  /// Internal event dispatcher with parameter sanitization (PII protection).
  Future<void> _logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    final sanitizedParams = _sanitizeParameters(parameters);

    recordedEvents.add({
      'name': name,
      'parameters': sanitizedParams,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (enableDebugLogs) {
      debugPrint('[AnalyticsService] Event: $name | params: $sanitizedParams');
    }

    if (analytics != null) {
      try {
        await analytics!.logEvent(
          name: name,
          parameters: sanitizedParams,
        );
      } catch (e) {
        debugPrint('AnalyticsService.logEvent error: $e');
      }
    }
  }

  /// Sanitizes parameter map to strictly forbid sensitive fields.
  Map<String, Object> _sanitizeParameters(Map<String, Object>? params) {
    if (params == null || params.isEmpty) return const {};
    final sanitized = <String, Object>{};

    const forbiddenKeys = [
      'password',
      'passwd',
      'sifre',
      'token',
      'secret',
      'credit_card',
      'email',
      'phone',
      'auth',
      'authorization',
    ];

    for (final entry in params.entries) {
      final keyLower = entry.key.toLowerCase();
      if (forbiddenKeys.any((forbidden) => keyLower.contains(forbidden))) {
        sanitized[entry.key] = '[REDACTED]';
      } else {
        sanitized[entry.key] = entry.value;
      }
    }

    return sanitized;
  }
}

/// Fallback navigator observer for offline, test, or environments without Firebase Analytics.
class _FallbackNavigatorObserver extends NavigatorObserver {}
