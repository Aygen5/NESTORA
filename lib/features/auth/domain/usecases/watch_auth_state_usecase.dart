import '../../../../core/usecases/usecase.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class WatchAuthStateUseCase implements NoParamsStreamUseCase<AuthUser?> {
  final AuthRepository repository;

  const WatchAuthStateUseCase(this.repository);

  @override
  Stream<AuthUser?> call() {
    return repository.authStateChanges;
  }
}
