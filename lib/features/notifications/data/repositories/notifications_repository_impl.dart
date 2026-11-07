import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';
import '../models/notification_model.dart';

/// Implementation of [NotificationsRepository] coordinating between Firestore and domain layer.
class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource remoteDataSource;

  NotificationsRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return remoteDataSource
        .watchNotifications(userId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Result<List<AppNotification>>> getNotifications(String userId) async {
    try {
      final models = await remoteDataSource.getNotifications(userId);
      return Result.success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure('Bildirimler alınırken beklenmeyen bir hata oluştu: $e'),
      );
    }
  }

  @override
  Future<Result<void>> markAsRead(String userId, String notificationId) async {
    try {
      await remoteDataSource.markAsRead(userId, notificationId);
      return Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure(
          'Bildirim okundu olarak işaretlenirken hata oluştu: $e',
        ),
      );
    }
  }

  @override
  Future<Result<void>> markAllAsRead(String userId) async {
    try {
      await remoteDataSource.markAllAsRead(userId);
      return Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure(
          'Tüm bildirimler okunurken beklenmeyen bir hata oluştu: $e',
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteNotification(
    String userId,
    String notificationId,
  ) async {
    try {
      await remoteDataSource.deleteNotification(userId, notificationId);
      return Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure('Bildirim silinirken beklenmeyen bir hata oluştu: $e'),
      );
    }
  }

  @override
  Future<Result<void>> createNotification(
    String userId,
    AppNotification notification,
  ) async {
    try {
      await remoteDataSource.createNotification(
        userId,
        NotificationModel.fromEntity(notification),
      );
      return Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(
        ServerFailure(
          'Bildirim oluşturulurken beklenmeyen bir hata oluştu: $e',
        ),
      );
    }
  }
}
