import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
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

  StreamSubscription<UserProfile?>? _profileSubscription;
  String? _currentUserId;

  ProfileCubit({
    required this.profileRepository,
    this.photoService,
    this.sharedPreferences,
    this.quotaService,
  }) : super(const ProfileInitial());

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

    if (state is! ProfileLoaded) {
      emit(const ProfileLoading());
    }

    _profileSubscription?.cancel();
    quotaService?.registerListener('ProfileCubit_$cleanUid');

    _profileSubscription = profileRepository.watchProfile(cleanUid).listen(
      (profile) {
        final cachedPhoto = sharedPreferences?.getString(_photoPrefKey(cleanUid)) ??
            sharedPreferences?.getString(AppConstants.prefProfilePhotoPath);

        if (profile == null) {
          final fallback = UserProfile(
            uid: cleanUid,
            email: '',
            displayName: 'Nestora Kullanıcısı',
            homeName: AppConstants.defaultHomeName,
            photoPath: cachedPhoto,
            preferences: const UserPreferences(),
          );
          emit(ProfileLoaded(profile: fallback));
          return;
        }

        final finalPhoto = profile.photoPath ?? cachedPhoto;
        final finalProfile = finalPhoto != profile.photoPath
            ? profile.copyWith(photoPath: finalPhoto)
            : profile;

        if (state is ProfileLoaded) {
          final current = state as ProfileLoaded;
          emit(current.copyWith(profile: finalProfile, isSaving: false));
        } else {
          emit(ProfileLoaded(profile: finalProfile));
        }
      },
      onError: (error) {
        emit(ProfileError('Profil yüklenirken bir hata oluştu: $error'));
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
    emit(current.copyWith(isSaving: true, clearFeedback: true, clearError: true));

    final result = await profileRepository.updateHomeName(
      current.profile.uid,
      cleanName,
    );

    if (result.isSuccess) {
      await sharedPreferences?.setString(AppConstants.prefUserHomeName, cleanName);
      emit(current.copyWith(
        profile: current.profile.copyWith(homeName: cleanName),
        isSaving: false,
        feedbackMessage: 'Ev adı başarıyla güncellendi.',
      ));
    } else {
      emit(current.copyWith(
        isSaving: false,
        errorMessage: result.failure.message,
      ));
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
    emit(current.copyWith(isSaving: true, clearFeedback: true, clearError: true));

    final result = await profileRepository.updateDisplayName(
      current.profile.uid,
      cleanName,
    );

    if (result.isSuccess) {
      emit(current.copyWith(
        profile: current.profile.copyWith(displayName: cleanName),
        isSaving: false,
        feedbackMessage: 'Kullanıcı adı başarıyla güncellendi.',
      ));
    } else {
      emit(current.copyWith(
        isSaving: false,
        errorMessage: result.failure.message,
      ));
    }
  }

  /// Toggles push notifications on/off.
  Future<void> toggleNotifications(bool enabled) async {
    if (state is! ProfileLoaded) return;
    final current = state as ProfileLoaded;
    final updatedPrefs = current.profile.preferences.copyWith(
      notificationsEnabled: enabled,
    );

    // Optimistic UI update
    emit(current.copyWith(
      profile: current.profile.copyWith(preferences: updatedPrefs),
    ));

    final result = await profileRepository.updatePreferences(
      current.profile.uid,
      updatedPrefs,
    );

    if (result.isFailure) {
      // Rollback on failure
      emit(current.copyWith(
        profile: current.profile,
        errorMessage: result.failure.message,
      ));
    }
  }

  /// Toggles eco mode preference on/off.
  Future<void> toggleEcoMode(bool enabled) async {
    if (state is! ProfileLoaded) return;
    final current = state as ProfileLoaded;
    final updatedPrefs = current.profile.preferences.copyWith(
      ecoModeEnabled: enabled,
    );

    // Optimistic UI update
    emit(current.copyWith(
      profile: current.profile.copyWith(preferences: updatedPrefs),
    ));

    final result = await profileRepository.updatePreferences(
      current.profile.uid,
      updatedPrefs,
    );

    if (result.isFailure) {
      emit(current.copyWith(
        profile: current.profile,
        errorMessage: result.failure.message,
      ));
    }
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

    emit(current.copyWith(
      profile: current.profile.copyWith(preferences: updatedPrefs),
    ));

    final result = await profileRepository.updatePreferences(
      current.profile.uid,
      updatedPrefs,
    );

    if (result.isFailure) {
      emit(current.copyWith(
        profile: current.profile,
        errorMessage: result.failure.message,
      ));
    }
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

    final result = await profileRepository.updatePhotoPath(
      current.profile.uid,
      path,
    );

    if (result.isSuccess) {
      emit(current.copyWith(
        profile: current.profile.copyWith(photoPath: path),
        isSaving: false,
        feedbackMessage: 'Profil fotoğrafı güncellendi.',
      ));
    } else {
      emit(current.copyWith(
        isSaving: false,
        errorMessage: result.failure.message,
      ));
    }
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

    final result = await profileRepository.updatePhotoPath(
      current.profile.uid,
      null,
    );

    if (result.isSuccess) {
      emit(current.copyWith(
        profile: current.profile.copyWith(clearPhotoPath: true),
        isSaving: false,
        feedbackMessage: 'Profil fotoğrafı kaldırıldı.',
      ));
    } else {
      emit(current.copyWith(
        isSaving: false,
        errorMessage: result.failure.message,
      ));
    }
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
