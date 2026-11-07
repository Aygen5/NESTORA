import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import '../../../../core/errors/exceptions.dart';
import '../models/user_profile_model.dart';

/// Contract for Remote Data Source managing User Profile documents in Cloud Firestore.
abstract class ProfileRemoteDataSource {
  /// Real-time stream of the user profile document for [userId].
  Stream<UserProfileModel?> watchProfile(String userId);

  /// One-time fetch of the user profile document.
  Future<UserProfileModel?> getProfile(String userId);

  /// Overwrites/updates the complete profile document in Firestore.
  Future<void> updateProfile(String userId, UserProfileModel profile);

  /// Quick update for home name (e.g. "Aygen'in Evi").
  Future<void> updateHomeName(String userId, String homeName);

  /// Quick update for user display name.
  Future<void> updateDisplayName(String userId, String displayName);

  /// Quick update for user preferences (notifications, eco mode, units).
  Future<void> updatePreferences(
    String userId,
    Map<String, dynamic> preferences,
  );

  /// Updates local photo path reference.
  Future<void> updatePhotoPath(String userId, String? photoPath);
}

/// Firebase implementation of [ProfileRemoteDataSource].
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseFirestore? firestore;

  ProfileRemoteDataSourceImpl({
    this.firestore,
  });

  FirebaseFirestore get _db {
    if (firestore == null) {
      throw const ServerException('Firestore servisi hazır değil.');
    }
    return firestore!;
  }

  DocumentReference<Map<String, dynamic>> _userDocRef(String userId) {
    if (userId.trim().isEmpty) {
      throw const ServerException('Geçersiz kullanıcı kimliği.');
    }
    return _db.collection('users').doc(userId.trim());
  }

  @override
  Stream<UserProfileModel?> watchProfile(String userId) {
    try {
      return _userDocRef(userId).snapshots().map((doc) {
        if (!doc.exists) return null;
        return UserProfileModel.fromFirestore(doc);
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Profil dinlenirken hata oluştu.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Profil dinlenirken beklenmeyen hata oluştu: $e');
    }
  }

  @override
  Future<UserProfileModel?> getProfile(String userId) async {
    try {
      final doc = await _userDocRef(userId).get();
      if (!doc.exists) return null;
      return UserProfileModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Profil bilgisi getirilemedi.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Profil bilgisi alınırken beklenmeyen hata: $e');
    }
  }

  @override
  Future<void> updateProfile(String userId, UserProfileModel profile) async {
    try {
      await _userDocRef(userId).set(
        profile.toFirestore(),
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Profil güncellenirken hata oluştu.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Profil güncellenirken beklenmeyen hata: $e');
    }
  }

  @override
  Future<void> updateHomeName(String userId, String homeName) async {
    try {
      await _userDocRef(userId).update({
        'homeName': homeName.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Ev adı güncellenemedi.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Ev adı güncellenirken beklenmeyen hata: $e');
    }
  }

  @override
  Future<void> updateDisplayName(String userId, String displayName) async {
    try {
      await _userDocRef(userId).update({
        'displayName': displayName.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Kullanıcı adı güncellenemedi.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Kullanıcı adı güncellenirken beklenmeyen hata: $e');
    }
  }

  @override
  Future<void> updatePreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      await _userDocRef(userId).update({
        'preferences': preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Kullanıcı tercihleri kaydedilemedi.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Kullanıcı tercihleri kaydedilirken hata: $e');
    }
  }

  @override
  Future<void> updatePhotoPath(String userId, String? photoPath) async {
    try {
      await _userDocRef(userId).update({
        'photoPath': photoPath,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Profil fotoğrafı yolu kaydedilemedi.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Profil fotoğrafı yolu kaydedilirken hata: $e');
    }
  }
}
