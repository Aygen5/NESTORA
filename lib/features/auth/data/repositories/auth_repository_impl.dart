import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Implementation of [AuthRepository] mediating between remote data sources and domain layer.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SharedPreferences? sharedPreferences;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    this.sharedPreferences,
  });

  @override
  Stream<AuthUser?> get authStateChanges =>
      remoteDataSource.authStateChanges.map(_mapFirebaseUserToAuthUser);

  @override
  AuthUser? get currentUser =>
      _mapFirebaseUserToAuthUser(remoteDataSource.currentUser);

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

      await _saveLastUserEmail(email);

      final authUser = _mapFirebaseUserToAuthUser(user)!;
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

      await _saveLastUserEmail(email);

      final authUser = _mapFirebaseUserToAuthUser(user)!;
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
      await remoteDataSource.signOut();
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
      if (user == null) {
        return Result.failure(
          const AuthFailure('Demo kullanıcı oturumu açılamadı.'),
        );
      }

      final authUser = _mapFirebaseUserToAuthUser(user)!;
      return Result.success(authUser);
    } on AuthException catch (e) {
      return Result.failure(AuthFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        AuthFailure('Demo girişi yapılırken beklenmeyen bir hata oluştu: $e'),
      );
    }
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
}
