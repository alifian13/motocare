import 'dart:async';
import 'package:flutter/foundation.dart'; 
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:motocare/services/api_service.dart'; 

enum RideState {
  IDLE,
  RIDING,
}

class BackgroundTrackingService {
  BackgroundTrackingService._privateConstructor();
  static final BackgroundTrackingService instance = BackgroundTrackingService._privateConstructor();

  final Location _location = Location();
  final ApiService _apiService = ApiService();
  StreamSubscription<LocationData>? _locationSubscription;
  StreamSubscription<ActivityEvent>? _activitySubscription;

  bool isTracking() {
    return _locationSubscription != null && !_locationSubscription!.isPaused;
  }

  //pelacakan di latar belakang.
  Future<void> startService(int vehicleId) async {
    if (isTracking()) return;

    try {
      await _location.enableBackgroundMode(enable: true);
    } catch (e) {
      print("Error saat mengaktifkan background mode: $e");
      return;
    }
    
    await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 15000,
      distanceFilter: 15,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTrackingActive', true);
    await prefs.setInt('trackingVehicleId', vehicleId);
    await prefs.setInt('rideState', RideState.IDLE.index);

    _locationSubscription = _location.onLocationChanged.listen(_onLocationUpdate);
    _activitySubscription = ActivityRecognition().activityStream().listen(_onActivityUpdate);

    print("[Intelligent Tracking Service] Service dimulai untuk Vehicle ID: $vehicleId");
  }

  /// Menghentikan servis pelacakan.
  Future<void> stopService() async {
    await _locationSubscription?.cancel();
    await _activitySubscription?.cancel();
    _locationSubscription = null;
    _activitySubscription = null;
    
    await _location.enableBackgroundMode(enable: false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTrackingActive', false);
    await prefs.remove('trackingVehicleId');
    print("[Intelligent Tracking Service] Service dihentikan.");
  }

  Future<void> _onActivityUpdate(ActivityEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    var currentState = RideState.values[prefs.getInt('rideState') ?? RideState.IDLE.index];

    print("AKTIVITAS TERDETEKSI: ${event.type} (${event.confidence}%)");

    RideState newState = currentState;

    if (event.type == ActivityType.IN_VEHICLE && event.confidence > 70) {
      newState = RideState.RIDING;
    } 
    else if (event.type == ActivityType.STILL || event.type == ActivityType.WALKING || event.type == ActivityType.RUNNING) {
      newState = RideState.IDLE;
    }

    if (newState != currentState) {
      print("==> Perubahan State: Dari $currentState menjadi $newState");
      await prefs.setInt('rideState', newState.index);

      if (newState == RideState.IDLE && currentState == RideState.RIDING) {
        print("==> Perjalanan Selesai. Menghapus titik lokasi terakhir.");
        await prefs.remove('lastLat');
        await prefs.remove('lastLon');
      }
    }
  }

  //hanya merekam jika state sedang RIDING.
  Future<void> _onLocationUpdate(LocationData currentLocation) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('isTrackingActive') ?? false)) return;

    var state = RideState.values[prefs.getInt('rideState') ?? RideState.IDLE.index];

    if (state == RideState.RIDING) {
      final vehicleId = prefs.getInt('trackingVehicleId');
      if (vehicleId != null) {
        print("...Merekam lokasi karena State adalah RIDING...");
        await _recordTripLeg(prefs, vehicleId, currentLocation);
      }
    }
  }

  Future<void> _recordTripLeg(SharedPreferences prefs, int vehicleId, LocationData currentLocation) async {
    final lastLat = prefs.getDouble('lastLat');
    final lastLon = prefs.getDouble('lastLon');
    final currentLat = currentLocation.latitude;
    final currentLon = currentLocation.longitude;

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
  
  Future<void> _saveLastPoint(SharedPreferences prefs, LocationData location) async {
    if (location.latitude != null && location.longitude != null) {
      await prefs.setDouble('lastLat', location.latitude!);
      await prefs.setDouble('lastLon', location.longitude!);
    }
  }
}