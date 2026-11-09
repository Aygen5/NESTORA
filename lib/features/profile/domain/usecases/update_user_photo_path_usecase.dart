import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/profile_repository.dart';

class UpdatePhotoPathParams {
  final String userId;
  final String? photoPath;

  const UpdatePhotoPathParams({required this.userId, required this.photoPath});
}

class UpdatePhotoPathUseCase implements UseCase<void, UpdatePhotoPathParams> {
  final ProfileRepository repository;

  const UpdatePhotoPathUseCase(this.repository);

  @override
  Future<Result<void>> call(UpdatePhotoPathParams params) {
    return repository.updatePhotoPath(params.userId, params.photoPath);
  }
}

