import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import '../../../../core/errors/exceptions.dart';
import '../models/room_model.dart';

/// Contract for Remote Data Source managing Room documents in Cloud Firestore.
abstract class RoomsRemoteDataSource {
  /// Real-time stream of all rooms belonging to [userId].
  Stream<List<RoomModel>> watchRooms(String userId);

  /// One-time fetch of all rooms belonging to [userId].
  Future<List<RoomModel>> getRooms(String userId);

  /// Fetches a specific room document by [roomId].
  Future<RoomModel> getRoomById(String userId, String roomId);

  /// Creates a new room document in Firestore.
  Future<void> createRoom(String userId, RoomModel room);

  /// Updates an existing room document in Firestore.
  Future<void> updateRoom(String userId, RoomModel room);

  /// Deletes a room document by [roomId].
  Future<void> deleteRoom(String userId, String roomId);
}

/// Firebase implementation of [RoomsRemoteDataSource].
class RoomsRemoteDataSourceImpl implements RoomsRemoteDataSource {
  final FirebaseFirestore? firestore;

  RoomsRemoteDataSourceImpl({
    this.firestore,
  });

  FirebaseFirestore get _db {
    if (firestore == null) {
      throw const ServerException('Firestore servisi hazır değil.');
    }
    return firestore!;
  }

  CollectionReference<Map<String, dynamic>> _roomsRef(String userId) {
    if (userId.trim().isEmpty) {
      throw const ServerException('Geçersiz kullanıcı kimliği.');
    }
    return _db.collection('users').doc(userId.trim()).collection('rooms');
  }

  @override
  Stream<List<RoomModel>> watchRooms(String userId) {
    try {
      return _roomsRef(userId)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => RoomModel.fromFirestore(doc))
              .toList());
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Odalar dinlenirken hata oluştu.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Odalar dinlenirken beklenmeyen hata oluştu: $e');
    }
  }

  @override
  Future<List<RoomModel>> getRooms(String userId) async {
    try {
      final snapshot = await _roomsRef(userId).get();
      return snapshot.docs
          .map((doc) => RoomModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Odalar getirilemedi.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Odalar getirilirken beklenmeyen hata oluştu: $e');
    }
  }

  @override
  Future<RoomModel> getRoomById(String userId, String roomId) async {
    try {
      final doc = await _roomsRef(userId).doc(roomId).get();
      if (!doc.exists) {
        throw const ServerException('Oda bulunamadı.', code: 'not-found');
      }
      return RoomModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Oda bilgisi alınamadı.',
        code: e.code,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Oda bilgisi alınırken beklenmeyen hata oluştu: $e');
    }
  }

  @override
  Future<void> createRoom(String userId, RoomModel room) async {
    try {
      final docRef = room.id.trim().isNotEmpty
          ? _roomsRef(userId).doc(room.id.trim())
          : _roomsRef(userId).doc();
      await docRef.set(room.toFirestore(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Oda eklenirken hata oluştu.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Oda eklenirken beklenmeyen hata oluştu: $e');
    }
  }

  @override
  Future<void> updateRoom(String userId, RoomModel room) async {
    try {
      await _roomsRef(userId)
          .doc(room.id.trim())
          .set(room.toFirestore(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Oda güncellenirken hata oluştu.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Oda güncellenirken beklenmeyen hata oluştu: $e');
    }
  }

  @override
  Future<void> deleteRoom(String userId, String roomId) async {
    try {
      await _roomsRef(userId).doc(roomId.trim()).delete();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Oda silinirken hata oluştu.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Oda silinirken beklenmeyen hata oluştu: $e');
    }
  }
}
