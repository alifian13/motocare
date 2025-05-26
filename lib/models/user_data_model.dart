// lib/models/user_data_model.dart
import 'package:intl/intl.dart';
import 'vehicle_model.dart'; // <-- IMPOR Vehicle DARI SINI

class UserData {
  final String? name;
  final String? email;
  final String? address; // Tambahkan jika ada di profil
  final String? userPhotoUrl; // Foto pengguna dari User model
  final Vehicle? vehicle; // <-- GUNAKAN Vehicle YANG SUDAH DIIMPOR

  // Informasi spesifik kendaraan yang mungkin ingin ditampilkan bersamaan
  final String? plateNumber;
  final String? brand;
  final String? vehicleModel; // Menggunakan vehicleModel agar tidak bentrok dengan model class
  final int? currentOdometer;
  final String? lastServiceDate; // String YYYY-MM-DD
  final String? vehiclePhotoUrl; // Foto kendaraan dari Vehicle model
  final String? vehicleLogoUrl; // Logo kendaraan

  UserData({
    this.name,
    this.email,
    this.address,
    this.userPhotoUrl,
    this.vehicle,
    this.plateNumber,
    this.brand,
    this.vehicleModel,
    this.currentOdometer,
    this.lastServiceDate,
    this.vehiclePhotoUrl,
    this.vehicleLogoUrl,
  });

  // Helper untuk memformat tanggal
  String? get formattedLastServiceDate {
    if (lastServiceDate == null || lastServiceDate!.isEmpty) return "N/A";
    try {
      final date = DateFormat("yyyy-MM-dd").parse(lastServiceDate!);
      return DateFormat("dd MMMM yyyy", "id_ID").format(date); // Format Indonesia
    } catch (e) {
      return lastServiceDate; // Kembalikan tanggal asli jika parsing gagal
    }
  }

  // Factory constructor untuk membuat UserData dari JSON (misalnya dari endpoint /profile)
  factory UserData.fromJson(Map<String, dynamic> json) {
    // Jika endpoint /profile juga mengembalikan detail kendaraan utama,
    // Anda bisa mem-parse-nya di sini juga.
    // Untuk contoh ini, kita fokus pada data User.
    // Asumsi Vehicle dipisah dan akan di-combine.
    return UserData(
      name: json['name'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      userPhotoUrl: json['photo_url'] as String?, // Sesuaikan dengan field di backend
      // Vehicle akan di-combine
    );
  }

  // Metode untuk menggabungkan data User dan Vehicle (jika primary vehicle diketahui)
  // Metode ini dari file Anda, sudah baik.
  static UserData combine(Map<String, dynamic>? userDataJson, Vehicle? primaryVehicle) {
    return UserData(
      name: userDataJson?['name'] as String?,
      email: userDataJson?['email'] as String?,
      userPhotoUrl: userDataJson?['userPhotoUrl'] as String?, // Dari SharedPreferences atau state
      address: userDataJson?['address'] as String?, // Jika ada
      vehicle: primaryVehicle, // Objek Vehicle lengkap
      plateNumber: primaryVehicle?.plateNumber,
      brand: primaryVehicle?.brand,
      vehicleModel: primaryVehicle?.model,
      currentOdometer: primaryVehicle?.currentOdometer,
      lastServiceDate: primaryVehicle?.lastServiceDate,
      vehiclePhotoUrl: primaryVehicle?.photoUrl,
      vehicleLogoUrl: primaryVehicle?.logoUrl,
    );
  }
}

// HAPUS DEFINISI KELAS Vehicle DARI FILE INI JIKA ADA SEBELUMNYA
// class Vehicle {
//   final int vehicleId;
//   final String plateNumber;
//   final String brand;
//   final String model;
//   final int currentOdometer; // dibuat final
//   final String? lastServiceDate;
//   final String? photoUrl;
//   final String? logoUrl;

//   Vehicle({
//     required this.vehicleId,
//     required this.plateNumber,
//     required this.brand,
//     required this.model,
//     required this.currentOdometer,
//     this.lastServiceDate,
//     this.photoUrl,
//     this.logoUrl,
//   });

//   factory Vehicle.fromJson(Map<String, dynamic> json) {
//     return Vehicle(
//       vehicleId: json['vehicle_id'] as int,
//       plateNumber: json['plate_number'] as String,
//       brand: json['brand'] as String,
//       model: json['model'] as String,
//       currentOdometer: (json['current_odometer'] as num?)?.toInt() ?? 0,
//       lastServiceDate: json['last_service_date'] as String?,
//       photoUrl: json['photo_url'] as String?,
//       logoUrl: json['logo_url'] as String?,
//     );
//   }
// }
