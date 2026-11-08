import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/crashlytics_service.dart';
import '../../core/services/performance_service.dart';
import '../../core/services/remote_config_service.dart';
import '../../core/services/spark_quota_service.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/demo_config_service.dart';
import '../../features/auth/data/datasources/firestore_seed_service.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/devices/data/datasources/devices_remote_data_source.dart';
import '../../features/devices/data/repositories/devices_repository_impl.dart';
import '../../features/devices/domain/repositories/devices_repository.dart';
import '../../features/devices/presentation/cubit/devices_cubit.dart';
import '../../features/notifications/data/datasources/notifications_remote_data_source.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/profile/data/datasources/profile_photo_service.dart';
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/rooms/data/datasources/rooms_remote_data_source.dart';
import '../../features/rooms/data/repositories/rooms_repository_impl.dart';
import '../../features/rooms/domain/repositories/rooms_repository.dart';
import '../../features/rooms/presentation/cubit/rooms_cubit.dart';
import '../router/auth_guard.dart';
import '../theme/theme_cubit.dart';

typedef FactoryFunc<T> = T Function();

/// [ServiceLocator] provides a lightweight, type-safe, reflection-free dependency
/// injection and service lookup mechanism for Nestora.
class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator _instance = ServiceLocator._();

  /// Singleton instance of the locator.
  static ServiceLocator get instance => _instance;

  final Map<Type, dynamic> _singletons = {};
  final Map<Type, FactoryFunc<dynamic>> _lazySingletons = {};
  final Map<Type, FactoryFunc<dynamic>> _factories = {};

  /// Registers an already instantiated singleton of type [T].
  void registerSingleton<T extends Object>(T instance) {
    if (isRegistered<T>()) {
      throw StateError('ServiceLocator: Type $T is already registered.');
    }
    _singletons[T] = instance;
  }

  /// Registers a lazy singleton of type [T] that will be instantiated upon first access.
  void registerLazySingleton<T extends Object>(FactoryFunc<T> factory) {
    if (isRegistered<T>()) {
      throw StateError('ServiceLocator: Type $T is already registered.');
    }
    _lazySingletons[T] = factory;
  }

  /// Registers a factory of type [T] that creates a new instance on every request.
  void registerFactory<T extends Object>(FactoryFunc<T> factory) {
    if (isRegistered<T>()) {
      throw StateError('ServiceLocator: Type $T is already registered.');
    }
    _factories[T] = factory;
  }

  /// Retrieves an instance of type [T].
  T get<T extends Object>() {
    // 1. Check existing singletons
    if (_singletons.containsKey(T)) {
      return _singletons[T] as T;
    }

    // 2. Check lazy singletons
    if (_lazySingletons.containsKey(T)) {
      final instance = _lazySingletons[T]!() as T;
      _singletons[T] = instance;
      _lazySingletons.remove(T);
      return instance;
    }

    // 3. Check factories
    if (_factories.containsKey(T)) {
      return _factories[T]!() as T;
    }

    throw StateError('ServiceLocator: Type $T is not registered.');
  }

  /// Shortcut callable syntax: `sl<T>()` or `locator<T>()`
  T call<T extends Object>() => get<T>();

  /// Checks if type [T] is registered in any form.
  bool isRegistered<T extends Object>() {
    return _singletons.containsKey(T) ||
        _lazySingletons.containsKey(T) ||
        _factories.containsKey(T);
  }

  /// Unregisters type [T] if registered.
  void unregister<T extends Object>() {
    _singletons.remove(T);
    _lazySingletons.remove(T);
    _factories.remove(T);
  }

  /// Resets all registrations. Primarily used for clean test teardowns.
  void reset() {
    _singletons.clear();
    _lazySingletons.clear();
    _factories.clear();
  }
}

/// Global Service Locator instance accessor (short alias).
final sl = ServiceLocator.instance;

/// Global Service Locator instance accessor (standard alias).
final locator = ServiceLocator.instance;

