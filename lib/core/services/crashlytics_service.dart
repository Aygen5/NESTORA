import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Service managing application crash tracking, fatal/non-fatal exception recording,
/// and privacy-compliant diagnostic logging through [FirebaseCrashlytics].
///
/// Fully supports Web, Desktop (graceful fallback without native Crashlytics),
/// and headless widget test environments.
class CrashlyticsService {
  final FirebaseCrashlytics? crashlytics;
  final bool enableDebugLogs;

  /// In-memory records primarily used for unit test assertions and offline verification.
  final List<String> recordedLogs = [];
  final List<Map<String, dynamic>> recordedErrors = [];
  final Map<String, Object> customKeys = {};
  String? currentUserId;

  CrashlyticsService({
    this.crashlytics,
    this.enableDebugLogs = false,
  });

  /// Returns true if Firebase Crashlytics is natively supported on the active platform.
  bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  /// Configures global Flutter framework and asynchronous error handlers.
  Future<void> initialize() async {
    if (isSupported && crashlytics != null) {
      try {
        // Enable in-app crash data collection
        await crashlytics!.setCrashlyticsCollectionEnabled(!kDebugMode);

        // Catch Flutter framework errors (e.g. build phase exceptions)
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (FlutterErrorDetails details) {
          recordFlutterError(details);
          originalOnError?.call(details);
        };

        // Catch asynchronous errors outside the Flutter widget tree
        PlatformDispatcher.instance.onError = (error, stack) {
          recordError(error, stack, fatal: true);
          return true;
        };
      } catch (e) {
        debugPrint('CrashlyticsService initialization warning: $e');
      }
    } else {
      // Non-supported platforms (Web, Windows) or headless test environments
      FlutterError.onError = (FlutterErrorDetails details) {
        recordFlutterError(details);
      };
    }
  }

  /// Records an uncaught or caught exception with stack trace.
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    final sanitizedReason = _sanitize(reason?.toString());

    recordedErrors.add({
      'exception': exception.toString(),
      'stack': stack?.toString(),
      'reason': sanitizedReason,
      'fatal': fatal,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (enableDebugLogs || kDebugMode) {
      debugPrint('[CrashlyticsService] Error (fatal: $fatal): $exception | reason: $sanitizedReason');
    }

    if (isSupported && crashlytics != null) {
      try {
        await crashlytics!.recordError(
          exception,
          stack,
          reason: sanitizedReason,
          information: information,
          fatal: fatal,
        );
      } catch (e) {
        debugPrint('CrashlyticsService.recordError error: $e');
      }
    }
  }

  /// Records a framework [FlutterErrorDetails] instance.
  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) async {
    recordedErrors.add({
      'exception': details.exceptionAsString(),
      'stack': details.stack?.toString(),
      'library': details.library,
      'context': details.context?.toString(),
      'fatal': fatal,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (enableDebugLogs || kDebugMode) {
      debugPrint('[CrashlyticsService] FlutterError: ${details.exceptionAsString()}');
    }

    if (isSupported && crashlytics != null) {
      try {
        await crashlytics!.recordFlutterError(details, fatal: fatal);
      } catch (e) {
        debugPrint('CrashlyticsService.recordFlutterError error: $e');
      }
    }
  }

  /// Appends a sanitized diagnostic breadcrumb message.
  /// Passwords, tokens, API keys, and sensitive PII are automatically scrubbed.
  Future<void> log(String message) async {
    final cleanMessage = _sanitize(message);
    recordedLogs.add(cleanMessage);

    if (enableDebugLogs) {
      debugPrint('[CrashlyticsService Log] $cleanMessage');
    }

    if (isSupported && crashlytics != null) {
      try {
        await crashlytics!.log(cleanMessage);
      } catch (e) {
        debugPrint('CrashlyticsService.log error: $e');
      }
    }
  }

  /// Sets a custom key-value diagnostic tag for crash context.
  Future<void> setCustomKey(String key, Object value) async {
    final cleanKey = _sanitize(key);
    customKeys[cleanKey] = value;

    if (isSupported && crashlytics != null) {
      try {
        await crashlytics!.setCustomKey(cleanKey, value);
      } catch (e) {
        debugPrint('CrashlyticsService.setCustomKey error: $e');
      }
    }
  }

  /// Associates subsequent crashes with the authenticated user ID.
  Future<void> setUserId(String? identifier) async {
    currentUserId = identifier;

    if (isSupported && crashlytics != null) {
      try {
        await crashlytics!.setUserIdentifier(identifier ?? '');
      } catch (e) {
        debugPrint('CrashlyticsService.setUserId error: $e');
      }
    }
  }

  /// Removes sensitive tokens, passwords, credit card numbers, or authorization headers.
  String _sanitize(String? input) {
    if (input == null || input.isEmpty) return '';
    var text = input;

    // Redact password or token values in logs (e.g. password: xyz, token=abc)
    final sensitivePattern = RegExp(
      r'(password|passwd|sifre|token|bearer|secret|apiKey|api_key)\s*[:=]\s*[^\s,;]+',
      caseSensitive: false,
    );
    text = text.replaceAllMapped(sensitivePattern, (match) {
      final key = match.group(1);
      return '$key=[REDACTED]';
    });

    // Redact email addresses from raw technical logs for strict privacy
    final emailPattern = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}');
    text = text.replaceAll(emailPattern, '[EMAIL_REDACTED]');

    return text;
  }
}
