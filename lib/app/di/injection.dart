import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/network_info.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/crashlytics_service.dart';
import '../../core/services/local_cache_service.dart';
import '../../core/services/performance_service.dart';
import '../../core/services/remote_config_service.dart';
import '../../core/services/secure_image_service.dart';
import '../../core/services/spark_quota_service.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/demo_config_service.dart';
import '../../features/auth/data/datasources/firestore_seed_service.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/devices/data/datasources/devices_remote_data_source.dart';
import '../../features/devices/data/repositories/devices_repository_impl.dart';
import '../../features/devices/domain/repositories/devices_repository.dart';
import '../../features/devices/domain/usecases/devices_usecases.dart';
import '../../features/devices/presentation/cubit/devices_cubit.dart';
import '../../features/notifications/data/datasources/notifications_remote_data_source.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/domain/usecases/notifications_usecases.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/profile/data/datasources/profile_photo_service.dart';
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/profile_usecases.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/rooms/data/datasources/rooms_remote_data_source.dart';
import '../../features/rooms/data/repositories/rooms_repository_impl.dart';
import '../../features/rooms/domain/repositories/rooms_repository.dart';
import '../../features/rooms/domain/usecases/rooms_usecases.dart';
import '../../features/rooms/presentation/cubit/rooms_cubit.dart';
import '../router/auth_guard.dart';
import '../theme/theme_cubit.dart';

typedef FactoryFunc<T> = T Function();

// Nestora için tip güvenli, yansıma (reflection) içermeyen bağımlılık enjeksiyonu yöneticisi.
class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator _instance = ServiceLocator._();

  // Servis bulucunun tekil (singleton) örneğini döndürür.
  static ServiceLocator get instance => _instance;

  final Map<Type, dynamic> _singletons = {};
  final Map<Type, FactoryFunc<dynamic>> _lazySingletons = {};
  final Map<Type, FactoryFunc<dynamic>> _factories = {};

  // Önceden oluşturulmuş bir nesneyi tekil örnek (singleton) olarak kaydeder.
  void registerSingleton<T extends Object>(T instance) {
    if (isRegistered<T>()) {
      throw StateError('ServiceLocator: Type $T is already registered.');
    }
    _singletons[T] = instance;
  }

  // İlk erişimde oluşturulacak tembel tekil örneği (lazy singleton) kaydeder.
  void registerLazySingleton<T extends Object>(FactoryFunc<T> factory) {
    if (isRegistered<T>()) {
      throw StateError('ServiceLocator: Type $T is already registered.');
    }
    _lazySingletons[T] = factory;
  }

  // Her çağrıda yeni bir örnek üreten fabrika fonksiyonunu kaydeder.
  void registerFactory<T extends Object>(FactoryFunc<T> factory) {
    if (isRegistered<T>()) {
      throw StateError('ServiceLocator: Type $T is already registered.');
    }
    _factories[T] = factory;
  }

  // Kayıtlı örneği tipine göre bulup döndürür.
  T get<T extends Object>() {
    // 1. Mevcut tekil örnekleri kontrol et.
    if (_singletons.containsKey(T)) {
      return _singletons[T] as T;
    }

    // 2. Tembel tekil örnekleri kontrol et ve oluştur.
    if (_lazySingletons.containsKey(T)) {
      final instance = _lazySingletons[T]!() as T;
      _singletons[T] = instance;
      _lazySingletons.remove(T);
      return instance;
    }

    // 3. Fabrika kayıtlarını kontrol et ve yeni örnek üret.
    if (_factories.containsKey(T)) {
      return _factories[T]!() as T;
    }

    throw StateError('ServiceLocator: Type $T is not registered.');
  }

  // Kısa çağrı sözdizimi: `sl<T>()`
  T call<T extends Object>() => get<T>();

  // Verilen tipin kayıtlı olup olmadığını kontrol eder.
  bool isRegistered<T extends Object>() {
    return _singletons.containsKey(T) ||
        _lazySingletons.containsKey(T) ||
        _factories.containsKey(T);
  }

  // Belirtilen tipin kaydını siler.
  void unregister<T extends Object>() {
    _singletons.remove(T);
    _lazySingletons.remove(T);
    _factories.remove(T);
  }

  // Tüm kayıtları sıfırlar; test temizliklerinde kullanılır.
  void reset() {
    _singletons.clear();
    _lazySingletons.clear();
    _factories.clear();
  }
}

