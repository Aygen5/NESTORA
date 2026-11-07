import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/core/constants/app_constants.dart';
import 'package:nestora/features/auth/data/datasources/demo_config_service.dart';
import 'package:nestora/features/auth/data/datasources/firestore_seed_service.dart';

void main() {
  group('DemoConfigService Tests', () {
    test('returns default constants when RemoteConfig is null and no dart-define is set', () async {
      const service = DemoConfigService(remoteConfig: null);

      final email = await service.getDemoEmail();
      final password = await service.getDemoPassword();

      expect(email, AppConstants.demoEmail);
      expect(password, AppConstants.demoPassword);
    });

    test('initializeDefaults executes safely without exception when remoteConfig is null', () async {
      const service = DemoConfigService(remoteConfig: null);
      await expectLater(service.initializeDefaults(), completes);
    });
  });

  group('FirestoreSeedService Safety Tests', () {
    test('returns false gracefully when firestore instance is null', () async {
      const service = FirestoreSeedService(firestore: null);

      final result = await service.seedDemoUserDataIfEmpty(
        'test-uid',
        displayName: 'Aygen Yıldırım',
        email: 'demo@nestora.app',
      );

      expect(result, isFalse);
    });
  });
}
