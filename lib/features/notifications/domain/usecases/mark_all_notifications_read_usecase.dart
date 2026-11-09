import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/notifications_repository.dart';

class MarkAllNotificationsReadUseCase implements UseCase<void, String> {
  final NotificationsRepository repository;

  const MarkAllNotificationsReadUseCase(this.repository);

  @override
  Future<Result<void>> call(String userId) {
    return repository.markAllAsRead(userId);
  }
}

