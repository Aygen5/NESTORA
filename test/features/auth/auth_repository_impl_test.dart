import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/core/constants/app_constants.dart';
import 'package:nestora/core/errors/exceptions.dart';
import 'package:nestora/core/errors/failures.dart';
import 'package:nestora/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:nestora/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:nestora/features/auth/domain/entities/auth_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Fake implementations to test AuthRepositoryImpl cleanly without depending on Firebase SDK binaries
class FakeUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;
  @override
  final String? photoURL;
  @override
  final bool isAnonymous;

  FakeUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.isAnonymous = false,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserCredential implements UserCredential {
  @override
  final User? user;

  FakeUserCredential({this.user});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  final StreamController<User?> _streamController =
      StreamController<User?>.broadcast();
  User? _currentUser;
  bool shouldThrow = false;
  String throwCode = 'invalid-credential';
  String throwMessage = 'E-posta veya şifre hatalı.';

  FakeAuthRemoteDataSource({User? initialUser}) : _currentUser = initialUser;

  @override
  Stream<User?> get authStateChanges => _streamController.stream;

  @override
  User? get currentUser => _currentUser;

  void emitUser(User? user) {
    _currentUser = user;
    _streamController.add(user);
  }

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (shouldThrow) {
      throw AuthException(throwMessage, code: throwCode);
    }
    final user = FakeUser(
      uid: 'user-123',
      email: email,
      displayName: 'Test User',
    );
    _currentUser = user;
    _streamController.add(user);
    return FakeUserCredential(user: user);
  }

  @override
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (shouldThrow) {
      throw AuthException(throwMessage, code: throwCode);
    }
    final user = FakeUser(
      uid: 'user-new',
      email: email,
      displayName: displayName ?? 'New User',
    );
    _currentUser = user;
    _streamController.add(user);
    return FakeUserCredential(user: user);
  }

  @override
  Future<void> signOut() async {
    if (shouldThrow) {
      throw AuthException(throwMessage, code: throwCode);
    }
    _currentUser = null;
    _streamController.add(null);
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    if (shouldThrow) {
      throw AuthException(throwMessage, code: throwCode);
    }
  }

  @override
  Future<UserCredential> signInDemo({String? email, String? password}) async {
    if (shouldThrow) {
      throw AuthException(throwMessage, code: throwCode);
    }
    final user = FakeUser(
      uid: 'demo-uid-99',
      email: email ?? AppConstants.demoEmail,
      displayName: 'Demo User',
    );
    _currentUser = user;
    _streamController.add(user);
    return FakeUserCredential(user: user);
  }

  void dispose() {
    _streamController.close();
  }
}

