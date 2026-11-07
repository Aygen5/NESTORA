import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/di/injection.dart';
import 'package:nestora/core/constants/app_constants.dart';
import 'package:nestora/core/errors/failures.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/core/widgets/nestora_button.dart';
import 'package:nestora/features/auth/domain/entities/auth_user.dart';
import 'package:nestora/features/auth/domain/repositories/auth_repository.dart';
import 'package:nestora/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nestora/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:nestora/features/auth/presentation/pages/login_page.dart';
import 'package:nestora/features/auth/presentation/pages/register_page.dart';
import 'package:nestora/features/auth/presentation/widgets/password_validator_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;

  Result<AuthUser>? nextSignInResult;
  Result<AuthUser>? nextSignUpResult;
  Result<AuthUser>? nextDemoResult;
  Result<void>? nextResetResult;

  String? lastSignInEmail;
  String? lastSignInPassword;
  String? lastSignUpEmail;
  String? lastSignUpPassword;
  String? lastSignUpName;
  String? lastResetEmail;
  bool demoCalled = false;

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser => _currentUser;

  void emitUser(AuthUser? user) {
    _currentUser = user;
    _controller.add(user);
  }

  @override
  Future<Result<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    lastSignInEmail = email;
    lastSignInPassword = password;
    return nextSignInResult ??
        Result.success(AuthUser(id: 'uid-1', email: email, displayName: 'Test User'));
  }

  @override
  Future<Result<AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    lastSignUpEmail = email;
    lastSignUpPassword = password;
    lastSignUpName = displayName;
    return nextSignUpResult ??
        Result.success(AuthUser(id: 'uid-2', email: email, displayName: displayName));
  }

  @override
  Future<Result<AuthUser>> signInDemo({String? email, String? password}) async {
    demoCalled = true;
    return nextDemoResult ??
        Result.success(const AuthUser(id: 'demo-uid', email: 'demo@nestora.com', displayName: 'Demo'));
  }

  @override
  Future<Result<void>> sendPasswordReset({required String email}) async {
    lastResetEmail = email;
    return nextResetResult ?? Result.success(null);
  }

  @override
  Future<Result<void>> signOut() async {
    _currentUser = null;
    _controller.add(null);
    return Result.success(null);
  }

  void dispose() {
    _controller.close();
  }
}

void _setTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
}

