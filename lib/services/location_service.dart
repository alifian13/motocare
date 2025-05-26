import 'dart:async';
import 'package:flutter/material.dart'; // Untuk BuildContext di callback
import 'package:location/location.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:shared_preferences/shared_preferences.dart';
import 'vehicle_service.dart'; // Pastikan path ini benar untuk VehicleService

// Definisikan tipe callback untuk trip yang terdeteksi
// Parameter: BuildContext, jarak (km), vehicleId
typedef TripDetectedCallback = Future<void> Function(BuildContext, double, String);

class LocationService {
  Location location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  LocationData? _previousLocationData;

  bool _isTripStarted = false;
  DateTime? _tripStartTime;
  double _accumulatedDistanceKm = 0.0;
  List<LocationData> _tripPoints = [];

  // --- Konstanta untuk Deteksi Perjalanan (bisa disesuaikan) ---
  static const double _minSpeedKmhToStartTrip = 10.0; // Kecepatan minimum (km/jam) untuk memulai trip
  static const double _minSpeedKmhToMaintainTrip = 5.0; // Kecepatan minimum (km/jam) untuk dianggap masih dalam trip
  static const int _minConsecutivePointsAboveMinSpeed = 3; // Jumlah titik berurutan di atas kecepatan minimum untuk memulai trip
  static const int _minConsecutivePointsBelowMinSpeedToEnd = 5; // Jumlah titik berurutan di bawah kecepatan untuk mengakhiri trip
  static const double _minTripDistanceKm = 0.1; // Jarak minimum perjalanan agar dicatat (100 meter)
  static const int _locationIntervalMilliseconds = 5000; // Interval update lokasi (5 detik)
  static const double _distanceFilterMeters = 10.0; // Jarak minimum antar update lokasi agar diproses

  int _consecutiveHighSpeedPoints = 0;
  int _consecutiveLowSpeedPoints = 0;

  // final VehicleService _vehicleService = VehicleService(); // Untuk memanggil addTrip

  bool isTrackingActive() {
    return _locationSubscription != null && !_locationSubscription!.isPaused;
  }

