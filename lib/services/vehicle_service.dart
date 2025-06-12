// lib/services/vehicle_service.dart
import 'dart:convert';
import 'package:motocare/models/vehicle_model.dart';
import 'package:motocare/models/trip_model.dart'; // Pastikan impor ini ada
import 'package:motocare/models/service_history_item.dart';
import 'package:motocare/models/schedule_item.dart';
import 'package:motocare/services/api_service.dart';

class VehicleService {
  final ApiService _apiService = ApiService();

  // --- Metode untuk mendapatkan semua kendaraan pengguna ---
  Future<List<Vehicle>> getMyVehicles() async {
    try {
      final response = await _apiService.get('/vehicles/my-vehicles');
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<Vehicle> vehicles = body.map((dynamic item) => Vehicle.fromJson(item)).toList();
        return vehicles;
      } else {
        print('[VehicleService] Gagal mendapatkan kendaraan: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      print('[VehicleService] Error di getMyVehicles: $e');
      return [];
    }
  }

  // --- Metode untuk menambah kendaraan baru ---
  Future<Map<String, dynamic>> addVehicle(Map<String, dynamic> vehicleData) async {
    try {
      final response = await _apiService.post('/vehicles', vehicleData);
      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': responseBody};
      } else {
        return {'success': false, 'message': responseBody['message'] ?? 'Gagal menambah kendaraan'};
      }
    } catch (e) {
      print('[VehicleService] Error di addVehicle: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: ${e.toString()}'};
    }
  }

  // --- Metode untuk menambah perjalanan ---
  Future<Map<String, dynamic>> addTrip(String vehicleId, Map<String, dynamic> tripData) async {
    try {
      final response = await _apiService.post('/vehicles/${vehicleId.toString()}/trips', tripData);
      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': responseBody};
      } else {
        return {'success': false, 'message': responseBody['message'] ?? 'Gagal mencatat perjalanan'};
      }
    } catch (e) {
      print('[VehicleService] Error di addTrip: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: ${e.toString()}'};
    }
  }

  // --- Metode untuk menambah riwayat servis ---
  Future<Map<String, dynamic>> addServiceHistory(String vehicleId, Map<String, dynamic> serviceData) async {
    try {
      final response = await _apiService.post('/vehicles/${vehicleId.toString()}/service-history', serviceData);
      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': responseBody};
      } else {
        return {'success': false, 'message': responseBody['message'] ?? 'Gagal menambah riwayat servis'};
      }
    } catch (e) {
      print('[VehicleService] Error di addServiceHistory: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: ${e.toString()}'};
    }
  }

  // --- Metode untuk mendapatkan jadwal perawatan ---
  Future<List<ScheduleItem>> getSchedules(String vehicleId) async {
    try {
      final response = await _apiService.get('/vehicles/${vehicleId.toString()}/schedules');
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<ScheduleItem> schedules = body
            .map((dynamic item) => ScheduleItem.fromJson(item))
            .toList();
        return schedules;
      } else {
        print('[VehicleService] Gagal mendapatkan jadwal: ${response.statusCode} ${response.body}');
        throw Exception('Gagal memuat jadwal perawatan. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('[VehicleService] Error di getSchedules: $e');
      throw Exception('Terjadi kesalahan saat memuat jadwal: ${e.toString()}');
    }
  }

  // --- Metode untuk mendapatkan riwayat servis ---
  Future<List<ServiceHistoryItem>> getServiceHistory(String vehicleId) async {
    try {
      final response = await _apiService.get('/vehicles/${vehicleId.toString()}/history');
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<ServiceHistoryItem> historyItems = body
            .map((dynamic item) => ServiceHistoryItem.fromJson(item))
            .toList();
        return historyItems;
      } else {
         print('[VehicleService] Gagal mendapatkan riwayat servis: ${response.statusCode} ${response.body}');
        throw Exception('Gagal memuat riwayat servis. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('[VehicleService] Error di getServiceHistory: $e');
      throw Exception('Terjadi kesalahan saat memuat riwayat servis: ${e.toString()}');
    }
  }

  // --- Metode untuk Update Odometer Manual ---
  Future<Map<String, dynamic>> updateOdometerManually(
      String vehicleId, int newOdometer) async {
    try {
      final Map<String, dynamic> requestBody = {
        'current_odometer': newOdometer,
      };
      final response = await _apiService.put(
          '/vehicles/${vehicleId.toString()}/odometer', requestBody);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal update odometer manual'
        };
      }
    } catch (e) {
      print('[VehicleService] Error di updateOdometerManually: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: ${e.toString()}'};
    }
  }

  // --- Metode untuk mendapatkan perjalanan terbaru ---
  Future<List<Trip>> getRecentTrips(String vehicleId, {int limit = 3}) async {
    try {
      // PERBAIKAN: Menggunakan endpoint 'all-trips' yang benar sesuai backend Anda
      final response = await _apiService.get('/vehicles/$vehicleId/all-trips?limit=$limit&sortBy=end_time&sortOrder=DESC');
      
      if (response.statusCode == 200) {
        // Backend Anda mengembalikan array langsung di properti 'trips'
        final responseBody = jsonDecode(response.body);
        if (responseBody['trips'] != null && responseBody['trips'] is List) {
            List<dynamic> body = responseBody['trips'];
            List<Trip> trips = body.map((dynamic item) => Trip.fromJson(item)).toList();
            return trips;
        } else {
             print('[VehicleService] Format respons perjalanan terbaru tidak sesuai: ${response.body}');
            return [];
        }
      } else {
        print('[VehicleService] Gagal mendapatkan perjalanan terbaru: ${response.statusCode} ${response.body}');
        return []; // Kembalikan list kosong jika gagal
      }
    } catch (e) {
      print('[VehicleService] Error di getRecentTrips: $e');
      return []; // Kembalikan list kosong jika terjadi error
    }
  }
}
