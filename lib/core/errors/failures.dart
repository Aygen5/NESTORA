import 'package:flutter/foundation.dart';

/// Base class for all failure representations in the domain and presentation layers.
@immutable
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ (code?.hashCode ?? 0);

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

/// Authentication & authorization failures.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

/// Server, Firebase Firestore or network connection failures.
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// Local storage & SharedPreferences caching failures.
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

/// Input validation or form verification failures.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Virtual smart home device control failures.
class DeviceFailure extends Failure {
  const DeviceFailure(super.message, {super.code});
}
