import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class GetUserProfileUseCase implements UseCase<UserProfile?, String> {
  final ProfileRepository repository;

  const GetUserProfileUseCase(this.repository);

  @override
  Future<Result<UserProfile?>> call(String userId) {
    return repository.getProfile(userId);
  }
}
