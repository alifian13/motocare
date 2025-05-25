// lib/models/user_data_model.dart
import 'package:intl/intl.dart';

class UserData {
  final String name;
  final String email; // Mungkin tidak ditampilkan langsung di dashboard utama, tapi bisa di drawer
  // final String address; // Opsional untuk ditampilkan
  final String vehicleModel;
  final String plateNumber;
  final DateTime? lastServiceDate;
  final String brand;
  final int currentOdometer;
  final String? vehicleLogoUrl;
  final String? userPhotoUrl;

  UserData({
    required this.name,
    required this.email,
    // required this.address,
    required this.vehicleModel,
    required this.plateNumber,
    this.lastServiceDate,
    required this.brand,
    required this.currentOdometer,
    this.vehicleLogoUrl,
    this.userPhotoUrl
  });

  // Jika Anda ingin membuat UserData dari data SharedPreferences dan data kendaraan terpisah
  factory UserData.combine(Map<String, dynamic> userDataFromPrefs, Vehicle? vehicleData) {
    return UserData(
      name: userDataFromPrefs['name'] ?? "Pengguna",
      email: userDataFromPrefs['email'] ?? "",
      userPhotoUrl: userDataFromPrefs['userPhotoUrl'], // Ambil dari SharedPreferences atau data user login
      vehicleModel: vehicleData?.model ?? "N/A",
      vehicleLogoUrl: vehicleData?.logoUrl,
      plateNumber: vehicleData?.plateNumber ?? "N/A",
      lastServiceDate: vehicleData?.lastServiceDate,
      brand: vehicleData?.brand ?? "N/A",
      currentOdometer: vehicleData?.currentOdometer ?? 0,
    );
  }

  String get formattedLastServiceDate {
    if (lastServiceDate == null) return "Belum ada data";
    try {
      return DateFormat('dd/MM/yyyy').format(lastServiceDate!);
    } catch (e) {
      return "Format tanggal salah";
    }
  }
}

// Model sederhana untuk Kendaraan
class Vehicle {
  final int vehicleId;
  final int userId;
  final String plateNumber;
  final String brand;
  final String model;
  final int currentOdometer;
  final DateTime? lastServiceDate;
  final String? photoUrl;
  final String? logoUrl;
  // Tambahkan field lain jika ada dari API (created_at, updated_at)

  Vehicle({
    required this.vehicleId,
    required this.userId,
    required this.plateNumber,
    required this.brand,
    required this.model,
    required this.currentOdometer,
    this.lastServiceDate,
    this.photoUrl,
    this.logoUrl,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleId: json['vehicle_id'] as int,
      userId: json['user_id'] as int,
      plateNumber: json['plate_number'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      currentOdometer: json['current_odometer'] as int? ?? 0,
      lastServiceDate: json['last_service_date'] != null
          ? DateTime.tryParse(json['last_service_date'])
          : null,
      photoUrl: json['photo_url'] as String?,
      logoUrl: json['logo_url'] as String?,
    );
  }
}