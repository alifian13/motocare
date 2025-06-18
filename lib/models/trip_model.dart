class Trip {
  final int tripId;
  final int vehicleId;
  final double distanceKm;
  final DateTime? startTime;
  final DateTime? endTime;
  final double? startLatitude;
  final double? startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final String? startAddress;
  final String? endAddress; 
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Trip({
    required this.tripId,
    required this.vehicleId,
    required this.distanceKm,
    this.startTime,
    this.endTime,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.startAddress, 
    this.endAddress, 
    this.createdAt,
    this.updatedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      tripId: json['trip_id'] as int,
      vehicleId: json['vehicle_id'] as int,
      distanceKm: (json['distance_km'] != null)
          ? (json['distance_km'] is String
              ? (double.tryParse(json['distance_km']) ?? 0.0)
              : (json['distance_km'] as num).toDouble())
          : 0.0,
      startTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? DateTime.tryParse(json['end_time'] as String)
          : null,
      startLatitude: (json['start_latitude'] != null)
          ? (json['start_latitude'] is String
              ? (double.tryParse(json['start_latitude']))
              : (json['start_latitude'] as num?)?.toDouble())
          : null,
      startLongitude: (json['start_longitude'] != null)
          ? (json['start_longitude'] is String
              ? (double.tryParse(json['start_longitude']))
              : (json['start_longitude'] as num?)?.toDouble())
          : null,
      endLatitude: (json['end_latitude'] != null)
          ? (json['end_latitude'] is String
              ? (double.tryParse(json['end_latitude']))
              : (json['end_latitude'] as num?)?.toDouble())
          : null,
      endLongitude: (json['end_longitude'] != null)
          ? (json['end_longitude'] is String
              ? (double.tryParse(json['end_longitude']))
              : (json['end_longitude'] as num?)?.toDouble())
          : null,
      startAddress: json['start_address'] as String?,
      endAddress: json['end_address'] as String?, 
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'vehicle_id': vehicleId,
      'distance_km': distanceKm,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'start_latitude': startLatitude,
      'start_longitude': startLongitude,
      'end_latitude': endLatitude,
      'end_longitude': endLongitude,
      'start_address': startAddress,
      'end_address': endAddress, 
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
