import '../../../../core/utils/result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class SignUpWithEmailUseCase {
  final AuthRepository repository;

  const SignUpWithEmailUseCase(this.repository);

  Future<Result<AuthUser>> call({
    required String email,
    required String password,
    String? displayName,
  }) {
    return repository.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
  }
}
