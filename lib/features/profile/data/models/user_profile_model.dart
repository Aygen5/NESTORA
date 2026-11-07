import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import '../../../../core/utils/firestore_helpers.dart';
import '../../domain/entities/user_profile.dart';

/// Data Transfer Object (DTO) for [UserProfile] handling Cloud Firestore serialization.
class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.uid,
    required super.email,
    required super.displayName,
    required super.homeName,
    super.photoPath,
    super.preferences = const UserPreferences(),
    super.createdAt,
    super.updatedAt,
  });

  /// Factory creating a [UserProfileModel] from a raw Firestore Map and document [uid].
  factory UserProfileModel.fromMap(
    Map<String, dynamic> map, {
    required String uid,
  }) {
    UserPreferences prefs = const UserPreferences();
    if (map['preferences'] is Map<String, dynamic>) {
      final p = map['preferences'] as Map<String, dynamic>;
      prefs = UserPreferences(
        notificationsEnabled:
            FirestoreHelpers.parseBool(p['notificationsEnabled'], true),
        ecoModeEnabled: FirestoreHelpers.parseBool(p['ecoModeEnabled'], true),
        temperatureUnit:
            FirestoreHelpers.parseString(p['temperatureUnit'], 'C'),
      );
    }

    final name = FirestoreHelpers.parseString(
      map['displayName'] ?? map['name'],
      'Nestora Kullanıcısı',
    );

    final home = FirestoreHelpers.parseString(
      map['homeName'],
      name.isNotEmpty ? "$name'in Evi" : "Nestora Evi",
    );

    return UserProfileModel(
      uid: uid,
      email: FirestoreHelpers.parseString(map['email'], ''),
      displayName: name,
      homeName: home,
      photoPath: map['photoPath'] as String?,
      preferences: prefs,
      createdAt: FirestoreHelpers.parseDateTime(map['createdAt']),
      updatedAt: FirestoreHelpers.parseDateTime(map['updatedAt']),
    );
  }

  /// Factory creating a [UserProfileModel] from a Firestore [DocumentSnapshot].
  factory UserProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return UserProfileModel.fromMap(
      snapshot.data() ?? {},
      uid: snapshot.id,
    );
  }

  /// Factory creating a [UserProfileModel] from a pure domain [UserProfile] entity.
  factory UserProfileModel.fromEntity(UserProfile profile) {
    return UserProfileModel(
      uid: profile.uid,
      email: profile.email,
      displayName: profile.displayName,
      homeName: profile.homeName,
      photoPath: profile.photoPath,
      preferences: profile.preferences,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  /// Converts this model into a Firestore write payload with [FieldValue.serverTimestamp].
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'homeName': homeName,
      'email': email,
      if (photoPath != null) 'photoPath': photoPath,
      'preferences': {
        'notificationsEnabled': preferences.notificationsEnabled,
        'ecoModeEnabled': preferences.ecoModeEnabled,
        'temperatureUnit': preferences.temperatureUnit,
      },
      'createdAt': FirestoreHelpers.dateTimeToTimestamp(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Converts this model into a serializable standard Dart Map.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'homeName': homeName,
      if (photoPath != null) 'photoPath': photoPath,
      'preferences': {
        'notificationsEnabled': preferences.notificationsEnabled,
        'ecoModeEnabled': preferences.ecoModeEnabled,
        'temperatureUnit': preferences.temperatureUnit,
      },
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Pure domain conversion.
  UserProfile toEntity() => UserProfile(
        uid: uid,
        email: email,
        displayName: displayName,
        homeName: homeName,
        photoPath: photoPath,
        preferences: preferences,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
