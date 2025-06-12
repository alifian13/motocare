import 'dart:async';
import 'package:flutter/material.dart'; // Hanya untuk BuildContext jika diperlukan
import 'package:location/location.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motocare/services/user_service.dart';

// Data perjalanan tentatif yang akan dikirim saat motor berhenti
class TentativeTripData {
  final double distanceKm;
  final DateTime startTime;
  final LocationData startLocation;
  final DateTime endTime;
  final LocationData endLocation;

  TentativeTripData({
    required this.distanceKm,
    required this.startTime,
    required this.startLocation,
    required this.endTime,
    required this.endLocation,
  });
}

// Callback lama untuk TripDetectedCallback mungkin tidak lagi digunakan
// atau perannya berubah. Untuk saat ini kita fokus pada alur notifikasi berhenti.
// typedef TripDetectedCallback = Future<void> Function(...);

typedef LiveLocationUpdateCallback = void Function(
  LocationData currentLocation,
  double accumulatedSegmentDistanceKm
);

// Callback baru untuk motor berhenti dengan data perjalanan tentatif
typedef MotorStoppedWithDataCallback = void Function(
  TentativeTripData tentativeTripData
);

class LocationService {
  Location location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  LocationData? _previousLocationData;

  bool _isTripStarted = false;
  DateTime? _tripStartTime;
  double _accumulatedDistanceKm = 0.0;
  List<LocationData> _tripPoints = []; // Menyimpan semua titik lokasi dalam perjalanan saat ini

  static const double _minSpeedKmhToStartTrip = 10.0;
  // Kecepatan untuk mempertahankan trip mungkin tidak relevan jika kita hanya mengandalkan stop 15 detik
  // static const double _minSpeedKmhToMaintainTrip = 5.0;
  static const double _speedKmhConsideredStopped = 2.0;
  static const int _minConsecutivePointsAboveMinSpeed = 3;
  // static const int _minConsecutivePointsBelowMinSpeedToEnd = 5; // Tidak lagi digunakan untuk auto-end
  // static const double _minTripDistanceKm = 0.05; // Validasi jarak dilakukan di HomeScreen
  static const int _locationIntervalMilliseconds = 3000;
  static const double _distanceFilterMeters = 5.0;
  static const double _uiUpdateDistanceThresholdKm = 0.1;

  int _consecutiveHighSpeedPoints = 0;
  // int _consecutiveLowSpeedPoints = 0; // Tidak lagi digunakan untuk auto-end
  double _distanceSinceLastUiUpdateKm = 0.0;

  LiveLocationUpdateCallback? _onLiveLocationUpdate;
  MotorStoppedWithDataCallback? _onMotorStoppedWithData;

  Timer? _motorStoppedTimer;
  bool _isCurrentlyStoppedForTimer = false;
  static const Duration _motorStoppedNotificationDuration = Duration(seconds: 5); // DURASI BARU

  bool isTrackingActive() {
    return _locationSubscription != null && !_locationSubscription!.isPaused;
  }

