import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/core/constants/app_constants.dart';
import 'package:nestora/core/services/performance_service.dart';
import 'package:nestora/core/services/remote_config_service.dart';
import 'package:nestora/core/widgets/nestora_announcement_banner.dart';

void main() {
  group('PerformanceService Unit Tests', () {
    late PerformanceService performanceService;

    setUp(() {
      performanceService = PerformanceService(enableDebugLogs: false);
    });

    test('starts and stops trace, records duration metric and custom attributes', () async {
      final trace = await performanceService.startTrace('firestore_fetch_devices');
      expect(trace.isRunning, isTrue);

      trace.putAttribute('user_id', 'usr-777');
      trace.setMetric('item_count', 12);
      trace.incrementMetric('item_count', 3);

      expect(trace.getAttribute('user_id'), 'usr-777');
      expect(trace.getMetric('item_count'), 15);

      await Future<void>.delayed(const Duration(milliseconds: 15));
      await performanceService.stopTrace('firestore_fetch_devices');

      expect(trace.isStopped, isTrue);
      expect(trace.durationMs, greaterThanOrEqualTo(10));
      expect(trace.getMetric('duration_ms'), greaterThanOrEqualTo(10));
      expect(performanceService.completedTraces.length, 1);
    });

    test('measureOperation executes action, records execution timing and returns result', () async {
      final result = await performanceService.measureOperation<int>(
        'heavy_calc',
        () async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return 42;
        },
        attributes: {'source': 'cache'},
        metrics: {'retry_count': 0},
      );

      expect(result, 42);
      expect(performanceService.completedTraces.length, 1);

      final completed = performanceService.completedTraces.first;
      expect(completed.name, 'heavy_calc');
      expect(completed.getAttribute('source'), 'cache');
      expect(completed.getMetric('retry_count'), 0);
      expect(completed.durationMs, greaterThanOrEqualTo(15));
    });

    test('measureNetworkCall records request latency and payload sizes', () async {
      await performanceService.measureNetworkCall(
        url: 'https://firestore.googleapis.com/v1/projects/nestora',
        method: 'POST',
        responseCode: 200,
        durationMs: 145,
        requestPayloadBytes: 512,
        responsePayloadBytes: 2048,
      );

      expect(performanceService.recordedNetworkMetrics.length, 1);
      final metric = performanceService.recordedNetworkMetrics.first;
      expect(metric['url'], contains('firestore.googleapis.com'));
      expect(metric['method'], 'POST');
      expect(metric['responseCode'], 200);
      expect(metric['durationMs'], 145);
      expect(metric['requestPayloadBytes'], 512);
      expect(metric['responsePayloadBytes'], 2048);
    });

    test('PerformanceRouteObserver tracks screen transition and layout duration', () async {
      final observer = performanceService.getRouteObserver();
      expect(observer, isA<PerformanceRouteObserver>());

      final route = MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'DashboardScreen'),
        builder: (_) => const Scaffold(body: Text('Dashboard Content')),
      );

      observer.didPush(route, null);
      expect(performanceService.activeTraces.containsKey('screen_render_DashboardScreen'), isTrue);
    });
  });

  group('RemoteConfigService Unit Tests', () {
    late RemoteConfigService remoteConfigService;

    setUp(() {
      remoteConfigService = RemoteConfigService(enableDebugLogs: false);
    });

    test('provides built-in Spark default parameters', () {
      expect(remoteConfigService.demoEmail, AppConstants.demoEmail);
      expect(remoteConfigService.demoPassword, AppConstants.demoPassword);
      expect(remoteConfigService.isMaintenanceMode, isFalse);
      expect(remoteConfigService.minSupportedVersion, '1.0.0');
      expect(remoteConfigService.maxRoomsPerUser, 20);
      expect(remoteConfigService.maxDevicesPerRoom, 50);
      expect(remoteConfigService.isEnergyTipEnabled, isTrue);

      final announcement = remoteConfigService.announcement;
      expect(announcement.isEnabled, isFalse);
      expect(announcement.hasContent, isFalse);
    });

    test('evaluates dynamic parameter overrides correctly', () {
      remoteConfigService.setOverride(AppConstants.remoteConfigMaintenanceMode, true);
      remoteConfigService.setOverride(AppConstants.remoteConfigMaxRoomsPerUser, 35);
      remoteConfigService.setOverride(AppConstants.remoteConfigAnnouncementEnabled, true);
      remoteConfigService.setOverride(AppConstants.remoteConfigAnnouncementTitle, 'Bakım Duyurusu');
      remoteConfigService.setOverride(AppConstants.remoteConfigAnnouncementMessage, 'Sunucularda planlı bakım yapılmaktadır.');
      remoteConfigService.setOverride(AppConstants.remoteConfigAnnouncementType, 'warning');

      expect(remoteConfigService.isMaintenanceMode, isTrue);
      expect(remoteConfigService.maxRoomsPerUser, 35);

      final announcement = remoteConfigService.announcement;
      expect(announcement.isEnabled, isTrue);
      expect(announcement.hasContent, isTrue);
      expect(announcement.title, 'Bakım Duyurusu');
      expect(announcement.message, 'Sunucularda planlı bakım yapılmaktadır.');
      expect(announcement.type, 'warning');
      expect(announcement.isDismissible, isTrue);

      remoteConfigService.clearOverrides();
      expect(remoteConfigService.isMaintenanceMode, isFalse);
      expect(remoteConfigService.announcement.hasContent, isFalse);
    });

    test('typed getters handle various input types gracefully', () {
      remoteConfigService.setOverride('test_string', 'hello');
      remoteConfigService.setOverride('test_bool_str', 'true');
      remoteConfigService.setOverride('test_int_str', '42');
      remoteConfigService.setOverride('test_double_str', '3.14');

      expect(remoteConfigService.getString('test_string'), 'hello');
      expect(remoteConfigService.getBool('test_bool_str'), isTrue);
      expect(remoteConfigService.getInt('test_int_str'), 42);
      expect(remoteConfigService.getDouble('test_double_str'), 3.14);
    });
  });

  group('NestoraAnnouncementBanner Widget Tests', () {
    testWidgets('renders nothing when announcement has no content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NestoraAnnouncementBanner(
              announcement: AppAnnouncement(isEnabled: false),
            ),
          ),
        ),
      );

      expect(find.byType(NestoraAnnouncementBanner), findsOneWidget);
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('renders warning broadcast banner with title, message and icon', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NestoraAnnouncementBanner(
              announcement: const AppAnnouncement(
                isEnabled: true,
                title: 'Hava Durumu Uyarısı',
                message: 'Bölgenizde fırtına bekleniyor. Camları kapatmanız önerilir.',
                type: 'warning',
                isDismissible: true,
              ),
              onDismiss: () {
                dismissed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Hava Durumu Uyarısı'), findsOneWidget);
      expect(find.text('Bölgenizde fırtına bekleniyor. Camları kapatmanız önerilir.'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(dismissed, isTrue);
    });

    testWidgets('renders update broadcast banner without dismiss button when isDismissible is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NestoraAnnouncementBanner(
              announcement: AppAnnouncement(
                isEnabled: true,
                title: 'Yeni Sürüm Yayında',
                message: 'Nestora v1.1 sürümü yeniliklerle App Store ve Play Store’da.',
                type: 'update',
                isDismissible: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Yeni Sürüm Yayında'), findsOneWidget);
      expect(find.byIcon(Icons.system_update_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });
  });
}
