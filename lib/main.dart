import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/di/injection.dart';
import 'core/services/crashlytics_service.dart';
import 'core/services/performance_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase servislerini platforma uygun ayarlarla başlatır.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization notice: $e');
    if (kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // Bağımlılık enjeksiyonunu (ServiceLocator) kurar.
  await initDependencies();

  // Global hata ve çökme takip servisini (Crashlytics) başlatır.
  if (sl.isRegistered<CrashlyticsService>()) {
    await sl<CrashlyticsService>().initialize();
  }

  // Uygulama performans izleme servisini başlatır.
  if (sl.isRegistered<PerformanceService>()) {
    await sl<PerformanceService>().initialize();
  }

  runApp(const NestoraApp());
}
