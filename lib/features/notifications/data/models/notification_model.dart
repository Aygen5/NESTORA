import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import '../../../../core/utils/firestore_helpers.dart';
import '../../domain/entities/app_notification.dart';

// Firestore serileştirme ve veri dönüşümlerini yöneten Bildirim Veri Modeli (DTO).
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

  // Ham Firestore Map verisinden ve doküman ID'sinden NotificationModel üretir.
  factory NotificationModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    // Hem `isRead` hem de eski `isUnread` alanlarını güvenle işler.
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

  // Firestore DocumentSnapshot nesnesinden NotificationModel üretir.
  factory NotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return NotificationModel.fromMap(
      snapshot.data() ?? {},
      id: snapshot.id,
    );
  }

  // Saf domain AppNotification entity nesnesinden NotificationModel üretir.
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

  // Modeli Firestore yazma formatına dönüştürür.
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

  // Modeli yerel önbellek ve testler için standart Map formatına dönüştürür.
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

  // Modeli saf domain entity nesnesine dönüştürür.
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
