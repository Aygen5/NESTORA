import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nestora/app/di/injection.dart';
import 'package:nestora/core/constants/app_constants.dart';
import 'package:nestora/core/errors/failures.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/features/profile/data/datasources/profile_photo_service.dart';
import 'package:nestora/features/profile/domain/entities/user_profile.dart';
import 'package:nestora/features/profile/domain/repositories/profile_repository.dart';
import 'package:nestora/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:nestora/features/profile/presentation/cubit/profile_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Fake ProfileRepository for deterministic testing
class FakeProfileRepository implements ProfileRepository {
  bool shouldThrow = false;
  String errorMessage = 'Sunucu hatası';
  UserProfile? storedProfile;

  final StreamController<UserProfile?> _controller =
      StreamController<UserProfile?>.broadcast();

  void emitProfile(UserProfile? profile) {
    storedProfile = profile;
    _controller.add(profile);
  }

  void emitError(dynamic error) {
    _controller.addError(error);
  }

  @override
  Stream<UserProfile?> watchProfile(String userId) => _controller.stream;

  @override
  Future<Result<UserProfile?>> getProfile(String userId) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    return Result.success(storedProfile);
  }

  @override
  Future<Result<void>> updateProfile(String userId, UserProfile profile) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    storedProfile = profile;
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateHomeName(String userId, String homeName) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    if (storedProfile != null) {
      storedProfile = storedProfile!.copyWith(homeName: homeName);
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateDisplayName(String userId, String displayName) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    if (storedProfile != null) {
      storedProfile = storedProfile!.copyWith(displayName: displayName);
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> updatePreferences(
    String userId,
    UserPreferences preferences,
  ) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    if (storedProfile != null) {
      storedProfile = storedProfile!.copyWith(preferences: preferences);
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> updatePhotoPath(String userId, String? photoPath) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    if (storedProfile != null) {
      storedProfile = storedProfile!.copyWith(photoPath: photoPath);
    }
    return Result.success(null);
  }
}

// Fake ProfilePhotoService
class FakeProfilePhotoService implements ProfilePhotoService {
  String? returnPath = '/data/user/0/app/avatar.png';
  String? lastDeletedPath;

  @override
  Future<String?> pickAndSaveImage({
    ImageSource source = ImageSource.gallery,
    String? userId,
  }) async {
    return returnPath;
  }

  @override
  Future<void> deleteLocalImage(String? path) async {
    lastDeletedPath = path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeProfileRepository fakeRepo;
  late FakeProfilePhotoService fakePhotoService;
  late SharedPreferences prefs;
  late ProfileCubit cubit;

  final testProfile = UserProfile(
    uid: 'user-1',
    email: 'aygen@nestora.app',
    displayName: 'Aygen Yıldırım',
    homeName: "Aygen'in Evi",
    preferences: const UserPreferences(
      notificationsEnabled: true,
      ecoModeEnabled: true,
      temperatureUnit: 'C',
    ),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeRepo = FakeProfileRepository();
    fakePhotoService = FakeProfilePhotoService();

    cubit = ProfileCubit(
      profileRepository: fakeRepo,
      photoService: fakePhotoService,
      sharedPreferences: prefs,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  group('ProfileCubit Initialization & Load Tests', () {
    test('initial state is ProfileInitial', () {
      expect(cubit.state, isA<ProfileInitial>());
    });

    test('loadProfile emits ProfileError for empty userId', () {
      cubit.loadProfile('   ');
      expect(cubit.state, isA<ProfileError>());
      expect((cubit.state as ProfileError).message, 'Geçersiz kullanıcı kimliği.');
    });

    test('loadProfile emits [ProfileLoading, ProfileLoaded] on successful watch', () async {
      final states = <ProfileState>[];
      final subscription = cubit.stream.listen(states.add);

      cubit.loadProfile('user-1');
      expect(cubit.state, isA<ProfileLoading>());

      fakeRepo.emitProfile(testProfile);
      await pumpEventQueue();

      expect(states.length, 2);
      expect(states[0], isA<ProfileLoading>());
      expect(states[1], isA<ProfileLoaded>());
      final loaded = states[1] as ProfileLoaded;
      expect(loaded.profile.displayName, 'Aygen Yıldırım');
      expect(loaded.profile.homeName, "Aygen'in Evi");

      await subscription.cancel();
    });

    test('loadProfile creates fallback profile when stream emits null', () async {
      cubit.loadProfile('user-2');
      fakeRepo.emitProfile(null);
      await pumpEventQueue();

      expect(cubit.state, isA<ProfileLoaded>());
      final loaded = cubit.state as ProfileLoaded;
      expect(loaded.profile.uid, 'user-2');
      expect(loaded.profile.homeName, AppConstants.defaultHomeName);
    });

    test('loadProfile restores photo from SharedPreferences when profile photo is null', () async {
      await prefs.setString('${AppConstants.prefProfilePhotoPath}_user-1', '/cached/photo.png');

      cubit.loadProfile('user-1');
      fakeRepo.emitProfile(testProfile.copyWith(photoPath: null));
      await pumpEventQueue();

      expect(cubit.state, isA<ProfileLoaded>());
      final loaded = cubit.state as ProfileLoaded;
      expect(loaded.profile.photoPath, '/cached/photo.png');
    });

    test('loadProfile emits ProfileError on stream exception', () async {
      cubit.loadProfile('user-1');
      fakeRepo.emitError('Stream kesildi');
      await pumpEventQueue();

      expect(cubit.state, isA<ProfileError>());
      expect((cubit.state as ProfileError).message, contains('Stream kesildi'));
    });
  });

  group('ProfileCubit Home Name & Display Name Updates', () {
    setUp(() async {
      cubit.loadProfile('user-1');
      fakeRepo.emitProfile(testProfile);
      await pumpEventQueue();
    });

    test('updateHomeName rejects empty home name', () async {
      await cubit.updateHomeName('   ');
      final state = cubit.state as ProfileLoaded;
      expect(state.errorMessage, 'Ev adı boş bırakılamaz.');
    });

    test('updateHomeName successfully updates home name and saves to prefs', () async {
      await cubit.updateHomeName('Modern Akıllı Ev');
      final state = cubit.state as ProfileLoaded;

      expect(state.profile.homeName, 'Modern Akıllı Ev');
      expect(state.feedbackMessage, 'Ev adı başarıyla güncellendi.');
      expect(prefs.getString(AppConstants.prefUserHomeName), 'Modern Akıllı Ev');
    });

    test('updateHomeName emits errorMessage on repository failure', () async {
      fakeRepo.shouldThrow = true;
      fakeRepo.errorMessage = 'Ev adı kaydedilemedi';

      await cubit.updateHomeName('Yeni Ev');
      final state = cubit.state as ProfileLoaded;

      expect(state.errorMessage, 'Ev adı kaydedilemedi');
      expect(state.profile.homeName, "Aygen'in Evi"); // unchanged
    });

    test('updateDisplayName rejects empty display name', () async {
      await cubit.updateDisplayName('   ');
      final state = cubit.state as ProfileLoaded;
      expect(state.errorMessage, 'Kullanıcı adı boş bırakılamaz.');
    });

    test('updateDisplayName successfully updates display name', () async {
      await cubit.updateDisplayName('M. Aygen Yıldırım');
      final state = cubit.state as ProfileLoaded;

      expect(state.profile.displayName, 'M. Aygen Yıldırım');
      expect(state.feedbackMessage, 'Kullanıcı adı başarıyla güncellendi.');
    });
  });

  group('ProfileCubit Preferences Toggle Tests', () {
    setUp(() async {
      cubit.loadProfile('user-1');
      fakeRepo.emitProfile(testProfile);
      await pumpEventQueue();
    });

    test('toggleNotifications updates preferences optimistically', () async {
      await cubit.toggleNotifications(false);
      final state = cubit.state as ProfileLoaded;
      expect(state.profile.preferences.notificationsEnabled, isFalse);
    });

    test('toggleNotifications rolls back on repository failure', () async {
      fakeRepo.shouldThrow = true;
      fakeRepo.errorMessage = 'Ayar güncellenemedi';

      await cubit.toggleNotifications(false);
      final state = cubit.state as ProfileLoaded;
      expect(state.profile.preferences.notificationsEnabled, isTrue); // rolled back
      expect(state.errorMessage, 'Ayar güncellenemedi');
    });

    test('toggleEcoMode updates eco mode preference', () async {
      await cubit.toggleEcoMode(false);
      final state = cubit.state as ProfileLoaded;
      expect(state.profile.preferences.ecoModeEnabled, isFalse);
    });

    test('setTemperatureUnit updates unit to F or C', () async {
      await cubit.setTemperatureUnit('F');
      var state = cubit.state as ProfileLoaded;
      expect(state.profile.preferences.temperatureUnit, 'F');

      await cubit.setTemperatureUnit('invalid');
      state = cubit.state as ProfileLoaded;
      expect(state.profile.preferences.temperatureUnit, 'F'); // unchanged
    });
  });

  group('ProfileCubit Profile Photo & Avatar Tests', () {
    setUp(() async {
      cubit.loadProfile('user-1');
      fakeRepo.emitProfile(testProfile);
      await pumpEventQueue();
    });

    test('pickAndSavePhoto updates photo path in profile and SharedPreferences', () async {
      fakePhotoService.returnPath = '/local/avatar_new.png';

      await cubit.pickAndSavePhoto();
      final state = cubit.state as ProfileLoaded;

      expect(state.profile.photoPath, '/local/avatar_new.png');
      expect(state.feedbackMessage, 'Profil fotoğrafı güncellendi.');
      expect(
        prefs.getString('${AppConstants.prefProfilePhotoPath}_user-1'),
        '/local/avatar_new.png',
      );
    });

    test('pickAndSavePhoto does nothing if user cancels picker', () async {
      fakePhotoService.returnPath = null;

      await cubit.pickAndSavePhoto();
      final state = cubit.state as ProfileLoaded;

      expect(state.isSaving, isFalse);
      expect(state.profile.photoPath, isNull);
    });

    test('removePhoto deletes local image and clears preferences', () async {
      // First set a photo
      fakePhotoService.returnPath = '/local/avatar_to_delete.png';
      await cubit.pickAndSavePhoto();

      // Now remove it
      await cubit.removePhoto();
      final state = cubit.state as ProfileLoaded;

      expect(state.profile.photoPath, isNull);
      expect(state.feedbackMessage, 'Profil fotoğrafı kaldırıldı.');
      expect(fakePhotoService.lastDeletedPath, '/local/avatar_to_delete.png');
      expect(
        prefs.getString('${AppConstants.prefProfilePhotoPath}_user-1'),
        isNull,
      );
    });

    test('clearMessages clears feedback and error messages', () async {
      await cubit.updateHomeName('Test');
      var state = cubit.state as ProfileLoaded;
      expect(state.feedbackMessage, isNotNull);

      cubit.clearMessages();
      state = cubit.state as ProfileLoaded;
      expect(state.feedbackMessage, isNull);
      expect(state.errorMessage, isNull);
    });
  });

  group('ServiceLocator Registration for Profile Services', () {
    setUp(() async {
      sl.reset();
      SharedPreferences.setMockInitialValues({});
      final p = await SharedPreferences.getInstance();
      await initDependencies(sharedPreferences: p);
    });

    tearDown(() {
      sl.reset();
    });

    test('ProfilePhotoService and ProfileCubit are registered and resolvable', () {
      expect(sl.isRegistered<ProfilePhotoService>(), isTrue);
      expect(sl<ProfilePhotoService>(), isA<ProfilePhotoServiceImpl>());

      expect(sl.isRegistered<ProfileCubit>(), isTrue);
      final profileCubit = sl<ProfileCubit>();
      expect(profileCubit, isA<ProfileCubit>());
      profileCubit.close();
    });
  });
}
