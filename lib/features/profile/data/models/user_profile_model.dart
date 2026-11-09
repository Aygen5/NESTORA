import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import '../../../../core/utils/firestore_helpers.dart';
import '../../domain/entities/user_profile.dart';

// Firestore serileştirme ve veri dönüşümlerini yöneten Kullanıcı Profili Veri Modeli (DTO).
class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.uid,
    required super.email,
    required super.displayName,
    required super.homeName,
    super.roleTitle = 'Ev Sahibi',
    super.photoPath,
    super.preferences = const UserPreferences(),
    super.createdAt,
    super.updatedAt,
  });

  // Ham Firestore Map verisinden ve doküman ID'sinden (uid) UserProfileModel üretir.
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

    final role = FirestoreHelpers.parseString(
      map['roleTitle'] ?? map['role'],
      'Ev Sahibi',
    );

    return UserProfileModel(
      uid: uid,
      email: FirestoreHelpers.parseString(map['email'], ''),
      displayName: name,
      homeName: home,
      roleTitle: role,
      photoPath: map['photoPath'] as String?,
      preferences: prefs,
      createdAt: FirestoreHelpers.parseDateTime(map['createdAt']),
      updatedAt: FirestoreHelpers.parseDateTime(map['updatedAt']),
    );
  }

  // Firestore DocumentSnapshot nesnesinden UserProfileModel üretir.
  factory UserProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return UserProfileModel.fromMap(
      snapshot.data() ?? {},
      uid: snapshot.id,
    );
  }

  // Saf domain UserProfile entity nesnesinden UserProfileModel üretir.
  factory UserProfileModel.fromEntity(UserProfile profile) {
    return UserProfileModel(
      uid: profile.uid,
      email: profile.email,
      displayName: profile.displayName,
      homeName: profile.homeName,
      roleTitle: profile.roleTitle,
      photoPath: profile.photoPath,
      preferences: profile.preferences,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  // Modeli sunucu zaman damgasıyla Firestore yazma formatına dönüştürür.
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'homeName': homeName,
      'email': email,
      'roleTitle': roleTitle,
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

  // Modeli yerel önbellek ve testler için standart Map formatına dönüştürür.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'homeName': homeName,
      'roleTitle': roleTitle,
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

  // Modeli saf domain entity nesnesine dönüştürür.
  UserProfile toEntity() => UserProfile(
        uid: uid,
        email: email,
        displayName: displayName,
        homeName: homeName,
        roleTitle: roleTitle,
        photoPath: photoPath,
        preferences: preferences,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
