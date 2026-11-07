import '../../domain/entities/auth_user.dart';

/// Base class for all Authentication states in Nestora.
abstract class AuthState {
  const AuthState();
}

/// Initial uninitialized state before checking existing session.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// State emitted while performing asynchronous authentication operations.
class AuthLoading extends AuthState {
  final String? message;
  const AuthLoading({this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthLoading &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// State representing an actively authenticated user session.
class Authenticated extends AuthState {
  final AuthUser user;
  const Authenticated(this.user);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Authenticated &&
          runtimeType == other.runtimeType &&
          user == other.user;

  @override
  int get hashCode => user.hashCode;
}

/// State representing an unauthenticated session (logged out or no active user).
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// State emitted when an authentication or validation error occurs.
class AuthError extends AuthState {
  final String message;
  final String? code;

  const AuthError(this.message, {this.code});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ code.hashCode;
}

/// State emitted after successfully requesting a password reset email.
class AuthPasswordResetSent extends AuthState {
  final String email;
  const AuthPasswordResetSent(this.email);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthPasswordResetSent &&
          runtimeType == other.runtimeType &&
          email == other.email;

  @override
  int get hashCode => email.hashCode;
}
