// lib/models/service_history_item.dart
// Untuk IconData jika masih mau digunakan di UI
import 'package:intl/intl.dart';

class ServiceHistoryItem {
  final int historyId;
  final int vehicleId;
  final DateTime serviceDate;
  final int odometerAtService;
  final String serviceType;
  final String? description;
  final String? workshopName;
  final double? cost;
  // final IconData icon; // Anda bisa tentukan icon di UI berdasarkan serviceType

  ServiceHistoryItem({
    required this.historyId,
    required this.vehicleId,
    required this.serviceDate,
    required this.odometerAtService,
    required this.serviceType,
    this.description,
    this.workshopName,
    this.cost,
    // required this.icon,
  });

  factory ServiceHistoryItem.fromJson(Map<String, dynamic> json) {
    return ServiceHistoryItem(
      historyId: json['history_id'] as int,
      vehicleId: json['vehicle_id'] as int,
      serviceDate: DateTime.parse(json['service_date'] as String),
      odometerAtService: json['odometer_at_service'] as int,
      serviceType: json['service_type'] as String,
      description: json['description'] as String?,
      workshopName: json['workshop_name'] as String?,
      cost: json['cost'] != null ? double.tryParse(json['cost'].toString()) : null,
      // icon: _getIconForServiceType(json['service_type'] as String), // Logika icon di UI
    );
  }

  String get formattedServiceDate {
    return DateFormat('dd MMM yyyy').format(serviceDate);
  }
}

// Contoh helper untuk menentukan icon berdasarkan tipe servis (opsional, bisa di UI langsung)
// IconData _getIconForServiceType(String serviceType) {
//   if (serviceType.toLowerCase().contains('oli')) {
//     return Icons.opacity_outlined;
//   } else if (serviceType.toLowerCase().contains('cvt')) {
//     return Icons.settings_applications_outlined;
//   }
//   return Icons.build_outlined; // Default icon
// }