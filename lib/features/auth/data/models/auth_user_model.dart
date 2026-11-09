import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/auth_user.dart';

/// Data Transfer Object (DTO) for [AuthUser] handling Firebase User mapping and serialization.
class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.photoUrl,
    super.isAnonymous = false,
  });

  /// Factory creating an [AuthUserModel] from a Firebase [User].
  factory AuthUserModel.fromFirebaseUser(User user) {
    return AuthUserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isAnonymous: user.isAnonymous,
    );
  }

  /// Factory creating an [AuthUserModel] from a Map (e.g. for tests, cache, or Firestore).
  factory AuthUserModel.fromMap(Map<String, dynamic> map, {required String id}) {
    return AuthUserModel(
      id: id,
      email: (map['email'] as String?) ?? '',
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      isAnonymous: (map['isAnonymous'] as bool?) ?? false,
    );
  }

  /// Serializes the model into a standard JSON/Firestore Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isAnonymous': isAnonymous,
    };
  }
}

