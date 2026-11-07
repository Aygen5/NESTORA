import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';
import '../models/user_profile_model.dart';

/// Implementation of [ProfileRepository] coordinating between Firestore and domain layer.
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Stream<UserProfile?> watchProfile(String userId) {
    return remoteDataSource
        .watchProfile(userId)
        .map((model) => model?.toEntity());
  }

  @override
  Future<Result<UserProfile?>> getProfile(String userId) async {
    try {
      final model = await remoteDataSource.getProfile(userId);
      return Result.success(model?.toEntity());
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure('Profil bilgisi alınırken beklenmeyen bir hata oluştu: $e'),
      );
    }
  }

  @override
  Future<Result<void>> updateProfile(
    String userId,
    UserProfile profile,
  ) async {
    try {
      await remoteDataSource.updateProfile(
        userId,
        UserProfileModel.fromEntity(profile),
      );
      return Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure('Profil güncellenirken beklenmeyen bir hata oluştu: $e'),
      );
    }
  }

  @override
  Future<Result<void>> updateHomeName(
    String userId,
    String homeName,
  ) async {
    try {
      await remoteDataSource.updateHomeName(userId, homeName);
      return Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure('Ev adı güncellenirken beklenmeyen bir hata oluştu: $e'),
      );
    }
  }

  @override
  Future<Result<void>> updateDisplayName(
    String userId,
    String displayName,
  ) async {
    try {
      await remoteDataSource.updateDisplayName(userId, displayName);
      return Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure(
          'Kullanıcı adı güncellenirken beklenmeyen bir hata oluştu: $e',
        ),
      );
    }
  }

  @override
  Future<Result<void>> updatePreferences(
    String userId,
    UserPreferences preferences,
  ) async {
    try {
      final map = {
        'notificationsEnabled': preferences.notificationsEnabled,
        'ecoModeEnabled': preferences.ecoModeEnabled,
        'temperatureUnit': preferences.temperatureUnit,
      };
      await remoteDataSource.updatePreferences(userId, map);
      return Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure('Tercihler kaydedilirken beklenmeyen bir hata oluştu: $e'),
      );
    }
  }

  @override
  Future<Result<void>> updatePhotoPath(
    String userId,
    String? photoPath,
  ) async {
    try {
      await remoteDataSource.updatePhotoPath(userId, photoPath);
      return Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure(
          'Profil fotoğrafı kaydedilirken beklenmeyen bir hata oluştu: $e',
        ),
      );
    }
  }
}
