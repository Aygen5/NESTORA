import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import '../../../../core/utils/firestore_helpers.dart';
import '../../domain/entities/app_notification.dart';

/// Data Transfer Object (DTO) for [AppNotification] handling Cloud Firestore serialization.
class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.message,
    super.type = NotificationType.device,
    super.isRead = false,
    super.relatedRoomId,
    super.relatedDeviceId,
    required super.createdAt,
  });

  /// Factory creating a [NotificationModel] from a raw Firestore Map and document [id].
  factory NotificationModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    // Handle both `isRead` and legacy `isUnread` fields safely
    bool readState = false;
    if (map.containsKey('isRead')) {
      readState = FirestoreHelpers.parseBool(map['isRead'], false);
    } else if (map.containsKey('isUnread')) {
      readState = !FirestoreHelpers.parseBool(map['isUnread'], true);
    }

    return NotificationModel(
      id: id,
      title: FirestoreHelpers.parseString(map['title'], 'Bildirim'),
      message: FirestoreHelpers.parseString(
        map['message'] ?? map['description'],
        '',
      ),
      type: NotificationType.fromString(map['type'] as String?),
      isRead: readState,
      relatedRoomId: map['relatedRoomId'] as String?,
      relatedDeviceId: map['relatedDeviceId'] as String?,
      createdAt:
          FirestoreHelpers.parseDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  /// Factory creating a [NotificationModel] from a Firestore [DocumentSnapshot].
  factory NotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return NotificationModel.fromMap(
      snapshot.data() ?? {},
      id: snapshot.id,
    );
  }

  /// Factory creating a [NotificationModel] from a pure domain [AppNotification] entity.
  factory NotificationModel.fromEntity(AppNotification notification) {
    return NotificationModel(
      id: notification.id,
      title: notification.title,
      message: notification.message,
      type: notification.type,
      isRead: notification.isRead,
      relatedRoomId: notification.relatedRoomId,
      relatedDeviceId: notification.relatedDeviceId,
      createdAt: notification.createdAt,
    );
  }

  /// Converts this model into a Firestore write payload.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type.toShortString(),
      'isRead': isRead,
      if (relatedRoomId != null) 'relatedRoomId': relatedRoomId,
      if (relatedDeviceId != null) 'relatedDeviceId': relatedDeviceId,
      'createdAt': FirestoreHelpers.dateTimeToTimestamp(createdAt),
    };
  }

  /// Converts this model into a serializable standard Dart Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toShortString(),
      'isRead': isRead,
      if (relatedRoomId != null) 'relatedRoomId': relatedRoomId,
      if (relatedDeviceId != null) 'relatedDeviceId': relatedDeviceId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Pure domain conversion.
  AppNotification toEntity() => AppNotification(
        id: id,
        title: title,
        message: message,
        type: type,
        isRead: isRead,
        relatedRoomId: relatedRoomId,
        relatedDeviceId: relatedDeviceId,
        createdAt: createdAt,
      );
}
