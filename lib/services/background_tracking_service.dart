import 'dart:async';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:motocare/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Service ini dibuat khusus untuk berjalan di background
// dan logikanya lebih sederhana: lacak dan kirim.
class BackgroundTrackingService {
  // Singleton Pattern
  BackgroundTrackingService._privateConstructor();
  static final BackgroundTrackingService instance = BackgroundTrackingService._privateConstructor();

  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  final ApiService _apiService = ApiService();

  bool isTracking() {
    return _locationSubscription != null && !_locationSubscription!.isPaused;
  }

  Future<void> startService(int vehicleId) async {
    if (isTracking()) return;

    // KUNCI UTAMA: Mengaktifkan Foreground Service
    try {
      await _location.enableBackgroundMode(enable: true);
    } catch (e) {
      print("Error saat mengaktifkan background mode: $e");
      // Mungkin perlu menampilkan notifikasi ke pengguna bahwa background mode gagal
    }
    
    await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 15000, // 15 detik
      distanceFilter: 15, // 15 meter
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBackgroundTrackingActive', true);
    await prefs.setInt('background_vehicle_id', vehicleId);
    await prefs.remove('background_last_lat');
    await prefs.remove('background_last_lon');
    print("[BackgroundService] Dimulai untuk Vehicle ID: $vehicleId");

    _locationSubscription = _location.onLocationChanged.listen((LocationData loc) {
      _onLocationUpdate(loc);
    });
  }

  Future<void> _onLocationUpdate(LocationData currentLocation) async {
    final prefs = await SharedPreferences.getInstance();
    // Jika service dimatikan dari luar, hentikan proses
    if (!(prefs.getBool('isBackgroundTrackingActive') ?? false)) {
      stopService();
      return;
    }

    final vehicleId = prefs.getInt('background_vehicle_id');
    if (vehicleId == null) return;

    final lastLat = prefs.getDouble('background_last_lat');
    final lastLon = prefs.getDouble('background_last_lon');

    final currentLat = currentLocation.latitude;
    final currentLon = currentLocation.longitude;

    if (currentLat == null || currentLon == null) return;
        
    if (lastLat != null && lastLon != null) {
      final distanceInMeters = geolocator.Geolocator.distanceBetween(lastLat, lastLon, currentLat, currentLon);

      if (distanceInMeters > 15) {
        try {
          await _apiService.recordTrip(
            vehicleId: vehicleId,
            distanceKm: distanceInMeters / 1000.0,
            startLatitude: lastLat,
            startLongitude: lastLon,
            endLatitude: currentLat,
            endLongitude: currentLon,
          );
          await prefs.setDouble('background_last_lat', currentLat);
          await prefs.setDouble('background_last_lon', currentLon);
        } catch (e) {
          print('[BackgroundService] Gagal mengirim trip: $e');
        }
      }
    } else {
      await prefs.setDouble('background_last_lat', currentLat);
      await prefs.setDouble('background_last_lon', currentLon);
    }
  }

  Future<void> stopService() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    await _location.enableBackgroundMode(enable: false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBackgroundTrackingActive', false);
    await prefs.remove('background_vehicle_id');
    print("[BackgroundService] Dihentikan.");
  }
}