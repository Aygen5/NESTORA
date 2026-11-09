import '../../../../core/utils/result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class SignInDemoUseCase {
  final AuthRepository repository;

  const SignInDemoUseCase(this.repository);

  Future<Result<AuthUser>> call({String? email, String? password}) {
    return repository.signInDemo(email: email, password: password);
  }
}
