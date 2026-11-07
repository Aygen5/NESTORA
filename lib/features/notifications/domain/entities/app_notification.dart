/// Types of in-app notifications in Nestora.
enum NotificationType {
  device,
  security,
  eco,
  system;

  String toShortString() => name;

  static NotificationType fromString(String? value) {
    if (value == null) return NotificationType.device;
    final normalized = value.trim().toLowerCase();
    return NotificationType.values.firstWhere(
      (e) => e.name == normalized,
      orElse: () => NotificationType.device,
    );
  }
}

/// Pure domain entity representing an in-app notification in Nestora.
class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final String? relatedRoomId;
  final String? relatedDeviceId;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    this.type = NotificationType.device,
    this.isRead = false,
    this.relatedRoomId,
    this.relatedDeviceId,
    required this.createdAt,
  });

  /// User-friendly relative time string in Turkish.
  String get timeAgoFormatted {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${createdAt.day.toString().padLeft(2, '0')}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}';
    }
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    String? relatedRoomId,
    String? relatedDeviceId,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      relatedRoomId: relatedRoomId ?? this.relatedRoomId,
      relatedDeviceId: relatedDeviceId ?? this.relatedDeviceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          id == other.id &&
          title == other.title &&
          message == other.message &&
          type == other.type &&
          isRead == other.isRead &&
          relatedRoomId == other.relatedRoomId &&
          relatedDeviceId == other.relatedDeviceId &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      message.hashCode ^
      type.hashCode ^
      isRead.hashCode ^
      relatedRoomId.hashCode ^
      relatedDeviceId.hashCode ^
      createdAt.hashCode;

  @override
  String toString() =>
      'AppNotification(id: $id, title: $title, isRead: $isRead, type: $type, time: $timeAgoFormatted)';
}

