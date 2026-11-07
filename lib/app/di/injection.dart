import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../router/auth_guard.dart';

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
///
/// In subsequent phases, Data Sources and Repositories will be registered here.
Future<void> initDependencies({
  SharedPreferences? sharedPreferences,
  FirebaseAuth? firebaseAuth,
  FirebaseFirestore? firebaseFirestore,
  FirebaseAnalytics? firebaseAnalytics,
  FirebaseRemoteConfig? firebaseRemoteConfig,
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

  // 3. Auth Redirect Listenable for GoRouter
  if (!sl.isRegistered<AppAuthListenable>()) {
    FirebaseAuth? auth;
    if (sl.isRegistered<FirebaseAuth>()) {
      auth = sl<FirebaseAuth>();
    }
    sl.registerSingleton<AppAuthListenable>(AppAuthListenable(firebaseAuth: auth));
  }

  // 4. Auth Data Source & Repository
  if (!sl.isRegistered<AuthRemoteDataSource>()) {
    sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(
        firebaseAuth: sl.isRegistered<FirebaseAuth>() ? sl<FirebaseAuth>() : null,
        firestore: sl.isRegistered<FirebaseFirestore>() ? sl<FirebaseFirestore>() : null,
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
}
