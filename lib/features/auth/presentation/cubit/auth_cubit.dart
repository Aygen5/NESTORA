import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/crashlytics_service.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../widgets/password_validator_widget.dart';
import 'auth_state.dart';

/// Cubit managing user authentication flow, input validation, and session states.
/// Dispatches privacy-safe analytics events and records unexpected auth failures.
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;
  final AnalyticsService? analyticsService;
  final CrashlyticsService? crashlyticsService;

  // Domain Use Cases
  final SignInWithEmailUseCase signInWithEmailUseCase;
  final SignUpWithEmailUseCase signUpWithEmailUseCase;
  final SignInDemoUseCase signInDemoUseCase;
  final SignOutUseCase signOutUseCase;
  final SendPasswordResetUseCase sendPasswordResetUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final WatchAuthStateUseCase watchAuthStateUseCase;

  StreamSubscription<AuthUser?>? _authSubscription;

  AuthCubit({
    required this.authRepository,
    this.analyticsService,
    this.crashlyticsService,
    SignInWithEmailUseCase? signInWithEmailUseCase,
    SignUpWithEmailUseCase? signUpWithEmailUseCase,
    SignInDemoUseCase? signInDemoUseCase,
    SignOutUseCase? signOutUseCase,
    SendPasswordResetUseCase? sendPasswordResetUseCase,
    GetCurrentUserUseCase? getCurrentUserUseCase,
    WatchAuthStateUseCase? watchAuthStateUseCase,
  })  : signInWithEmailUseCase = signInWithEmailUseCase ?? SignInWithEmailUseCase(authRepository),
        signUpWithEmailUseCase = signUpWithEmailUseCase ?? SignUpWithEmailUseCase(authRepository),
        signInDemoUseCase = signInDemoUseCase ?? SignInDemoUseCase(authRepository),
        signOutUseCase = signOutUseCase ?? SignOutUseCase(authRepository),
        sendPasswordResetUseCase = sendPasswordResetUseCase ?? SendPasswordResetUseCase(authRepository),
        getCurrentUserUseCase = getCurrentUserUseCase ?? GetCurrentUserUseCase(authRepository),
        watchAuthStateUseCase = watchAuthStateUseCase ?? WatchAuthStateUseCase(authRepository),
        super(const AuthInitial()) {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription = watchAuthStateUseCase().listen((authUser) {
      if (authUser != null) {
        analyticsService?.setUserId(authUser.id);
        crashlyticsService?.setUserId(authUser.id);
        emit(Authenticated(authUser));
      } else {
        if (state is! AuthInitial && state is! AuthLoading) {
          emit(const Unauthenticated());
        }
      }
    });
  }

  /// Checks the current cached/SDK authentication status and emits the proper state.
  void checkAuthStatus() {
    final user = getCurrentUserUseCase();
    if (user != null) {
      analyticsService?.setUserId(user.id);
      crashlyticsService?.setUserId(user.id);
      emit(Authenticated(user));
    } else {
      emit(const Unauthenticated());
    }
  }

  /// Authenticates using email and password with format validation.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !AppConstants.emailRegex.hasMatch(cleanEmail)) {
      emit(const AuthError('Lütfen geçerli bir e-posta adresi giriniz.'));
      return;
    }

    if (password.isEmpty) {
      emit(const AuthError('Lütfen şifrenizi giriniz.'));
      return;
    }

    emit(const AuthLoading(message: 'Giriş yapılıyor...'));

    final result = await signInWithEmailUseCase(
      email: cleanEmail,
      password: password,
    );

    result.when(
      success: (user) {
        analyticsService?.logLogin(method: 'email');
        analyticsService?.setUserId(user.id);
        crashlyticsService?.setUserId(user.id);
        emit(Authenticated(user));
      },
      failure: (failure) {
        crashlyticsService?.recordError(
          failure,
          null,
          reason: 'signInWithEmail failure: ${failure.code}',
        );
        emit(AuthError(failure.message, code: failure.code));
      },
    );
  }

  /// Registers a new account with email, password complexity verification, and confirmation match.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String passwordConfirm,
    String? displayName,
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !AppConstants.emailRegex.hasMatch(cleanEmail)) {
      emit(const AuthError('Lütfen geçerli bir e-posta adresi giriniz.'));
      return;
    }

    // Evaluate password rules: min 8 chars, uppercase, number, special char, and matching confirmation
    final validation = PasswordValidationResult.evaluate(password, passwordConfirm);

    if (!validation.hasMin8Chars) {
      emit(const AuthError('Şifreniz en az 8 karakter uzunluğunda olmalıdır.'));
      return;
    }

    if (!validation.hasUppercase) {
      emit(const AuthError('Şifreniz en az bir büyük harf içermelidir.'));
      return;
    }

    if (!validation.hasNumber) {
      emit(const AuthError('Şifreniz en az bir rakam içermelidir.'));
      return;
    }

    if (!validation.hasSpecialChar) {
      emit(const AuthError('Şifreniz en az bir özel karakter (!@#\$% vb.) içermelidir.'));
      return;
    }

    if (!validation.isMatching) {
      emit(const AuthError('Girdiğiniz şifreler birbiriyle eşleşmiyor.'));
      return;
    }

    emit(const AuthLoading(message: 'Hesabınız oluşturuluyor...'));

    final result = await signUpWithEmailUseCase(
      email: cleanEmail,
      password: password,
      displayName: displayName?.trim(),
    );

    result.when(
      success: (user) {
        analyticsService?.logSignUp(method: 'email');
        analyticsService?.setUserId(user.id);
        crashlyticsService?.setUserId(user.id);
        emit(Authenticated(user));
      },
      failure: (failure) {
        crashlyticsService?.recordError(
          failure,
          null,
          reason: 'signUpWithEmail failure: ${failure.code}',
        );
        emit(AuthError(failure.message, code: failure.code));
      },
    );
  }

  /// Signs in using the pre-configured Demo account credentials.
  Future<void> signInDemo({
    String? email,
    String? password,
  }) async {
    emit(const AuthLoading(message: 'Demo hesaba bağlanılıyor...'));

    final result = await signInDemoUseCase(
      email: email,
      password: password,
    );

    result.when(
      success: (user) {
        analyticsService?.logLogin(method: 'demo');
        analyticsService?.setUserId(user.id);
        crashlyticsService?.setUserId(user.id);
        emit(Authenticated(user));
      },
      failure: (failure) {
        crashlyticsService?.recordError(
          failure,
          null,
          reason: 'signInDemo failure: ${failure.code}',
        );
        emit(AuthError(failure.message, code: failure.code));
      },
    );
  }

  /// Dispatches a password reset link to the provided email address.
  Future<void> sendPasswordReset({
    required String email,
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !AppConstants.emailRegex.hasMatch(cleanEmail)) {
      emit(const AuthError('Lütfen geçerli bir e-posta adresi giriniz.'));
      return;
    }

    emit(const AuthLoading(message: 'Şifre sıfırlama bağlantısı gönderiliyor...'));

    final result = await sendPasswordResetUseCase(email: cleanEmail);

    result.when(
      success: (_) => emit(AuthPasswordResetSent(cleanEmail)),
      failure: (failure) {
        crashlyticsService?.recordError(
          failure,
          null,
          reason: 'sendPasswordReset failure: ${failure.code}',
        );
        emit(AuthError(failure.message, code: failure.code));
      },
    );
  }

  /// Signs the user out from active session.
  Future<void> signOut() async {
    emit(const AuthLoading(message: 'Çıkış yapılıyor...'));

    final result = await signOutUseCase();

    result.when(
      success: (_) {
        analyticsService?.logLogout();
        analyticsService?.setUserId(null);
        crashlyticsService?.setUserId(null);
        emit(const Unauthenticated());
      },
      failure: (failure) {
        crashlyticsService?.recordError(
          failure,
          null,
          reason: 'signOut failure: ${failure.code}',
        );
        emit(AuthError(failure.message, code: failure.code));
      },
    );
  }

  /// Resets an active error state back to unauthenticated or current session.
  void clearError() {
    if (state is AuthError) {
      final user = authRepository.currentUser;
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
