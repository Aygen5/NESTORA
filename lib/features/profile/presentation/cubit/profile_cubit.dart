import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/spark_quota_service.dart';
import '../../data/datasources/profile_photo_service.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

/// Cubit managing the User Profile, local preferences, and avatar storage in Nestora.
class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository profileRepository;
  final ProfilePhotoService? photoService;
  final SharedPreferences? sharedPreferences;
  final SparkQuotaService? quotaService;
  final LocalCacheService? localCacheService;

  StreamSubscription<UserProfile?>? _profileSubscription;
  String? _currentUserId;

  ProfileCubit({
    required this.profileRepository,
    this.photoService,
    this.sharedPreferences,
    this.quotaService,
    this.localCacheService,
  }) : super(
          ProfileLoaded(
            profile: _resolveInitialProfile(localCacheService, sharedPreferences),
          ),
        );

  static UserProfile _resolveInitialProfile(
    LocalCacheService? localCacheService,
    SharedPreferences? sharedPreferences,
  ) {
    final cached = localCacheService?.loadProfile() ?? SeedData.defaultProfile;
    final prefPhoto = sharedPreferences?.getString(AppConstants.prefProfilePhotoPath);
    if (prefPhoto != null && prefPhoto.trim().isNotEmpty) {
      return cached.copyWith(photoPath: prefPhoto.trim());
    }
    return cached;
  }

  String _photoPrefKey(String userId) =>
      '${AppConstants.prefProfilePhotoPath}_$userId';

  /// Loads and listens to real-time updates for the user profile of [userId].
  void loadProfile(String userId) {
    final cleanUid = userId.trim();
    if (cleanUid.isEmpty) {
      emit(const ProfileError('Geçersiz kullanıcı kimliği.'));
      return;
    }
    _currentUserId = cleanUid;

    final cached = localCacheService?.loadProfile();
    if (cached != null) {
      emit(ProfileLoaded(profile: cached));
    } else if (state is! ProfileLoaded) {
      emit(const ProfileLoading());
    }

    _profileSubscription?.cancel();
    quotaService?.registerListener('ProfileCubit_$cleanUid');

    _profileSubscription = profileRepository.watchProfile(cleanUid).listen(
      (profile) {
        final cachedPhoto = sharedPreferences?.getString(_photoPrefKey(cleanUid)) ??
            sharedPreferences?.getString(AppConstants.prefProfilePhotoPath);

        if (profile == null) {
          final fallback = localCacheService?.loadProfile() ??
              UserProfile(
                uid: cleanUid,
                email: '',
                displayName: 'Nestora Kullanıcısı',
                roleTitle: 'Ev Sahibi',
                homeName: AppConstants.defaultHomeName,
                photoPath: cachedPhoto,
                preferences: const UserPreferences(),
              );
          localCacheService?.saveProfile(fallback);
          emit(ProfileLoaded(profile: fallback));
          return;
        }

        final finalPhoto = profile.photoPath ?? cachedPhoto;
        final finalProfile = finalPhoto != profile.photoPath
            ? profile.copyWith(photoPath: finalPhoto)
            : profile;

        localCacheService?.saveProfile(finalProfile);

        if (state is ProfileLoaded) {
          final current = state as ProfileLoaded;
          emit(current.copyWith(profile: finalProfile, isSaving: false));
        } else {
          emit(ProfileLoaded(profile: finalProfile));
        }
      },
      onError: (error) {
        if (state is! ProfileLoaded) {
          final fallback = localCacheService?.loadProfile() ?? SeedData.defaultProfile;
          emit(ProfileLoaded(profile: fallback));
        }
      },
    );
  }

  /// Updates the user's home name (e.g. "Aygen'in Evi").
  Future<void> updateHomeName(String newHomeName) async {
    final cleanName = newHomeName.trim();
    if (cleanName.isEmpty) {
      _emitErrorMessage('Ev adı boş bırakılamaz.');
      return;
    }

    if (state is! ProfileLoaded) return;
    final current = state as ProfileLoaded;
    final updatedProfile = current.profile.copyWith(homeName: cleanName);

    await sharedPreferences?.setString(AppConstants.prefUserHomeName, cleanName);
    await localCacheService?.saveProfile(updatedProfile);

    emit(current.copyWith(
      profile: updatedProfile,
      isSaving: false,
      feedbackMessage: 'Ev adı başarıyla güncellendi.',
    ));

    final result = await profileRepository.updateHomeName(
      current.profile.uid,
      cleanName,
    );
    if (result.isFailure) {
      final msg = result.failureOrNull?.message ?? 'Ev adı kaydedilemedi';
      emit(current.copyWith(errorMessage: msg));
    }
  }

  /// Updates multiple profile details atomically (displayName, email, roleTitle, homeName).
  Future<void> updateProfileDetails({
    String? displayName,
    String? email,
    String? roleTitle,
    String? homeName,
  }) async {
    if (state is! ProfileLoaded) return;
    final current = state as ProfileLoaded;
    var updated = current.profile;

    if (displayName != null && displayName.trim().isNotEmpty) {
      updated = updated.copyWith(displayName: displayName.trim());
    }
    if (email != null && email.trim().isNotEmpty) {
      updated = updated.copyWith(email: email.trim());
    }
    if (roleTitle != null && roleTitle.trim().isNotEmpty) {
      updated = updated.copyWith(roleTitle: roleTitle.trim());
    }
    if (homeName != null && homeName.trim().isNotEmpty) {
      updated = updated.copyWith(homeName: homeName.trim());
    }

    await localCacheService?.saveProfile(updated);
    emit(current.copyWith(
      profile: updated,
      isSaving: false,
      feedbackMessage: 'Profil başarıyla güncellendi.',
    ));

    await profileRepository.updateProfile(updated.uid, updated);
    if (displayName != null && displayName.trim().isNotEmpty) {
      await profileRepository.updateDisplayName(updated.uid, displayName.trim());
    }
    if (homeName != null && homeName.trim().isNotEmpty) {
      await profileRepository.updateHomeName(updated.uid, homeName.trim());
    }
  }

  /// Updates the user's display name.
  Future<void> updateDisplayName(String newDisplayName) async {
    final cleanName = newDisplayName.trim();
    if (cleanName.isEmpty) {
      _emitErrorMessage('Kullanıcı adı boş bırakılamaz.');
      return;
    }

    if (state is! ProfileLoaded) return;
    final current = state as ProfileLoaded;
    final updatedProfile = current.profile.copyWith(displayName: cleanName);

    await localCacheService?.saveProfile(updatedProfile);

    emit(current.copyWith(
      profile: updatedProfile,
      isSaving: false,
      feedbackMessage: 'Kullanıcı adı başarıyla güncellendi.',
    ));

    await profileRepository.updateDisplayName(
      current.profile.uid,
      cleanName,
    );
  }

  /// Updates the user's role title (e.g. "Ev Sahibi", "Yönetici", "Misafir").
  Future<void> updateRoleTitle(String newRoleTitle) async {
    final cleanRole = newRoleTitle.trim();
    if (cleanRole.isEmpty) return;

    if (state is! ProfileLoaded) return;
    final current = state as ProfileLoaded;
    final updatedProfile = current.profile.copyWith(roleTitle: cleanRole);

    await localCacheService?.saveProfile(updatedProfile);

    emit(current.copyWith(
      profile: updatedProfile,
      isSaving: false,
      feedbackMessage: 'Rol başarıyla güncellendi.',
    ));

    await profileRepository.updateProfile(
      current.profile.uid,
      updatedProfile,
    );
  }

  /// Updates the user's email address.
  Future<void> updateEmail(String newEmail) async {
    final cleanEmail = newEmail.trim();
    if (cleanEmail.isEmpty) return;

    if (state is! ProfileLoaded) return;
    final current = state as ProfileLoaded;
    final updatedProfile = current.profile.copyWith(email: cleanEmail);

    await localCacheService?.saveProfile(updatedProfile);

    emit(current.copyWith(
      profile: updatedProfile,
      isSaving: false,
      feedbackMessage: 'E-posta başarıyla güncellendi.',
    ));

    await profileRepository.updateProfile(
      current.profile.uid,
      updatedProfile,
    );
  }

  /// Toggles push notifications on/off.
  Future<void> toggleNotifications(bool enabled) async {
    if (state is! ProfileLoaded) return;
    final current = state as ProfileLoaded;
    final previousProfile = current.profile;
    final updatedPrefs = current.profile.preferences.copyWith(
      notificationsEnabled: enabled,
    );
    final updatedProfile = current.profile.copyWith(preferences: updatedPrefs);

    // Optimistic UI update & local persistence
    await localCacheService?.saveProfile(updatedProfile);
    emit(current.copyWith(profile: updatedProfile));

    final result = await profileRepository.updatePreferences(
      current.profile.uid,
      updatedPrefs,
    );
    if (result.isFailure) {
      final msg = result.failureOrNull?.message ?? 'Ayar güncellenemedi';
      emit(current.copyWith(profile: previousProfile, errorMessage: msg));
    }
  }

  /// Toggles eco mode preference on/off.
  Future<void> toggleEcoMode(bool enabled) async {
    if (state is! ProfileLoaded) return;
    final current = state as ProfileLoaded;
    final updatedPrefs = current.profile.preferences.copyWith(
      ecoModeEnabled: enabled,
    );
    final updatedProfile = current.profile.copyWith(preferences: updatedPrefs);

    // Optimistic UI update & local persistence
    await localCacheService?.saveProfile(updatedProfile);
    emit(current.copyWith(profile: updatedProfile));

    await profileRepository.updatePreferences(
      current.profile.uid,
      updatedPrefs,
    );
  }

  /// Updates the preferred temperature unit ('C' or 'F').
  Future<void> setTemperatureUnit(String unit) async {
    final cleanUnit = unit.toUpperCase().trim();
    if (cleanUnit != 'C' && cleanUnit != 'F') return;

    if (state is! ProfileLoaded) return;
    final current = state as ProfileLoaded;
    final updatedPrefs = current.profile.preferences.copyWith(
      temperatureUnit: cleanUnit,
    );
    final updatedProfile = current.profile.copyWith(preferences: updatedPrefs);

    await localCacheService?.saveProfile(updatedProfile);
    emit(current.copyWith(profile: updatedProfile));

    await profileRepository.updatePreferences(
      current.profile.uid,
      updatedPrefs,
    );
  }

  /// Picks an image via [photoService], saves it locally, and saves the file path.
  Future<void> pickAndSavePhoto({ImageSource source = ImageSource.gallery}) async {
    if (state is! ProfileLoaded) return;
    final current = state as ProfileLoaded;

    emit(current.copyWith(isSaving: true, clearFeedback: true, clearError: true));

    final path = await photoService?.pickAndSaveImage(
      source: source,
      userId: current.profile.uid,
    );

    if (path == null) {
      emit(current.copyWith(isSaving: false));
      return;
    }

    await sharedPreferences?.setString(_photoPrefKey(current.profile.uid), path);
    await sharedPreferences?.setString(AppConstants.prefProfilePhotoPath, path);

    final updatedProfile = current.profile.copyWith(photoPath: path);
    await localCacheService?.saveProfile(updatedProfile);

    emit(current.copyWith(
      profile: updatedProfile,
      isSaving: false,
      feedbackMessage: 'Profil fotoğrafı güncellendi.',
    ));

    await profileRepository.updatePhotoPath(
      current.profile.uid,
      path,
    );
  }

  /// Sets a predefined or custom photo path directly (e.g. preset asset or saved path).
  Future<void> setPhotoPath(String? path) async {
    if (state is! ProfileLoaded) return;
    final current = state as ProfileLoaded;

    emit(current.copyWith(isSaving: true, clearFeedback: true, clearError: true));

    if (path == null) {
      await removePhoto();
      return;
    }

    await sharedPreferences?.setString(_photoPrefKey(current.profile.uid), path);
    await sharedPreferences?.setString(AppConstants.prefProfilePhotoPath, path);

    final updatedProfile = current.profile.copyWith(photoPath: path);
    await localCacheService?.saveProfile(updatedProfile);

    emit(current.copyWith(
      profile: updatedProfile,
      isSaving: false,
      feedbackMessage: 'Profil fotoğrafı güncellendi.',
    ));

    await profileRepository.updatePhotoPath(
      current.profile.uid,
      path,
    );
  }

  /// Removes the user's profile photo and deletes the local cached file.
  Future<void> removePhoto() async {
    if (state is! ProfileLoaded) return;
    final current = state as ProfileLoaded;

    emit(current.copyWith(isSaving: true, clearFeedback: true, clearError: true));

    final oldPath = current.profile.photoPath;
    await photoService?.deleteLocalImage(oldPath);

    await sharedPreferences?.remove(_photoPrefKey(current.profile.uid));
    await sharedPreferences?.remove(AppConstants.prefProfilePhotoPath);

    final updatedProfile = current.profile.copyWith(clearPhotoPath: true);
    await localCacheService?.saveProfile(updatedProfile);

    emit(current.copyWith(
      profile: updatedProfile,
      isSaving: false,
      feedbackMessage: 'Profil fotoğrafı kaldırıldı.',
    ));

    await profileRepository.updatePhotoPath(
      current.profile.uid,
      null,
    );
  }

  /// Clears any transient feedback or error messages.
  void clearMessages() {
    if (state is ProfileLoaded) {
      final current = state as ProfileLoaded;
      emit(current.copyWith(clearFeedback: true, clearError: true));
    }
  }

  void _emitErrorMessage(String message) {
    if (state is ProfileLoaded) {
      final current = state as ProfileLoaded;
      emit(current.copyWith(errorMessage: message, isSaving: false));
    }
  }

  @override
  Future<void> close() {
    _profileSubscription?.cancel();
    if (_currentUserId != null) {
      quotaService?.unregisterListener('ProfileCubit_$_currentUserId');
    }
    return super.close();
  }
}