// Global bağımlılık bulucu örneği (kısa alias).
final sl = ServiceLocator.instance;

// Global bağımlılık bulucu örneği (standart alias).
final locator = ServiceLocator.instance;

// Tüm çekirdek servisleri, veri kaynaklarını, repository ve use case'leri kaydeder.
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
  // 1. SharedPreferences (Yerel anahtar-değer depolama)
  if (!sl.isRegistered<SharedPreferences>()) {
    final prefs = sharedPreferences ?? await SharedPreferences.getInstance();
    sl.registerSingleton<SharedPreferences>(prefs);
  }

  // 1.1 LocalCacheService (Oturum bazlı izole yerel önbellek)
  if (!sl.isRegistered<LocalCacheService>()) {
    sl.registerSingleton<LocalCacheService>(
      LocalCacheService(
        prefs: sl.isRegistered<SharedPreferences>() ? sl<SharedPreferences>() : null,
      ),
    );
  }

  // 1.2 NetworkInfo (Ağ bağlantı durumu kontrolü)
  if (!sl.isRegistered<NetworkInfo>()) {
    sl.registerSingleton<NetworkInfo>(const NetworkInfoImpl());
  }

  // 2. Firebase Servisleri (Güvenli ve test edilebilir singleton kayıtları)
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

  // 2.1 Crashlytics ve Analytics Servisleri
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

  // 2.2 Performance İzleme Servisi
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

  // 2.3 Remote Config Servisi
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

  // 2.4 Spark Kota Koruma Servisi (SparkQuotaService)
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

  // 3. GoRouter için Auth Yönlendirme Dinleyicisi
  if (!sl.isRegistered<AppAuthListenable>()) {
    FirebaseAuth? auth;
    if (sl.isRegistered<FirebaseAuth>()) {
      auth = sl<FirebaseAuth>();
    }
    sl.registerSingleton<AppAuthListenable>(AppAuthListenable(
      firebaseAuth: auth,
      sharedPreferences:
          sl.isRegistered<SharedPreferences>() ? sl<SharedPreferences>() : null,
    ));
  }

  // 4. Demo Yapılandırma ve Firestore Tohumlama Servisi
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

  // 5. Kimlik Doğrulama Veri Kaynağı ve Deposu
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

  // 6. Kimlik Doğrulama Durum Yönetimi (AuthCubit)
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

  // 7. Özellik Uzak Veri Kaynakları (Data Sources)
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

  // 8. Özellik Depoları (Repositories)
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

  // 8.1 İş Mantığı Kullanım Senaryoları (Use Cases)
  // Kimlik Doğrulama Senaryoları
  if (!sl.isRegistered<SignInWithEmailUseCase>()) {
    sl.registerLazySingleton<SignInWithEmailUseCase>(() => SignInWithEmailUseCase(sl<AuthRepository>()));
  }
  if (!sl.isRegistered<SignUpWithEmailUseCase>()) {
    sl.registerLazySingleton<SignUpWithEmailUseCase>(() => SignUpWithEmailUseCase(sl<AuthRepository>()));
  }
  if (!sl.isRegistered<SignInDemoUseCase>()) {
    sl.registerLazySingleton<SignInDemoUseCase>(() => SignInDemoUseCase(sl<AuthRepository>()));
  }
  if (!sl.isRegistered<SignOutUseCase>()) {
    sl.registerLazySingleton<SignOutUseCase>(() => SignOutUseCase(sl<AuthRepository>()));
  }
  if (!sl.isRegistered<SendPasswordResetUseCase>()) {
    sl.registerLazySingleton<SendPasswordResetUseCase>(() => SendPasswordResetUseCase(sl<AuthRepository>()));
  }
  if (!sl.isRegistered<GetCurrentUserUseCase>()) {
    sl.registerLazySingleton<GetCurrentUserUseCase>(() => GetCurrentUserUseCase(sl<AuthRepository>()));
  }
  if (!sl.isRegistered<WatchAuthStateUseCase>()) {
    sl.registerLazySingleton<WatchAuthStateUseCase>(() => WatchAuthStateUseCase(sl<AuthRepository>()));
  }

  // Cihaz İşlem Senaryoları
  if (!sl.isRegistered<GetDevicesUseCase>()) {
    sl.registerLazySingleton<GetDevicesUseCase>(() => GetDevicesUseCase(sl<DevicesRepository>()));
  }
  if (!sl.isRegistered<WatchDevicesUseCase>()) {
    sl.registerLazySingleton<WatchDevicesUseCase>(() => WatchDevicesUseCase(sl<DevicesRepository>()));
  }
  if (!sl.isRegistered<ToggleDevicePowerUseCase>()) {
    sl.registerLazySingleton<ToggleDevicePowerUseCase>(() => ToggleDevicePowerUseCase(sl<DevicesRepository>()));
  }
  if (!sl.isRegistered<UpdateDeviceStateUseCase>()) {
    sl.registerLazySingleton<UpdateDeviceStateUseCase>(() => UpdateDeviceStateUseCase(sl<DevicesRepository>()));
  }
  if (!sl.isRegistered<CreateDeviceUseCase>()) {
    sl.registerLazySingleton<CreateDeviceUseCase>(() => CreateDeviceUseCase(sl<DevicesRepository>()));
  }
  if (!sl.isRegistered<UpdateDeviceUseCase>()) {
    sl.registerLazySingleton<UpdateDeviceUseCase>(() => UpdateDeviceUseCase(sl<DevicesRepository>()));
  }
  if (!sl.isRegistered<DeleteDeviceUseCase>()) {
    sl.registerLazySingleton<DeleteDeviceUseCase>(() => DeleteDeviceUseCase(sl<DevicesRepository>()));
  }
  if (!sl.isRegistered<MoveDevicesToRoomUseCase>()) {
    sl.registerLazySingleton<MoveDevicesToRoomUseCase>(() => MoveDevicesToRoomUseCase(sl<DevicesRepository>()));
  }

  // Oda İşlem Senaryoları
  if (!sl.isRegistered<GetRoomsUseCase>()) {
    sl.registerLazySingleton<GetRoomsUseCase>(() => GetRoomsUseCase(sl<RoomsRepository>()));
  }
  if (!sl.isRegistered<WatchRoomsUseCase>()) {
    sl.registerLazySingleton<WatchRoomsUseCase>(() => WatchRoomsUseCase(sl<RoomsRepository>()));
  }
  if (!sl.isRegistered<CreateRoomUseCase>()) {
    sl.registerLazySingleton<CreateRoomUseCase>(() => CreateRoomUseCase(sl<RoomsRepository>()));
  }
  if (!sl.isRegistered<UpdateRoomUseCase>()) {
    sl.registerLazySingleton<UpdateRoomUseCase>(() => UpdateRoomUseCase(sl<RoomsRepository>()));
  }
  if (!sl.isRegistered<DeleteRoomUseCase>()) {
    sl.registerLazySingleton<DeleteRoomUseCase>(() => DeleteRoomUseCase(sl<RoomsRepository>()));
  }

  // Bildirim Senaryoları
  if (!sl.isRegistered<GetNotificationsUseCase>()) {
    sl.registerLazySingleton<GetNotificationsUseCase>(() => GetNotificationsUseCase(sl<NotificationsRepository>()));
  }
  if (!sl.isRegistered<WatchNotificationsUseCase>()) {
    sl.registerLazySingleton<WatchNotificationsUseCase>(() => WatchNotificationsUseCase(sl<NotificationsRepository>()));
  }
  if (!sl.isRegistered<MarkNotificationReadUseCase>()) {
    sl.registerLazySingleton<MarkNotificationReadUseCase>(() => MarkNotificationReadUseCase(sl<NotificationsRepository>()));
  }
  if (!sl.isRegistered<MarkAllNotificationsReadUseCase>()) {
    sl.registerLazySingleton<MarkAllNotificationsReadUseCase>(() => MarkAllNotificationsReadUseCase(sl<NotificationsRepository>()));
  }
  if (!sl.isRegistered<DeleteNotificationUseCase>()) {
    sl.registerLazySingleton<DeleteNotificationUseCase>(() => DeleteNotificationUseCase(sl<NotificationsRepository>()));
  }
  if (!sl.isRegistered<CreateNotificationUseCase>()) {
    sl.registerLazySingleton<CreateNotificationUseCase>(() => CreateNotificationUseCase(sl<NotificationsRepository>()));
  }

  // Profil Senaryoları
  if (!sl.isRegistered<GetUserProfileUseCase>()) {
    sl.registerLazySingleton<GetUserProfileUseCase>(() => GetUserProfileUseCase(sl<ProfileRepository>()));
  }
  if (!sl.isRegistered<WatchUserProfileUseCase>()) {
    sl.registerLazySingleton<WatchUserProfileUseCase>(() => WatchUserProfileUseCase(sl<ProfileRepository>()));
  }
  if (!sl.isRegistered<UpdateUserProfileUseCase>()) {
    sl.registerLazySingleton<UpdateUserProfileUseCase>(() => UpdateUserProfileUseCase(sl<ProfileRepository>()));
  }
  if (!sl.isRegistered<UpdatePhotoPathUseCase>()) {
    sl.registerLazySingleton<UpdatePhotoPathUseCase>(() => UpdatePhotoPathUseCase(sl<ProfileRepository>()));
  }

  // 9. Profil Fotoğrafı ve Profil Durum Yönetimi (ProfileCubit)
  if (!sl.isRegistered<SecureImageService>()) {
    sl.registerLazySingleton<SecureImageService>(
      () => SecureImageService(),
    );
  }

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
        localCacheService:
            sl.isRegistered<LocalCacheService>() ? sl<LocalCacheService>() : null,
      ),
    );
  }

  // 10. Oda Durum Yönetimi (RoomsCubit)
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
        localCacheService:
            sl.isRegistered<LocalCacheService>() ? sl<LocalCacheService>() : null,
      ),
    );
  }

  // 11. Cihaz Durum Yönetimi (DevicesCubit)
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
        localCacheService:
            sl.isRegistered<LocalCacheService>() ? sl<LocalCacheService>() : null,
      ),
    );
  }

  // 12. Bildirim Durum Yönetimi (NotificationsCubit)
  if (!sl.isRegistered<NotificationsCubit>()) {
    sl.registerFactory<NotificationsCubit>(
      () => NotificationsCubit(
        notificationsRepository: sl<NotificationsRepository>(),
        quotaService:
            sl.isRegistered<SparkQuotaService>() ? sl<SparkQuotaService>() : null,
        localCacheService:
            sl.isRegistered<LocalCacheService>() ? sl<LocalCacheService>() : null,
      ),
    );
  }

  // 13. Tema Durum Yönetimi (ThemeCubit)
  if (!sl.isRegistered<ThemeCubit>()) {
    sl.registerFactory<ThemeCubit>(
      () => ThemeCubit(
        analyticsService:
            sl.isRegistered<AnalyticsService>() ? sl<AnalyticsService>() : null,
      ),
    );
  }
}
