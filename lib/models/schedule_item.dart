// lib/models/schedule_item.dart
import 'package:flutter/material.dart'; // Untuk Color dan IconData
import 'package:intl/intl.dart';

class ScheduleItem {
  final int scheduleId;
  final int vehicleId;
  final String itemName;
  final String? description;
  final int? recommendedIntervalKm;
  final int? recommendedIntervalMonths; // Tambahkan jika ada dari API
  final DateTime? lastPerformedDate;   // Tambahkan jika ada dari API
  final int? lastPerformedOdometer; // Tambahkan jika ada dari API
  final DateTime? nextDueDate;
  final int? nextDueOdometer;
  final String status; // PENDING, UPCOMING, OVERDUE, COMPLETED, SKIPPED
  final String? notes; // Tambahkan jika ada dari API
  final DateTime? createdAt;

  ScheduleItem({
    required this.scheduleId,
    required this.vehicleId,
    required this.itemName,
    this.description,
    this.recommendedIntervalKm,
    this.recommendedIntervalMonths,
    this.lastPerformedDate,
    this.lastPerformedOdometer,
    this.nextDueDate,
    this.nextDueOdometer,
    required this.status,
    this.notes,
    this.createdAt,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      scheduleId: json['schedule_id'] as int,
      vehicleId: json['vehicle_id'] as int,
      itemName: json['item_name'] as String? ?? 'Item Jadwal',
      description: json['description'] as String?,
      recommendedIntervalKm: json['recommended_interval_km'] as int?,
      recommendedIntervalMonths: json['recommended_interval_months'] as int?,
      lastPerformedDate: json['last_performed_date'] != null
          ? DateTime.tryParse(json['last_performed_date'])
          : null,
      lastPerformedOdometer: json['last_performed_odometer'] as int?,
      nextDueDate: json['next_due_date'] != null
          ? DateTime.tryParse(json['next_due_date'])
          : null,
      nextDueOdometer: json['next_due_odometer'] as int?,
      status: json['status'] as String? ?? 'PENDING',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : (json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null),
    );
  }

  String get displayDueDate {
    if (nextDueDate != null) return DateFormat('dd MMM yyyy').format(nextDueDate!);
    if (nextDueOdometer != null) return "Pada $nextDueOdometer km";
    return "Belum terjadwal";
  }

  Color getStatusColor() {
    switch (status.toUpperCase()) {
      case 'OVERDUE': return Colors.red.shade50;
      case 'UPCOMING': return Colors.orange.shade50;
      case 'PENDING': return Colors.blue.shade50;
      case 'COMPLETED': return Colors.green.shade50;
      default: return Colors.grey.shade200;
    }
  }

  IconData getStatusIcon() {
     switch (status.toUpperCase()) {
      case 'OVERDUE': return Icons.warning_amber_rounded;
      case 'UPCOMING': return Icons.notifications_active_outlined;
      case 'PENDING': return Icons.pending_actions_outlined;
      case 'COMPLETED': return Icons.check_circle_outline_rounded;
      default: return Icons.event_outlined;
    }
  }
}