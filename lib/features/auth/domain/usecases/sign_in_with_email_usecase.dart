import '../../../../core/utils/result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmailUseCase {
  final AuthRepository repository;

  const SignInWithEmailUseCase(this.repository);

  Future<Result<AuthUser>> call({
    required String email,
    required String password,
  }) {
    return repository.signInWithEmail(email: email, password: password);
  }
}
