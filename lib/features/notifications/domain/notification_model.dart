import 'package:flutter/material.dart';
import 'entities/app_notification.dart';

export 'entities/app_notification.dart' show NotificationType;

class NotificationModel {
  final String id;
  final String title;
  final String description;
  final String timeAgo;
  bool isUnread;
  final IconData icon;
  final Color? iconBg;
  final DateTime? createdAt;
  final String? relatedRoomId;
  final String? relatedDeviceId;
  final NotificationType type;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timeAgo,
    this.isUnread = true,
    required this.icon,
    this.iconBg,
    this.createdAt,
    this.relatedRoomId,
    this.relatedDeviceId,
    this.type = NotificationType.device,
  });
}
