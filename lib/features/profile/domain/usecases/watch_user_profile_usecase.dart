import '../../../../core/usecases/usecase.dart';
import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class WatchUserProfileUseCase implements StreamUseCase<UserProfile?, String> {
  final ProfileRepository repository;

  const WatchUserProfileUseCase(this.repository);

  @override
  Stream<UserProfile?> call(String userId) {
    return repository.watchProfile(userId);
  }
}

