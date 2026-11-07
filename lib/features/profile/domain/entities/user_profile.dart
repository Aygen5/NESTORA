/// User preference settings within the Nestora smart home profile.
class UserPreferences {
  final bool notificationsEnabled;
  final bool ecoModeEnabled;
  final String temperatureUnit;

  const UserPreferences({
    this.notificationsEnabled = true,
    this.ecoModeEnabled = true,
    this.temperatureUnit = 'C',
  });

  UserPreferences copyWith({
    bool? notificationsEnabled,
    bool? ecoModeEnabled,
    String? temperatureUnit,
  }) {
    return UserPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      ecoModeEnabled: ecoModeEnabled ?? this.ecoModeEnabled,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferences &&
          runtimeType == other.runtimeType &&
          notificationsEnabled == other.notificationsEnabled &&
          ecoModeEnabled == other.ecoModeEnabled &&
          temperatureUnit == other.temperatureUnit;

  @override
  int get hashCode =>
      notificationsEnabled.hashCode ^
      ecoModeEnabled.hashCode ^
      temperatureUnit.hashCode;

  @override
  String toString() =>
      'UserPreferences(notifications: $notificationsEnabled, ecoMode: $ecoModeEnabled, unit: °$temperatureUnit)';
}

/// Pure domain entity representing a user's smart home profile in Nestora.
/// Completely decoupled from Firebase SDK types and network layers.
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String homeName;
  final String? photoPath;
  final UserPreferences preferences;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.homeName,
    this.photoPath,
    this.preferences = const UserPreferences(),
    this.createdAt,
    this.updatedAt,
  });

  /// Extracts two uppercase initials from the display name or email for avatar badges.
  String get initials {
    if (displayName.trim().isNotEmpty) {
      final parts = displayName.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    if (email.trim().isNotEmpty) {
      return email.trim()[0].toUpperCase();
    }
    return 'N';
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? homeName,
    String? photoPath,
    UserPreferences? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      homeName: homeName ?? this.homeName,
      photoPath: photoPath ?? this.photoPath,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          displayName == other.displayName &&
          homeName == other.homeName &&
          photoPath == other.photoPath &&
          preferences == other.preferences &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      uid.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      homeName.hashCode ^
      photoPath.hashCode ^
      preferences.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() =>
      'UserProfile(uid: $uid, email: $email, name: $displayName, home: $homeName)';
}
