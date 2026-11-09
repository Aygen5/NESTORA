import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class UpdateUserProfileParams {
  final String userId;
  final UserProfile profile;

  const UpdateUserProfileParams({required this.userId, required this.profile});
}

class UpdateUserProfileUseCase implements UseCase<void, UpdateUserProfileParams> {
  final ProfileRepository repository;

  const UpdateUserProfileUseCase(this.repository);

  @override
  Future<Result<void>> call(UpdateUserProfileParams params) {
    return repository.updateProfile(params.userId, params.profile);
  }
}

