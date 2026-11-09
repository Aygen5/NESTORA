import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/auth_guard.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Implementation of [AuthRepository] mediating between remote data sources and domain layer.
/// Features a zero-failure offline-first simulated fallback for Demo logins.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SharedPreferences? sharedPreferences;
  final StreamController<AuthUser?> _authStateController =
      StreamController<AuthUser?>.broadcast();
  StreamSubscription<User?>? _remoteSubscription;
  AuthUser? _simulatedUser;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    this.sharedPreferences,
  }) {
    final isDemoActive =
        sharedPreferences?.getBool(AppConstants.prefDemoSessionActive) ?? false;
    if (isDemoActive) {
      _simulatedUser = _createFallbackDemoUser();
    }

    _remoteSubscription = remoteDataSource.authStateChanges.listen((user) {
      if (_simulatedUser != null) {
        _authStateController.add(_simulatedUser);
      } else {
        _authStateController.add(_mapFirebaseUserToAuthUser(user));
      }
    });
  }

  @override
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;

  @override
  AuthUser? get currentUser {
    if (_simulatedUser != null) {
      return _simulatedUser;
    }
    final isDemoActive =
        sharedPreferences?.getBool(AppConstants.prefDemoSessionActive) ?? false;
    if (isDemoActive) {
      _simulatedUser = _createFallbackDemoUser();
      return _simulatedUser;
    }
    return _mapFirebaseUserToAuthUser(remoteDataSource.currentUser);
  }

  @override
  Future<Result<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return Result.failure(
          const AuthFailure(
            'Giriş işlemi tamamlandı ancak kullanıcı verisi alınamadı.',
          ),
        );
      }

      await _clearSimulatedDemoSession();
      await _saveLastUserEmail(email);

      final authUser = _mapFirebaseUserToAuthUser(user)!;
      if (sl.isRegistered<AppAuthListenable>()) {
        sl<AppAuthListenable>().setAuthenticated(true);
      }
      return Result.success(authUser);
    } on AuthException catch (e) {
      return Result.failure(AuthFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        AuthFailure('Giriş yapılırken beklenmeyen bir hata oluştu: $e'),
      );
    }
  }

  @override
  Future<Result<AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await remoteDataSource.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      final user = credential.user;
      if (user == null) {
        return Result.failure(
          const AuthFailure(
            'Kayıt işlemi tamamlandı ancak kullanıcı profili oluşturulamadı.',
          ),
        );
      }

      await _clearSimulatedDemoSession();
      await _saveLastUserEmail(email);

      final authUser = _mapFirebaseUserToAuthUser(user)!;
      if (sl.isRegistered<AppAuthListenable>()) {
        sl<AppAuthListenable>().setAuthenticated(true);
      }
      return Result.success(authUser);
    } on AuthException catch (e) {
      return Result.failure(AuthFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        AuthFailure('Kayıt yapılırken beklenmeyen bir hata oluştu: $e'),
      );
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      final wasSimulated = _simulatedUser != null;
      await _clearSimulatedDemoSession();
      if (wasSimulated) {
        _authStateController.add(null);
      }
      if (sl.isRegistered<AppAuthListenable>()) {
        sl<AppAuthListenable>().setAuthenticated(false);
      }
      try {
        await remoteDataSource.signOut();
      } catch (e) {
        debugPrint('AuthRepositoryImpl: Remote signOut notice ($e)');
      }
      return Result.success(null);
    } on AuthException catch (e) {
      return Result.failure(AuthFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        AuthFailure('Çıkış yapılırken bir hata oluştu: $e'),
      );
    }
  }

  @override
  Future<Result<void>> sendPasswordReset({
    required String email,
  }) async {
    try {
      await remoteDataSource.sendPasswordReset(email: email);
      return Result.success(null);
    } on AuthException catch (e) {
      return Result.failure(AuthFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        AuthFailure('Şifre sıfırlama işlemi gerçekleştirilemedi: $e'),
      );
    }
  }

  @override
  Future<Result<AuthUser>> signInDemo({
    String? email,
    String? password,
  }) async {
    try {
      final credential = await remoteDataSource.signInDemo(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        final authUser = _mapFirebaseUserToAuthUser(user)!;
        await _clearSimulatedDemoSession();
        await _saveLastUserEmail(authUser.email);
        if (sl.isRegistered<AppAuthListenable>()) {
          sl<AppAuthListenable>().setAuthenticated(true);
        }
        return Result.success(authUser);
      }
    } catch (e) {
      debugPrint('AuthRepositoryImpl: Remote demo login unavailable ($e), switching to local demo mode.');
    }

    // Resilient offline fallback for Demo mode
    final fallbackUser = _createFallbackDemoUser(
      email: email ?? AppConstants.demoEmail,
      displayName: SeedData.defaultProfile.displayName,
    );
    await _activateSimulatedDemoSession(fallbackUser);
    return Result.success(fallbackUser);
  }

  Future<void> _activateSimulatedDemoSession(AuthUser user) async {
    _simulatedUser = user;
    try {
      await sharedPreferences?.setBool(AppConstants.prefDemoSessionActive, true);
      await _saveLastUserEmail(user.email);
    } catch (_) {}
    _authStateController.add(user);
    if (sl.isRegistered<AppAuthListenable>()) {
      sl<AppAuthListenable>().setAuthenticated(true);
    }
  }

  Future<void> _clearSimulatedDemoSession() async {
    _simulatedUser = null;
    try {
      await sharedPreferences?.remove(AppConstants.prefDemoSessionActive);
    } catch (_) {}
  }

  static AuthUser _createFallbackDemoUser({
    String? email,
    String? displayName,
  }) {
    return AuthUser(
      id: SeedData.defaultProfile.uid,
      email: email ?? SeedData.defaultProfile.email,
      displayName: displayName ?? SeedData.defaultProfile.displayName,
      photoUrl: SeedData.defaultProfile.photoPath,
      isAnonymous: false,
    );
  }

  /// Helper converting Firebase SDK [User] to pure domain [AuthUser].
  AuthUser? _mapFirebaseUserToAuthUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isAnonymous: user.isAnonymous,
    );
  }

  Future<void> _saveLastUserEmail(String email) async {
    try {
      await sharedPreferences?.setString(
        AppConstants.prefLastUserEmail,
        email.trim(),
      );
    } catch (_) {
      // Ignored non-fatal preference caching
    }
  }

  void dispose() {
    _remoteSubscription?.cancel();
    _authStateController.close();
  }
}