/// Initializes core infrastructure dependencies:
/// - [SharedPreferences]
/// - [FirebaseAuth]
/// - [FirebaseFirestore]
/// - [FirebaseAnalytics]
/// - [FirebaseRemoteConfig]
/// - [CrashlyticsService]
/// - [AnalyticsService]
/// - [PerformanceService]
/// - [RemoteConfigService]
/// - [SparkQuotaService]
///
/// In subsequent phases, Data Sources and Repositories will be registered here.
Future<void> initDependencies({
  SharedPreferences? sharedPreferences,
  FirebaseAuth? firebaseAuth,
  FirebaseFirestore? firebaseFirestore,
  FirebaseAnalytics? firebaseAnalytics,
  FirebaseRemoteConfig? firebaseRemoteConfig,
  FirebaseCrashlytics? firebaseCrashlytics,
  FirebasePerformance? firebasePerformance,
  CrashlyticsService? crashlyticsService,
  AnalyticsService? analyticsService,
  PerformanceService? performanceService,
  RemoteConfigService? remoteConfigService,
  SparkQuotaService? sparkQuotaService,
}) async {
  // 1. SharedPreferences (Local key-value storage)
  if (!sl.isRegistered<SharedPreferences>()) {
    final prefs = sharedPreferences ?? await SharedPreferences.getInstance();
    sl.registerSingleton<SharedPreferences>(prefs);
  }

  // 2. Firebase Services (Registered safely with optional test overrides)
  if (firebaseAuth != null) {
    if (!sl.isRegistered<FirebaseAuth>()) {
      sl.registerSingleton<FirebaseAuth>(firebaseAuth);
    }
  } else {
    try {
      if (!sl.isRegistered<FirebaseAuth>()) {
        sl.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
      }
    } catch (e) {
      debugPrint('ServiceLocator: FirebaseAuth could not be initialized ($e)');
    }
  }

  if (firebaseFirestore != null) {
    if (!sl.isRegistered<FirebaseFirestore>()) {
      sl.registerSingleton<FirebaseFirestore>(firebaseFirestore);
    }
  } else {
    try {
      if (!sl.isRegistered<FirebaseFirestore>()) {
        sl.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
      }
    } catch (e) {
      debugPrint('ServiceLocator: FirebaseFirestore could not be initialized ($e)');
    }
  }

  if (firebaseAnalytics != null) {
    if (!sl.isRegistered<FirebaseAnalytics>()) {
      sl.registerSingleton<FirebaseAnalytics>(firebaseAnalytics);
    }
  } else {
    try {
      if (!sl.isRegistered<FirebaseAnalytics>()) {
        sl.registerSingleton<FirebaseAnalytics>(FirebaseAnalytics.instance);
      }
    } catch (e) {
      debugPrint('ServiceLocator: FirebaseAnalytics could not be initialized ($e)');
    }
  }

  if (firebaseRemoteConfig != null) {
    if (!sl.isRegistered<FirebaseRemoteConfig>()) {
      sl.registerSingleton<FirebaseRemoteConfig>(firebaseRemoteConfig);
    }
  } else {
    try {
      if (!sl.isRegistered<FirebaseRemoteConfig>()) {
        sl.registerSingleton<FirebaseRemoteConfig>(FirebaseRemoteConfig.instance);
      }
    } catch (e) {
      debugPrint('ServiceLocator: FirebaseRemoteConfig could not be initialized ($e)');
    }
  }

  // 2.1 Crashlytics & Analytics Services
  if (crashlyticsService != null) {
    if (!sl.isRegistered<CrashlyticsService>()) {
      sl.registerSingleton<CrashlyticsService>(crashlyticsService);
    }
  } else if (!sl.isRegistered<CrashlyticsService>()) {
    FirebaseCrashlytics? crashlytics;
    if (firebaseCrashlytics != null) {
      crashlytics = firebaseCrashlytics;
    } else {
      try {
        if (!kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS)) {
          crashlytics = FirebaseCrashlytics.instance;
        }
      } catch (e) {
        debugPrint('ServiceLocator: FirebaseCrashlytics could not be initialized ($e)');
      }
    }
    sl.registerSingleton<CrashlyticsService>(
      CrashlyticsService(crashlytics: crashlytics),
    );
  }

  if (analyticsService != null) {
    if (!sl.isRegistered<AnalyticsService>()) {
      sl.registerSingleton<AnalyticsService>(analyticsService);
    }
  } else if (!sl.isRegistered<AnalyticsService>()) {
    FirebaseAnalytics? analytics =
        sl.isRegistered<FirebaseAnalytics>() ? sl<FirebaseAnalytics>() : null;
    sl.registerSingleton<AnalyticsService>(
      AnalyticsService(analytics: analytics),
    );
  }

  // 2.2 Performance Service
  if (performanceService != null) {
    if (!sl.isRegistered<PerformanceService>()) {
      sl.registerSingleton<PerformanceService>(performanceService);
    }
  } else if (!sl.isRegistered<PerformanceService>()) {
    FirebasePerformance? perf;
    if (firebasePerformance != null) {
      perf = firebasePerformance;
    } else {
      try {
        if (!kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS)) {
          perf = FirebasePerformance.instance;
        }
      } catch (e) {
        debugPrint('ServiceLocator: FirebasePerformance could not be initialized ($e)');
      }
    }
    sl.registerSingleton<PerformanceService>(
      PerformanceService(performance: perf),
    );
  }

  // 2.3 Remote Config Service
  if (remoteConfigService != null) {
    if (!sl.isRegistered<RemoteConfigService>()) {
      sl.registerSingleton<RemoteConfigService>(remoteConfigService);
    }
  } else if (!sl.isRegistered<RemoteConfigService>()) {
    final rcService = RemoteConfigService(
      remoteConfig: sl.isRegistered<FirebaseRemoteConfig>()
          ? sl<FirebaseRemoteConfig>()
          : null,
    );
    rcService.initializeDefaults();
    sl.registerSingleton<RemoteConfigService>(rcService);
  }

  // 2.4 Spark Quota Service (Firebase Spark Plan Quota Guard)
  if (sparkQuotaService != null) {
    if (!sl.isRegistered<SparkQuotaService>()) {
      sl.registerSingleton<SparkQuotaService>(sparkQuotaService);
    }
  } else if (!sl.isRegistered<SparkQuotaService>()) {
    sl.registerSingleton<SparkQuotaService>(
      SparkQuotaService(
        remoteConfigService: sl.isRegistered<RemoteConfigService>()
            ? sl<RemoteConfigService>()
            : null,
        crashlyticsService: sl.isRegistered<CrashlyticsService>()
            ? sl<CrashlyticsService>()
            : null,
      ),
    );
  }

  // 3. Auth Redirect Listenable for GoRouter
  if (!sl.isRegistered<AppAuthListenable>()) {
    FirebaseAuth? auth;
    if (sl.isRegistered<FirebaseAuth>()) {
      auth = sl<FirebaseAuth>();
    }
    sl.registerSingleton<AppAuthListenable>(AppAuthListenable(firebaseAuth: auth));
  }

  // 4. Demo Config & Firestore Seed Services
  if (!sl.isRegistered<DemoConfigService>()) {
    final demoConfig = DemoConfigService(
      remoteConfig: sl.isRegistered<FirebaseRemoteConfig>()
          ? sl<FirebaseRemoteConfig>()
          : null,
      remoteConfigService: sl.isRegistered<RemoteConfigService>()
          ? sl<RemoteConfigService>()
          : null,
    );
    demoConfig.initializeDefaults();
    sl.registerSingleton<DemoConfigService>(demoConfig);
  }

  if (!sl.isRegistered<FirestoreSeedService>()) {
    sl.registerLazySingleton<FirestoreSeedService>(
      () => FirestoreSeedService(
        firestore: sl.isRegistered<FirebaseFirestore>()
            ? sl<FirebaseFirestore>()
            : null,
      ),
    );
  }

  // 5. Auth Data Source & Repository
  if (!sl.isRegistered<AuthRemoteDataSource>()) {
    sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(
        firebaseAuth: sl.isRegistered<FirebaseAuth>() ? sl<FirebaseAuth>() : null,
        firestore: sl.isRegistered<FirebaseFirestore>() ? sl<FirebaseFirestore>() : null,
        demoConfigService: sl.isRegistered<DemoConfigService>()
            ? sl<DemoConfigService>()
            : null,
        seedService: sl.isRegistered<FirestoreSeedService>()
            ? sl<FirestoreSeedService>()
            : null,
      ),
    );
  }

  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDataSource: sl<AuthRemoteDataSource>(),
        sharedPreferences:
            sl.isRegistered<SharedPreferences>() ? sl<SharedPreferences>() : null,
      ),
    );
  }

  // 6. Auth Cubit
  if (!sl.isRegistered<AuthCubit>()) {
    sl.registerFactory<AuthCubit>(
      () => AuthCubit(
        authRepository: sl<AuthRepository>(),
        analyticsService:
            sl.isRegistered<AnalyticsService>() ? sl<AnalyticsService>() : null,
        crashlyticsService:
            sl.isRegistered<CrashlyticsService>() ? sl<CrashlyticsService>() : null,
      ),
    );
  }

  // 7. Feature Remote Data Sources
  if (!sl.isRegistered<RoomsRemoteDataSource>()) {
    sl.registerLazySingleton<RoomsRemoteDataSource>(
      () => RoomsRemoteDataSourceImpl(
        firestore: sl.isRegistered<FirebaseFirestore>()
            ? sl<FirebaseFirestore>()
            : null,
      ),
    );
  }

  if (!sl.isRegistered<DevicesRemoteDataSource>()) {
    sl.registerLazySingleton<DevicesRemoteDataSource>(
      () => DevicesRemoteDataSourceImpl(
        firestore: sl.isRegistered<FirebaseFirestore>()
            ? sl<FirebaseFirestore>()
            : null,
      ),
    );
  }

  if (!sl.isRegistered<NotificationsRemoteDataSource>()) {
    sl.registerLazySingleton<NotificationsRemoteDataSource>(
      () => NotificationsRemoteDataSourceImpl(
        firestore: sl.isRegistered<FirebaseFirestore>()
            ? sl<FirebaseFirestore>()
            : null,
      ),
    );
  }

  if (!sl.isRegistered<ProfileRemoteDataSource>()) {
    sl.registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSourceImpl(
        firestore: sl.isRegistered<FirebaseFirestore>()
            ? sl<FirebaseFirestore>()
            : null,
      ),
    );
  }

  // 8. Feature Repositories
  if (!sl.isRegistered<RoomsRepository>()) {
    sl.registerLazySingleton<RoomsRepository>(
      () => RoomsRepositoryImpl(
        remoteDataSource: sl<RoomsRemoteDataSource>(),
      ),
    );
  }

  if (!sl.isRegistered<DevicesRepository>()) {
    sl.registerLazySingleton<DevicesRepository>(
      () => DevicesRepositoryImpl(
        remoteDataSource: sl<DevicesRemoteDataSource>(),
      ),
    );
  }

  if (!sl.isRegistered<NotificationsRepository>()) {
    sl.registerLazySingleton<NotificationsRepository>(
      () => NotificationsRepositoryImpl(
        remoteDataSource: sl<NotificationsRemoteDataSource>(),
      ),
    );
  }

  if (!sl.isRegistered<ProfileRepository>()) {
    sl.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(
        remoteDataSource: sl<ProfileRemoteDataSource>(),
      ),
    );
  }

  // 9. Profile Photo Service & Profile Cubit
  if (!sl.isRegistered<ProfilePhotoService>()) {
    sl.registerLazySingleton<ProfilePhotoService>(
      () => ProfilePhotoServiceImpl(),
    );
  }

  if (!sl.isRegistered<ProfileCubit>()) {
    sl.registerFactory<ProfileCubit>(
      () => ProfileCubit(
        profileRepository: sl<ProfileRepository>(),
        photoService: sl<ProfilePhotoService>(),
        sharedPreferences:
            sl.isRegistered<SharedPreferences>() ? sl<SharedPreferences>() : null,
        quotaService:
            sl.isRegistered<SparkQuotaService>() ? sl<SparkQuotaService>() : null,
      ),
    );
  }

  // 10. Rooms Cubit
  if (!sl.isRegistered<RoomsCubit>()) {
    sl.registerFactory<RoomsCubit>(
      () => RoomsCubit(
        roomsRepository: sl<RoomsRepository>(),
        devicesRepository: sl<DevicesRepository>(),
        analyticsService:
            sl.isRegistered<AnalyticsService>() ? sl<AnalyticsService>() : null,
        crashlyticsService:
            sl.isRegistered<CrashlyticsService>() ? sl<CrashlyticsService>() : null,
        quotaService:
            sl.isRegistered<SparkQuotaService>() ? sl<SparkQuotaService>() : null,
      ),
    );
  }

  // 11. Devices Cubit
  if (!sl.isRegistered<DevicesCubit>()) {
    sl.registerFactory<DevicesCubit>(
      () => DevicesCubit(
        devicesRepository: sl<DevicesRepository>(),
        analyticsService:
            sl.isRegistered<AnalyticsService>() ? sl<AnalyticsService>() : null,
        crashlyticsService:
            sl.isRegistered<CrashlyticsService>() ? sl<CrashlyticsService>() : null,
        quotaService:
            sl.isRegistered<SparkQuotaService>() ? sl<SparkQuotaService>() : null,
      ),
    );
  }

  // 12. Notifications Cubit
  if (!sl.isRegistered<NotificationsCubit>()) {
    sl.registerFactory<NotificationsCubit>(
      () => NotificationsCubit(
        notificationsRepository: sl<NotificationsRepository>(),
        quotaService:
            sl.isRegistered<SparkQuotaService>() ? sl<SparkQuotaService>() : null,
      ),
    );
  }

  // 13. Theme Cubit
  if (!sl.isRegistered<ThemeCubit>()) {
    sl.registerFactory<ThemeCubit>(
      () => ThemeCubit(
        analyticsService:
            sl.isRegistered<AnalyticsService>() ? sl<AnalyticsService>() : null,
      ),
    );
  }
}
