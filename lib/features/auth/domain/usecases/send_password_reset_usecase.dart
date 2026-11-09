import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

class SendPasswordResetUseCase {
  final AuthRepository repository;

  const SendPasswordResetUseCase(this.repository);

  Future<Result<void>> call({required String email}) {
    return repository.sendPasswordReset(email: email);
  }
}