  Future<bool> _checkAndRequestPermissions() async {
    // ... (kode _checkAndRequestPermissions tidak berubah, sudah ada di file Anda)
    print("[LocationService] Memeriksa izin lokasi...");
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      print("[LocationService] Layanan lokasi mati, meminta untuk diaktifkan...");
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        print("[LocationService] Pengguna menolak mengaktifkan layanan lokasi.");
        return false;
      }
      print("[LocationService] Layanan lokasi berhasil diaktifkan oleh pengguna.");
    } else {
      print("[LocationService] Layanan lokasi sudah aktif.");
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      print("[LocationService] Izin lokasi ditolak, meminta izin...");
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        print("[LocationService] Pengguna menolak memberikan izin lokasi.");
        return false;
      }
      print("[LocationService] Izin lokasi berhasil diberikan oleh pengguna.");
    } else {
      print("[LocationService] Izin lokasi sudah ada: $permissionGranted");
    }
    return true;
  }


  // Hapus TripDetectedCallback dari parameter jika tidak digunakan untuk alur utama
  Future<void> startTracking({
    LiveLocationUpdateCallback? onLiveLocationUpdate,
    MotorStoppedWithDataCallback? onMotorStoppedWithData,
  }) async {
    if (isTrackingActive()) {
      print("[LocationService] Pelacakan sudah aktif.");
      return;
    }
    print("[LocationService] Mencoba memulai pelacakan...");

    _onLiveLocationUpdate = onLiveLocationUpdate;
    _onMotorStoppedWithData = onMotorStoppedWithData;

    final hasPermission = await _checkAndRequestPermissions();
    if (!hasPermission) {
      print("[LocationService] Izin lokasi tidak ada. Pelacakan tidak dimulai.");
      return;
    }

    await location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: _locationIntervalMilliseconds,
      distanceFilter: _distanceFilterMeters,
    );

    // Jangan reset trip state di sini jika kita mau resume trip yang belum dikonfirmasi.
    // Reset hanya jika trip sebelumnya sudah dikonfirmasi atau dibatalkan.
    // Untuk sekarang, asumsikan setiap startTracking memulai sesi baru atau melanjutkan yang belum selesai.
    // Jika _isTripStarted false, maka reset.
    if (!_isTripStarted) {
        _resetTripStateInternal();
    }
    _previousLocationData = null; // Selalu reset previous location

    _locationSubscription = location.onLocationChanged.listen((LocationData currentLocationData) {
      if (currentLocationData.latitude == null || currentLocationData.longitude == null) return;
      if (currentLocationData.accuracy != null && currentLocationData.accuracy! > 30) return;

      double speedMs = currentLocationData.speed ?? 0.0;
      double speedKmh = speedMs * 3.6;

      if (!_isTripStarted) {
        if (speedKmh >= _minSpeedKmhToStartTrip) {
          _consecutiveHighSpeedPoints++;
          if (_consecutiveHighSpeedPoints >= _minConsecutivePointsAboveMinSpeed) {
            _isTripStarted = true;
            _tripStartTime = DateTime.now();
            _accumulatedDistanceKm = 0.0;
            _distanceSinceLastUiUpdateKm = 0.0;
            _tripPoints = [currentLocationData]; // Poin pertama
            _consecutiveHighSpeedPoints = 0;
            print("[LocationService] ------- PERJALANAN BARU DIMULAI ------- Speed: ${speedKmh.toStringAsFixed(1)} km/h");
            if (_onLiveLocationUpdate != null) {
              _onLiveLocationUpdate!(currentLocationData, _accumulatedDistanceKm);
            }
          }
        } else {
          _consecutiveHighSpeedPoints = 0;
        }
         // Kirim update UI bahkan jika trip belum mulai, untuk koordinat
        if (_onLiveLocationUpdate != null && !_isTripStarted) {
            _onLiveLocationUpdate!(currentLocationData, 0.0);
        }
      } else { // Jika _isTripStarted == true
        // Tambahkan poin saat ini ke perjalanan
        if (_previousLocationData != null) {
            final latlong.Distance distanceCalculator = latlong.Distance();
            double distanceMovedMeters = distanceCalculator(
                latlong.LatLng(_previousLocationData!.latitude!, _previousLocationData!.longitude!),
                latlong.LatLng(currentLocationData.latitude!, currentLocationData.longitude!),
            );
            if (distanceMovedMeters > 0) {
                _accumulatedDistanceKm += (distanceMovedMeters / 1000.0);
                _distanceSinceLastUiUpdateKm += (distanceMovedMeters / 1000.0);
            }
        }
        _tripPoints.add(currentLocationData);

        if (_onLiveLocationUpdate != null) {
          if (_distanceSinceLastUiUpdateKm >= _uiUpdateDistanceThresholdKm || _tripPoints.length == 1) {
            _onLiveLocationUpdate!(currentLocationData, _accumulatedDistanceKm);
            _distanceSinceLastUiUpdateKm = 0.0;
          } else {
            // Kirim update lokasi saja tanpa reset _distanceSinceLastUiUpdateKm
            // agar odometer tidak update terus jika jarak < 100m tapi koordinat ingin diupdate
             _onLiveLocationUpdate!(currentLocationData, _accumulatedDistanceKm);
          }
        }

        // Logika Deteksi Motor Berhenti 15 detik
        if (speedKmh < _speedKmhConsideredStopped) {
          if (!_isCurrentlyStoppedForTimer) {
            _isCurrentlyStoppedForTimer = true;
            _motorStoppedTimer?.cancel();
            print("[LocationService] Kecepatan rendah (<${_speedKmhConsideredStopped}kmh). Memulai timer ${_motorStoppedNotificationDuration.inSeconds} detik untuk notifikasi motor berhenti.");
            _motorStoppedTimer = Timer(_motorStoppedNotificationDuration, () {
              if (_isCurrentlyStoppedForTimer && _isTripStarted && _onMotorStoppedWithData != null && _tripPoints.isNotEmpty) {
                print("[LocationService] Timer motor berhenti SELESAI. Motor masih berhenti. Menyiapkan data dan memanggil callback.");
                
                DateTime actualTripStartTime = _tripStartTime ?? _tripPoints.first.timestampFromDevice(); // Fallback
                LocationData actualStartLocation = _tripPoints.first;

                TentativeTripData data = TentativeTripData(
                  distanceKm: _accumulatedDistanceKm,
                  startTime: actualTripStartTime,
                  startLocation: actualStartLocation,
                  endTime: currentLocationData.timestampFromDevice(), // Waktu saat ini saat berhenti
                  endLocation: currentLocationData // Lokasi saat ini saat berhenti
                );
                _onMotorStoppedWithData!(data);
                // JANGAN reset trip di sini. Reset akan dilakukan oleh HomeScreen setelah konfirmasi.
                // Namun, reset timer agar tidak berulang.
                _isCurrentlyStoppedForTimer = false;
              } else {
                 print("[LocationService] Timer motor berhenti selesai, TAPI kondisi tidak terpenuhi (stopped: $_isCurrentlyStoppedForTimer, tripStarted: $_isTripStarted, points: ${_tripPoints.isNotEmpty})");
                 _isCurrentlyStoppedForTimer = false; // Reset jika tidak jadi kirim
              }
            });
          }
        } else { // Jika motor bergerak lagi
          if (_isCurrentlyStoppedForTimer) {
            _isCurrentlyStoppedForTimer = false;
            _motorStoppedTimer?.cancel();
            print("[LocationService] Motor bergerak lagi (>${_speedKmhConsideredStopped}kmh), timer motor berhenti dibatalkan.");
          }
        }
      }
      _previousLocationData = currentLocationData;
    });
    print("[LocationService] Pelacakan lokasi berhasil dimulai.");
  }

  void stopTracking() {
    print("[LocationService] Mencoba menghentikan pelacakan...");
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _previousLocationData = null;
    _motorStoppedTimer?.cancel();
    _isCurrentlyStoppedForTimer = false;
    print("[LocationService] Pelacakan dihentikan. Timer (jika ada) dibatalkan.");
    // Jangan reset trip state di sini, biarkan HomeScreen yang mengontrolnya
    // agar data perjalanan tentatif tidak hilang sebelum dikonfirmasi.
  }

  // Metode internal untuk mereset state perjalanan
  void _resetTripStateInternal() {
    print("[LocationService] Mereset state perjalanan internal.");
    _isTripStarted = false;
    _tripStartTime = null;
    _accumulatedDistanceKm = 0.0;
    _tripPoints = [];
    _consecutiveHighSpeedPoints = 0;
    _motorStoppedTimer?.cancel();
    _isCurrentlyStoppedForTimer = false;
  }

  // Metode publik yang akan dipanggil oleh HomeScreen untuk mereset setelah konfirmasi
  void resetCurrentTripDetection() {
    print("[LocationService] resetCurrentTripDetection dipanggil dari luar (misal HomeScreen).");
    _resetTripStateInternal();
    // Jika tracking masih aktif, _previousLocationData akan di-set lagi oleh stream.
    // Jika tracking dihentikan, _previousLocationData sudah null.
  }
}

// Helper extension untuk mendapatkan DateTime dari LocationData
extension LocationDataTimestamp on LocationData {
  DateTime timestampFromDevice() {
    if (time != null) {
      return DateTime.fromMillisecondsSinceEpoch(time!.toInt());
    }
    return DateTime.now(); // Fallback jika time null
  }
}