  Future<bool> _checkAndRequestPermissions() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        print("Layanan lokasi tidak aktif.");
        return false;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        print("Izin lokasi ditolak.");
        return false;
      }
    }
    return true;
  }

  Future<void> startTracking(BuildContext context, TripDetectedCallback onTripDetectedCallback) async {
    if (_locationSubscription != null) {
      print("Pelacakan sudah berjalan.");
      return;
    }

    final hasPermission = await _checkAndRequestPermissions();
    if (!hasPermission) {
      print("Tidak ada izin atau layanan lokasi tidak aktif. Pelacakan tidak dimulai.");
      return;
    }

    // Mengatur interval dan jarak filter untuk update lokasi
    await location.changeSettings(
      accuracy: LocationAccuracy.high, // Atau .balanced
      interval: _locationIntervalMilliseconds,
      distanceFilter: _distanceFilterMeters, // Hanya update jika bergerak minimal sekian meter
    );

    _locationSubscription = location.onLocationChanged.listen((LocationData currentLocationData) {
      // print("Lokasi baru: ${currentLocationData.latitude}, ${currentLocationData.longitude}, Speed: ${currentLocationData.speed} m/s");

      if (_previousLocationData != null && currentLocationData.speed != null) {
        final latlong.Distance distanceCalculator = latlong.Distance();
        double distanceMovedMeters = distanceCalculator(
          latlong.LatLng(_previousLocationData!.latitude!, _previousLocationData!.longitude!),
          latlong.LatLng(currentLocationData.latitude!, currentLocationData.longitude!),
        );

        double speedKmh = (currentLocationData.speed ?? 0) * 3.6; // Konversi m/s ke km/jam

        if (!_isTripStarted) {
          if (speedKmh >= _minSpeedKmhToStartTrip) {
            _consecutiveHighSpeedPoints++;
            _consecutiveLowSpeedPoints = 0; // Reset low speed counter
            if (_consecutiveHighSpeedPoints >= _minConsecutivePointsAboveMinSpeed) {
              // Mulai perjalanan
              _isTripStarted = true;
              _tripStartTime = DateTime.now();
              _accumulatedDistanceKm = 0.0;
              _tripPoints = [currentLocationData];
              _consecutiveHighSpeedPoints = 0; // Reset counter setelah trip dimulai
              print("------- PERJALANAN DIMULAI ------- Speed: $speedKmh km/h");
            }
          } else {
            _consecutiveHighSpeedPoints = 0; // Reset jika kecepatan turun sebelum trip dimulai
          }
        } else { // Jika perjalanan sudah dimulai
          if (speedKmh >= _minSpeedKmhToMaintainTrip) {
            _accumulatedDistanceKm += (distanceMovedMeters / 1000.0); // Tambah jarak dalam km
            _tripPoints.add(currentLocationData);
            _consecutiveLowSpeedPoints = 0; // Reset low speed counter
            // print("Trip berjalan. Jarak: ${_accumulatedDistanceKm.toStringAsFixed(2)} km, Speed: ${speedKmh.toStringAsFixed(1)} km/h");
          } else {
            _consecutiveLowSpeedPoints++;
            if (_consecutiveLowSpeedPoints >= _minConsecutivePointsBelowMinSpeedToEnd) {
              // Akhiri perjalanan
              print("------- PERJALANAN BERAKHIR (Kecepatan rendah) ------- Speed: $speedKmh km/h");
              _finalizeAndProcessTrip(context, onTripDetectedCallback);
            }
          }
        }
      }
      _previousLocationData = currentLocationData;
    });
    print("Pelacakan lokasi dimulai.");
  }

  void stopTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _previousLocationData = null;
    if (_isTripStarted) {
      // Jika tracking dihentikan saat trip masih berjalan, anggap trip selesai
      // Namun, ini mungkin tidak ideal. Pertimbangkan bagaimana menangani kasus ini.
      // Untuk sekarang, kita tidak memprosesnya agar tidak ada trip yang "menggantung".
      print("Pelacakan dihentikan saat perjalanan sedang berlangsung. Trip tidak diproses.");
      _resetTripState();
    } else {
       print("Pelacakan lokasi dihentikan.");
    }
  }

  void _resetTripState() {
    _isTripStarted = false;
    _tripStartTime = null;
    _accumulatedDistanceKm = 0.0;
    _tripPoints = [];
    _consecutiveHighSpeedPoints = 0;
    _consecutiveLowSpeedPoints = 0;
  }

  Future<void> _finalizeAndProcessTrip(BuildContext context, TripDetectedCallback onTripDetectedCallback) async {
    if (!_isTripStarted) return;

    // Simpan data trip sebelum direset
    double finalDistanceKm = _accumulatedDistanceKm;
    DateTime tripStartTime = _tripStartTime ?? DateTime.now();
    DateTime tripEndTime = DateTime.now();
    LocationData? startPoint = _tripPoints.isNotEmpty ? _tripPoints.first : null;
    LocationData? endPoint = _tripPoints.isNotEmpty ? _tripPoints.last : null;

    _resetTripState(); // Reset state untuk perjalanan berikutnya

    if (finalDistanceKm >= _minTripDistanceKm) {
      print("Memproses perjalanan: Jarak ${finalDistanceKm.toStringAsFixed(2)} km");
      final prefs = await SharedPreferences.getInstance();
      // Anda perlu mekanisme untuk menyimpan/mengambil ID kendaraan yang aktif
      // Misalnya, saat pengguna memilih kendaraan di UI, simpan ID-nya di SharedPreferences
      String? currentVehicleId = prefs.getString('current_vehicle_id');

      if (currentVehicleId != null) {
        // Panggil callback yang akan menampilkan dialog dan mengirim ke backend
        await onTripDetectedCallback(context, finalDistanceKm, currentVehicleId);

        // Data tambahan yang bisa dikirim ke backend jika diperlukan:
        final tripDataForBackend = {
          'distance_km': finalDistanceKm,
          'start_time': tripStartTime.toIso8601String(),
          'end_time': tripEndTime.toIso8601String(),
          if (startPoint?.latitude != null) 'start_latitude': startPoint!.latitude,
          if (startPoint?.longitude != null) 'start_longitude': startPoint!.longitude,
          if (endPoint?.latitude != null) 'end_latitude': endPoint!.latitude,
          if (endPoint?.longitude != null) 'end_longitude': endPoint!.longitude,
        };
        print("Data trip untuk backend: $tripDataForBackend");

      } else {
        print("Tidak ada ID kendaraan aktif yang tersimpan. Perjalanan tidak dikirim ke backend.");
      }
    } else {
      print("Perjalanan terlalu pendek (${finalDistanceKm.toStringAsFixed(2)} km), tidak dicatat.");
    }
  }

  // Fungsi ini akan dipanggil dari UI (misalnya HomeScreen)
  // dan akan menangani dialog konfirmasi serta pemanggilan ke backend
  // Ini adalah implementasi dari `onTripDetected` yang kita diskusikan sebelumnya,
  // namun sekarang menjadi bagian dari UI yang memanggil LocationService.
  // Saya akan memindahkannya ke contoh penggunaan di bawah.
}