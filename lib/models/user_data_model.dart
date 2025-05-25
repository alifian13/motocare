// lib/models/user_data_model.dart
import 'package:intl/intl.dart';

// Model untuk Pengguna (dari API /api/users/profile atau respons login)
class UserModel {
  final int userId;
  final String name;
  final String email;
  final String? address;
  final String? photoUrl; // URL lengkap atau path relatif dari server
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    this.address,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as int,
      name: json['name'] as String? ?? 'Nama Pengguna',
      email: json['email'] as String? ?? '',
      address: json['address'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  // Fungsi untuk mengkonversi ke Map, berguna jika ingin menyimpan ke SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'address': address,
      'photo_url': photoUrl,
      // Anda mungkin tidak perlu menyimpan tanggal ke SharedPreferences
    };
  }
}

// Model untuk Kendaraan (dari API /api/vehicles/my-vehicles)
class Vehicle {
  final int vehicleId;
  final int userId;
  final String plateNumber;
  final String brand;
  final String model;
  final int currentOdometer;
  final DateTime? lastOdometerUpdate;
  final DateTime? lastServiceDate; // Tanggal servis umum terakhir
  final String? photoUrl; // Foto kendaraan (jika ada)
  final String? logoUrl;  // URL logo brand/model dari server
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleId: json['vehicle_id'] as int,
      userId: json['user_id'] as int,
      plateNumber: json['plate_number'] as String? ?? 'N/A',
      brand: json['brand'] as String? ?? 'N/A',
      model: json['model'] as String? ?? 'N/A',
      currentOdometer: json['current_odometer'] as int? ?? 0,
      lastOdometerUpdate: json['last_odometer_update'] != null
          ? DateTime.tryParse(json['last_odometer_update'])
          : null,
      lastServiceDate: json['last_service_date'] != null
          ? DateTime.tryParse(json['last_service_date'])
          : null,
      photoUrl: json['photo_url'] as String?,
      logoUrl: json['logo_url'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
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

// UserData bisa menjadi kelas helper untuk menggabungkan data tampilan di HomeScreen
// jika Anda masih ingin pendekatan itu, atau Anda bisa langsung menggunakan UserModel dan Vehicle.
// Untuk saat ini, kita akan fokus menggunakan UserModel dan Vehicle secara terpisah.
// Jika Anda ingin UserData.combine, pastikan ia menerima UserModel dan Vehicle.
class UserDataForDisplay {
  final String name;
  final String email;
  final String? userPhotoUrl;
  final String vehicleModel;
  final String plateNumber;
  final DateTime? vehicleLastServiceDate;
  final String vehicleBrand;
  final int vehicleCurrentOdometer;
  final String? vehicleLogoUrl;

  UserDataForDisplay({
    required this.name,
    required this.email,
    this.userPhotoUrl,
    required this.vehicleModel,
    required this.plateNumber,
    this.vehicleLastServiceDate,
    required this.vehicleBrand,
    required this.vehicleCurrentOdometer,
    this.vehicleLogoUrl,
  });

  factory UserDataForDisplay.fromModels(UserModel? user, Vehicle? vehicle) {
    return UserDataForDisplay(
      name: user?.name ?? "Pengguna",
      email: user?.email ?? "",
      userPhotoUrl: user?.photoUrl,
      vehicleModel: vehicle?.model ?? "N/A",
      plateNumber: vehicle?.plateNumber ?? "N/A",
      vehicleLastServiceDate: vehicle?.lastServiceDate,
      vehicleBrand: vehicle?.brand ?? "N/A",
      vehicleCurrentOdometer: vehicle?.currentOdometer ?? 0,
      vehicleLogoUrl: vehicle?.logoUrl,
    );
  }

   String get formattedVehicleLastServiceDate {
    if (vehicleLastServiceDate == null) return "Belum ada data";
    try {
      return DateFormat('dd/MM/yyyy').format(vehicleLastServiceDate!);
    } catch (e) {
      return "Format tanggal salah";
    }
  }
}