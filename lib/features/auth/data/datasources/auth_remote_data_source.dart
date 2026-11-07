import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';

/// Contract for Remote Authentication Data Source interacting directly with Firebase SDKs.
abstract class AuthRemoteDataSource {
  /// Stream emitting Firebase [User] state changes.
  Stream<User?> get authStateChanges;

  /// Current Firebase [User], if any.
  User? get currentUser;

  /// Signs in existing user with email and password via Firebase Auth.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  });

  /// Creates a new user in Firebase Auth and initializes user profile data.
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  /// Signs out from Firebase Auth.
  Future<void> signOut();

  /// Requests password reset email via Firebase Auth.
  Future<void> sendPasswordReset({
    required String email,
  });

  /// Authenticates using the configured Demo account credentials.
  Future<UserCredential> signInDemo({
    String? email,
    String? password,
  });
}

/// Firebase implementation of [AuthRemoteDataSource].
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore? firestore;

  AuthRemoteDataSourceImpl({
    FirebaseAuth? firebaseAuth,
    this.firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseErrorToMessage(e), code: e.code);
    } catch (e) {
      throw AuthException('Giriş yapılırken beklenmeyen bir hata oluştu: $e');
    }
  }

  @override
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        if (displayName != null && displayName.trim().isNotEmpty) {
          try {
            await user.updateDisplayName(displayName.trim());
          } catch (e) {
            debugPrint('AuthRemoteDataSource: updateDisplayName error ($e)');
          }
        }

        // Initialize user document in Cloud Firestore if available
        if (firestore != null) {
          try {
            final name = (displayName != null && displayName.trim().isNotEmpty)
                ? displayName.trim()
                : 'Nestora Kullanıcısı';

            await firestore!.collection('users').doc(user.uid).set({
              'email': email.trim(),
              'displayName': name,
              'homeName': "$name'in Evi",
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } catch (e) {
            debugPrint('AuthRemoteDataSource: Firestore user doc creation notice ($e)');
          }
        }
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseErrorToMessage(e), code: e.code);
    } catch (e) {
      throw AuthException('Kayıt olurken beklenmeyen bir hata oluştu: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseErrorToMessage(e), code: e.code);
    } catch (e) {
      throw AuthException('Çıkış yapılırken bir hata oluştu: $e');
    }
  }

  @override
  Future<void> sendPasswordReset({
    required String email,
  }) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseErrorToMessage(e), code: e.code);
    } catch (e) {
      throw AuthException('Şifre sıfırlama e-postası gönderilirken hata oluştu: $e');
    }
  }

  @override
  Future<UserCredential> signInDemo({
    String? email,
    String? password,
  }) async {
    final demoEmail = email ?? AppConstants.demoEmail;
    final demoPassword = password ?? AppConstants.demoPassword;

    try {
      return await signInWithEmail(
        email: demoEmail,
        password: demoPassword,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Demo girişi yapılırken bir hata oluştu: $e');
    }
  }

  /// Maps standard Firebase Auth error codes into clear, user-friendly Turkish messages.
  String _mapFirebaseErrorToMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Lütfen geçerli bir e-posta adresi giriniz.';
      case 'user-disabled':
        return 'Bu kullanıcı hesabı askıya alınmıştır.';
      case 'user-not-found':
        return 'Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı. Lütfen kontrol ediniz.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'operation-not-allowed':
        return 'E-posta/şifre ile oturum açma yöntemi şu anda devre dışı.';
      case 'weak-password':
        return 'Belirtilen şifre yeterince güçlü değil.';
      case 'too-many-requests':
        return 'Çok fazla başarısız deneme yapıldı. Lütfen biraz sonra tekrar deneyiniz.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edip tekrar deneyiniz.';
      default:
        return e.message ?? 'Kimlik doğrulama işlemi gerçekleştirilemedi.';
    }
  }
}