void main() {
  late FakeAuthRemoteDataSource fakeRemoteDataSource;
  late SharedPreferences sharedPreferences;
  late AuthRepositoryImpl authRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
    fakeRemoteDataSource = FakeAuthRemoteDataSource();
    authRepository = AuthRepositoryImpl(
      remoteDataSource: fakeRemoteDataSource,
      sharedPreferences: sharedPreferences,
    );
  });

  tearDown(() {
    fakeRemoteDataSource.dispose();
  });

  group('AuthUser Entity Tests', () {
    test('computes initials correctly for full name and single name', () {
      const userWithFullName = AuthUser(
        id: '1',
        email: 'john.doe@example.com',
        displayName: 'John Doe',
      );
      expect(userWithFullName.initials, equals('JD'));

      const userWithSingleName = AuthUser(
        id: '2',
        email: 'aygen@example.com',
        displayName: 'Aygen',
      );
      expect(userWithSingleName.initials, equals('A'));

      const userWithoutName = AuthUser(
        id: '3',
        email: 'nestora@test.com',
      );
      expect(userWithoutName.initials, equals('N'));
    });

    test('supports value equality and copyWith', () {
      const user1 = AuthUser(id: '1', email: 'a@b.com', displayName: 'User');
      const user2 = AuthUser(id: '1', email: 'a@b.com', displayName: 'Different');
      expect(user1, equals(user2));

      final updated = user1.copyWith(displayName: 'Updated');
      expect(updated.displayName, equals('Updated'));
      expect(updated.id, equals('1'));
    });
  });

  group('signInWithEmail Tests', () {
    test('returns Result.success(AuthUser) and caches last email', () async {
      final result = await authRepository.signInWithEmail(
        email: 'test@nestora.app',
        password: 'ValidPassword1!',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data.id, equals('user-123'));
      expect(result.data.email, equals('test@nestora.app'));
      expect(
        sharedPreferences.getString(AppConstants.prefLastUserEmail),
        equals('test@nestora.app'),
      );
    });

    test('returns Result.failure(AuthFailure) when remote datasource throws AuthException', () async {
      fakeRemoteDataSource.shouldThrow = true;
      fakeRemoteDataSource.throwCode = 'wrong-password';
      fakeRemoteDataSource.throwMessage = 'E-posta veya şifre hatalı.';

      final result = await authRepository.signInWithEmail(
        email: 'wrong@nestora.app',
        password: 'WrongPassword!',
      );

      expect(result.isFailure, isTrue);
      expect(result.failure, isA<AuthFailure>());
      expect(result.failure.message, equals('E-posta veya şifre hatalı.'));
      expect((result.failure as AuthFailure).code, equals('wrong-password'));
    });
  });

  group('signUpWithEmail Tests', () {
    test('returns Result.success(AuthUser) and caches last email on signup', () async {
      final result = await authRepository.signUpWithEmail(
        email: 'newuser@nestora.app',
        password: 'Password123!',
        displayName: 'Yeni Kullanıcı',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data.id, equals('user-new'));
      expect(result.data.displayName, equals('Yeni Kullanıcı'));
      expect(
        sharedPreferences.getString(AppConstants.prefLastUserEmail),
        equals('newuser@nestora.app'),
      );
    });

    test('returns Result.failure on signup error', () async {
      fakeRemoteDataSource.shouldThrow = true;
      fakeRemoteDataSource.throwCode = 'email-already-in-use';
      fakeRemoteDataSource.throwMessage = 'Bu e-posta adresi zaten kullanımda.';

      final result = await authRepository.signUpWithEmail(
        email: 'existing@nestora.app',
        password: 'Password123!',
      );

      expect(result.isFailure, isTrue);
      expect(result.failure.message, contains('zaten kullanımda'));
    });
  });

  group('signOut & sendPasswordReset Tests', () {
    test('signOut returns Result.success', () async {
      final result = await authRepository.signOut();
      expect(result.isSuccess, isTrue);
    });

    test('sendPasswordReset returns Result.success on valid email', () async {
      final result = await authRepository.sendPasswordReset(
        email: 'reset@nestora.app',
      );
      expect(result.isSuccess, isTrue);
    });
  });

  group('signInDemo Tests', () {
    test('signInDemo uses default demo credentials and returns Result.success', () async {
      final result = await authRepository.signInDemo();

      expect(result.isSuccess, isTrue);
      expect(result.data.id, equals('demo-uid-99'));
      expect(result.data.email, equals(AppConstants.demoEmail));
    });
  });

  group('currentUser & authStateChanges Tests', () {
    test('currentUser returns AuthUser when logged in and null when logged out', () async {
      expect(authRepository.currentUser, isNull);

      await authRepository.signInWithEmail(
        email: 'user@test.com',
        password: 'Password1!',
      );

      expect(authRepository.currentUser, isNotNull);
      expect(authRepository.currentUser!.email, equals('user@test.com'));

      await authRepository.signOut();
      expect(authRepository.currentUser, isNull);
    });

    test('authStateChanges emits stream of AuthUser entities', () async {
      expectLater(
        authRepository.authStateChanges,
        emitsInOrder([
          isA<AuthUser>().having((u) => u.email, 'email', 'stream@test.com'),
          isNull,
        ]),
      );

      await authRepository.signInWithEmail(
        email: 'stream@test.com',
        password: 'Password1!',
      );

      await authRepository.signOut();
    });
  });
}
