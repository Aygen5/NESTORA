import '../../../../core/utils/result.dart';
import '../entities/app_notification.dart';

/// Contract for operations on in-app notifications in NESTORA.
abstract class NotificationsRepository {
  /// Real-time stream of all notifications for [userId], ordered newest first.
  Stream<List<AppNotification>> watchNotifications(String userId);

  /// Fetches a list of all notifications for [userId].
  Future<Result<List<AppNotification>>> getNotifications(String userId);

  /// Marks a specific notification as read.
  Future<Result<void>> markAsRead(String userId, String notificationId);

  /// Marks all unread notifications of [userId] as read in a single batch.
  Future<Result<void>> markAllAsRead(String userId);

  /// Deletes a specific notification by [notificationId].
  Future<Result<void>> deleteNotification(String userId, String notificationId);

  /// Creates and stores a new in-app notification.
  Future<Result<void>> createNotification(
    String userId,
    AppNotification notification,
  );
}
