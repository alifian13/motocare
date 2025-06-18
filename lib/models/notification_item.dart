import 'package:flutter/material.dart';
import '../utils/date_formatter.dart';

class NotificationItem {
  final int notificationId;
  final int userId;
  final int? vehicleId;
  final int? scheduleId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt;

  NotificationItem({
    required this.notificationId,
    required this.userId,
    this.vehicleId,
    this.scheduleId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.updatedAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      notificationId: json['notification_id'] as int,
      userId: json['user_id'] as int,
      vehicleId: json['vehicle_id'] as int?,
      scheduleId: json['schedule_id'] as int?,
      title: json['title'] as String? ?? 'Tanpa Judul',
      message: json['message'] as String? ?? 'Tidak ada pesan.',
      type: json['type'] as String? ?? 'INFO',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  String get formattedCreatedAt {
    return DateFormatter.toWibString(createdAt);
  }

  Color getNotificationColor(BuildContext context) {
    if (type.toUpperCase() == 'OVERDUE_ALERT') return Colors.red.shade50;
    if (type.toUpperCase() == 'SERVICE_REMINDER' && !isRead) return Colors.orange.shade50;
    if (isRead) return Colors.grey.shade200;
    return Theme.of(context).cardColor;
  }

  IconData getNotificationIcon() {
    if (type.toUpperCase() == 'OVERDUE_ALERT') return Icons.warning_amber_rounded;
    if (type.toUpperCase() == 'SERVICE_REMINDER') return Icons.notifications_active_outlined;
    return Icons.info_outline_rounded;
  }
}