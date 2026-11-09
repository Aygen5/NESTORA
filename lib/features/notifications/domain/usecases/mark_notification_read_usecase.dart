import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/notifications_repository.dart';

class MarkNotificationReadParams {
  final String userId;
  final String notificationId;

  const MarkNotificationReadParams({
    required this.userId,
    required this.notificationId,
  });
}

class MarkNotificationReadUseCase implements UseCase<void, MarkNotificationReadParams> {
  final NotificationsRepository repository;

  const MarkNotificationReadUseCase(this.repository);

  @override
  Future<Result<void>> call(MarkNotificationReadParams params) {
    return repository.markAsRead(params.userId, params.notificationId);
  }
}

