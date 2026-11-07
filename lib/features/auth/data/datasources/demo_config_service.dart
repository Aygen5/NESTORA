import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';

/// Service responsible for securely retrieving Demo account credentials
/// from Firebase Remote Config, build environment variables (`--dart-define`),
/// or default configurations without exposing credentials in client logs.
class DemoConfigService {
  final FirebaseRemoteConfig? remoteConfig;

  const DemoConfigService({
    this.remoteConfig,
  });

  /// Initializes default Remote Config key-value pairs and attempts an activation.
  Future<void> initializeDefaults() async {
    if (remoteConfig == null) return;

    try {
      await remoteConfig!.setDefaults({
        AppConstants.remoteConfigDemoEmail: AppConstants.demoEmail,
        AppConstants.remoteConfigDemoPassword: AppConstants.demoPassword,
      });

      await remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 5),
          minimumFetchInterval: kDebugMode
              ? const Duration(seconds: 0)
              : const Duration(hours: 1),
        ),
      );

      await remoteConfig!.fetchAndActivate();
    } catch (e) {
      debugPrint('DemoConfigService: RemoteConfig init warning ($e)');
    }
  }

  /// Retrieves the active demo email from Remote Config, Dart environment, or defaults.
  Future<String> getDemoEmail() async {
    if (remoteConfig != null) {
      try {
        final remoteEmail =
            remoteConfig!.getString(AppConstants.remoteConfigDemoEmail).trim();
        if (remoteEmail.isNotEmpty) {
          return remoteEmail;
        }
      } catch (_) {}
    }

    const envEmail = String.fromEnvironment('DEMO_EMAIL');
    if (envEmail.trim().isNotEmpty) {
      return envEmail.trim();
    }

    return AppConstants.demoEmail;
  }

  /// Retrieves the active demo password from Remote Config, Dart environment, or defaults.
  Future<String> getDemoPassword() async {
    if (remoteConfig != null) {
      try {
        final remotePassword =
            remoteConfig!.getString(AppConstants.remoteConfigDemoPassword).trim();
        if (remotePassword.isNotEmpty) {
          return remotePassword;
        }
      } catch (_) {}
    }

    const envPassword = String.fromEnvironment('DEMO_PASSWORD');
    if (envPassword.trim().isNotEmpty) {
      return envPassword.trim();
    }

    return AppConstants.demoPassword;
  }
}