void main() {
  late _FakeAuthRepository fakeRepo;
  late AuthCubit cubit;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    sl.reset();
    sl.registerSingleton<SharedPreferences>(prefs);

    fakeRepo = _FakeAuthRepository();
    cubit = AuthCubit(authRepository: fakeRepo);
  });

  tearDown(() {
    cubit.close();
    fakeRepo.dispose();
    sl.reset();
  });

  group('LoginPage Widget & Interaction Tests', () {
    testWidgets('renders all visual elements and fields correctly', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(authCubit: cubit),
        ),
      );
      await tester.pump();

      expect(find.text('Tekrar hoş geldin!'), findsOneWidget);
      expect(find.text('E-posta'), findsOneWidget);
      expect(find.text('Şifre'), findsOneWidget);
      expect(find.text('Beni Hatırla'), findsOneWidget);
      expect(find.text('Şifremi Unuttum?'), findsOneWidget);
      expect(find.text('Giriş Yap'), findsOneWidget);
      expect(find.text('Hızlı Demo ile Giriş Yap'), findsOneWidget);
      expect(find.text('Kayıt Ol'), findsOneWidget);
    });

    testWidgets('validates empty and invalid email format with SnackBar feedback', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginPage(authCubit: cubit),
          ),
        ),
      );
      await tester.pump();

      // Tap Giriş Yap with empty email
      await tester.tap(find.widgetWithText(NestoraButton, 'Giriş Yap'));
      await tester.pump();
      expect(find.text('Lütfen e-posta adresinizi giriniz.'), findsOneWidget);

      // Enter invalid email
      await tester.enterText(find.byType(TextField).first, 'invalid-email');
      await tester.tap(find.widgetWithText(NestoraButton, 'Giriş Yap'));
      await tester.pump();
      expect(find.text('Lütfen geçerli bir e-posta adresi giriniz.'), findsOneWidget);
    });

    testWidgets('validates empty password with SnackBar feedback', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginPage(authCubit: cubit),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, 'user@example.com');
      await tester.tap(find.widgetWithText(NestoraButton, 'Giriş Yap'));
      await tester.pump();
      expect(find.text('Lütfen şifrenizi giriniz.'), findsOneWidget);
    });

    testWidgets('toggles Remember Me checkbox and saves preference upon success', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      bool successCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginPage(
              authCubit: cubit,
              onLoginSuccess: () => successCalled = true,
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap "Beni Hatırla"
      await tester.tap(find.text('Beni Hatırla'));
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, 'aygen@nestora.com');
      await tester.enterText(find.byType(TextField).last, 'Nestora2026*');
      await tester.tap(find.widgetWithText(NestoraButton, 'Giriş Yap'));
      await tester.pumpAndSettle();

      expect(successCalled, isTrue);
      final prefs = sl<SharedPreferences>();
      expect(prefs.getBool(AppConstants.prefRememberMe), isTrue);
      expect(prefs.getString(AppConstants.prefLastUserEmail), 'aygen@nestora.com');
    });

    testWidgets('loads remembered email on initialization', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final prefs = sl<SharedPreferences>();
      await prefs.setBool(AppConstants.prefRememberMe, true);
      await prefs.setString(AppConstants.prefLastUserEmail, 'remembered@nestora.com');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginPage(authCubit: cubit),
          ),
        ),
      );
      await tester.pump();

      final emailField = tester.widget<TextField>(find.byType(TextField).first);
      expect(emailField.controller?.text, 'remembered@nestora.com');
    });

    testWidgets('displays error SnackBar on authentication failure', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      fakeRepo.nextSignInResult = Result.failure(
        const AuthFailure('Girdiğiniz şifre hatalıdır.'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginPage(authCubit: cubit),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, 'user@example.com');
      await tester.enterText(find.byType(TextField).last, 'WrongPass123!');
      await tester.tap(find.widgetWithText(NestoraButton, 'Giriş Yap'));
      await tester.pumpAndSettle();

      expect(find.text('Girdiğiniz şifre hatalıdır.'), findsOneWidget);
    });

    testWidgets('triggers navigation callbacks for register, forgot password, and demo', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      bool registerTapped = false;
      bool forgotTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginPage(
              authCubit: cubit,
              onNavigateToRegister: () => registerTapped = true,
              onNavigateToForgotPassword: () => forgotTapped = true,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Şifremi Unuttum?'));
      await tester.pump();
      expect(forgotTapped, isTrue);

      await tester.tap(find.text('Kayıt Ol'));
      await tester.pump();
      expect(registerTapped, isTrue);

      await tester.tap(find.text('Hızlı Demo ile Giriş Yap'));
      await tester.pumpAndSettle();
      expect(fakeRepo.demoCalled, isTrue);
      expect(find.text("Aygen Yıldırım profili yüklendi (Aygen'in Evi)"), findsOneWidget);
    });
  });

  group('RegisterPage Widget & Validation Tests', () {
    testWidgets('renders all fields and shows live password validator on input', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegisterPage(authCubit: cubit),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Aramıza Katıl'), findsOneWidget);
      expect(find.text('Ad Soyad'), findsOneWidget);
      expect(find.text('E-posta'), findsOneWidget);
      expect(find.text('Şifre'), findsOneWidget);
      expect(find.text('Şifre Tekrar'), findsOneWidget);
      expect(find.text('Hesap Oluştur'), findsOneWidget);

      // Password validator should not be visible before typing password
      expect(find.byType(PasswordValidatorWidget), findsNothing);

      // Type in password field
      await tester.enterText(find.byType(TextField).at(2), 'Pass');
      await tester.pump();
      expect(find.byType(PasswordValidatorWidget), findsOneWidget);
      expect(find.text('En az 8 karakter'), findsOneWidget);
    });

    testWidgets('validates required fields: empty name, email, and password complexity', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegisterPage(authCubit: cubit),
          ),
        ),
      );
      await tester.pump();

      // 1. Empty name
      await tester.tap(find.widgetWithText(NestoraButton, 'Hesap Oluştur'));
      await tester.pump();
      expect(find.text('Lütfen adınızı ve soyadınızı giriniz.'), findsOneWidget);

      // 2. Empty email
      await tester.enterText(find.byType(TextField).at(0), 'Aygen Yıldırım');
      await tester.tap(find.widgetWithText(NestoraButton, 'Hesap Oluştur'));
      await tester.pump();
      expect(find.text('Lütfen geçerli bir e-posta adresi giriniz.'), findsOneWidget);

      // 3. Password shorter than 8 chars
      await tester.enterText(find.byType(TextField).at(1), 'aygen@nestora.com');
      await tester.enterText(find.byType(TextField).at(2), 'Ab1!');
      await tester.enterText(find.byType(TextField).at(3), 'Ab1!');
      await tester.tap(find.widgetWithText(NestoraButton, 'Hesap Oluştur'));
      await tester.pump();
      expect(find.text('Şifreniz en az 8 karakter uzunluğunda olmalıdır.'), findsOneWidget);

      // 4. Password mismatch
      await tester.enterText(find.byType(TextField).at(2), 'Nestora2026*');
      await tester.enterText(find.byType(TextField).at(3), 'Different2026*');
      await tester.pump();
      expect(find.text('Şifreler eşleşmiyor'), findsOneWidget);
    });

    testWidgets('validates terms checkbox acceptance', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegisterPage(authCubit: cubit),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'Aygen Yıldırım');
      await tester.enterText(find.byType(TextField).at(1), 'aygen@nestora.com');
      await tester.enterText(find.byType(TextField).at(2), 'Nestora2026*');
      await tester.enterText(find.byType(TextField).at(3), 'Nestora2026*');

      // Uncheck terms
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tester.tap(find.widgetWithText(NestoraButton, 'Hesap Oluştur'));
      await tester.pump();
      expect(find.text('Lütfen Kullanım Koşulları\'nı onaylayınız.'), findsOneWidget);
    });

    testWidgets('successful registration calls cubit and triggers onRegisterSuccess', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      bool successCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegisterPage(
              authCubit: cubit,
              onRegisterSuccess: () => successCalled = true,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'Aygen Yıldırım');
      await tester.enterText(find.byType(TextField).at(1), 'aygen@nestora.com');
      await tester.enterText(find.byType(TextField).at(2), 'Nestora2026*');
      await tester.enterText(find.byType(TextField).at(3), 'Nestora2026*');

      await tester.tap(find.widgetWithText(NestoraButton, 'Hesap Oluştur'));
      await tester.pumpAndSettle();

      expect(successCalled, isTrue);
      expect(fakeRepo.lastSignUpEmail, 'aygen@nestora.com');
      expect(fakeRepo.lastSignUpPassword, 'Nestora2026*');
      expect(fakeRepo.lastSignUpName, 'Aygen Yıldırım');
    });
  });

  group('ForgotPasswordPage Widget & Interaction Tests', () {
    testWidgets('renders email field and handles validation and submit flow', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ForgotPasswordPage(authCubit: cubit),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Şifre Sıfırlama'), findsOneWidget);
      expect(find.text('Şifreni mi unuttun?'), findsOneWidget);
      expect(find.text('Sıfırlama Bağlantısı Gönder'), findsOneWidget);

      // 1. Empty email validation
      await tester.tap(find.widgetWithText(NestoraButton, 'Sıfırlama Bağlantısı Gönder'));
      await tester.pump();
      expect(find.text('Lütfen e-posta adresinizi giriniz.'), findsOneWidget);

      // 2. Invalid email format
      await tester.enterText(find.byType(TextField), 'not-an-email');
      await tester.tap(find.widgetWithText(NestoraButton, 'Sıfırlama Bağlantısı Gönder'));
      await tester.pump();
      expect(find.text('Lütfen geçerli bir e-posta adresi giriniz.'), findsOneWidget);

      // 3. Valid email triggers password reset link
      await tester.enterText(find.byType(TextField), 'aygen@nestora.com');
      await tester.tap(find.widgetWithText(NestoraButton, 'Sıfırlama Bağlantısı Gönder'));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastResetEmail, 'aygen@nestora.com');
      expect(find.text('E-posta gönderildi.'), findsOneWidget);
      expect(find.text('Bağlantı İletildi'), findsOneWidget);
    });

    testWidgets('displays error SnackBar when reset link dispatch fails', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      fakeRepo.nextResetResult = Result.failure(
        const AuthFailure('Bu e-posta adresine kayıtlı kullanıcı bulunamadı.'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ForgotPasswordPage(authCubit: cubit),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'unknown@nestora.com');
      await tester.tap(find.widgetWithText(NestoraButton, 'Sıfırlama Bağlantısı Gönder'));
      await tester.pumpAndSettle();

      expect(find.text('Bu e-posta adresine kayıtlı kullanıcı bulunamadı.'), findsOneWidget);
    });

    testWidgets('triggers onBackToLogin callback when return button is tapped', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      bool backCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ForgotPasswordPage(
              authCubit: cubit,
              onBackToLogin: () => backCalled = true,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Giriş Ekranına Dön'));
      await tester.pump();
      expect(backCalled, isTrue);
    });
  });
}
