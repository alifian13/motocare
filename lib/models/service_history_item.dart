// lib/models/service_history_item.dart
import 'package:intl/intl.dart';
// import 'package:flutter/material.dart'; // Hanya jika Anda menggunakan IconData di sini

class ServiceHistoryItem {
  final int historyId;
  final int vehicleId;
  final DateTime serviceDate;
  final int odometerAtService;
  final String serviceType;
  final String? description;
  final String? workshopName;
  final double? cost;
  final DateTime? createdAt; // Tambahkan jika dikirim API
  // final IconData icon; // Logika icon lebih baik di UI berdasarkan serviceType

  ServiceHistoryItem({
    required this.historyId,
    required this.vehicleId,
    required this.serviceDate,
    required this.odometerAtService,
    required this.serviceType,
    this.description,
    this.workshopName,
    this.cost,
    this.createdAt,
  });

  factory ServiceHistoryItem.fromJson(Map<String, dynamic> json) {
    return ServiceHistoryItem(
      historyId: json['history_id'] as int,
      vehicleId: json['vehicle_id'] as int,
      serviceDate: DateTime.parse(json['service_date'] as String), // API mengirim DATEONLY
      odometerAtService: json['odometer_at_service'] as int,
      serviceType: json['service_type'] as String? ?? 'Servis Umum',
      description: json['description'] as String?,
      workshopName: json['workshop_name'] as String?,
      cost: json['cost'] != null ? double.tryParse(json['cost'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : (json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null), // Handle createdAt dari Sequelize
    );
  }

  String get formattedServiceDate {
    return DateFormat('dd MMM yyyy').format(serviceDate); // Format sedikit berbeda untuk contoh
  }
}