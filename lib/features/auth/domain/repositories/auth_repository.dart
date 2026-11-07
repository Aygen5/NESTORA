import '../../../../core/utils/result.dart';
import '../entities/auth_user.dart';

/// Contract for Authentication repository operations in Nestora.
/// Returns domain-level [Result<T>] types and [AuthUser] entities.
abstract class AuthRepository {
  /// Stream emitting the current authenticated user or null when logged out.
  Stream<AuthUser?> get authStateChanges;

  /// Current authenticated user entity, if any.
  AuthUser? get currentUser;

  /// Authenticates an existing user using email and password.
  Future<Result<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Registers a new user with email and password, setting an optional display name.
  Future<Result<AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  /// Signs the currently authenticated user out.
  Future<Result<void>> signOut();

  /// Triggers a password reset email via Firebase Authentication.
  Future<Result<void>> sendPasswordReset({
    required String email,
  });

  /// Performs one-touch quick demo authentication using configured demo credentials.
  Future<Result<AuthUser>> signInDemo({
    String? email,
    String? password,
  });
}
