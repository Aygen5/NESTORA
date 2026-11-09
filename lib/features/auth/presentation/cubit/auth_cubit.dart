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

// Kullanıcı kimlik doğrulama akışını, form doğrulamasını ve oturum durumunu yönetir.
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;
  final AnalyticsService? analyticsService;
  final CrashlyticsService? crashlyticsService;

  // İş mantığı kullanım senaryoları (Use Cases)
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

  // Mevcut oturum durumunu denetler ve uygun durumu yayar.
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

  // E-posta ve şifre ile sisteme giriş yapar.
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

  // E-posta, şifre ve şifre tekrarı ile yeni bir kullanıcı hesabı kaydeder.
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

    // Şifre kurallarını doğrular: en az 8 karakter, büyük harf, rakam ve özel karakter.
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

  // Önceden yapılandırılmış Demo hesabıyla hızlı giriş yapar.
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

  // Belirtilen e-posta adresine şifre sıfırlama bağlantısı gönderir.
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

  // Kullanıcının mevcut oturumunu kapatır.
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

  // Hata durumunu temizleyerek oturum durumuna geri döner.
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
