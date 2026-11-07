import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/core/errors/failures.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/features/auth/domain/entities/auth_user.dart';
import 'package:nestora/features/auth/domain/repositories/auth_repository.dart';
import 'package:nestora/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nestora/features/auth/presentation/cubit/auth_state.dart';

class FakeAuthRepository implements AuthRepository {
  final StreamController<AuthUser?> _authController =
      StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;
  bool shouldFail = false;
  String failMessage = 'Kimlik doğrulama hatası.';

  FakeAuthRepository({AuthUser? initialUser}) : _currentUser = initialUser;

  @override
  Stream<AuthUser?> get authStateChanges => _authController.stream;

  @override
  AuthUser? get currentUser => _currentUser;

  void emitAuthUser(AuthUser? user) {
    _currentUser = user;
    _authController.add(user);
  }

  @override
  Future<Result<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    if (shouldFail) {
      return Result.failure(AuthFailure(failMessage));
    }
    final user = AuthUser(
      id: 'test-user-id',
      email: email,
      displayName: 'Test User',
    );
    _currentUser = user;
    _authController.add(user);
    return Result.success(user);
  }

  @override
  Future<Result<AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    if (shouldFail) {
      return Result.failure(AuthFailure(failMessage));
    }
    final user = AuthUser(
      id: 'new-user-id',
      email: email,
      displayName: displayName ?? 'New User',
    );
    _currentUser = user;
    _authController.add(user);
    return Result.success(user);
  }

  @override
  Future<Result<void>> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    if (shouldFail) {
      return Result.failure(AuthFailure(failMessage));
    }
    _currentUser = null;
    _authController.add(null);
    return Result.success(null);
  }

  @override
  Future<Result<void>> sendPasswordReset({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    if (shouldFail) {
      return Result.failure(AuthFailure(failMessage));
    }
    return Result.success(null);
  }

  @override
  Future<Result<AuthUser>> signInDemo({String? email, String? password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    if (shouldFail) {
      return Result.failure(AuthFailure(failMessage));
    }
    const user = AuthUser(
      id: 'demo-user-id',
      email: 'demo@nestora.app',
      displayName: 'Demo User',
    );
    _currentUser = user;
    _authController.add(user);
    return Result.success(user);
  }

  void dispose() {
    _authController.close();
  }
}

void main() {
  late FakeAuthRepository fakeRepository;
  late AuthCubit authCubit;

  setUp(() {
    fakeRepository = FakeAuthRepository();
    authCubit = AuthCubit(authRepository: fakeRepository);
  });

  tearDown(() {
    authCubit.close();
    fakeRepository.dispose();
  });

  group('AuthCubit Initial & checkAuthStatus Tests', () {
    test('initial state is AuthInitial', () {
      expect(authCubit.state, equals(const AuthInitial()));
    });

    test('checkAuthStatus emits Authenticated when user is logged in', () {
      const user = AuthUser(id: '1', email: 'test@nestora.app');
      fakeRepository._currentUser = user;

      authCubit.checkAuthStatus();
      expect(authCubit.state, equals(const Authenticated(user)));
    });

    test('checkAuthStatus emits Unauthenticated when user is null', () {
      fakeRepository._currentUser = null;

      authCubit.checkAuthStatus();
      expect(authCubit.state, equals(const Unauthenticated()));
    });
  });

  group('signInWithEmail Tests', () {
    test('emits AuthError when email format is invalid', () async {
      await authCubit.signInWithEmail(
        email: 'invalid-email',
        password: 'ValidPassword1!',
      );

      expect(authCubit.state, isA<AuthError>());
      expect(
        (authCubit.state as AuthError).message,
        contains('geçerli bir e-posta'),
      );
    });

    test('emits AuthError when password is empty', () async {
      await authCubit.signInWithEmail(
        email: 'test@nestora.app',
        password: '',
      );

      expect(authCubit.state, isA<AuthError>());
      expect((authCubit.state as AuthError).message, contains('şifrenizi'));
    });

    test('emits [AuthLoading, Authenticated] on successful login', () async {
      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Authenticated>().having((a) => a.user.email, 'email', 'aygen@nestora.app'),
        ]),
      );

      await authCubit.signInWithEmail(
        email: 'aygen@nestora.app',
        password: 'Password123!',
      );
    });

    test('emits [AuthLoading, AuthError] on failed login', () async {
      fakeRepository.shouldFail = true;
      fakeRepository.failMessage = 'E-posta veya şifre hatalı.';

      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthError>().having((e) => e.message, 'message', 'E-posta veya şifre hatalı.'),
        ]),
      );

      await authCubit.signInWithEmail(
        email: 'aygen@nestora.app',
        password: 'Password123!',
      );
    });
  });

  group('signUpWithEmail & Validation Tests', () {
    test('rejects passwords shorter than 8 characters', () async {
      await authCubit.signUpWithEmail(
        email: 'test@nestora.app',
        password: 'Pass1!',
        passwordConfirm: 'Pass1!',
      );

      expect(authCubit.state, isA<AuthError>());
      expect((authCubit.state as AuthError).message, contains('en az 8 karakter'));
    });

    test('rejects passwords without uppercase letter', () async {
      await authCubit.signUpWithEmail(
        email: 'test@nestora.app',
        password: 'password123!',
        passwordConfirm: 'password123!',
      );

      expect(authCubit.state, isA<AuthError>());
      expect((authCubit.state as AuthError).message, contains('büyük harf'));
    });

    test('rejects passwords without digit', () async {
      await authCubit.signUpWithEmail(
        email: 'test@nestora.app',
        password: 'Password!',
        passwordConfirm: 'Password!',
      );

      expect(authCubit.state, isA<AuthError>());
      expect((authCubit.state as AuthError).message, contains('rakam'));
    });

    test('rejects passwords without special character', () async {
      await authCubit.signUpWithEmail(
        email: 'test@nestora.app',
        password: 'Password123',
        passwordConfirm: 'Password123',
      );

      expect(authCubit.state, isA<AuthError>());
      expect((authCubit.state as AuthError).message, contains('özel karakter'));
    });

    test('rejects passwords when confirmation does not match', () async {
      await authCubit.signUpWithEmail(
        email: 'test@nestora.app',
        password: 'ValidPassword1!',
        passwordConfirm: 'DifferentPassword1!',
      );

      expect(authCubit.state, isA<AuthError>());
      expect((authCubit.state as AuthError).message, contains('eşleşmiyor'));
    });

    test('emits [AuthLoading, Authenticated] when signup requirements are all met', () async {
      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Authenticated>().having((a) => a.user.displayName, 'displayName', 'Aygen'),
        ]),
      );

      await authCubit.signUpWithEmail(
        email: 'new@nestora.app',
        password: 'SecurePassword2026!',
        passwordConfirm: 'SecurePassword2026!',
        displayName: 'Aygen',
      );
    });
  });

  group('signInDemo, sendPasswordReset, signOut & clearError Tests', () {
    test('signInDemo emits [AuthLoading, Authenticated]', () async {
      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Authenticated>(),
        ]),
      );

      await authCubit.signInDemo();
    });

    test('sendPasswordReset emits [AuthLoading, AuthPasswordResetSent]', () async {
      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthPasswordResetSent>().having((s) => s.email, 'email', 'forgot@nestora.app'),
        ]),
      );

      await authCubit.sendPasswordReset(email: 'forgot@nestora.app');
    });

    test('signOut emits [AuthLoading, Unauthenticated]', () async {
      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Unauthenticated>(),
        ]),
      );

      await authCubit.signOut();
    });

    test('clearError resets AuthError to Unauthenticated when logged out', () async {
      await authCubit.signInWithEmail(email: 'invalid', password: '');
      expect(authCubit.state, isA<AuthError>());

      authCubit.clearError();
      expect(authCubit.state, equals(const Unauthenticated()));
    });
  });
}
