// lib/models/notification_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationItem {
  final int notificationId;
  final int userId;
  final int? vehicleId;
  final int? scheduleId;
  final String title;
  final String message;
  final String type; // SERVICE_REMINDER, OVERDUE_ALERT, PROMOTION, INFO
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt; // Dari API (camelCase 'updatedAt')

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
      title: json['title'] as String? ?? 'Notifikasi',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'INFO',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String), // API mengirim 'createdAt'
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null, // API mengirim 'updatedAt'
    );
  }

  String get formattedCreatedAt {
    return DateFormat('dd MMM yyyy, HH:mm').format(createdAt);
  }

  Color getNotificationColor(BuildContext context) {
    String typeUpper = type.toUpperCase();
    if (typeUpper == 'OVERDUE_ALERT' && !isRead) return Colors.red.shade100;
    if (typeUpper == 'OVERDUE_ALERT' && isRead) return Colors.red.shade50;
    if (typeUpper == 'SERVICE_REMINDER' && !isRead) return Colors.orange.shade100;
    if (typeUpper == 'SERVICE_REMINDER' && isRead) return Colors.orange.shade50;
    if (isRead) return Colors.grey.shade200;
    return Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5);
  }

  IconData getNotificationIcon() {
    String typeUpper = type.toUpperCase();
    if (typeUpper == 'OVERDUE_ALERT') return Icons.warning_amber_rounded;
    if (typeUpper == 'SERVICE_REMINDER') return Icons.notifications_active_outlined;
    if (typeUpper == 'PROMOTION') return Icons.campaign_outlined;
    return Icons.info_outline_rounded;
  }
}