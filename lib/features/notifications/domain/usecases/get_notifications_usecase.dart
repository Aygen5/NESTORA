import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/app_notification.dart';
import '../repositories/notifications_repository.dart';

class GetNotificationsUseCase implements UseCase<List<AppNotification>, String> {
  final NotificationsRepository repository;

  const GetNotificationsUseCase(this.repository);

  @override
  Future<Result<List<AppNotification>>> call(String userId) {
    return repository.getNotifications(userId);
  }
}
