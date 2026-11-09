import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

class SignOutUseCase implements NoParamsUseCase<void> {
  final AuthRepository repository;

  const SignOutUseCase(this.repository);

  @override
  Future<Result<void>> call() {
    return repository.signOut();
  }
}

