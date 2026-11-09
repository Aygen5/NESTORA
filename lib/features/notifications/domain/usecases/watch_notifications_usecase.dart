import '../../../../core/usecases/usecase.dart';
import '../entities/app_notification.dart';
import '../repositories/notifications_repository.dart';

class WatchNotificationsUseCase implements StreamUseCase<List<AppNotification>, String> {
  final NotificationsRepository repository;

  const WatchNotificationsUseCase(this.repository);

  @override
  Stream<List<AppNotification>> call(String userId) {
    return repository.watchNotifications(userId);
  }
}
