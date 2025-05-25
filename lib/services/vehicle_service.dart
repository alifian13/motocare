// services/vehicle_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_service.dart'; // To get the token

class VehicleService {
  final String _baseUrl = "http://127.0.0.1:3000/api"; // Ensure this matches
  final UserService _userService = UserService();

  Future<Map<String, dynamic>> getMyVehicles() async {
    try {
      String? token = await _userService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'User not authenticated. Please login.'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/vehicles/my-vehicles'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token', // Send token in Authorization header
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData}; // responseData will be a List of vehicles
      } else if (response.statusCode == 404) {
        return {'success': true, 'data': []}; // No vehicles found, return empty list
      }
      else {
        return {'success': false, 'message': responseData['message'] ?? 'Failed to fetch vehicles'};
      }
    } catch (e) {
      print("Get My Vehicles Exception: $e");
      return {'success': false, 'message': 'Cannot connect to server: $e'};
    }
  }

  Future<Map<String, dynamic>> getServiceHistory(int vehicleId) async {
    try {
      String? token = await _userService.getToken(); // Asumsi _userService sudah diinisialisasi
      if (token == null) {
        return {'success': false, 'message': 'User not authenticated.'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/vehicles/$vehicleId/history'), // Endpoint baru
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // responseData akan berupa List<Map<String, dynamic>>
        return {'success': true, 'data': responseData};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Failed to fetch service history'};
      }
    } catch (e) {
      print("Get Service History Exception: $e");
      return {'success': false, 'message': 'Cannot connect to server: $e'};
    }
  }

  Future<Map<String, dynamic>> getMaintenanceSchedules(int vehicleId) async {
  // Mirip dengan getServiceHistory, tapi panggil endpoint /api/vehicles/$vehicleId/schedules
  try {
    String? token = await _userService.getToken();
    if (token == null) return {'success': false, 'message': 'User not authenticated.'};
    final response = await http.get(
      Uri.parse('$_baseUrl/vehicles/$vehicleId/schedules'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'data': responseData};
    } else {
      return {'success': false, 'message': responseData['message'] ?? 'Failed to fetch schedules'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Cannot connect to server: $e'};
  }
}

  // TODO: Add methods for:
  // addVehicle(Map<String, dynamic> vehicleData)
  // updateVehicleOdometer(int vehicleId, int newOdometer)
  // getServiceHistory(int vehicleId)
  // addServiceHistory(int vehicleId, Map<String, dynamic> historyData)
} 