import 'package:shared_preferences/shared_preferences.dart';
// import 'package:location/location.dart'; // Jika masih menggunakan LocationData dari package location
// import 'package:latlong2/latlong.dart'; // Jika menggunakan LatLng dari latlong2

class UserService {
  // Fungsi untuk mendaftar pengguna - PERLU PENYESUAIAN BESAR
  Future<void> registerUser(
    String name,
    String email,
    String address,
    String motorModel, // Ini adalah model motor, bukan LatLng
    // LatLng location, // Ubah tipe data jika perlu
    { // Tambahkan parameter opsional bernama untuk field baru
      String? plateNumber,
      DateTime? lastServiceDate,
      String? brand,
      int? currentOdometer,
      String? password,
    }
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
    await prefs.setString('email', email);
    await prefs.setString('address', address);
    await prefs.setString('motor_model', motorModel); // Ganti 'motor' menjadi 'motor_model'
    // await prefs.setDouble('latitude', location.latitude);
    // await prefs.setDouble('longitude', location.longitude);

    if (plateNumber != null) await prefs.setString('plate_number', plateNumber);
    if (lastServiceDate != null) await prefs.setString('last_service_date', lastServiceDate.toIso8601String());
    if (brand != null) await prefs.setString('brand', brand);
    if (currentOdometer != null) await prefs.setInt('odometer', currentOdometer); else await prefs.setInt('odometer', 0);
    if (password != null) await prefs.setString('password', password); // Simpan password (pertimbangkan keamanan)

    // Kilometer motor mulai dari 0 atau dari input pengguna
    // prefs.setInt('kilometer', currentOdometer ?? 0); // Sudah dihandle oleh 'odometer'
  }

  // Fungsi untuk mengambil data pengguna
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('name') ?? '',
      'email': prefs.getString('email') ?? '',
      'address': prefs.getString('address') ?? '',
      'motor_model': prefs.getString('motor_model') ?? '', // Ganti 'motor'
      'plate_number': prefs.getString('plate_number') ?? '',
      'last_service_date': prefs.getString('last_service_date'), // Ini string ISO, perlu parse ke DateTime
      'brand': prefs.getString('brand') ?? '',
      'odometer': prefs.getInt('odometer') ?? 0,
      'password': prefs.getString('password') ?? '', // Ambil password
      // 'latitude': prefs.getDouble('latitude') ?? 0.0,
      // 'longitude': prefs.getDouble('longitude') ?? 0.0,
      // 'kilometer': prefs.getInt('kilometer') ?? 0, // Sudah dihandle 'odometer'
    };
  }

  // Fungsi untuk menghapus data pengguna (logout)
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    // Hapus semua kunci yang relevan atau gunakan prefs.clear() jika ingin menghapus semua
    await prefs.remove('name');
    await prefs.remove('email');
    await prefs.remove('address');
    await prefs.remove('motor_model');
    await prefs.remove('plate_number');
    await prefs.remove('last_service_date');
    await prefs.remove('brand');
    await prefs.remove('odometer');
    await prefs.remove('password');
    // await prefs.remove('latitude');
    // await prefs.remove('longitude');
  }
}