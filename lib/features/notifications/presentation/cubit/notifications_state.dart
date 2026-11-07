import 'package:flutter/foundation.dart';
import '../../domain/entities/app_notification.dart';

/// Base state for [NotificationsCubit].
@immutable
abstract class NotificationsState {
  const NotificationsState();
}

/// Initial uninitialized state.
class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

/// Notifications are loading from Firestore.
class NotificationsLoading extends NotificationsState {
  final String? message;
  const NotificationsLoading({this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationsLoading &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// Notifications successfully loaded and synchronized in real time.
class NotificationsLoaded extends NotificationsState {
  final List<AppNotification> notifications;
  final bool isProcessing;
  final String? feedbackMessage;
  final String? errorMessage;

  const NotificationsLoaded({
    required this.notifications,
    this.isProcessing = false,
    this.feedbackMessage,
    this.errorMessage,
  });

  /// Total count of unread notifications, powering the red badge on Dashboard bell icon.
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  /// Whether there are any unread notifications.
  bool get hasUnread => unreadCount > 0;

  /// Returns unread notifications only.
  List<AppNotification> get unreadNotifications =>
      notifications.where((n) => !n.isRead).toList();

  /// Group notifications by human-friendly date labels ('Bugün', 'Dün', 'Daha Eski').
  Map<String, List<AppNotification>> get groupedNotifications {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<AppNotification>> groups = {
      'Bugün': [],
      'Dün': [],
      'Daha Eski': [],
    };

    for (final notif in notifications) {
      final notifDate = DateTime(
        notif.createdAt.year,
        notif.createdAt.month,
        notif.createdAt.day,
      );

      if (notifDate.isAtSameMomentAs(today)) {
        groups['Bugün']!.add(notif);
      } else if (notifDate.isAtSameMomentAs(yesterday)) {
        groups['Dün']!.add(notif);
      } else {
        groups['Daha Eski']!.add(notif);
      }
    }

    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  NotificationsLoaded copyWith({
    List<AppNotification>? notifications,
    bool? isProcessing,
    String? feedbackMessage,
    String? errorMessage,
    bool clearFeedback = false,
    bool clearError = false,
  }) {
    return NotificationsLoaded(
      notifications: notifications ?? this.notifications,
      isProcessing: isProcessing ?? this.isProcessing,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationsLoaded &&
          runtimeType == other.runtimeType &&
          listEquals(notifications, other.notifications) &&
          isProcessing == other.isProcessing &&
          feedbackMessage == other.feedbackMessage &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      notifications.hashCode ^
      isProcessing.hashCode ^
      (feedbackMessage?.hashCode ?? 0) ^
      (errorMessage?.hashCode ?? 0);
}

/// Fatal error state when loading notifications fails.
class NotificationsError extends NotificationsState {
  final String message;
  final String? code;

  const NotificationsError(this.message, {this.code});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationsError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ (code?.hashCode ?? 0);
}

