import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository repository;

  const GetCurrentUserUseCase(this.repository);

  AuthUser? call() {
    return repository.currentUser;
  }
}

