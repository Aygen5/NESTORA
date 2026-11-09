import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/notifications_repository.dart';

class DeleteNotificationParams {
  final String userId;
  final String notificationId;

  const DeleteNotificationParams({
    required this.userId,
    required this.notificationId,
  });
}

class DeleteNotificationUseCase implements UseCase<void, DeleteNotificationParams> {
  final NotificationsRepository repository;

  const DeleteNotificationUseCase(this.repository);

  @override
  Future<Result<void>> call(DeleteNotificationParams params) {
    return repository.deleteNotification(params.userId, params.notificationId);
  }
}

