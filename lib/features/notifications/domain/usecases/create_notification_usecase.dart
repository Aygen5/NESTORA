import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/app_notification.dart';
import '../repositories/notifications_repository.dart';

class CreateNotificationParams {
  final String userId;
  final AppNotification notification;

  const CreateNotificationParams({
    required this.userId,
    required this.notification,
  });
}

class CreateNotificationUseCase implements UseCase<void, CreateNotificationParams> {
  final NotificationsRepository repository;

  const CreateNotificationUseCase(this.repository);

  @override
  Future<Result<void>> call(CreateNotificationParams params) {
    return repository.createNotification(params.userId, params.notification);
  }
}
