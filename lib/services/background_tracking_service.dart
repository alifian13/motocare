import 'dart:async';
import 'package:flutter/foundation.dart'; // Untuk anotasi @visibleForTesting
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';

import 'package:motocare/services/api_service.dart'; // Pastikan path ini benar

/// Enum untuk merepresentasikan state dari perjalanan pengguna.
/// Dengan Activity Recognition API, kita cukup state IDLE dan RIDING.
enum RideState {
  IDLE,   // Tidak sedang berkendara
  RIDING, // Aktif berkendara
}

/// Service cerdas yang berjalan di background untuk melacak perjalanan motor.
/// MENGGUNAKAN ACTIVITY RECOGNITION API untuk deteksi akurat dan hemat baterai.
class BackgroundTrackingService {
  // Singleton Pattern
  BackgroundTrackingService._privateConstructor();
  static final BackgroundTrackingService instance = BackgroundTrackingService._privateConstructor();

  // Servis dan Stream dari package
  final Location _location = Location();
  final ApiService _apiService = ApiService();
  StreamSubscription<LocationData>? _locationSubscription;
  StreamSubscription<ActivityEvent>? _activitySubscription; // BARU: Untuk Activity Recognition

  /// Memeriksa apakah servis sedang berjalan.
  bool isTracking() {
    return _locationSubscription != null && !_locationSubscription!.isPaused;
  }

  /// Memulai servis pelacakan di latar belakang.
  Future<void> startService(int vehicleId) async {
    if (isTracking()) return;

    // 1. Mengaktifkan mode background & foreground service
    try {
      await _location.enableBackgroundMode(enable: true);
    } catch (e) {
      print("Error saat mengaktifkan background mode: $e");
      return;
    }
    
    // 2. Mengatur akurasi & interval pelacakan lokasi
    await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 15000, // 15 detik, bisa diperbesar karena deteksi utama dari activity
      distanceFilter: 15, // 15 meter
    );

    // 3. Menyiapkan state awal di SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTrackingActive', true);
    await prefs.setInt('trackingVehicleId', vehicleId);
    await prefs.setInt('rideState', RideState.IDLE.index);

    // 4. Mulai mendengarkan DUA stream: Aktivitas dan Lokasi
    _locationSubscription = _location.onLocationChanged.listen(_onLocationUpdate);
    _activitySubscription = ActivityRecognition().activityStream().listen(_onActivityUpdate);

    print("[Intelligent Tracking Service] Service dimulai untuk Vehicle ID: $vehicleId");
  }

  /// Menghentikan servis pelacakan.
  Future<void> stopService() async {
    await _locationSubscription?.cancel();
    await _activitySubscription?.cancel(); // Hentikan juga stream aktivitas
    _locationSubscription = null;
    _activitySubscription = null;
    
    await _location.enableBackgroundMode(enable: false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTrackingActive', false);
    await prefs.remove('trackingVehicleId');
    print("[Intelligent Tracking Service] Service dihentikan.");
  }

  // --- LOGIKA BARU BERBASIS ACTIVITY RECOGNITION ---

  /// Callback setiap kali ada update aktivitas dari OS (Android/iOS).
  /// Tugasnya hanya mengubah state RIDING/IDLE.
  Future<void> _onActivityUpdate(ActivityEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    var currentState = RideState.values[prefs.getInt('rideState') ?? RideState.IDLE.index];

    print("AKTIVITAS TERDETEKSI: ${event.type} (${event.confidence}%)");

    RideState newState = currentState;

    // Jika OS mendeteksi kita di dalam kendaraan dengan konfidensi > 70%
    if (event.type == ActivityType.IN_VEHICLE && event.confidence > 70) {
      newState = RideState.RIDING;
    } 
    // Jika OS mendeteksi kita diam, jalan, atau lari
    else if (event.type == ActivityType.STILL || event.type == ActivityType.WALKING || event.type == ActivityType.RUNNING) {
      newState = RideState.IDLE;
    }

    // Hanya update jika ada perubahan state
    if (newState != currentState) {
      print("==> Perubahan State: Dari $currentState menjadi $newState");
      await prefs.setInt('rideState', newState.index);

      // Jika kita BARU SAJA berhenti berkendara, hapus titik lokasi terakhir
      // agar perjalanan berikutnya dimulai dari titik yang baru.
      if (newState == RideState.IDLE && currentState == RideState.RIDING) {
        print("==> Perjalanan Selesai. Menghapus titik lokasi terakhir.");
        await prefs.remove('lastLat');
        await prefs.remove('lastLon');
        // Di sini bisa ditambahkan notifikasi "Perjalanan Anda telah direkam"
      }
    }
  }

  /// Callback setiap kali ada update lokasi.
  /// Tugasnya hanya merekam jika state sedang RIDING.
  Future<void> _onLocationUpdate(LocationData currentLocation) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('isTrackingActive') ?? false)) return;

    var state = RideState.values[prefs.getInt('rideState') ?? RideState.IDLE.index];

    // HANYA REKAM LOKASI JIKA STATE-NYA RIDING
    if (state == RideState.RIDING) {
      final vehicleId = prefs.getInt('trackingVehicleId');
      if (vehicleId != null) {
        print("...Merekam lokasi karena State adalah RIDING...");
        await _recordTripLeg(prefs, vehicleId, currentLocation);
      }
    }
  }

  // Helper untuk merekam segmen perjalanan (tidak perlu diubah)
  Future<void> _recordTripLeg(SharedPreferences prefs, int vehicleId, LocationData currentLocation) async {
    final lastLat = prefs.getDouble('lastLat');
    final lastLon = prefs.getDouble('lastLon');
    final currentLat = currentLocation.latitude;
    final currentLon = currentLocation.longitude;

    // Jika titik awal belum ada, simpan dulu
    if (lastLat == null || lastLon == null) {
      await _saveLastPoint(prefs, currentLocation);
      return;
    }

    if (currentLat == null || currentLon == null) return;

    final distanceMeters = geolocator.Geolocator.distanceBetween(lastLat, lastLon, currentLat, currentLon);

    if (distanceMeters > 15) {
      try {
        await _apiService.recordTrip(
          vehicleId: vehicleId,
          distanceKm: distanceMeters / 1000.0,
          startLatitude: lastLat,
          startLongitude: lastLon,
          endLatitude: currentLat,
          endLongitude: currentLon,
        );
        await _saveLastPoint(prefs, currentLocation);
        print("Sukses rekam segmen: ${distanceMeters.toStringAsFixed(1)} meter");
      } catch (e) {
        print("Gagal rekam segmen: $e");
      }
    }
  }
  
  // Helper untuk menyimpan titik lokasi terakhir (tidak perlu diubah)
  Future<void> _saveLastPoint(SharedPreferences prefs, LocationData location) async {
    if (location.latitude != null && location.longitude != null) {
      await prefs.setDouble('lastLat', location.latitude!);
      await prefs.setDouble('lastLon', location.longitude!);
    }
  }
}