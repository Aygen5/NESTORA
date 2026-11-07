import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'app_router.dart';

/// [AppAuthListenable] listens to authentication state changes (via FirebaseAuth or manual overrides)
/// and notifies GoRouter so redirect guards can trigger automatically.
class AppAuthListenable extends ChangeNotifier {
  final FirebaseAuth? firebaseAuth;
  StreamSubscription<User?>? _authSubscription;
  bool _isAuthenticated;

  AppAuthListenable({
    this.firebaseAuth,
    bool initialAuthState = false,
  }) : _isAuthenticated = initialAuthState {
    if (firebaseAuth != null) {
      _isAuthenticated = firebaseAuth!.currentUser != null;
      _authSubscription = firebaseAuth!.authStateChanges().listen((User? user) {
        final newAuth = user != null;
        if (_isAuthenticated != newAuth) {
          _isAuthenticated = newAuth;
          notifyListeners();
        }
      });
    }
  }

  /// Whether a user is currently authenticated.
  bool get isAuthenticated => _isAuthenticated;

  /// Manually set the auth status (useful for unit tests, demo mode, and transitions).
  void setAuthenticated(bool value) {
    if (_isAuthenticated != value) {
      _isAuthenticated = value;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Central redirect guard function to evaluate route accessibility based on auth state.
String? defaultRedirectGuard({
  required String location,
  required bool isAuthenticated,
}) {
  final isAuthRoute = location == AppRoutePaths.welcome ||
      location == AppRoutePaths.login ||
      location == AppRoutePaths.register ||
      location == AppRoutePaths.forgotPassword;

  final isPublicRoute = isAuthRoute ||
      location == AppRoutePaths.splash ||
      location == AppRoutePaths.onboarding ||
      location == AppRoutePaths.componentsPreview;

  // 1. Unauthenticated user trying to access a protected route
  if (!isAuthenticated && !isPublicRoute) {
    return AppRoutePaths.welcome;
  }

  // 2. Authenticated user trying to access login, register, or welcome
  if (isAuthenticated && isAuthRoute) {
    return AppRoutePaths.dashboard;
  }

  // No redirect necessary
  return null;
}
