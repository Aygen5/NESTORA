import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import '../../../../core/errors/exceptions.dart';
import '../models/notification_model.dart';

/// Contract for Remote Data Source managing in-app notifications in Cloud Firestore.
abstract class NotificationsRemoteDataSource {
  /// Real-time stream of all notifications belonging to [userId], ordered newest first.
  Stream<List<NotificationModel>> watchNotifications(String userId);

  /// One-time fetch of all notifications belonging to [userId].
  Future<List<NotificationModel>> getNotifications(String userId);

  /// Marks a specific notification as read.
  Future<void> markAsRead(String userId, String notificationId);

  /// Marks all unread notifications of [userId] as read in a single atomic batch.
  Future<void> markAllAsRead(String userId);

  /// Deletes a specific notification by [notificationId].
  Future<void> deleteNotification(String userId, String notificationId);

  /// Creates and stores a new in-app notification.
  Future<void> createNotification(
    String userId,
    NotificationModel notification,
  );
}

/// Firebase implementation of [NotificationsRemoteDataSource].
class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  final FirebaseFirestore? firestore;

  NotificationsRemoteDataSourceImpl({
    this.firestore,
  });

  FirebaseFirestore get _db {
    if (firestore == null) {
      throw const ServerException('Firestore servisi hazır değil.');
    }
    return firestore!;
  }

  CollectionReference<Map<String, dynamic>> _notifsRef(String userId) {
    if (userId.trim().isEmpty) {
      throw const ServerException('Geçersiz kullanıcı kimliği.');
    }
    return _db
        .collection('users')
        .doc(userId.trim())
        .collection('notifications');
  }

  @override
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    try {
      return _notifsRef(userId)
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs
                .map((doc) => NotificationModel.fromFirestore(doc))
                .toList();
            // Client-side sort by createdAt descending to avoid composite index requirements
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
          });
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Bildirimler dinlenirken hata oluştu.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Bildirimler dinlenirken beklenmeyen hata: $e');
    }
  }

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final snapshot = await _notifsRef(userId).get();
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Bildirimler getirilemedi.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Bildirimler getirilirken beklenmeyen hata: $e');
    }
  }

  @override
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _notifsRef(userId).doc(notificationId.trim()).update({
        'isRead': true,
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Bildirim okundu olarak işaretlenemedi.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Bildirim güncellenirken beklenmeyen hata: $e');
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _notifsRef(userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Tüm bildirimler okundu olarak işaretlenemedi.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Bildirimler güncellenirken beklenmeyen hata: $e');
    }
  }

  @override
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _notifsRef(userId).doc(notificationId.trim()).delete();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Bildirim silinirken hata oluştu.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Bildirim silinirken beklenmeyen hata: $e');
    }
  }

  @override
  Future<void> createNotification(
    String userId,
    NotificationModel notification,
  ) async {
    try {
      final docRef = notification.id.trim().isNotEmpty
          ? _notifsRef(userId).doc(notification.id.trim())
          : _notifsRef(userId).doc();
      await docRef.set(notification.toFirestore(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Bildirim oluşturulurken hata oluştu.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException('Bildirim oluşturulurken beklenmeyen hata: $e');
    }
  }
}
