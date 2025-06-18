import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleItem {
  final int scheduleId;
  final String itemName;
  final String? description;
  final DateTime? nextDueDate;
  final int? nextDueOdometer;
  final String status;

  ScheduleItem({
    required this.scheduleId,
    required this.itemName,
    this.description,
    this.nextDueDate,
    this.nextDueOdometer,
    required this.status,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      scheduleId: json['schedule_id'] as int,
      itemName: json['item_name'] as String,
      description: json['description'] as String?,
      nextDueDate: json['next_due_date'] != null ? DateTime.tryParse(json['next_due_date']) : null,
      nextDueOdometer: json['next_due_odometer'] as int?,
      status: json['status'] as String,
    );
  }

  String get displayDueDate {
    if (nextDueDate != null) return DateFormat('dd MMM yyyy').format(nextDueDate!);
    if (nextDueOdometer != null) return "pada $nextDueOdometer km";
    return "Belum terjadwal";
  }

  Color getStatusColor() {
    switch (status.toUpperCase()) {
      case 'OVERDUE': return Colors.red.shade100;
      case 'UPCOMING': return Colors.orange.shade100;
      default: return Colors.green.shade100;
    }
  }
  IconData getStatusIcon() {
     switch (status.toUpperCase()) {
      case 'OVERDUE': return Icons.warning_amber_rounded;
      case 'UPCOMING': return Icons.notifications_active_outlined;
      default: return Icons.event_available_outlined;
    }
  }
}