import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/spare_part_model.dart';

class ApiService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (requiresAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<http.Response> get(String endpoint, {bool requiresAuth = true}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    print('[ApiService] GET: $url'); 
    print('[ApiService] Headers: $headers'); 
    return http.get(url, headers: headers);
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body,
      {bool requiresAuth = true}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    final encodedBody = jsonEncode(body);
    print('[ApiService] POST: $url'); 
    print('[ApiService] Headers: $headers'); 
    print('[ApiService] Body: $encodedBody'); 
    return http.post(url, headers: headers, body: encodedBody);
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body,
      {bool requiresAuth = true}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    final encodedBody = jsonEncode(body);
    print('[ApiService] PUT: $url'); 
    print('[ApiService] Headers: $headers'); 
    print('[ApiService] Body: $encodedBody'); 
    return http.put(url, headers: headers, body: encodedBody);
  }

  Future<http.Response> delete(String endpoint,
      {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    final encodedBody = body != null ? jsonEncode(body) : null;
    print('[ApiService] DELETE: $url'); 
    print('[ApiService] Headers: $headers'); 
    if (encodedBody != null) print('[ApiService] Body: $encodedBody'); 
    return http.delete(url, headers: headers, body: encodedBody);
  }

  Future<void> recordTrip({
    required int vehicleId,
    required double distanceKm,
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) async {
    final String endpoint = '/vehicles/$vehicleId/trips';
    
    final Map<String, dynamic> body = {
      'distance_km': distanceKm,
      'start_latitude': startLatitude,
      'start_longitude': startLongitude,
      'end_latitude': endLatitude,
      'end_longitude': endLongitude,
    };

    final response = await post(endpoint, body, requiresAuth: true);

    if (response.statusCode != 201) {
      throw Exception('Gagal mencatat perjalanan: ${response.body}');
    } else {
      print('Trip berhasil dicatat untuk vehicle $vehicleId');
    }
  }

  Future<SparePart> getSparePart(int vehicleId, String serviceName) async {
    final response = await get('/spare-parts/for-vehicle/$vehicleId/$serviceName');

    if (response.statusCode == 200) {
      return sparePartFromJson(response.body);
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Gagal memuat data spare part');
    }
  }
}