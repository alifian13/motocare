import 'package:intl/intl.dart'; // Tambahkan intl ke pubspec.yaml: `flutter pub add intl`

class UserData {
  final String name;
  final String email;
  final String address;
  final String vehicleModel; // Sebelumnya 'motor' atau 'motor_model'
  final String plateNumber;
  final DateTime? lastServiceDate;
  final String brand;
  final int currentOdometer;
  // final String password; // Mungkin tidak perlu ditampilkan di UI

  UserData({
    required this.name,
    required this.email,
    required this.address,
    required this.vehicleModel,
    required this.plateNumber,
    this.lastServiceDate,
    required this.brand,
    required this.currentOdometer,
    // required this.password,
  });

  factory UserData.fromMap(Map<String, dynamic> map) {
    DateTime? parsedDate;
    if (map['last_service_date'] != null) {
      try {
        parsedDate = DateTime.tryParse(map['last_service_date']);
      } catch (e) {
        print("Error parsing date from SharedPreferences: ${map['last_service_date']}");
        parsedDate = null;
      }
    }

    return UserData(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      vehicleModel: map['motor_model'] ?? '', // Sesuaikan dengan key di SharedPreferences
      plateNumber: map['plate_number'] ?? 'N/A',
      lastServiceDate: parsedDate,
      brand: map['brand'] ?? 'N/A',
      currentOdometer: map['odometer'] ?? 0,
      // password: map['password'] ?? '',
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