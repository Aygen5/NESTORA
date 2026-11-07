import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String description;
  final String timeAgo;
  bool isUnread;
  final IconData icon;
  final Color? iconBg;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timeAgo,
    this.isUnread = true,
    required this.icon,
    this.iconBg,
  });
}

