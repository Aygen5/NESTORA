import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Fallback implementation of [AuthRepository] used when dependency injection
/// is not initialized (e.g. isolated unit/widget tests).
class FallbackAuthRepository implements AuthRepository {
  const FallbackAuthRepository();

  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();

  @override
  AuthUser? get currentUser => null;

  @override
  Future<Result<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return Result.failure(
      const AuthFailure('Kimlik doğrulama servisi henüz hazır değil.'),
    );
  }

  @override
  Future<Result<AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return Result.failure(
      const AuthFailure('Kayıt servisi henüz hazır değil.'),
    );
  }

  @override
  Future<Result<void>> signOut() async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> sendPasswordReset({
    required String email,
  }) async {
    return Result.failure(
      const AuthFailure('Şifre sıfırlama servisi henüz hazır değil.'),
    );
  }

  @override
  Future<Result<AuthUser>> signInDemo({
    String? email,
    String? password,
  }) async {
    return Result.failure(
      const AuthFailure('Demo servisi henüz hazır değil.'),
    );
  }
}

