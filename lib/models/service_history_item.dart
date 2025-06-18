import '../utils/date_formatter.dart';

class ServiceHistoryItem {
  final int historyId;
  final int vehicleId;
  final DateTime serviceDate;
  final int odometerAtService;
  final String serviceType;
  final String? description;
  final String? workshopName;
  final double? cost;

  ServiceHistoryItem({
    required this.historyId,
    required this.vehicleId,
    required this.serviceDate,
    required this.odometerAtService,
    required this.serviceType,
    this.description,
    this.workshopName,
    this.cost,
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
    );
  }

  String get formattedServiceDate {
    return DateFormatter.toWibString(serviceDate, format: 'dd MMM yyyy');
  }
}