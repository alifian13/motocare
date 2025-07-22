class Vehicle {
  final int vehicleId;
  final int userId;
  final String plateNumber;
  final String brand;
  final String model;
  int currentOdometer;
  final DateTime? lastOdometerUpdate;
  final String? lastServiceDate;
  final String? photoUrl;
  final String? logoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? year;
  final String? vehicleCode;

  Vehicle({
    required this.vehicleId,
    required this.userId,
    required this.plateNumber,
    required this.brand,
    required this.model,
    required this.currentOdometer,
    this.lastOdometerUpdate,
    this.lastServiceDate,
    this.photoUrl,
    this.logoUrl,
    this.createdAt,
    this.updatedAt,
    this.year,
    this.vehicleCode,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleId: json['vehicle_id'] as int,
      userId: json['user_id'] as int,
      plateNumber: json['plate_number'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      currentOdometer: (json['current_odometer'] != null)
          ? (json['current_odometer'] is String
              ? (int.tryParse(json['current_odometer']) ?? 0)
              : (json['current_odometer'] as num).toInt())
          : 0,
      lastOdometerUpdate: json['last_odometer_update'] != null
          ? DateTime.tryParse(json['last_odometer_update'] as String)
          : null,
      lastServiceDate: json['last_service_date'] as String?,
      photoUrl: json['photo_url'] as String?,
      logoUrl: json['logo_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      year: json['year'],
      vehicleCode: json['vehicle_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'user_id': userId,
      'plate_number': plateNumber,
      'brand': brand,
      'model': model,
      'current_odometer': currentOdometer,
      'last_odometer_update': lastOdometerUpdate?.toIso8601String(),
      'last_service_date': lastServiceDate,
      'photo_url': photoUrl,
      'logo_url': logoUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
