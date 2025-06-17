// lib/models/notification_item.dart
import 'package:flutter/material.dart';
import '../utils/date_formatter.dart';

class NotificationItem {
  final int notificationId;
  final int userId;         // Tambahkan jika ada dan perlu
  final int? vehicleId;    // Jadikan nullable jika bisa null dari API
  final int? scheduleId;   // Jadikan nullable jika bisa null dari API
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt; // Tambahkan jika ada dan jadikan nullable

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
    // Tambahkan print di sini untuk melihat JSON yang masuk jika masih error
    // print("Parsing NotificationItem from JSON: $json");
    return NotificationItem(
      notificationId: json['notification_id'] as int,
      userId: json['user_id'] as int, // Pastikan ini ada di JSON Anda
      vehicleId: json['vehicle_id'] as int?, // Tangani jika bisa null
      scheduleId: json['schedule_id'] as int?, // Tangani jika bisa null
      title: json['title'] as String? ?? 'Tanpa Judul', // Beri nilai default jika null
      message: json['message'] as String? ?? 'Tidak ada pesan.', // Beri nilai default jika null
      type: json['type'] as String? ?? 'INFO', // Beri nilai default jika null
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String), // Sesuaikan dengan field 'createdAt' dari JSON
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null, // Sesuaikan dengan field 'updatedAt'
    );
  }

  String get formattedCreatedAt {
    return DateFormatter.toWibString(createdAt);
  }

  Color getNotificationColor(BuildContext context) {
    // ... (logika warna Anda)
    if (type.toUpperCase() == 'OVERDUE_ALERT') return Colors.red.shade50;
    if (type.toUpperCase() == 'SERVICE_REMINDER' && !isRead) return Colors.orange.shade50;
    if (isRead) return Colors.grey.shade200;
    return Theme.of(context).cardColor;
  }

  IconData getNotificationIcon() {
    // ... (logika ikon Anda)
    if (type.toUpperCase() == 'OVERDUE_ALERT') return Icons.warning_amber_rounded;
    if (type.toUpperCase() == 'SERVICE_REMINDER') return Icons.notifications_active_outlined;
    return Icons.info_outline_rounded;
  }
}