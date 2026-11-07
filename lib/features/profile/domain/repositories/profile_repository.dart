import '../../../../core/utils/result.dart';
import '../entities/user_profile.dart';

/// Contract for operations on the user's smart home profile in NESTORA.
abstract class ProfileRepository {
  /// Real-time stream of the user profile document for [userId].
  Stream<UserProfile?> watchProfile(String userId);

  /// One-time fetch of the user profile document.
  Future<Result<UserProfile?>> getProfile(String userId);

  /// Updates the complete profile document.
  Future<Result<void>> updateProfile(String userId, UserProfile profile);

  /// Quick update for home name (e.g. "Aygen'in Evi").
  Future<Result<void>> updateHomeName(String userId, String homeName);

  /// Quick update for user display name.
  Future<Result<void>> updateDisplayName(String userId, String displayName);

  /// Quick update for user preferences (notifications, eco mode, units).
  Future<Result<void>> updatePreferences(
    String userId,
    UserPreferences preferences,
  );

  /// Updates the local photo path reference.
  Future<Result<void>> updatePhotoPath(String userId, String? photoPath);
}
